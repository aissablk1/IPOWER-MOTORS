#!/bin/bash
# Script de déploiement S3 pour le frontend IPOWER MOTORS

set -e

# Configuration
BUCKET_NAME="ipower-motors-frontend"
REGION="eu-west-3"
CLOUDFRONT_DISTRIBUTION_ID=""
BUILD_DIR="dist"
CACHE_CONTROL="public, max-age=3600"

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
    
    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI n'est pas installé. Installez-le d'abord."
    fi
    
    # Vérifier la configuration AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI n'est pas configuré. Exécutez 'aws configure' d'abord."
    fi
    
    # Vérifier que le bucket existe
    if ! aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
        error "Le bucket S3 '$BUCKET_NAME' n'existe pas ou n'est pas accessible."
    fi
    
    # Vérifier que le dossier de build existe
    if [ ! -d "$BUILD_DIR" ]; then
        error "Le dossier de build '$BUILD_DIR' n'existe pas. Exécutez 'npm run build' d'abord."
    fi
    
    success "Tous les prérequis sont satisfaits"
}

# Build de l'application
build_application() {
    log "🏗️ Build de l'application..."
    
    # Vérifier si pnpm est disponible
    if command -v pnpm &> /dev/null; then
        pnpm run build
    else
        npm run build
    fi
    
    if [ ! -d "$BUILD_DIR" ]; then
        error "Le build a échoué. Vérifiez les erreurs de compilation."
    fi
    
    success "Application buildée avec succès"
}

# Synchronisation avec S3
sync_to_s3() {
    log "☁️ Synchronisation avec S3..."
    
    # Options de synchronisation
    SYNC_OPTIONS=(
        --delete                    # Supprimer les fichiers qui n'existent plus
        --cache-control "$CACHE_CONTROL"  # Contrôle du cache
        --metadata-directive REPLACE      # Remplacer les métadonnées
    )
    
    # Synchroniser les fichiers statiques
    aws s3 sync "$BUILD_DIR/" "s3://$BUCKET_NAME/" "${SYNC_OPTIONS[@]}"
    
    success "Synchronisation S3 terminée"
}

# Configuration des métadonnées spécifiques
set_metadata() {
    log "🏷️ Configuration des métadonnées..."
    
    # HTML - pas de cache (toujours frais)
    aws s3 cp "$BUILD_DIR/index.html" "s3://$BUCKET_NAME/index.html" \
        --cache-control "no-cache, no-store, must-revalidate" \
        --content-type "text/html" \
        --metadata-directive REPLACE
    
    # CSS - cache long
    find "$BUILD_DIR" -name "*.css" -exec aws s3 cp {} "s3://$BUCKET_NAME/{}" \
        --cache-control "public, max-age=31536000" \
        --content-type "text/css" \
        --metadata-directive REPLACE \;
    
    # JavaScript - cache long
    find "$BUILD_DIR" -name "*.js" -exec aws s3 cp {} "s3://$BUCKET_NAME/{}" \
        --cache-control "public, max-age=31536000" \
        --content-type "application/javascript" \
        --metadata-directive REPLACE \;
    
    # Images - cache moyen
    find "$BUILD_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" | \
        xargs -I {} aws s3 cp {} "s3://$BUCKET_NAME/{}" \
        --cache-control "public, max-age=86400" \
        --metadata-directive REPLACE
    
    # Fonts - cache très long
    find "$BUILD_DIR" -name "*.woff" -o -name "*.woff2" -o -name "*.ttf" -o -name "*.otf" -o -name "*.eot" | \
        xargs -I {} aws s3 cp {} "s3://$BUCKET_NAME/{}" \
        --cache-control "public, max-age=31536000" \
        --metadata-directive REPLACE
    
    success "Métadonnées configurées"
}

# Configuration de la redirection SPA
setup_spa_redirect() {
    log "🔄 Configuration de la redirection SPA..."
    
    # Créer un fichier de configuration pour la redirection SPA
    cat > "s3-website-config.json" << EOF
{
    "IndexDocument": {
        "Suffix": "index.html"
    },
    "ErrorDocument": {
        "Key": "index.html"
    },
    "RoutingRules": [
        {
            "Condition": {
                "HttpErrorCodeReturnedEquals": "404"
            },
            "Redirect": {
                "ReplaceKeyWith": "index.html"
            }
        }
    ]
}
EOF
    
    # Appliquer la configuration
    aws s3api put-bucket-website \
        --bucket "$BUCKET_NAME" \
        --website-configuration file://s3-website-config.json
    
    # Nettoyer le fichier temporaire
    rm "s3-website-config.json"
    
    success "Configuration SPA appliquée"
}

# Invalidation CloudFront
invalidate_cloudfront() {
    if [[ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]]; then
        log "🔄 Invalidation CloudFront..."
        
        aws cloudfront create-invalidation \
            --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
            --paths "/*"
        
        success "Invalidation CloudFront créée"
    else
        warning "ID de distribution CloudFront non configuré, invalidation ignorée"
    fi
}

# Configuration des en-têtes de sécurité
setup_security_headers() {
    log "🔒 Configuration des en-têtes de sécurité..."
    
    # Créer un fichier de politique de bucket
    cat > "bucket-policy.json" << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF
    
    # Appliquer la politique
    aws s3api put-bucket-policy \
        --bucket "$BUCKET_NAME" \
        --policy file://bucket-policy.json
    
    # Nettoyer le fichier temporaire
    rm "bucket-policy.json"
    
    success "En-têtes de sécurité configurés"
}

# Vérification du déploiement
verify_deployment() {
    log "✅ Vérification du déploiement..."
    
    # Vérifier que les fichiers principaux sont présents
    local required_files=("index.html" "assets/js" "assets/css")
    
    for file in "${required_files[@]}"; do
        if aws s3 ls "s3://$BUCKET_NAME/$file" &> /dev/null; then
            log "✅ $file vérifié"
        else
            warning "⚠️ $file non trouvé"
        fi
    done
    
    # Afficher l'URL du site
    local website_url=$(aws s3api get-bucket-website --bucket "$BUCKET_NAME" --query 'WebsiteEndpoint' --output text 2>/dev/null || echo "N/A")
    
    if [[ "$website_url" != "N/A" ]]; then
        success "Site déployé avec succès !"
        log "URL: http://$website_url"
    else
        log "Site déployé, mais l'URL n'est pas encore disponible"
    fi
}

# Nettoyage
cleanup() {
    log "🧹 Nettoyage..."
    
    # Supprimer les fichiers temporaires s'ils existent
    rm -f "s3-website-config.json" "bucket-policy.json"
    
    success "Nettoyage terminé"
}

# Fonction principale
main() {
    log "🚀 Démarrage du déploiement S3 pour IPOWER MOTORS..."
    
    # Vérifications
    check_prerequisites
    
    # Déploiement
    build_application
    sync_to_s3
    set_metadata
    setup_spa_redirect
    setup_security_headers
    
    # Finalisation
    invalidate_cloudfront
    verify_deployment
    cleanup
    
    success "Déploiement S3 terminé avec succès !"
    log "Bucket: $BUCKET_NAME"
    log "Région: $REGION"
    
    if [[ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]]; then
        log "CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"
    fi
}

# Gestion des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --bucket)
            BUCKET_NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --cloudfront)
            CLOUDFRONT_DISTRIBUTION_ID="$2"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --cache-control)
            CACHE_CONTROL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --bucket NAME           Nom du bucket S3 (défaut: $BUCKET_NAME)"
            echo "  --region REGION         Région AWS (défaut: $REGION)"
            echo "  --cloudfront ID         ID de distribution CloudFront"
            echo "  --build-dir DIR         Dossier de build (défaut: $BUILD_DIR)"
            echo "  --cache-control CONTROL Contrôle du cache (défaut: $CACHE_CONTROL)"
            echo "  -h, --help              Afficher cette aide"
            echo ""
            echo "EXEMPLES:"
            echo "  $0                                    # Déploiement avec valeurs par défaut"
            echo "  $0 --bucket mon-bucket               # Déploiement sur un bucket spécifique"
            echo "  $0 --cloudfront E1234567890ABCD      # Avec invalidation CloudFront"
            exit 0
            ;;
        *)
            error "Option inconnue: $1"
            ;;
    esac
done

# Exécution
main "$@"
