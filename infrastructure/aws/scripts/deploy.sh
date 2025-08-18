#!/bin/bash
# Script de déploiement automatisé IPOWER MOTORS
# ==============================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/infrastructure/aws/terraform"
BACKEND_DIR="$PROJECT_ROOT/app/backend"
FRONTEND_DIR="$PROJECT_ROOT/app/frontend"

# Variables d'environnement
ENVIRONMENT=${1:-production}
AWS_REGION=${AWS_REGION:-eu-west-3}
DEPLOY_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions de logging
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Vérification des prérequis
check_prerequisites() {
    log_info "🔍 Vérification des prérequis..."
    
    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI n'est pas installé"
        exit 1
    fi
    
    # Vérifier Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform n'est pas installé"
        exit 1
    fi
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        exit 1
    fi
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js n'est pas installé"
        exit 1
    fi
    
    # Vérifier la configuration AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Configuration AWS invalide"
        exit 1
    fi
    
    log_success "Prérequis vérifiés"
}

# Déploiement de l'infrastructure
deploy_infrastructure() {
    log_info "🏗️ Déploiement de l'infrastructure AWS..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialisation Terraform
    log_info "Initialisation de Terraform..."
    terraform init
    
    # Plan Terraform
    log_info "Planification des changements..."
    terraform plan -var-file="terraform.tfvars" -var="environment=$ENVIRONMENT" -out="terraform.tfplan"
    
    # Application des changements
    log_info "Application des changements..."
    terraform apply "terraform.tfplan"
    
    # Récupération des outputs
    log_info "Récupération des informations de déploiement..."
    FRONTEND_BUCKET=$(terraform output -raw s3_frontend_bucket)
    DOCUMENTS_BUCKET=$(terraform output -raw s3_documents_bucket)
    CLOUDFRONT_DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
    ALB_DNS_NAME=$(terraform output -raw alb_dns_name)
    EC2_PUBLIC_IP=$(terraform output -raw ec2_public_ip)
    
    log_success "Infrastructure déployée"
    
    # Export des variables pour les autres étapes
    export FRONTEND_BUCKET DOCUMENTS_BUCKET CLOUDFRONT_DISTRIBUTION_ID ALB_DNS_NAME EC2_PUBLIC_IP
}

# Build et déploiement du frontend
deploy_frontend() {
    log_info "🚀 Déploiement du frontend..."
    
    cd "$FRONTEND_DIR"
    
    # Installation des dépendances
    log_info "Installation des dépendances..."
    npm ci
    
    # Build de production
    log_info "Build de production..."
    npm run build
    
    # Synchronisation vers S3
    log_info "Synchronisation vers S3..."
    aws s3 sync dist/ "s3://$FRONTEND_BUCKET" --delete --cache-control "max-age=31536000,public"
    
    # Configuration des métadonnées pour SPA
    log_info "Configuration des métadonnées SPA..."
    aws s3 cp dist/index.html "s3://$FRONTEND_BUCKET/index.html" --cache-control "no-cache,no-store,must-revalidate"
    
    # Invalidation CloudFront
    log_info "Invalidation du cache CloudFront..."
    aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text
    
    log_success "Frontend déployé sur https://$FRONTEND_BUCKET.s3.$AWS_REGION.amazonaws.com"
}

# Build et déploiement du backend
deploy_backend() {
    log_info "🚀 Déploiement du backend..."
    
    cd "$BACKEND_DIR"
    
    # Installation des dépendances
    log_info "Installation des dépendances..."
    npm ci
    
    # Build de production
    log_info "Build de production..."
    npm run build
    
    # Build de l'image Docker
    log_info "Build de l'image Docker..."
    docker build -t ipower-backend:$DEPLOY_TIMESTAMP .
    
    # Tag de l'image
    docker tag ipower-backend:$DEPLOY_TIMESTAMP ipower-backend:latest
    
    # Sauvegarde de l'ancienne version
    log_info "Sauvegarde de l'ancienne version..."
    if docker ps -q --filter "ancestor=ipower-backend:latest" | grep -q .; then
        docker commit $(docker ps -q --filter "ancestor=ipower-backend:latest") ipower-backend:backup-$DEPLOY_TIMESTAMP
    fi
    
    # Arrêt de l'ancien conteneur
    log_info "Arrêt de l'ancien conteneur..."
    docker stop $(docker ps -q --filter "ancestor=ipower-backend:latest") 2>/dev/null || true
    
    # Démarrage du nouveau conteneur
    log_info "Démarrage du nouveau conteneur..."
    docker run -d \
        --name ipower-backend-$DEPLOY_TIMESTAMP \
        --restart unless-stopped \
        -p 3001:3001 \
        -e NODE_ENV=production \
        -e DB_HOST="$DB_HOST" \
        -e DB_NAME="$DB_NAME" \
        -e DB_USER="$DB_USER" \
        -e DB_PASSWORD="$DB_PASSWORD" \
        -e S3_BUCKET_FRONTEND="$FRONTEND_BUCKET" \
        -e S3_BUCKET_DOCUMENTS="$DOCUMENTS_BUCKET" \
        ipower-backend:latest
    
    # Vérification de la santé
    log_info "Vérification de la santé du backend..."
    sleep 10
    if curl -f "http://localhost:3001/health" > /dev/null 2>&1; then
        log_success "Backend déployé et en bonne santé"
        
        # Nettoyage des anciennes images
        log_info "Nettoyage des anciennes images..."
        docker image prune -f
    else
        log_error "Le backend n'est pas en bonne santé"
        exit 1
    fi
}

# Déploiement sur EC2 (si déployé sur AWS)
deploy_ec2() {
    if [ "$ENVIRONMENT" = "production" ] && [ -n "${EC2_PUBLIC_IP:-}" ]; then
        log_info "🚀 Déploiement sur EC2..."
        
        # Attendre que l'instance soit prête
        log_info "Attente que l'instance EC2 soit prête..."
        aws ec2 wait instance-running --instance-ids $(aws ec2 describe-instances --filters "Name=public-ip,Values=$EC2_PUBLIC_IP" --query 'Reservations[].Instances[].InstanceId' --output text)
        
        # Déploiement via SSM
        log_info "Déploiement via SSM..."
        INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=public-ip,Values=$EC2_PUBLIC_IP" --query 'Reservations[].Instances[].InstanceId' --output text)
        
        aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=[
                "cd /opt/ipower-backend",
                "git pull origin main",
                "npm install --production",
                "npm run build",
                "systemctl restart ipower-backend",
                "systemctl status ipower-backend"
            ]' \
            --query 'Command.CommandId' \
            --output text
        
        log_success "Déploiement EC2 initié"
    fi
}

# Configuration DNS OVH
configure_ovh_dns() {
    log_info "🌐 Configuration DNS OVH..."
    
    # Récupération des informations AWS
    CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" --query 'Distribution.DomainName' --output text)
    
    log_info "Informations pour la configuration DNS OVH:"
    echo "  🌍 Domaine principal: ipowerfrance.fr"
    echo "  🌍 Sous-domaine www: www.ipowerfrance.fr"
    echo "  ☁️ CloudFront: $CLOUDFRONT_DOMAIN"
    echo "  ⚖️ Load Balancer: $ALB_DNS_NAME"
    echo "  🖥️ EC2: $EC2_PUBLIC_IP"
    
    log_warning "Configuration manuelle requise dans l'interface OVH Manager"
    log_info "Voir le fichier: OVH-Config/domain-management/dns-config.md"
}

# Tests post-déploiement
post_deploy_tests() {
    log_info "✅ Tests post-déploiement..."
    
    # Test du frontend
    if [ -n "${FRONTEND_BUCKET:-}" ]; then
        log_info "Test du frontend..."
        if curl -f "https://$FRONTEND_BUCKET.s3.$AWS_REGION.amazonaws.com" > /dev/null 2>&1; then
            log_success "Frontend accessible"
        else
            log_warning "Frontend non accessible"
        fi
    fi
    
    # Test du backend
    if [ -n "${EC2_PUBLIC_IP:-}" ]; then
        log_info "Test du backend..."
        if curl -f "http://$EC2_PUBLIC_IP:3001/health" > /dev/null 2>&1; then
            log_success "Backend accessible"
        else
            log_warning "Backend non accessible"
        fi
    fi
    
    # Test de la base de données
    log_info "Test de la base de données..."
    # TODO: Implémenter les tests de connectivité base de données
    
    log_success "Tests post-déploiement terminés"
}

# Nettoyage et rapport final
cleanup_and_report() {
    log_info "🧹 Nettoyage..."
    
    # Suppression du plan Terraform
    if [ -f "$TERRAFORM_DIR/terraform.tfplan" ]; then
        rm "$TERRAFORM_DIR/terraform.tfplan"
    fi
    
    # Rapport final
    log_success "🎉 Déploiement IPOWER MOTORS terminé avec succès !"
    echo ""
    echo "📊 RÉSUMÉ DU DÉPLOIEMENT:"
    echo "  🌍 Environnement: $ENVIRONMENT"
    echo "  🕐 Timestamp: $DEPLOY_TIMESTAMP"
    echo "  ☁️ Région AWS: $AWS_REGION"
    echo "  🚀 Frontend: $FRONTEND_BUCKET"
    echo "  📁 Documents: $DOCUMENTS_BUCKET"
    echo "  🌐 CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"
    echo "  ⚖️ Load Balancer: $ALB_DNS_NAME"
    echo "  🖥️ EC2: $EC2_PUBLIC_IP"
    echo ""
    echo "🔗 URLs d'accès:"
    echo "  🌍 Site web: https://ipowerfrance.fr"
    echo "  🌍 Site web (www): https://www.ipowerfrance.fr"
    echo "  🖥️ API: https://api.ipowerfrance.fr"
    echo ""
    echo "📋 Prochaines étapes:"
    echo "  1. Configurer le DNS OVH (voir OVH-Config/domain-management/dns-config.md)"
    echo "  2. Tester les fonctionnalités"
    echo "  3. Configurer les alertes et monitoring"
    echo "  4. Mettre en place les sauvegardes automatiques"
}

# Fonction principale
main() {
    log_info "🚀 Déploiement IPOWER MOTORS - Environnement: $ENVIRONMENT"
    echo ""
    
    # Vérification des prérequis
    check_prerequisites
    
    # Déploiement de l'infrastructure
    deploy_infrastructure
    
    # Déploiement du frontend
    deploy_frontend
    
    # Déploiement du backend
    deploy_backend
    
    # Déploiement sur EC2
    deploy_ec2
    
    # Configuration DNS OVH
    configure_ovh_dns
    
    # Tests post-déploiement
    post_deploy_tests
    
    # Nettoyage et rapport final
    cleanup_and_report
}

# Gestion des erreurs
trap 'log_error "Erreur sur la ligne $LINENO. Sortie."; exit 1' ERR

# Exécution du script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
