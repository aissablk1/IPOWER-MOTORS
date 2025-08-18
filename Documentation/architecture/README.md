# Architecture IPOWER MOTORS - ipowerfrance.fr
## Architecture hybride OVH Cloud + AWS

### 🏗️ Vue d'ensemble

Cette architecture combine la simplicité de gestion des domaines d'OVH Cloud avec la puissance et la scalabilité d'AWS pour créer une solution web professionnelle et performante.

```
OVH Cloud (DNS) → AWS Route 53 → AWS Services
     ↓
ipowerfrance.fr → Load Balancer → EC2/Lambda
     ↓
     → RDS (Base de données)
     → S3 (Stockage)
     → CloudFront (CDN)
```

### 🌐 Composants OVH Cloud

#### **Gestion des domaines**
- **Domaine principal** : `ipowerfrance.fr`
- **Alias** : `www.ipowerfrance.fr`, `ipowerfrance.fr`
- **Sous-domaines** : `api.ipowerfrance.fr`, `admin.ipowerfrance.fr`

#### **Configuration DNS**
- **Serveurs de noms** : `ns1.ovh.net`, `ns2.ovh.net`
- **Pointage** : Vers l'infrastructure AWS
- **SSL** : Certificats gérés par OVH

### ☁️ Composants AWS

#### **Frontend (S3 + CloudFront)**
- **Stockage** : Amazon S3 pour les fichiers statiques
- **Distribution** : CloudFront pour la performance globale
- **HTTPS** : Certificats ACM intégrés

#### **Backend (EC2)**
- **Serveur** : Instance EC2 t3.medium
- **Runtime** : Node.js avec Express
- **Process Manager** : PM2 ou systemd

#### **Base de données (RDS)**
- **Type** : PostgreSQL 15
- **Instance** : db.t3.micro (développement) → db.t3.small (production)
- **Backup** : Automatique quotidien

#### **Stockage (S3)**
- **Documents** : Stockage des fichiers clients
- **Images** : Optimisation et redimensionnement
- **Backups** : Sauvegarde des données

#### **Monitoring (CloudWatch)**
- **Métriques** : CPU, mémoire, disque
- **Logs** : Centralisation des logs
- **Alertes** : Notifications automatiques

### 🔄 Flux de données

#### **Requête utilisateur**
1. `ipowerfrance.fr` → OVH DNS
2. OVH → AWS Route 53
3. Route 53 → CloudFront (frontend) ou Load Balancer (backend)

#### **Frontend**
1. CloudFront → S3 (fichiers statiques)
2. React SPA → API backend
3. Cache CloudFront pour la performance

#### **Backend**
1. Load Balancer → EC2
2. EC2 → RDS (base de données)
3. EC2 → S3 (stockage fichiers)

### 🚀 Déploiement

#### **Environnements**
- **Development** : Docker Compose local
- **Staging** : AWS avec données de test
- **Production** : AWS avec données réelles

#### **Pipeline CI/CD**
1. **Build** : Frontend (Vite) + Backend (TypeScript)
2. **Test** : Vitest + Supertest
3. **Deploy** : Terraform + Scripts AWS
4. **DNS** : Mise à jour OVH manuelle

### 🔐 Sécurité

#### **Réseau**
- **VPC** : Isolation des ressources
- **Security Groups** : Contrôle d'accès
- **NACLs** : Règles de pare-feu

#### **Authentification**
- **JWT** : Tokens sécurisés
- **OAuth** : Intégration Google/Microsoft
- **2FA** : Authentification à deux facteurs

#### **Chiffrement**
- **HTTPS** : TLS 1.3 obligatoire
- **Base de données** : Chiffrement au repos
- **S3** : Chiffrement des objets

### 📊 Performance

#### **Optimisations frontend**
- **Code splitting** : Chargement à la demande
- **Lazy loading** : Images et composants
- **Service Worker** : Cache offline

#### **Optimisations backend**
- **Redis** : Cache en mémoire
- **Connection pooling** : Base de données
- **Compression** : Gzip/Brotli

#### **CDN CloudFront**
- **Edge locations** : Distribution globale
- **Cache** : Stratégies intelligentes
- **Compression** : Optimisation automatique

### 💰 Coûts estimés

#### **AWS (mensuel)**
- **EC2 t3.medium** : ~15€
- **RDS db.t3.micro** : ~10€
- **S3 + CloudFront** : ~5€
- **Total estimé** : ~30€/mois

#### **OVH Cloud**
- **Domaine** : ~10€/an
- **SSL** : Gratuit (Let's Encrypt)

### 🛠️ Outils de développement

#### **Infrastructure**
- **Terraform** : Infrastructure as Code
- **Docker** : Conteneurisation
- **AWS CLI** : Gestion AWS

#### **Monitoring**
- **CloudWatch** : Métriques AWS
- **Grafana** : Tableaux de bord
- **Sentry** : Gestion des erreurs

### 📋 Checklist de déploiement

- [ ] Configuration AWS CLI
- [ ] Installation Terraform
- [ ] Création des clés SSH
- [ ] Configuration OVH DNS
- [ ] Déploiement infrastructure
- [ ] Déploiement applications
- [ ] Tests de connectivité
- [ ] Configuration SSL
- [ ] Tests de performance
- [ ] Mise en production

### 🔗 Liens utiles

- **AWS Console** : https://console.aws.amazon.com
- **OVH Manager** : https://www.ovh.com/manager
- **Terraform Docs** : https://www.terraform.io/docs
- **Docker Hub** : https://hub.docker.com

---

*Documentation maintenue par l'équipe IPOWER MOTORS*
*Dernière mise à jour : Janvier 2025*
