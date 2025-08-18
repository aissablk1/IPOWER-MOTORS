#!/bin/bash
# Script de renouvellement automatique des certificats SSL OVH
# Pour ipowerfrance.fr

set -e

# Configuration
DOMAIN="ipowerfrance.fr"
EMAIL="admin@ipowerfrance.fr"
OVH_APP_KEY=""
OVH_APP_SECRET=""
OVH_CONSUMER_KEY=""
OVH_SERVICE_NAME=""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERREUR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

# Vérification des prérequis
check_prerequisites() {
    log "🔍 Vérification des prérequis..."
    
    # Vérifier curl
    if ! command -v curl &> /dev/null; then
        error "curl n'est pas installé"
    fi
    
    # Vérifier openssl
    if ! command -v openssl &> /dev/null; then
        error "openssl n'est pas installé"
    fi
    
    # Vérifier les variables OVH
    if [[ -z "$OVH_APP_KEY" ]] || [[ -z "$OVH_APP_SECRET" ]] || [[ -z "$OVH_CONSUMER_KEY" ]]; then
        error "Variables OVH non configurées"
    fi
    
    success "Tous les prérequis sont satisfaits"
}

# Génération de la signature OVH
generate_signature() {
    local method="$1"
    local url="$2"
    local body="$3"
    local timestamp="$4"
    
    local to_sign="$OVH_APP_SECRET+$OVH_CONSUMER_KEY+$method+https://eu.api.ovh.com/1.0$url+$body+$timestamp"
    echo -n "$to_sign" | sha1sum | cut -d' ' -f1
}

# Appel API OVH
call_ovh_api() {
    local method="$1"
    local url="$2"
    local body="$3"
    
    local timestamp=$(date +%s)
    local signature=$(generate_signature "$method" "$url" "$body" "$timestamp")
    
    curl -s -X "$method" \
        -H "Content-Type: application/json" \
        -H "X-Ovh-Application: $OVH_APP_KEY" \
        -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" \
        -H "X-Ovh-Timestamp: $timestamp" \
        -H "X-Ovh-Signature: $1$signature" \
        -d "$body" \
        "https://eu.api.ovh.com/1.0$url"
}

# Vérification de l'expiration du certificat
check_certificate_expiry() {
    log "🔍 Vérification de l'expiration du certificat..."
    
    # Récupérer le certificat depuis le serveur
    local cert_info=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -dates)
    
    if [[ $? -ne 0 ]]; then
        error "Impossible de récupérer le certificat pour $DOMAIN"
    fi
    
    # Extraire la date d'expiration
    local expiry_date=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)
    local expiry_timestamp=$(date -d "$expiry_date" +%s)
    local current_timestamp=$(date +%s)
    local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
    
    log "Date d'expiration: $expiry_date"
    log "Jours restants: $days_until_expiry"
    
    if [[ $days_until_expiry -le 30 ]]; then
        warning "Le certificat expire dans $days_until_expiry jours"
        return 0
    else
        log "Le certificat est encore valide pour $days_until_expiry jours"
        return 1
    fi
}

# Renouvellement du certificat via Let's Encrypt
renew_certificate_letsencrypt() {
    log "🔄 Renouvellement du certificat via Let's Encrypt..."
    
    # Créer le répertoire de travail
    local work_dir="/tmp/ssl-renewal-$(date +%s)"
    mkdir -p "$work_dir"
    cd "$work_dir"
    
    # Télécharger certbot
    if ! command -v certbot &> /dev/null; then
        log "Installation de certbot..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y certbot
        elif command -v yum &> /dev/null; then
            sudo yum install -y certbot
        else
            error "Impossible d'installer certbot automatiquement"
        fi
    fi
    
    # Renouvellement du certificat
    local certbot_cmd="certbot certonly --standalone --email $EMAIL --agree-tos --no-eff-email -d $DOMAIN -d www.$DOMAIN"
    
    if sudo $certbot_cmd; then
        success "Certificat Let's Encrypt renouvelé avec succès"
        
        # Copier les nouveaux certificats
        local cert_path="/etc/letsencrypt/live/$DOMAIN"
        if [[ -d "$cert_path" ]]; then
            sudo cp "$cert_path/fullchain.pem" "/etc/ssl/certs/$DOMAIN.crt"
            sudo cp "$cert_path/privkey.pem" "/etc/ssl/private/$DOMAIN.key"
            sudo chmod 644 "/etc/ssl/certs/$DOMAIN.crt"
            sudo chmod 600 "/etc/ssl/private/$DOMAIN.key"
            
            success "Certificats copiés dans /etc/ssl/"
        fi
    else
        error "Échec du renouvellement du certificat"
    fi
    
    # Nettoyage
    cd /
    rm -rf "$work_dir"
}

# Renouvellement du certificat via OVH
renew_certificate_ovh() {
    log "🔄 Renouvellement du certificat via OVH..."
    
    # Récupérer la liste des certificats
    local certificates=$(call_ovh_api "GET" "/ssl" "")
    
    if [[ $? -ne 0 ]]; then
        error "Impossible de récupérer la liste des certificats"
    fi
    
    # Chercher le certificat pour notre domaine
    local cert_id=$(echo "$certificates" | grep -o '"[^"]*"' | grep "$DOMAIN" | head -1 | tr -d '"')
    
    if [[ -z "$cert_id" ]]; then
        error "Aucun certificat trouvé pour $DOMAIN"
    fi
    
    log "Certificat trouvé: $cert_id"
    
    # Renouveler le certificat
    local renew_body="{\"domain\":\"$DOMAIN\"}"
    local renew_result=$(call_ovh_api "POST" "/ssl/$cert_id/renew" "$renew_body")
    
    if [[ $? -eq 0 ]]; then
        success "Demande de renouvellement envoyée à OVH"
        log "Le renouvellement peut prendre quelques minutes"
    else
        error "Échec de la demande de renouvellement"
    fi
}

# Test du certificat
test_certificate() {
    log "🧪 Test du certificat..."
    
    # Test de connectivité
    if curl -f -s "https://$DOMAIN" >/dev/null; then
        success "Connexion HTTPS réussie"
    else
        warning "Problème de connexion HTTPS"
    fi
    
    # Test de la chaîne de certificats
    local chain_test=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -text | grep -c "Certificate:")
    
    if [[ $chain_test -gt 1 ]]; then
        success "Chaîne de certificats complète"
    else
        warning "Chaîne de certificats incomplète"
    fi
}

# Notification
send_notification() {
    local message="$1"
    local status="$2"
    
    log "📧 Envoi de notification..."
    
    # Envoyer un email (exemple avec mail)
    if command -v mail &> /dev/null; then
        echo "Renouvellement SSL $DOMAIN: $status - $message" | mail -s "SSL Renewal $DOMAIN" "$EMAIL"
    fi
    
    # Notification Slack (si configuré)
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        local slack_payload="{\"text\":\"SSL Renewal $DOMAIN: $status - $message\"}"
        curl -X POST -H 'Content-type: application/json' --data "$slack_payload" "$SLACK_WEBHOOK_URL"
    fi
    
    success "Notification envoyée"
}

# Fonction principale
main() {
    log "🚀 Démarrage du renouvellement SSL pour $DOMAIN..."
    
    # Vérifications
    check_prerequisites
    
    # Vérifier l'expiration
    if check_certificate_expiry; then
        log "Renouvellement nécessaire"
        
        # Essayer Let's Encrypt d'abord
        if renew_certificate_letsencrypt; then
            send_notification "Certificat renouvelé via Let's Encrypt" "SUCCÈS"
        else
            # Fallback vers OVH
            log "Tentative de renouvellement via OVH..."
            if renew_certificate_ovh; then
                send_notification "Demande de renouvellement envoyée à OVH" "EN_COURS"
            else
                send_notification "Échec du renouvellement automatique" "ERREUR"
                error "Renouvellement manuel requis"
            fi
        fi
        
        # Test du certificat
        test_certificate
    else
        log "Aucun renouvellement nécessaire"
        send_notification "Certificat encore valide" "INFO"
    fi
    
    success "Processus de renouvellement terminé"
}

# Gestion des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_RENEWAL=true
            shift
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --ovh-only)
            OVH_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --force        Forcer le renouvellement même si pas expiré"
            echo "  --test-only    Tester seulement le certificat"
            echo "  --ovh-only     Utiliser seulement OVH (pas Let's Encrypt)"
            echo "  -h, --help     Afficher cette aide"
            exit 0
            ;;
        *)
            error "Option inconnue: $1"
            ;;
    esac
done

# Exécution
main "$@"
