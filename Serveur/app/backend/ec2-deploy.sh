#!/bin/bash
# Script de déploiement EC2 pour le backend IPOWER MOTORS

set -e

# Configuration
APP_NAME="ipower-backend"
APP_DIR="/opt/ipower-backend"
SERVICE_NAME="ipower-backend"
USER="ec2-user"
GROUP="ec2-user"

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
    
    # Vérifier que nous sommes sur EC2
    if ! curl -s http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
        warning "Ce script est conçu pour s'exécuter sur EC2"
    fi
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js n'est pas installé"
    fi
    
    # Vérifier npm
    if ! command -v npm &> /dev/null; then
        error "npm n'est pas installé"
    fi
    
    # Vérifier les permissions
    if [[ "$EUID" -ne 0 ]]; then
        error "Ce script doit être exécuté en tant que root"
    fi
    
    success "Tous les prérequis sont satisfaits"
}

# Arrêt du service
stop_service() {
    log "🛑 Arrêt du service $SERVICE_NAME..."
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        success "Service arrêté"
    else
        log "Service déjà arrêté"
    fi
}

# Sauvegarde de l'ancienne version
backup_current_version() {
    log "💾 Sauvegarde de la version actuelle..."
    
    if [[ -d "$APP_DIR" ]]; then
        local backup_dir="$APP_DIR.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$APP_DIR" "$backup_dir"
        success "Sauvegarde créée: $backup_dir"
    else
        log "Aucune version précédente à sauvegarder"
    fi
}

# Création du répertoire de l'application
create_app_directory() {
    log "📁 Création du répertoire de l'application..."
    
    mkdir -p "$APP_DIR"
    chown "$USER:$GROUP" "$APP_DIR"
    chmod 755 "$APP_DIR"
    
    success "Répertoire créé: $APP_DIR"
}

# Installation des dépendances
install_dependencies() {
    log "📦 Installation des dépendances..."
    
    cd "$APP_DIR"
    
    # Copier package.json et pnpm-lock.yaml
    if [[ -f "package.json" ]]; then
        # Installation des dépendances de production
        npm ci --only=production
        
        success "Dépendances installées"
    else
        error "package.json non trouvé"
    fi
}

# Configuration du service systemd
setup_systemd_service() {
    log "⚙️ Configuration du service systemd..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=IPOWER MOTORS Backend API
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$GROUP
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node dist/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Variables d'environnement
Environment=NODE_ENV=production
Environment=PORT=3001

# Sécurité
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR

# Limites
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

    # Recharger systemd
    systemctl daemon-reload
    
    # Activer le service
    systemctl enable "$SERVICE_NAME"
    
    success "Service systemd configuré"
}

# Configuration des logs
setup_logging() {
    log "📝 Configuration des logs..."
    
    # Créer le répertoire de logs
    mkdir -p "/var/log/$SERVICE_NAME"
    chown "$USER:$GROUP" "/var/log/$SERVICE_NAME"
    
    # Configuration logrotate
    cat > "/etc/logrotate.d/$SERVICE_NAME" << EOF
/var/log/$SERVICE_NAME/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $USER $GROUP
    postrotate
        systemctl reload $SERVICE_NAME > /dev/null 2>&1 || true
    endscript
}
EOF

    success "Configuration des logs terminée"
}

# Configuration du firewall
setup_firewall() {
    log "🔥 Configuration du firewall..."
    
    # Vérifier si ufw est installé
    if command -v ufw &> /dev/null; then
        # Autoriser le port de l'application
        ufw allow 3001/tcp
        
        # Autoriser SSH
        ufw allow ssh
        
        success "Firewall configuré"
    else
        warning "ufw non installé, configuration du firewall ignorée"
    fi
}

# Démarrage du service
start_service() {
    log "🚀 Démarrage du service..."
    
    systemctl start "$SERVICE_NAME"
    
    # Attendre que le service soit prêt
    sleep 5
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        success "Service démarré avec succès"
    else
        error "Échec du démarrage du service"
    fi
}

# Vérification de la santé
health_check() {
    log "🏥 Vérification de la santé du service..."
    
    # Attendre un peu que le service soit complètement démarré
    sleep 10
    
    # Test de connectivité
    if curl -f http://localhost:3001/health >/dev/null 2>&1; then
        success "Service en bonne santé"
    else
        warning "Service ne répond pas au health check"
        
        # Afficher les logs
        log "Derniers logs du service:"
        journalctl -u "$SERVICE_NAME" --no-pager -n 20
    fi
}

# Nettoyage des sauvegardes anciennes
cleanup_old_backups() {
    log "🧹 Nettoyage des anciennes sauvegardes..."
    
    # Garder seulement les 5 dernières sauvegardes
    local backup_count=$(find "$APP_DIR.backup."* -maxdepth 0 -type d 2>/dev/null | wc -l)
    
    if [[ $backup_count -gt 5 ]]; then
        local to_remove=$((backup_count - 5))
        find "$APP_DIR.backup."* -maxdepth 0 -type d -printf '%T@ %p\n' | \
            sort -n | head -n $to_remove | cut -d' ' -f2- | xargs rm -rf
        
        success "$to_remove anciennes sauvegardes supprimées"
    else
        log "Aucune sauvegarde à supprimer"
    fi
}

# Fonction principale
main() {
    log "🚀 Démarrage du déploiement EC2 pour $APP_NAME..."
    
    # Vérifications
    check_prerequisites
    
    # Déploiement
    stop_service
    backup_current_version
    create_app_directory
    install_dependencies
    setup_systemd_service
    setup_logging
    setup_firewall
    start_service
    
    # Vérifications post-déploiement
    health_check
    cleanup_old_backups
    
    success "Déploiement terminé avec succès !"
    log "Service: $SERVICE_NAME"
    log "Répertoire: $APP_DIR"
    log "Port: 3001"
    log "Logs: journalctl -u $SERVICE_NAME -f"
}

# Exécution
main "$@"
