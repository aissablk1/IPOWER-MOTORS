#!/bin/bash
# Script de gestion IPOWER MOTORS - Flexibilité Ultime
# ===================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/infrastructure/aws/terraform"
DEPLOY_SCRIPT="$PROJECT_ROOT/infrastructure/aws/scripts/deploy.sh"

# Variables globales
FRONTEND_DIR="$SCRIPT_DIR/app/frontend"
BACKEND_DIR="$SCRIPT_DIR/app/backend"
DOCKER_COMPOSE_FILE="$BACKEND_DIR/docker-compose.yml"

# Options de déploiement
AWS_DEPLOY=false
AWS_FRONTEND=false
AWS_BACKEND=false
OVH_DNS=false
DOCKER_LOCAL=false
TERRAFORM_PLAN=false
TERRAFORM_APPLY=false
TERRAFORM_DESTROY=false
GITHUB_SETUP=false
MONITORING=false
HEALTH_CHECK=false

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonctions de logging
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_debug() { echo -e "${PURPLE}🔍 $1${NC}"; }
log_step() { echo -e "${CYAN}🚀 $1${NC}"; }

# Affichage de l'aide
show_help() {
    cat << EOF
🚀 Script de gestion IPOWER MOTORS - Flexibilité Ultime
=======================================================

USAGE:
    $0 [OPTIONS] [COMMAND]

OPTIONS AWS/OVH (Nouvelle architecture) :
    --aws-deploy        : déploie l'infrastructure AWS complète avec Terraform
    --aws-frontend      : déploie le frontend sur S3 + CloudFront
    --aws-backend       : déploie le backend sur EC2
    --ovh-dns           : configure le DNS OVH pour pointer vers AWS
    --docker-local      : lance l'environnement Docker local (simulation AWS)
    --terraform-plan    : affiche le plan Terraform sans l'appliquer
    --terraform-apply   : applique la configuration Terraform
    --terraform-destroy : détruit l'infrastructure AWS (attention !)
    --github-setup      : configure GitHub Actions + OIDC
    --monitoring        : lance le monitoring local (Prometheus + Grafana)
    --health-check      : vérifie la santé de tous les services

COMMANDES LOCALES :
    start               : démarre le frontend en mode développement
    stop                : arrête le frontend
    restart             : redémarre le frontend
    status              : affiche le statut des services
    logs                : affiche les logs du frontend
    clean               : nettoie les fichiers temporaires
    update              : met à jour les dépendances
    test                : lance les tests
    build               : build le projet pour la production

EXEMPLES :
    $0 --docker-local                    # Environnement Docker local
    $0 --aws-deploy                     # Déploiement AWS complet
    $0 --terraform-plan                 # Plan Terraform
    $0 --github-setup                   # Configuration GitHub Actions
    $0 start                            # Démarrage local
    $0 --monitoring                     # Monitoring local

ENVIRONNEMENTS :
    - Local (Docker Compose)
    - Staging (AWS)
    - Production (AWS)
    - GitHub Actions (CI/CD)

EOF
}

# Vérification des prérequis
check_prerequisites() {
    log_info "🔍 Vérification des prérequis..."
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js n'est pas installé"
        log_info "Installation recommandée: https://nodejs.org/"
        return 1
    fi
    
    # Vérifier npm
    if ! command -v npm &> /dev/null; then
        log_error "npm n'est pas installé"
        return 1
    fi
    
    # Vérifier Git
    if ! command -v git &> /dev/null; then
        log_error "Git n'est pas installé"
        return 1
    fi
    
    log_success "Prérequis de base vérifiés"
    return 0
}

# Vérification des prérequis AWS
check_aws_prerequisites() {
    log_info "🔍 Vérification des prérequis AWS..."
    
    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI n'est pas installé"
        log_info "Installation: brew install awscli"
        return 1
    fi
    
    # Vérifier Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform n'est pas installé"
        log_info "Installation: brew install terraform"
        return 1
    fi
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        log_info "Installation: https://docs.docker.com/get-docker/"
        return 1
    fi
    
    # Vérifier la configuration AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Configuration AWS invalide"
        log_info "Exécutez: aws configure"
        return 1
    fi
    
    log_success "Prérequis AWS vérifiés"
    return 0
}

# Fonction de déploiement Docker local
deploy_docker_local() {
    if [[ "$DOCKER_LOCAL" == true ]]; then
        log_step "🐳 Lancement de l'environnement Docker local..."
        
        # Vérifier que Docker est installé
        if ! command -v docker &> /dev/null; then
            log_error "Docker n'est pas installé"
            return 1
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            log_error "Docker Compose n'est pas installé"
            return 1
        fi
        
        # Aller dans le répertoire backend
        cd "$BACKEND_DIR"
        
        # Construire et lancer les conteneurs
        log_info "Construction des conteneurs Docker..."
        docker-compose up --build -d
        
        log_success "Environnement Docker local lancé"
        log_info "Frontend: http://localhost:5173"
        log_info "Backend: http://localhost:3001"
        log_info "Base de données: localhost:5432"
        log_info "Redis: localhost:6379"
        log_info "MailHog: http://localhost:8025"
        log_info "MinIO: http://localhost:9001"
        log_info "Nginx: http://localhost:8080"
        log_info "Prometheus: http://localhost:9090"
        log_info "Grafana: http://localhost:3000 (admin/admin123)"
        
        return 0
    fi
}

# Fonction de déploiement Terraform
deploy_terraform() {
    if [[ "$TERRAFORM_PLAN" == true ]] || [[ "$TERRAFORM_APPLY" == true ]] || [[ "$TERRAFORM_DESTROY" == true ]]; then
        log_step "🏗️ Opérations Terraform..."
        
        # Vérifier les prérequis AWS
        if ! check_aws_prerequisites; then
            return 1
        fi
        
        cd "$TERRAFORM_DIR"
        
        if [[ "$TERRAFORM_PLAN" == true ]]; then
            log_info "Planification Terraform..."
            terraform plan -var-file="terraform.tfvars"
        fi
        
        if [[ "$TERRAFORM_APPLY" == true ]]; then
            log_info "Application Terraform..."
            terraform apply -var-file="terraform.tfvars" -auto-approve
        fi
        
        if [[ "$TERRAFORM_DESTROY" == true ]]; then
            log_warning "⚠️  DESTRUCTION de l'infrastructure AWS !"
            read -p "Êtes-vous sûr ? (oui/non): " confirm
            if [[ "$confirm" == "oui" ]]; then
                terraform destroy -var-file="terraform.tfvars" -auto-approve
            else
                log_info "Destruction annulée"
            fi
        fi
        
        return 0
    fi
}

# Fonction de déploiement AWS
deploy_aws() {
    if [[ "$AWS_DEPLOY" == true ]] || [[ "$AWS_FRONTEND" == true ]] || [[ "$AWS_BACKEND" == true ]]; then
        log_step "☁️ Déploiement AWS..."
        
        # Vérifier les prérequis AWS
        if ! check_aws_prerequisites; then
            return 1
        fi
        
        # Utiliser le script de déploiement automatisé
        if [[ -f "$DEPLOY_SCRIPT" ]]; then
            log_info "Utilisation du script de déploiement automatisé..."
            chmod +x "$DEPLOY_SCRIPT"
            "$DEPLOY_SCRIPT" production
        else
            log_warning "Script de déploiement non trouvé, déploiement manuel..."
            cd "$TERRAFORM_DIR"
            terraform init
            terraform apply -var-file="terraform.tfvars" -auto-approve
        fi
        
        return 0
    fi
}

# Fonction de configuration OVH DNS
configure_ovh_dns() {
    if [[ "$OVH_DNS" == true ]]; then
        log_step "🌐 Configuration DNS OVH..."
        
        log_info "Configuration manuelle requise dans l'interface OVH Manager"
        log_info "Voir le fichier: OVH-Config/domain-management/dns-config.md"
        
        # Afficher les informations nécessaires
        if [[ -f "$TERRAFORM_DIR/terraform.tfstate" ]]; then
            cd "$TERRAFORM_DIR"
            log_info "Informations de déploiement:"
            terraform output
        fi
        
        return 0
    fi
}

# Fonction de configuration GitHub Actions
setup_github_actions() {
    if [[ "$GITHUB_SETUP" == true ]]; then
        log_step "🔑 Configuration GitHub Actions + OIDC..."
        
        log_info "Configuration requise dans GitHub:"
        log_info "1. Créer le repository: ipower-motors/ipower-backend"
        log_info "2. Configurer les secrets:"
        log_info "   - AWS_ROLE_ARN_PRODUCTION"
        log_info "   - AWS_ROLE_ARN_STAGING"
        log_info "   - CLOUDFRONT_DISTRIBUTION_ID_PRODUCTION"
        log_info "   - CLOUDFRONT_DISTRIBUTION_ID_STAGING"
        log_info "3. Pousser le code avec les workflows GitHub Actions"
        
        # Vérifier si le répertoire .github existe
        if [[ ! -d "$PROJECT_ROOT/.github" ]]; then
            log_warning "Répertoire .github non trouvé"
            log_info "Créez d'abord le repository GitHub"
        fi
        
        return 0
    fi
}

# Fonction de monitoring local
start_monitoring() {
    if [[ "$MONITORING" == true ]]; then
        log_step "📊 Lancement du monitoring local..."
        
        if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
            cd "$BACKEND_DIR"
            docker-compose --profile monitoring up -d prometheus grafana
            log_success "Monitoring local lancé"
            log_info "Prometheus: http://localhost:9090"
            log_info "Grafana: http://localhost:3000 (admin/admin123)"
        else
            log_error "Docker Compose non trouvé"
            return 1
        fi
        
        return 0
    fi
}

# Fonction de vérification de santé
health_check() {
    if [[ "$HEALTH_CHECK" == true ]]; then
        log_step "🏥 Vérification de santé des services..."
        
        # Vérifier Docker
        if command -v docker &> /dev/null; then
            log_info "Docker: $(docker --version)"
            if docker ps > /dev/null 2>&1; then
                log_success "Docker: ✅ Fonctionnel"
            else
                log_error "Docker: ❌ Problème"
            fi
        fi
        
        # Vérifier AWS CLI
        if command -v aws &> /dev/null; then
            log_info "AWS CLI: $(aws --version)"
            if aws sts get-caller-identity > /dev/null 2>&1; then
                log_success "AWS CLI: ✅ Configuré"
            else
                log_error "AWS CLI: ❌ Non configuré"
            fi
        fi
        
        # Vérifier Terraform
        if command -v terraform &> /dev/null; then
            log_info "Terraform: $(terraform --version | head -n1)"
            log_success "Terraform: ✅ Installé"
        fi
        
        # Vérifier Node.js
        if command -v node &> /dev/null; then
            log_info "Node.js: $(node --version)"
            log_success "Node.js: ✅ Installé"
        fi
        
        # Vérifier les services locaux
        if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
            cd "$BACKEND_DIR"
            if docker-compose ps | grep -q "Up"; then
                log_success "Services Docker: ✅ En cours d'exécution"
            else
                log_warning "Services Docker: ⚠️ Arrêtés"
            fi
        fi
        
        return 0
    fi
}

# Fonction de démarrage du frontend local
start_frontend() {
    log_step "🚀 Démarrage du frontend local..."
    
cd "$FRONTEND_DIR"
    
    # Vérifier les dépendances
    if [[ ! -d "node_modules" ]]; then
        log_info "Installation des dépendances..."
    npm install
fi

    # Démarrer le serveur de développement
    log_info "Démarrage du serveur de développement..."
    npm run dev
}

# Fonction d'arrêt du frontend
stop_frontend() {
    log_step "🛑 Arrêt du frontend..."
    
    # Trouver et arrêter le processus Node.js
    if pgrep -f "vite" > /dev/null; then
        pkill -f "vite"
        log_success "Frontend arrêté"
    else
        log_info "Aucun frontend en cours d'exécution"
    fi
}

# Fonction de statut
show_status() {
    log_step "📊 Statut des services..."
    
    echo ""
    echo "🔍 SERVICES LOCAUX:"
    
    # Statut du frontend
    if pgrep -f "vite" > /dev/null; then
        echo "  Frontend: ✅ En cours d'exécution"
    else
        echo "  Frontend: ❌ Arrêté"
    fi
    
    # Statut Docker
    if command -v docker &> /dev/null; then
        if docker ps | grep -q "ipower"; then
            echo "  Docker: ✅ Conteneurs actifs"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "ipower"
        else
            echo "  Docker: ⚠️ Aucun conteneur IPOWER actif"
        fi
    fi
    
    echo ""
    echo "☁️ SERVICES AWS:"
    
    # Statut AWS
    if command -v aws &> /dev/null; then
        if aws sts get-caller-identity > /dev/null 2>&1; then
            ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
            echo "  AWS Account: ✅ $ACCOUNT_ID"
        else
            echo "  AWS Account: ❌ Non configuré"
        fi
    fi
    
    # Statut Terraform
    if [[ -f "$TERRAFORM_DIR/terraform.tfstate" ]]; then
        echo "  Terraform: ✅ État local disponible"
    else
        echo "  Terraform: ⚠️ Aucun état local"
    fi
    
    echo ""
    echo "🔗 PORTS UTILISÉS:"
    echo "  Frontend: http://localhost:5173"
    echo "  Backend: http://localhost:3001"
    echo "  Base de données: localhost:5432"
    echo "  Redis: localhost:6379"
    echo "  MailHog: http://localhost:8025"
    echo "  MinIO: http://localhost:9001"
    echo "  Nginx: http://localhost:8080"
    echo "  Prometheus: http://localhost:9090"
    echo "  Grafana: http://localhost:3000"
}

# Fonction de logs
show_logs() {
    log_step "📝 Affichage des logs..."
    
    if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
        cd "$BACKEND_DIR"
        docker-compose logs -f
    else
        log_warning "Docker Compose non trouvé"
    fi
}

# Fonction de nettoyage
cleanup() {
    log_step "🧹 Nettoyage..."
    
    # Nettoyer les modules Node.js
    if [[ -d "$FRONTEND_DIR/node_modules" ]]; then
        log_info "Nettoyage des modules frontend..."
        rm -rf "$FRONTEND_DIR/node_modules"
    fi
    
    if [[ -d "$BACKEND_DIR/node_modules" ]]; then
        log_info "Nettoyage des modules backend..."
        rm -rf "$BACKEND_DIR/node_modules"
    fi
    
    # Nettoyer Docker
    if command -v docker &> /dev/null; then
        log_info "Nettoyage Docker..."
        docker system prune -f
    fi
    
    log_success "Nettoyage terminé"
}

# Fonction de mise à jour
update_dependencies() {
    log_step "🔄 Mise à jour des dépendances..."
    
    # Mise à jour frontend
    cd "$FRONTEND_DIR"
    log_info "Mise à jour frontend..."
    npm update
    
    # Mise à jour backend
    cd "$BACKEND_DIR"
    log_info "Mise à jour backend..."
    npm update
    
    log_success "Mise à jour terminée"
}

# Fonction de tests
run_tests() {
    log_step "🧪 Lancement des tests..."
    
    # Tests frontend
    cd "$FRONTEND_DIR"
    log_info "Tests frontend..."
    npm test
    
    # Tests backend
    cd "$BACKEND_DIR"
    log_info "Tests backend..."
    npm test
    
    log_success "Tests terminés"
}

# Fonction de build
build_project() {
    log_step "🏗️ Build du projet..."
    
    # Build frontend
    cd "$FRONTEND_DIR"
    log_info "Build frontend..."
    npm run build
    
    # Build backend
    cd "$BACKEND_DIR"
    log_info "Build backend..."
    npm run build
    
    log_success "Build terminé"
}

# Fonction principale
main() {
    # Affichage du header
    echo ""
    echo "🚀 IPOWER MOTORS - Flexibilité Ultime"
    echo "====================================="
    echo ""
    
    # Vérification des prérequis de base
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Traitement des options AWS/OVH en premier
    if [[ "$AWS_DEPLOY" == true ]] || [[ "$AWS_FRONTEND" == true ]] || [[ "$AWS_BACKEND" == true ]] || \
       [[ "$OVH_DNS" == true ]] || [[ "$DOCKER_LOCAL" == true ]] || [[ "$TERRAFORM_PLAN" == true ]] || \
       [[ "$TERRAFORM_APPLY" == true ]] || [[ "$TERRAFORM_DESTROY" == true ]] || [[ "$GITHUB_SETUP" == true ]] || \
       [[ "$MONITORING" == true ]] || [[ "$HEALTH_CHECK" == true ]]; then
        
        log_info "🚀 Exécution des opérations AWS/OVH/GitHub..."
        
        # Exécution des nouvelles fonctionnalités
        deploy_docker_local
        deploy_terraform
        deploy_aws
        configure_ovh_dns
        setup_github_actions
        start_monitoring
        health_check
        
        log_success "✅ Opération terminée"
        exit 0
    fi
    
    # Traitement des commandes locales
    case "${1:-start}" in
        start)
            start_frontend
            ;;
        stop)
            stop_frontend
            ;;
        restart)
            stop_frontend
            sleep 2
            start_frontend
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        clean)
            cleanup
            ;;
        update)
            update_dependencies
            ;;
        test)
            run_tests
            ;;
        build)
            build_project
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Commande inconnue: $1"
            show_help
            exit 1
            ;;
    esac
}

# Parsing des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --aws-deploy)
            AWS_DEPLOY=true
            shift
            ;;
        --aws-frontend)
            AWS_FRONTEND=true
            shift
            ;;
        --aws-backend)
            AWS_BACKEND=true
            shift
            ;;
        --ovh-dns)
            OVH_DNS=true
            shift
            ;;
        --docker-local)
            DOCKER_LOCAL=true
            shift
            ;;
        --terraform-plan)
            TERRAFORM_PLAN=true
            shift
            ;;
        --terraform-apply)
            TERRAFORM_APPLY=true
            shift
            ;;
        --terraform-destroy)
            TERRAFORM_DESTROY=true
            shift
            ;;
        --github-setup)
            GITHUB_SETUP=true
            shift
            ;;
        --monitoring)
            MONITORING=true
            shift
            ;;
        --health-check)
            HEALTH_CHECK=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            log_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Exécution du script
main "$@"