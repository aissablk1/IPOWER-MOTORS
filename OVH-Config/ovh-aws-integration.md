# Intégration OVH Cloud + AWS pour ipowerfrance.fr

## 🔗 Configuration de l'intégration

### 1. Configuration DNS OVH

#### **Enregistrements principaux**
```dns
# Pointage racine vers AWS Load Balancer
@       IN      A       [IP_LOAD_BALANCER_AWS]

# Pointage www vers CloudFront
www     IN      CNAME   [DOMAIN_CLOUDFRONT].cloudfront.net.

# Pointage API vers Load Balancer
api     IN      CNAME   [DOMAIN_LOAD_BALANCER_AWS]

# Pointage admin vers Load Balancer
admin   IN      CNAME   [DOMAIN_LOAD_BALANCER_AWS]
```

#### **Enregistrements de sécurité**
```dns
# SPF pour l'email
@       IN      TXT     "v=spf1 include:_spf.google.com ~all"

# DKIM (à configurer selon votre fournisseur email)
@       IN      TXT     "v=DKIM1; k=rsa; p=[CLE_PUBLIQUE_DKIM]"

# DMARC
@       IN      TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@ipowerfrance.fr"
```

### 2. Configuration AWS Route 53

#### **Zone hébergée**
- **Nom** : `ipowerfrance.fr.aws.`
- **Type** : Zone hébergée publique
- **Région** : `eu-west-3`

#### **Enregistrements NS**
```dns
# Dans OVH, ajouter ces serveurs de noms
ipowerfrance.fr.aws.    IN      NS      ns-1234.awsdns-12.com.
ipowerfrance.fr.aws.    IN      NS      ns-5678.awsdns-34.net.
```

### 3. Configuration des certificats SSL

#### **Option 1 : Certificat OVH**
1. Commander le certificat dans OVH Manager
2. Valider via DNS ou fichier
3. Exporter et importer dans AWS ACM

#### **Option 2 : Certificat AWS ACM**
1. Créer le certificat dans ACM
2. Valider via DNS (ajouter dans OVH)
3. Utiliser directement dans CloudFront/Load Balancer

### 4. Configuration CloudFront

#### **Domaines alternatifs**
- `ipowerfrance.fr`
- `www.ipowerfrance.fr`
- `cdn.ipowerfrance.fr`

#### **Origine S3**
- **Bucket** : `ipower-motors-frontend`
- **Access** : Origin Access Control (OAC)
- **Compression** : Gzip activé

#### **Comportements de cache**
- **HTML/CSS/JS** : Cache 1 heure
- **Images** : Cache 1 jour
- **Fonts** : Cache 1 semaine

### 5. Configuration Load Balancer

#### **Target Groups**
- **Frontend** : Port 80 → EC2:3000
- **Backend** : Port 3001 → EC2:3001
- **Health Checks** : `/health` toutes les 30 secondes

#### **Listeners**
- **HTTP 80** : Redirection vers HTTPS 443
- **HTTPS 443** : Certificat ACM + Target Groups

## 🚀 Processus de déploiement

### **Phase 1 : Configuration OVH**
```bash
# 1. Configurer les serveurs de noms AWS dans OVH
# 2. Ajouter les enregistrements DNS
# 3. Commander et valider le certificat SSL
```

### **Phase 2 : Déploiement AWS**
```bash
# 1. Déployer l'infrastructure Terraform
cd Site\ Web/Serveur/infrastructure/terraform
terraform init
terraform plan
terraform apply

# 2. Déployer les applications
cd Site\ Web/Serveur/infrastructure/aws/scripts
./deploy.sh production
```

### **Phase 3 : Finalisation DNS**
```bash
# 1. Récupérer les informations AWS
terraform output

# 2. Mettre à jour OVH avec les vraies valeurs
# 3. Tester la connectivité
```

## 🔍 Tests de validation

### **Test DNS**
```bash
# Vérifier la résolution DNS
nslookup ipowerfrance.fr
dig ipowerfrance.fr
```

### **Test SSL**
```bash
# Vérifier le certificat SSL
openssl s_client -connect ipowerfrance.fr:443 -servername ipowerfrance.fr
```

### **Test de performance**
```bash
# Test de vitesse avec curl
curl -w "@curl-format.txt" -o /dev/null -s "https://ipowerfrance.fr"

# Test CloudFront
curl -I "https://cdn.ipowerfrance.fr/logo.png"
```

### **Test de sécurité**
```bash
# Vérifier les en-têtes de sécurité
curl -I "https://ipowerfrance.fr"

# Test SSL Labs
# https://www.ssllabs.com/ssltest/analyze.html?d=ipowerfrance.fr
```

## ⚠️ Points d'attention

### **DNS**
- **TTL** : Réduire à 300 secondes pendant la migration
- **Propagation** : Peut prendre jusqu'à 48h
- **Cache** : Vider le cache DNS local si nécessaire

### **SSL**
- **Renouvellement** : Automatiser avec OVH
- **Chaîne** : Vérifier la complétude du certificat
- **HSTS** : Activer progressivement

### **Performance**
- **CloudFront** : Surveiller les métriques de cache
- **Latence** : Optimiser la région AWS
- **Compression** : Vérifier l'efficacité

## 🔧 Dépannage

### **Problèmes DNS**
```bash
# Vérifier la propagation
dig +trace ipowerfrance.fr

# Tester depuis différents serveurs
nslookup ipowerfrance.fr 8.8.8.8
nslookup ipowerfrance.fr 1.1.1.1
```

### **Problèmes SSL**
```bash
# Vérifier la chaîne de certificats
openssl s_client -connect ipowerfrance.fr:443 -showcerts

# Tester la compatibilité
curl -v "https://ipowerfrance.fr"
```

### **Problèmes de performance**
```bash
# Vérifier CloudFront
aws cloudfront get-distribution --id [DISTRIBUTION_ID]

# Vérifier les logs
aws logs describe-log-groups --log-group-name-prefix "/aws/cloudfront"
```

## 📞 Support

### **OVH Cloud**
- **Documentation** : https://docs.ovh.com
- **Support** : Via l'interface OVH Manager
- **Communauté** : https://community.ovh.com

### **AWS**
- **Documentation** : https://docs.aws.amazon.com
- **Support** : AWS Support (selon le plan)
- **Communauté** : https://aws.amazon.com/fr/community

---

*Configuration maintenue par l'équipe IPOWER MOTORS*
*Dernière mise à jour : Janvier 2025*
