# 🏗️ Structure d'Architecture IPOWER MOTORS - ipowerfrance.fr

## 📁 Nouvelle organisation des dossiers

### **Structure principale créée :**

```
IPOWER MOTORS/Site Web/
├── 📁 Serveur/                    # Code source principal (Git)
│   ├── 📁 app/
│   │   ├── 📁 frontend/          # React SPA (déployé sur AWS S3 + CloudFront)
│   │   ├── 📁 backend/           # API Express (déployée sur AWS EC2/Lambda)
│   │   └── 📁 shared/            # Code partagé front/back (NOUVEAU)
│   ├── 📁 infrastructure/         # Configuration AWS (NOUVEAU)
│   │   ├── 📁 terraform/         # Infrastructure as Code
│   │   ├── 📁 docker/            # Containers Docker
│   │   └── 📁 aws/               # Configurations AWS spécifiques
│   └── 📁 deployment/            # Scripts de déploiement
├── 📁 OVH-Config/                # Configuration OVH Cloud (NOUVEAU)
│   ├── 📁 dns/                   # Configuration DNS
│   ├── 📁 ssl/                   # Certificats SSL
│   └── 📁 domain-management/     # Gestion du domaine
├── 📁 AWS-Resources/             # Ressources AWS (NOUVEAU)
│   ├── 📁 databases/             # Schémas RDS
│   ├── 📁 storage/               # Configurations S3
│   └── 📁 monitoring/            # CloudWatch, logs
└── 📁 Documentation/              # Documentation technique (NOUVEAU)
    ├── 📁 architecture/           # Architecture système
    ├── 📁 deployment/             # Guides de déploiement
    └── 📁 maintenance/            # Maintenance et monitoring
```

## 🆕 Nouveaux dossiers créés

### **1. Infrastructure AWS (`Serveur/infrastructure/`)**
- **`terraform/`** : Configuration Terraform complète
  - `main.tf` : Infrastructure principale
  - `variables.tf` : Variables d'environnement
  - `terraform.tfvars.example` : Exemple de configuration
- **`docker/`** : Configuration Docker
  - `docker-compose.yml` : Environnement de développement local
- **`aws/`** : Scripts et configurations AWS
  - `scripts/deploy.sh` : Script de déploiement automatisé

### **2. Configuration OVH (`OVH-Config/`)**
- **`dns/`** : Configuration DNS
  - `ipowerfrance.fr.zone` : Zone DNS complète
- **`ssl/`** : Configuration SSL
  - `ssl-config.md` : Guide de configuration SSL
- **`domain-management/`** : Gestion des domaines
  - `renewal-scripts/` : Scripts de renouvellement

### **3. Ressources AWS (`AWS-Resources/`)**
- **`databases/`** : Schémas et migrations
- **`storage/`** : Configurations S3
- **`monitoring/`** : CloudWatch et alertes

### **4. Documentation (`Documentation/`)**
- **`architecture/README.md`** : Documentation complète de l'architecture
- **`deployment/`** : Guides de déploiement
- **`maintenance/`** : Procédures de maintenance

## 🔧 Fichiers de configuration créés

### **Terraform**
- **`main.tf`** : Infrastructure complète (VPC, EC2, RDS, S3, CloudFront)
- **`variables.tf`** : Variables avec validation et valeurs par défaut
- **`terraform.tfvars.example`** : Exemple de configuration

### **Docker**
- **`docker-compose.yml`** : Environnement de développement complet
  - Frontend React (port 5173)
  - Backend Express (port 3001)
  - Base de données PostgreSQL (port 5432)
  - Cache Redis (port 6379)
  - Nginx (port 8080)
  - MinIO (ports 9000, 9001)
  - MailHog (ports 1025, 8025)

### **Scripts de déploiement**
- **`deploy.sh`** : Script automatisé de déploiement
  - Vérification des prérequis
  - Build frontend/backend
  - Déploiement infrastructure
  - Déploiement applications
  - Instructions DNS

### **Configuration DNS**
- **`ipowerfrance.fr.zone`** : Zone DNS complète avec pointage AWS
- **`ovh-aws-integration.md`** : Guide d'intégration OVH-AWS

## 🚀 Prochaines étapes

### **Phase 1 : Configuration locale**
1. **Installer les prérequis** :
   ```bash
   # AWS CLI
   brew install awscli
   
   # Terraform
   brew install terraform
   
   # Docker
   brew install docker
   ```

2. **Configurer AWS** :
   ```bash
   aws configure
   # Entrer vos clés AWS
   ```

3. **Tester l'environnement local** :
   ```bash
   cd "Site Web/Serveur/infrastructure/docker"
   docker-compose up -d
   ```

### **Phase 2 : Déploiement AWS**
1. **Configurer les variables Terraform** :
   ```bash
   cd "Site Web/Serveur/infrastructure/terraform"
   cp terraform.tfvars.example terraform.tfvars
   # Éditer avec vos vraies valeurs
   ```

2. **Déployer l'infrastructure** :
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Déployer les applications** :
   ```bash
   cd "Site Web/Serveur/infrastructure/aws/scripts"
   ./deploy.sh production
   ```

### **Phase 3 : Configuration OVH**
1. **Mettre à jour le DNS** avec les informations AWS
2. **Configurer les certificats SSL**
3. **Tester la connectivité**

## 💡 Avantages de cette architecture

### **OVH Cloud**
- ✅ Gestion DNS simplifiée
- ✅ Support français
- ✅ Prix compétitifs
- ✅ Conformité RGPD

### **AWS**
- ✅ Scalabilité infinie
- ✅ Services managés
- ✅ Sécurité de niveau entreprise
- ✅ Intégration native

### **Architecture hybride**
- ✅ Meilleur des deux mondes
- ✅ Flexibilité maximale
- ✅ Coûts optimisés
- ✅ Performance garantie

## 📊 Coûts estimés

- **AWS** : ~30€/mois (EC2 + RDS + S3 + CloudFront)
- **OVH** : ~10€/an (domaine + SSL)
- **Total** : ~31€/mois

## 🔗 Liens utiles

- **Documentation complète** : `Documentation/architecture/README.md`
- **Guide d'intégration** : `OVH-Config/ovh-aws-integration.md`
- **Script de déploiement** : `Serveur/infrastructure/aws/scripts/deploy.sh`
- **Configuration Terraform** : `Serveur/infrastructure/terraform/`

---

*Structure créée le 18 août 2025 pour IPOWER MOTORS*
*Architecture hybride OVH Cloud + AWS pour ipowerfrance.fr*
