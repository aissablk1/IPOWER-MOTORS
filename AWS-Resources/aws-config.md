# Configuration AWS pour IPOWER MOTORS
# ====================================

## Informations du compte AWS

### Compte principal
- **Nom du compte** : IPOWER MOTORS
- **Adresse e-mail** : ipowermotors81@gmail.com
- **ID de compte AWS** : 509505638058
- **ID d'utilisateur canonique** : f60f8bcfb0727ef2455eac8cfa946e1f6177fbfe824419ad66100477309b79d0
- **Région par défaut** : eu-west-3 (Europe - Paris)

## Configuration AWS CLI

### 1. Configuration des identifiants
```bash
# Configuration AWS CLI (à exécuter une fois)
aws configure set aws_access_key_id [VOTRE_VRAIE_ACCESS_KEY]
aws configure set aws_secret_access_key [VOTRE_VRAIE_SECRET_KEY]
aws configure set default.region eu-west-3
aws configure set default.output json
```

### 2. Vérification de la configuration
```bash
# Vérifier la configuration
aws configure list

# Tester la connexion
aws sts get-caller-identity

# Vérifier les régions disponibles
aws ec2 describe-regions --query 'Regions[?RegionName==`eu-west-3`]'
```

## Services AWS utilisés

### 1. Compute
- **EC2** : Instance t3.medium pour le backend
- **Auto Scaling** : Gestion automatique de la charge
- **Load Balancer** : Distribution de la charge

### 2. Storage
- **S3** : Stockage des fichiers et du frontend
- **CloudFront** : Distribution de contenu global
- **EBS** : Stockage des volumes EC2

### 3. Database
- **RDS PostgreSQL** : Base de données principale (db.t3.micro)
- **ElastiCache Redis** : Cache et sessions

### 4. Networking
- **VPC** : Réseau privé virtuel
- **Route 53** : Gestion DNS (optionnel avec OVH)
- **CloudFront** : CDN global

### 5. Security
- **IAM** : Gestion des accès et identités
- **ACM** : Certificats SSL/TLS
- **Security Groups** : Règles de pare-feu

### 6. Monitoring
- **CloudWatch** : Surveillance et métriques
- **SNS** : Notifications et alertes
- **CloudTrail** : Audit des actions

## Configuration des ressources

### 1. VPC et sous-réseaux
```hcl
# VPC principal
resource "aws_vpc" "ipower_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "IPOWER-MOTORS-VPC"
    Project = "IPOWER-MOTORS"
  }
}

# Sous-réseaux publics
resource "aws_subnet" "ipower_public_1" {
  vpc_id            = aws_vpc.ipower_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
  
  tags = {
    Name = "IPOWER-MOTORS-Public-1"
  }
}

resource "aws_subnet" "ipower_public_2" {
  vpc_id            = aws_vpc.ipower_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3b"
  
  tags = {
    Name = "IPOWER-MOTORS-Public-2"
  }
}

# Sous-réseaux privés
resource "aws_subnet" "ipower_private_1" {
  vpc_id            = aws_vpc.ipower_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-west-3a"
  
  tags = {
    Name = "IPOWER-MOTORS-Private-1"
  }
}

resource "aws_subnet" "ipower_private_2" {
  vpc_id            = aws_vpc.ipower_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-west-3b"
  
  tags = {
    Name = "IPOWER-MOTORS-Private-2"
  }
}
```

### 2. Instance EC2
```hcl
# Instance EC2 pour le backend
resource "aws_instance" "ipower_backend" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04 LTS
  instance_type = "t3.medium"
  key_name      = "ipower-motors-key"
  
  subnet_id                   = aws_subnet.ipower_public_1.id
  vpc_security_group_ids      = [aws_security_group.ipower_backend.id]
  associate_public_ip_address = true
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  
  user_data = file("${path.module}/scripts/user-data.sh")
  
  tags = {
    Name = "IPOWER-MOTORS-Backend"
    Project = "IPOWER-MOTORS"
    Role = "Backend"
  }
}
```

### 3. Base de données RDS
```hcl
# Instance RDS PostgreSQL
resource "aws_db_instance" "ipower_rds" {
  identifier = "ipower-motors-rds"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  
  db_name  = "ipower_motors"
  username = "ipower_admin"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.ipower_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.ipower_rds.name
  
  backup_retention_period = 7
  backup_window          = "02:00-03:00"
  maintenance_window     = "sun:03:00-sun:04:00"
  
  skip_final_snapshot = false
  final_snapshot_identifier = "ipower-motors-final-snapshot"
  
  tags = {
    Name = "IPOWER-MOTORS-RDS"
    Project = "IPOWER-MOTORS"
  }
}
```

### 4. Buckets S3
```hcl
# Bucket frontend
resource "aws_s3_bucket" "ipower_frontend" {
  bucket = "ipower-motors-frontend"
  
  tags = {
    Name = "IPOWER-MOTORS-Frontend"
    Project = "IPOWER-MOTORS"
  }
}

# Bucket documents
resource "aws_s3_bucket" "ipower_documents" {
  bucket = "ipower-motors-documents"
  
  tags = {
    Name = "IPOWER-MOTORS-Documents"
    Project = "IPOWER-MOTORS"
  }
}

# Bucket sauvegardes
resource "aws_s3_bucket" "ipower_backups" {
  bucket = "ipower-motors-backups"
  
  tags = {
    Name = "IPOWER-MOTORS-Backups"
    Project = "IPOWER-MOTORS"
  }
}
```

### 5. Distribution CloudFront
```hcl
# Distribution CloudFront
resource "aws_cloudfront_distribution" "ipower_frontend" {
  origin {
    domain_name = aws_s3_bucket.ipower_frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.ipower_frontend.id}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.ipower_frontend.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  is_ipv6_enabled    = true
  default_root_object = "index.html"
  
  aliases = [var.domain_name, var.domain_www]
  
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.ipower_frontend.id}"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  # Cache pour les assets statiques
  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.ipower_frontend.id}"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }
  
  # Redirection des erreurs 404 vers index.html (SPA)
  custom_error_response {
    error_code         = 404
    response_code      = "200"
    response_page_path = "/index.html"
  }
  
  viewer_certificate {
    acm_certificate_arn      = var.ssl_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  tags = {
    Name = "IPOWER-MOTORS-CloudFront"
    Project = "IPOWER-MOTORS"
  }
}
```

## Coûts estimés

### Estimation mensuelle (eu-west-3)
- **EC2 t3.medium** : ~15€/mois
- **RDS db.t3.micro** : ~12€/mois
- **S3** : ~2€/mois (selon l'utilisation)
- **CloudFront** : ~3€/mois (selon le trafic)
- **Data Transfer** : ~5€/mois
- **Autres services** : ~3€/mois

**Total estimé** : ~40€/mois (dans votre budget de 50€)

## Sécurité

### 1. IAM Roles
```hcl
# Rôle EC2
resource "aws_iam_role" "ipower_ec2_role" {
  name = "IPOWER-MOTORS-EC2-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "IPOWER-MOTORS-EC2-Role"
    Project = "IPOWER-MOTORS"
  }
}

# Politique EC2
resource "aws_iam_role_policy" "ipower_ec2_policy" {
  name = "IPOWER-MOTORS-EC2-Policy"
  role = aws_iam_role.ipower_ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.ipower_documents.arn}/*",
          "${aws_s3_bucket.ipower_backups.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
```

### 2. Security Groups
```hcl
# Security Group pour le backend
resource "aws_security_group" "ipower_backend" {
  name        = "IPOWER-MOTORS-Backend-SG"
  description = "Security group pour le backend IPOWER MOTORS"
  vpc_id      = aws_vpc.ipower_vpc.id
  
  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTP (redirigé vers HTTPS)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Application
  ingress {
    description = "Application"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Tous les trafics sortants
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "IPOWER-MOTORS-Backend-SG"
    Project = "IPOWER-MOTORS"
  }
}
```

## Monitoring et alertes

### 1. CloudWatch Alarms
```hcl
# Alarme CPU EC2
resource "aws_cloudwatch_metric_alarm" "ipower_ec2_cpu" {
  alarm_name          = "IPOWER-MOTORS-EC2-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU utilisation élevée sur l'instance EC2"
  alarm_actions       = [aws_sns_topic.ipower_alerts.arn]
  
  dimensions = {
    InstanceId = aws_instance.ipower_backend.id
  }
  
  tags = {
    Name = "IPOWER-MOTORS-EC2-CPU-Alarm"
    Project = "IPOWER-MOTORS"
  }
}
```

### 2. SNS Topic
```hcl
# Topic SNS pour les alertes
resource "aws_sns_topic" "ipower_alerts" {
  name = "ipower-motors-alerts"
  
  tags = {
    Name = "IPOWER-MOTORS-Alerts"
    Project = "IPOWER-MOTORS"
  }
}

# Abonnement email
resource "aws_sns_topic_subscription" "ipower_email" {
  topic_arn = aws_sns_topic.ipower_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```

## Déploiement

### 1. Initialisation Terraform
```bash
# Aller dans le répertoire Terraform
cd "Site Web/infrastructure/aws/terraform"

# Initialiser Terraform
terraform init

# Vérifier le plan
terraform plan

# Appliquer la configuration
terraform apply
```

### 2. Déploiement des applications
```bash
# Déployer le frontend
cd "Site Web/Serveur"
./run.sh --aws-frontend

# Déployer le backend
./run.sh --aws-backend

# Déployer tout
./run.sh --aws-deploy
```

## Notes importantes

- **Région** : Toutes les ressources sont dans eu-west-3
- **Sécurité** : Chiffrement activé partout
- **Monitoring** : Alertes configurées
- **Sauvegarde** : RDS et S3 avec rétention
- **Coûts** : Dans votre budget de 50€/mois
- **Support** : Documentation complète fournie
