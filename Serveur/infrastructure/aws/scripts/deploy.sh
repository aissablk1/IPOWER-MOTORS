#!/bin/bash
# Script de déploiement AWS pour IPOWER MOTORS
# Architecture hybride OVH + AWS

set -e

# Configuration
PROJECT_NAME="IPOWER-MOTORS"
DOMAIN="ipowerfrance.fr"
AWS_REGION="eu-west-3"
ENVIRONMENT="${1:-production}"

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
    log "Vérification des prérequis..."
    
    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI n'est pas installé. Installez-le d'abord."
    fi
    
    # Vérifier Terraform
    if ! command -v terraform &> /dev/null; then
        error "Terraform n'est pas installé. Installez-le d'abord."
    fi
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé. Installez-le d'abord."
    fi
    
    # Vérifier la configuration AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI n'est pas configuré. Exécutez 'aws configure' d'abord."
    fi
    
    success "Tous les prérequis sont satisfaits"
}

# Build du frontend
build_frontend() {
    log "Build du frontend React..."
    
    cd app/frontend
    
    # Installation des dépendances
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm install
    else
        npm install
    fi
    
    # Build de production
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm build
    else
        npm run build
    fi
    
    cd ../..
    
    success "Frontend buildé avec succès"
}

# Build du backend
build_backend() {
    log "Build du backend Express..."
    
    cd app/backend
    
    # Installation des dépendances
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm install
    else
        npm install
    fi
    
    # Build TypeScript
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm build
    else
        npm run build
    fi
    
    cd ../..
    
    success "Backend buildé avec succès"
}

# Déploiement de l'infrastructure
deploy_infrastructure() {
    log "Déploiement de l'infrastructure AWS..."
    
    cd infrastructure/terraform
    
    # Initialisation Terraform
    terraform init
    
    # Planification
    terraform plan -var="environment=${ENVIRONMENT}" -out=tfplan
    
    # Application
    terraform apply tfplan
    
    cd ../..
    
    success "Infrastructure déployée avec succès"
}

# Déploiement du frontend sur S3
deploy_frontend() {
    log "Déploiement du frontend sur S3..."
    
    # Récupération du nom du bucket depuis Terraform
    BUCKET_NAME=$(cd infrastructure/terraform && terraform output -raw frontend_bucket_name)
    
    # Synchronisation avec S3
    aws s3 sync app/frontend/dist/ s3://${BUCKET_NAME}/ --delete
    
    # Invalidation CloudFront
    DISTRIBUTION_ID=$(cd infrastructure/terraform && terraform output -raw cloudfront_distribution_id)
    aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/*"
    
    success "Frontend déployé sur S3 avec succès"
}

# Déploiement du backend sur EC2
deploy_backend() {
    log "Déploiement du backend sur EC2..."
    
    # Récupération des informations EC2 depuis Terraform
    INSTANCE_IP=$(cd infrastructure/terraform && terraform output -raw ec2_public_ip)
    KEY_NAME=$(cd infrastructure/terraform && terraform output -raw ec2_key_name)
    
    # Création du package de déploiement
    tar -czf backend-deploy.tar.gz -C app/backend dist package.json
    
    # Upload sur EC2
    scp -i ~/.ssh/${KEY_NAME}.pem backend-deploy.tar.gz ec2-user@${INSTANCE_IP}:~/
    
    # Déploiement sur EC2
    ssh -i ~/.ssh/${KEY_NAME}.pem ec2-user@${INSTANCE_IP} << 'EOF'
        # Arrêt du service
        sudo systemctl stop ipower-backend || true
        
        # Sauvegarde de l'ancienne version
        sudo mv /opt/ipower-backend /opt/ipower-backend.backup.$(date +%Y%m%d_%H%M%S) || true
        
        # Création du nouveau répertoire
        sudo mkdir -p /opt/ipower-backend
        
        # Extraction
        tar -xzf backend-deploy.tar.gz -C /opt/ipower-backend/
        
        # Installation des dépendances
        cd /opt/ipower-backend
        npm install --production
        
        # Configuration du service systemd
        sudo tee /etc/systemd/system/ipower-backend.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=IPOWER MOTORS Backend
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/ipower-backend
ExecStart=/usr/bin/node dist/server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SERVICE_EOF
        
        # Activation et démarrage du service
        sudo systemctl daemon-reload
        sudo systemctl enable ipower-backend
        sudo systemctl start ipower-backend
        
        # Nettoyage
        rm ~/backend-deploy.tar.gz
EOF
    
    # Nettoyage local
    rm backend-deploy.tar.gz
    
    success "Backend déployé sur EC2 avec succès"
}

# Mise à jour du DNS OVH
update_ovh_dns() {
    log "Mise à jour du DNS OVH..."
    
    # Récupération des informations AWS depuis Terraform
    CLOUDFRONT_DOMAIN=$(cd infrastructure/terraform && terraform output -raw cloudfront_domain_name)
    LOAD_BALANCER_DNS=$(cd infrastructure/terraform && terraform output -raw load_balancer_dns_name)
    
    warning "Mise à jour manuelle du DNS OVH requise :"
    echo "  - Pointage racine vers : ${LOAD_BALANCER_DNS}"
    echo "  - Pointage www vers : ${CLOUDFRONT_DOMAIN}"
    echo "  - Pointage api vers : ${LOAD_BALANCER_DNS}"
    
    success "Instructions DNS affichées"
}

# Fonction principale
main() {
    log "Démarrage du déploiement IPOWER MOTORS vers AWS..."
    log "Environnement : ${ENVIRONMENT}"
    log "Domaine : ${DOMAIN}"
    log "Région AWS : ${AWS_REGION}"
    
    # Vérifications
    check_prerequisites
    
    # Builds
    build_frontend
    build_backend
    
    # Déploiement
    deploy_infrastructure
    deploy_frontend
    deploy_backend
    
    # DNS
    update_ovh_dns
    
    success "Déploiement terminé avec succès !"
    log "Site accessible sur : https://${DOMAIN}"
    log "API accessible sur : https://api.${DOMAIN}"
}

# Exécution
main "$@"
