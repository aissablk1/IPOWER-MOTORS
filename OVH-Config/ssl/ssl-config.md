# Configuration SSL pour IPOWER MOTORS
# ===================================

## Informations du certificat AWS ACM

### Certificat principal
- **ARN** : `arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5`
- **Domaine principal** : `ipowerfrance.fr`
- **Sous-domaines** : `*.ipowerfrance.fr` (inclut www.ipowerfrance.fr)
- **Région** : `eu-west-3` (Europe - Paris)
- **Statut** : Validé et actif
- **Type de validation** : DNS (automatique via OVH)

## Configuration des services AWS

### 1. CloudFront Distribution
```json
{
  "ViewerCertificate": {
    "ACMCertificateArn": "arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021",
    "Certificate": "arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5",
    "CertificateSource": "acm"
  }
}
```

### 2. Application Load Balancer
```json
{
  "Listener": {
    "Protocol": "HTTPS",
    "Port": 443,
    "DefaultActions": [
      {
        "Type": "forward",
        "TargetGroupArn": "arn:aws:elasticloadbalancing:eu-west-3:509505638058:targetgroup/ipower-backend/123456789"
      }
    ],
    "Certificates": [
      {
        "CertificateArn": "arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5"
      }
    ]
  }
}
```

### 3. API Gateway (si utilisé)
```json
{
  "DomainName": "api.ipowerfrance.fr",
  "CertificateArn": "arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5",
  "SecurityPolicy": "TLS_1_2"
}
```

## Configuration Terraform

### Variables SSL
```hcl
variable "ssl_certificate_arn" {
  description = "ARN du certificat SSL AWS ACM"
  type        = string
  default     = "arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5"
}

variable "domain_name" {
  description = "Nom de domaine principal"
  type        = string
  default     = "ipowerfrance.fr"
}

variable "domain_www" {
  description = "Sous-domaine www"
  type        = string
  default     = "www.ipowerfrance.fr"
}
```

### Ressources SSL
```hcl
# Certificat SSL (déjà créé)
data "aws_acm_certificate" "ipower_ssl" {
  arn = var.ssl_certificate_arn
}

# CloudFront avec SSL
resource "aws_cloudfront_distribution" "ipower_frontend" {
  # ... autres configurations ...
  
  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.ipower_ssl.arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# ALB avec SSL
resource "aws_lb_listener" "ipower_https" {
  load_balancer_arn = aws_lb.ipower_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.ipower_ssl.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ipower_backend.arn
  }
}
```

## Validation et tests

### 1. Vérification du certificat
```bash
# Vérifier le statut du certificat
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5 \
  --region eu-west-3

# Vérifier la validation DNS
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5 \
  --region eu-west-3 \
  --query 'Certificate.DomainValidationOptions'
```

### 2. Tests de connectivité SSL
```bash
# Test du certificat principal
openssl s_client -connect ipowerfrance.fr:443 -servername ipowerfrance.fr

# Test du sous-domaine www
openssl s_client -connect www.ipowerfrance.fr:443 -servername www.ipowerfrance.fr

# Test de l'API
openssl s_client -connect api.ipowerfrance.fr:443 -servername api.ipowerfrance.fr

# Vérification de la chaîne de certificats
echo | openssl s_client -connect ipowerfrance.fr:443 -servername ipowerfrance.fr 2>/dev/null | openssl x509 -noout -text
```

### 3. Tests de sécurité
```bash
# Test SSL Labs (en ligne)
# https://www.ssllabs.com/ssltest/analyze.html?d=ipowerfrance.fr

# Test de la configuration TLS
nmap --script ssl-enum-ciphers -p 443 ipowerfrance.fr

# Vérification des en-têtes de sécurité
curl -I https://ipowerfrance.fr
curl -I https://www.ipowerfrance.fr
```

## Renouvellement automatique

### 1. AWS ACM
- **Renouvellement automatique** : Activé par défaut
- **Période** : 13 mois avant expiration
- **Validation** : DNS automatique via OVH
- **Monitoring** : CloudWatch Events + SNS

### 2. Script de renouvellement
```bash
#!/bin/bash
# Script de vérification et renouvellement SSL

CERT_ARN="arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5"
REGION="eu-west-3"
ALERT_EMAIL="contact@ipowerfrance.fr"

# Vérifier l'expiration
EXPIRY_DATE=$(aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region $REGION \
  --query 'Certificate.NotAfter' \
  --output text)

DAYS_UNTIL_EXPIRY=$(( ($(date -d "$EXPIRY_DATE" +%s) - $(date +%s)) / 86400 ))

if [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
  echo "ALERTE: Le certificat SSL expire dans $DAYS_UNTIL_EXPIRY jours" | \
  mail -s "ALERTE SSL - IPOWER MOTORS" $ALERT_EMAIL
fi
```

## Monitoring et alertes

### 1. CloudWatch Alarms
```json
{
  "AlarmName": "IPOWER-MOTORS-SSL-Expiry",
  "AlarmDescription": "Certificat SSL expire bientôt",
  "MetricName": "DaysToExpiry",
  "Namespace": "AWS/ACM",
  "Statistic": "Minimum",
  "Period": 86400,
  "EvaluationPeriods": 1,
  "Threshold": 30,
  "ComparisonOperator": "LessThanThreshold",
  "AlarmActions": ["arn:aws:sns:eu-west-3:509505638058:ipower-motors-alerts"]
}
```

### 2. SNS Topic pour les alertes
```json
{
  "TopicArn": "arn:aws:sns:eu-west-3:509505638058:ipower-motors-alerts",
  "Subscriptions": [
    {
      "Protocol": "email",
      "Endpoint": "contact@ipowerfrance.fr"
    }
  ]
}
```

## Notes importantes

- **Région** : Le certificat doit être dans la même région que CloudFront (us-east-1) ou dans eu-west-3 pour l'ALB
- **Validation** : La validation DNS est automatique via OVH
- **Renouvellement** : AWS gère automatiquement le renouvellement
- **Monitoring** : Configurer des alertes pour l'expiration
- **Tests** : Tester régulièrement la configuration SSL
- **Sécurité** : Utiliser TLS 1.2+ et des suites de chiffrement sécurisées
