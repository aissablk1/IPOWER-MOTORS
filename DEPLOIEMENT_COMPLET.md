# 🚀 Guide de Déploiement Complet IPOWER MOTORS

## 📋 Vue d'ensemble

Ce guide vous accompagne dans le déploiement complet de votre application IPOWER MOTORS avec une **flexibilité ultime** :

- 🔐 **Backend Terraform distant** : S3 + DynamoDB pour les verrous
- 🔑 **OIDC GitHub + IAM** : Authentification sécurisée sans clés statiques
- 🐳 **Docker Compose local** : Environnement de développement complet
- 🚀 **Workflows GitHub Actions** : CI/CD automatisé complet
- 🔧 **Scripts de déploiement** : Frontend, Backend, Infrastructure
- 🔐 **Configuration nettoyée** : Plus de clés statiques, tout en IAM
- ☁️ **Infrastructure AWS complète** : VPC, EC2, RDS, S3, CloudFront, ALB
- 🌐 **Configuration OVH** : DNS et domaine prêts
- 🔐 **Zéro clé statique** : Tout via IAM Roles + OIDC GitHub
- 🔄 **Déploiement automatique** : Push sur GitHub = déploiement automatique
- 📊 **Monitoring intégré** : CloudWatch + surveillance EC2
- 🛡️ **Sécurité maximale** : VPC privé, Security Groups, chiffrement
- 💰 **Optimisé budget** : Ressources adaptées à vos 50€/mois
- 🌍 **Global** : CloudFront pour performance mondiale

## 🎯 Architecture de Déploiement

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │    │  GitHub Actions │    │   AWS Cloud    │
│                 │───▶│   (OIDC + IAM)  │───▶│                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Terraform     │    │  Infrastructure │
                       │  (S3 + Dynamo) │    │  (EC2 + RDS)    │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  S3 + CloudFront│    │  Load Balancer  │
                       │  (Frontend)     │    │  (Backend)      │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  OVH DNS       │    │  Monitoring     │
                       │  (ipowerfrance.fr)│  │  (CloudWatch)   │
                       └─────────────────┘    └─────────────────┘
```

## 🚀 Démarrage Rapide

### **Option 1 : Déploiement Local (Docker)**
```bash
cd "Site Web/Serveur"
./run.sh --docker-local
```

### **Option 2 : Déploiement AWS Complet**
```bash
cd "Site Web/Serveur"
./run.sh --aws-deploy
```

### **Option 3 : Déploiement Étape par Étape**
```bash
# 1. Infrastructure
./run.sh --terraform-apply

# 2. Frontend
./run.sh --aws-frontend

# 3. Backend
./run.sh --aws-backend

# 4. DNS OVH
./run.sh --ovh-dns
```

## 🔧 Configuration Préalable

### **1. Installation des Outils**

#### **macOS (Homebrew)**
```bash
# AWS CLI
brew install awscli

# Terraform
brew install terraform

# Docker
brew install --cask docker

# Node.js
brew install node
```

#### **Vérification des Installations**
```bash
aws --version
terraform --version
docker --version
node --version
```

### **2. Configuration AWS**

#### **Configuration des Credentials**
```bash
aws configure
# AWS Access Key ID: [VOTRE_ACCESS_KEY]
# AWS Secret Access Key: [VOTRE_SECRET_KEY]
# Default region name: eu-west-3
# Default output format: json
```

#### **Vérification de la Configuration**
```bash
aws sts get-caller-identity
```

### **3. Configuration GitHub**

#### **Création du Repository**
1. Créez le repository : `ipower-motors/ipower-backend`
2. Clonez-le localement
3. Copiez tous les fichiers du projet

#### **Configuration des Secrets GitHub**
Dans votre repository GitHub → Settings → Secrets and variables → Actions :

```
AWS_ROLE_ARN_PRODUCTION=arn:aws:iam::509505638058:role/IPOWER-MOTORS-GitHub-Actions-Role
AWS_ROLE_ARN_STAGING=arn:aws:iam::509505638058:role/IPOWER-MOTORS-GitHub-Actions-Role
CLOUDFRONT_DISTRIBUTION_ID_PRODUCTION=[ID_APRÈS_DÉPLOIEMENT]
CLOUDFRONT_DISTRIBUTION_ID_STAGING=[ID_APRÈS_DÉPLOIEMENT]
SLACK_WEBHOOK_URL=[URL_WEBHOOK_SLACK_OPTIONNEL]
```

## 🏗️ Déploiement de l'Infrastructure

### **1. Initialisation Terraform**
```bash
cd "Site Web/infrastructure/aws/terraform"

# Initialisation avec backend S3
terraform init

# Vérification du plan
terraform plan -var-file="terraform.tfvars"
```

### **2. Déploiement de l'Infrastructure**
```bash
# Application des changements
terraform apply -var-file="terraform.tfvars" -auto-approve

# Vérification des outputs
terraform output
```

### **3. Vérification des Ressources Créées**
```bash
# VPC et sous-réseaux
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=IPOWER-MOTORS"

# Instances EC2
aws ec2 describe-instances --filters "Name=tag:Project,Values=IPOWER-MOTORS"

# Buckets S3
aws s3 ls | grep ipower-motors

# Distribution CloudFront
aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `IPOWER MOTORS`)]'
```

## 🚀 Déploiement des Applications

### **1. Déploiement Frontend (S3 + CloudFront)**

#### **Build et Déploiement**
```bash
cd "Site Web/app/frontend"

# Installation des dépendances
npm ci

# Build de production
npm run build

# Déploiement vers S3
aws s3 sync dist/ s3://ipower-motors-frontend --delete

# Invalidation CloudFront
aws cloudfront create-invalidation \
    --distribution-id [DISTRIBUTION_ID] \
    --paths "/*"
```

#### **Vérification**
```bash
# Test du site
curl -I https://ipowerfrance.fr

# Test du cache CloudFront
curl -I https://[CLOUDFRONT_DOMAIN]
```

### **2. Déploiement Backend (EC2)**

#### **Déploiement Automatique**
```bash
cd "Site Web/infrastructure/aws/scripts"
chmod +x deploy.sh
./deploy.sh production
```

#### **Déploiement Manuel**
```bash
# Connexion SSH à l'instance EC2
ssh -i "ipower-motors-key.pem" ubuntu@[EC2_PUBLIC_IP]

# Dans l'instance EC2
cd /opt/ipower-backend
git pull origin main
npm install --production
npm run build
systemctl restart ipower-backend
```

#### **Vérification**
```bash
# Test de santé
curl -f http://[EC2_PUBLIC_IP]:3001/health

# Test de l'API
curl -f http://[EC2_PUBLIC_IP]:3001/api/health
```

## 🌐 Configuration DNS OVH

### **1. Accès à l'Interface OVH**
1. Connectez-vous à [OVH Manager](https://www.ovh.com/manager/)
2. Sélectionnez votre domaine `ipowerfrance.fr`
3. Allez dans la section "Zone DNS"

### **2. Configuration des Enregistrements**

#### **Enregistrement Principal (A)**
```
Type: A
Nom: @
Valeur: [IP_LOAD_BALANCER_AWS]
TTL: 300
```

#### **Enregistrement WWW (CNAME)**
```
Type: CNAME
Nom: www
Valeur: [DOMAINE_CLOUDFRONT]
TTL: 300
```

#### **Enregistrement API (CNAME)**
```
Type: CNAME
Nom: api
Valeur: [DNS_LOAD_BALANCER]
TTL: 300
```

### **3. Vérification de la Propagation**
```bash
# Vérification DNS
dig ipowerfrance.fr
dig www.ipowerfrance.fr
dig api.ipowerfrance.fr

# Test de connectivité
curl -I https://ipowerfrance.fr
curl -I https://www.ipowerfrance.fr
curl -I https://api.ipowerfrance.fr
```

## 🔄 CI/CD avec GitHub Actions

### **1. Workflow Automatique**
- **Push sur `main`** → Déploiement Production
- **Push sur `develop`** → Déploiement Staging
- **Pull Request** → Tests automatiques

### **2. Déploiement Manuel**
1. Allez dans votre repository GitHub
2. Actions → "🚀 Déploiement IPOWER MOTORS"
3. "Run workflow"
4. Sélectionnez l'environnement et les composants

### **3. Monitoring des Déploiements**
```bash
# Vérification des workflows
gh run list --workflow="deploy.yml"

# Logs d'un déploiement
gh run view [RUN_ID] --log
```

## 🐳 Environnement Local (Docker)

### **1. Lancement Complet**
```bash
cd "Site Web/Serveur"
./run.sh --docker-local
```

### **2. Services Disponibles**
- **Frontend** : http://localhost:5173
- **Backend** : http://localhost:3001
- **Base de données** : localhost:5432
- **Redis** : localhost:6379
- **MailHog** : http://localhost:8025
- **MinIO** : http://localhost:9001
- **Nginx** : http://localhost:8080
- **Prometheus** : http://localhost:9090
- **Grafana** : http://localhost:3000

### **3. Gestion des Services**
```bash
# Arrêt
docker-compose down

# Redémarrage
docker-compose restart

# Logs
docker-compose logs -f

# Nettoyage
docker-compose down -v
```

## 📊 Monitoring et Surveillance

### **1. CloudWatch (AWS)**
- **Métriques EC2** : CPU, mémoire, disque
- **Métriques RDS** : CPU, connexions, stockage
- **Métriques ALB** : santé, latence, erreurs
- **Logs** : Application, système, accès

### **2. Alertes et Notifications**
```bash
# Vérification des alarmes
aws cloudwatch describe-alarms --alarm-names-prefix "IPOWER-MOTORS"

# Test des notifications
aws sns publish \
    --topic-arn "arn:aws:sns:eu-west-3:509505638058:ipower-motors-alerts" \
    --message "Test de notification"
```

### **3. Monitoring Local (Prometheus + Grafana)**
```bash
# Lancement du monitoring
./run.sh --monitoring

# Accès Grafana
# URL: http://localhost:3000
# Utilisateur: admin
# Mot de passe: admin123
```

## 🔐 Sécurité et Conformité

### **1. IAM Roles et Politiques**
- **EC2 Role** : Accès S3, CloudWatch, SES
- **GitHub Actions Role** : Déploiement et gestion
- **Principle of Least Privilege** : Permissions minimales

### **2. Chiffrement**
- **Transit** : TLS 1.2+ pour toutes les communications
- **Stockage** : Chiffrement AES-256 pour S3 et RDS
- **Volumes** : Chiffrement EBS pour les instances EC2

### **3. Sécurité Réseau**
- **VPC** : Isolation réseau complète
- **Security Groups** : Contrôle d'accès granulaire
- **WAF** : Protection contre les attaques web

## 💰 Optimisation des Coûts

### **1. Ressources Recommandées**
- **EC2** : t3.medium (équilibré performance/coût)
- **RDS** : db.t3.micro (développement)
- **S3** : Standard + IA + Glacier (lifecycle automatique)
- **CloudFront** : Cache global (réduction latence)

### **2. Estimation Mensuelle**
```
EC2 t3.medium: ~15€/mois
RDS db.t3.micro: ~12€/mois
S3 + CloudFront: ~5€/mois
ALB + NAT Gateway: ~18€/mois
Total estimé: ~50€/mois
```

### **3. Optimisations**
- **Auto-scaling** : Adaptation automatique à la charge
- **Lifecycle S3** : Transition vers classes moins chères
- **Réservation** : Réduction de 30-60% avec engagement
- **Spot Instances** : Réduction de 70-90% pour workloads flexibles

## 🧪 Tests et Validation

### **1. Tests Automatiques**
```bash
# Tests unitaires
npm test

# Tests d'intégration
npm run test:integration

# Tests de charge
npm run test:load
```

### **2. Tests Post-Déploiement**
```bash
# Vérification de santé
./run.sh --health-check

# Tests de connectivité
curl -f https://ipowerfrance.fr
curl -f https://api.ipowerfrance.fr/health

# Tests de base de données
# TODO: Implémenter les tests de connectivité
```

### **3. Validation de Sécurité**
```bash
# Audit des dépendances
npm audit

# Scan de vulnérabilités
# TODO: Intégrer OWASP ZAP ou Snyk
```

## 🚨 Dépannage et Maintenance

### **1. Problèmes Courants**

#### **Instance EC2 Non Accessible**
```bash
# Vérification du statut
aws ec2 describe-instance-status --instance-ids [INSTANCE_ID]

# Vérification des Security Groups
aws ec2 describe-security-groups --group-ids [SECURITY_GROUP_ID]

# Connexion via Session Manager
aws ssm start-session --target [INSTANCE_ID]
```

#### **Base de Données RDS Inaccessible**
```bash
# Vérification du statut
aws rds describe-db-instances --db-instance-identifier ipower-motors-rds

# Vérification des Security Groups
aws rds describe-db-security-groups --db-security-group-name [SG_NAME]

# Test de connectivité
psql -h [RDS_ENDPOINT] -U ipower_admin -d ipower_motors
```

#### **Frontend Non Accessible**
```bash
# Vérification du bucket S3
aws s3 ls s3://ipower-motors-frontend

# Vérification de CloudFront
aws cloudfront get-distribution --id [DISTRIBUTION_ID]

# Test direct S3
curl -I https://ipower-motors-frontend.s3.eu-west-3.amazonaws.com
```

### **2. Maintenance Routinière**

#### **Mise à Jour des Applications**
```bash
# Pull des dernières modifications
git pull origin main

# Mise à jour des dépendances
npm update

# Redéploiement
./run.sh --aws-deploy
```

#### **Sauvegarde de la Base de Données**
```bash
# Sauvegarde automatique (configurée dans RDS)
aws rds describe-db-snapshots --db-instance-identifier ipower-motors-rds

# Sauvegarde manuelle
aws rds create-db-snapshot \
    --db-instance-identifier ipower-motors-rds \
    --db-snapshot-identifier ipower-motors-manual-$(date +%Y%m%d)
```

#### **Rotation des Logs**
```bash
# Vérification des logs CloudWatch
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/ipower-backend"

# Nettoyage des anciens logs
aws logs delete-log-group --log-group-name "/aws/ec2/ipower-backend/old-logs"
```

## 📚 Ressources et Documentation

### **1. Documentation Officielle**
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)

### **2. Fichiers de Configuration**
- **Terraform** : `infrastructure/aws/terraform/`
- **Docker** : `app/backend/docker-compose.yml`
- **GitHub Actions** : `.github/workflows/`
- **Scripts** : `infrastructure/aws/scripts/`

### **3. Support et Communauté**
- [AWS Support](https://aws.amazon.com/support/)
- [Terraform Community](https://www.terraform.io/community)
- [GitHub Community](https://github.community/)
- [Stack Overflow](https://stackoverflow.com/)

## 🎯 Prochaines Étapes

### **1. Immédiat (1-2 jours)**
- [ ] Déploiement de l'infrastructure AWS
- [ ] Configuration DNS OVH
- [ ] Tests de connectivité
- [ ] Validation des fonctionnalités

### **2. Court terme (1 semaine)**
- [ ] Configuration GitHub Actions
- [ ] Mise en place du monitoring
- [ ] Tests de charge
- [ ] Documentation utilisateur

### **3. Moyen terme (1 mois)**
- [ ] Optimisation des performances
- [ ] Mise en place des sauvegardes
- [ ] Formation de l'équipe
- [ ] Plan de reprise d'activité

### **4. Long terme (3-6 mois)**
- [ ] Multi-région pour la résilience
- [ ] Intégration CI/CD avancée
- [ ] Observabilité complète
- [ ] Automatisation des opérations

---

## 🎉 Félicitations !

Vous avez maintenant une infrastructure **IPOWER MOTORS** complète, sécurisée et évolutive !

**Besoin d'aide ?** Consultez ce guide ou contactez l'équipe technique.

**🚀 Bon déploiement !**
