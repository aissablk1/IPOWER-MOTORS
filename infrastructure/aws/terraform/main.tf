# Configuration Terraform pour IPOWER MOTORS
# =========================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "ipower-motors-terraform-state"
    key            = "ipower-motors/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "ipower-terraform-locks"
    encrypt        = true
  }
}

# Configuration du provider AWS
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Client      = var.client_name
      Service     = var.service_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# Variables
variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "aws_account_id" {
  description = "ID du compte AWS"
  type        = string
  default     = "509505638058"
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

variable "ovh_ns1" {
  description = "Serveur de noms OVH principal"
  type        = string
  default     = "ns10.ovh.net"
}

variable "ovh_ns2" {
  description = "Serveur de noms OVH secondaire"
  type        = string
  default     = "dns10.ovh.net"
}

variable "ovh_account_id" {
  description = "ID du compte OVH"
  type        = string
  default     = "kd264307-ovh"
}

variable "ssl_certificate_arn" {
  description = "ARN du certificat SSL AWS ACM"
  type        = string
  default     = "arn:aws:acm:eu-west-3:509505638058:certificate/17bf551e-5e1e-44a0-8134-1ace507767a5"
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "ipower_admin"
}

variable "db_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
  default     = "BO6p1ROrRhn7ZDdkYpDvk7QtqV+av/SsdbFKvLogu4E="
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "ipower_motors"
}

variable "db_instance_class" {
  description = "Classe de l'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "ec2_instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.medium"
}

variable "ec2_key_name" {
  description = "Nom de la clé SSH"
  type        = string
  default     = "ipower-motors-key"
}

variable "admin_email" {
  description = "Email d'administration"
  type        = string
  default     = "contact@ipowerfrance.fr"
}

variable "tech_email" {
  description = "Email technique"
  type        = string
  default     = "contact@ipowerfrance.fr"
}

variable "alert_email" {
  description = "Email pour les alertes"
  type        = string
  default     = "contact@ipowerfrance.fr"
}

variable "budget_monthly" {
  description = "Budget mensuel en euros"
  type        = number
  default     = 50
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "IPOWER-MOTORS"
}

variable "client_name" {
  description = "Nom du client"
  type        = string
  default     = "IPOWER MOTORS"
}

variable "service_name" {
  description = "Nom du service"
  type        = string
  default     = "ipowerfrance.fr"
}

# =============================================================================
# RESSOURCES AWS
# =============================================================================

# 1. VPC et sous-réseaux
resource "aws_vpc" "ipower_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "IPOWER-MOTORS-VPC"
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

# 2. Internet Gateway et Route Tables
resource "aws_internet_gateway" "ipower_igw" {
  vpc_id = aws_vpc.ipower_vpc.id
  
  tags = {
    Name = "IPOWER-MOTORS-IGW"
  }
}

resource "aws_route_table" "ipower_public_rt" {
  vpc_id = aws_vpc.ipower_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ipower_igw.id
  }
  
  tags = {
    Name = "IPOWER-MOTORS-Public-RT"
  }
}

resource "aws_route_table_association" "ipower_public_1" {
  subnet_id      = aws_subnet.ipower_public_1.id
  route_table_id = aws_route_table.ipower_public_rt.id
}

resource "aws_route_table_association" "ipower_public_2" {
  subnet_id      = aws_subnet.ipower_public_2.id
  route_table_id = aws_route_table.ipower_public_rt.id
}

# 3. Security Groups
resource "aws_security_group" "ipower_alb" {
  name        = "IPOWER-MOTORS-ALB-SG"
  description = "Security group pour l'Application Load Balancer"
  vpc_id      = aws_vpc.ipower_vpc.id
  
  # HTTP
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
  
  # Tous les trafics sortants
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "IPOWER-MOTORS-ALB-SG"
  }
}

resource "aws_security_group" "ipower_backend" {
  name        = "IPOWER-MOTORS-Backend-SG"
  description = "Security group pour le backend EC2"
  vpc_id      = aws_vpc.ipower_vpc.id
  
  # SSH (seulement depuis votre IP)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restreindre à votre IP
  }
  
  # Application (depuis ALB)
  ingress {
    description     = "Application"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.ipower_alb.id]
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
  }
}

resource "aws_security_group" "ipower_rds" {
  name        = "IPOWER-MOTORS-RDS-SG"
  description = "Security group pour RDS"
  vpc_id      = aws_vpc.ipower_vpc.id
  
  # PostgreSQL (depuis EC2)
  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ipower_backend.id]
  }
  
  tags = {
    Name = "IPOWER-MOTORS-RDS-SG"
  }
}

# 4. IAM Role pour EC2 (OIDC GitHub + S3 + CloudWatch)
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
  }
}

resource "aws_iam_instance_profile" "ipower_ec2_profile" {
  name = "IPOWER-MOTORS-EC2-Profile"
  role = aws_iam_role.ipower_ec2_role.name
}

# Politique pour accès S3, CloudWatch, etc.
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
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.ipower_documents.arn,
          "${aws_s3_bucket.ipower_documents.arn}/*",
          aws_s3_bucket.ipower_backups.arn,
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
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# 5. Instance EC2
resource "aws_instance" "ipower_backend" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04 LTS
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name
  
  subnet_id                   = aws_subnet.ipower_public_1.id
  vpc_security_group_ids      = [aws_security_group.ipower_backend.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ipower_ec2_profile.name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  
  user_data = file("${path.module}/scripts/user-data.sh")
  
  tags = {
    Name = "IPOWER-MOTORS-Backend"
  }
}

# 6. Base de données RDS
resource "aws_db_subnet_group" "ipower_rds" {
  name       = "ipower-motors-rds-subnet-group"
  subnet_ids = [aws_subnet.ipower_private_1.id, aws_subnet.ipower_private_2.id]
  
  tags = {
    Name = "IPOWER-MOTORS-RDS-Subnet-Group"
  }
}

resource "aws_db_instance" "ipower_rds" {
  identifier = "ipower-motors-rds"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  
  db_name  = var.db_name
  username = var.db_username
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
  }
}

# 7. Buckets S3
resource "aws_s3_bucket" "ipower_frontend" {
  bucket = "ipower-motors-frontend"
  
  tags = {
    Name = "IPOWER-MOTORS-Frontend"
  }
}

resource "aws_s3_bucket" "ipower_documents" {
  bucket = "ipower-motors-documents"
  
  tags = {
    Name = "IPOWER-MOTORS-Documents"
  }
}

resource "aws_s3_bucket" "ipower_backups" {
  bucket = "ipower-motors-backups"
  
  tags = {
    Name = "IPOWER-MOTORS-Backups"
  }
}

# Configuration des buckets S3
resource "aws_s3_bucket_versioning" "ipower_frontend_versioning" {
  bucket = aws_s3_bucket.ipower_frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "ipower_documents_versioning" {
  bucket = aws_s3_bucket.ipower_documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "ipower_backups_versioning" {
  bucket = aws_s3_bucket.ipower_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Politiques de bucket
resource "aws_s3_bucket_policy" "ipower_frontend_policy" {
  bucket = aws_s3_bucket.ipower_frontend.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.ipower_frontend.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "ipower_documents_policy" {
  bucket = aws_s3_bucket.ipower_documents.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.ipower_documents.arn}/*"
      }
    ]
  })
}

# 8. CloudFront Distribution
resource "aws_cloudfront_origin_access_identity" "ipower_frontend" {
  comment = "IPOWER MOTORS Frontend OAI"
}

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
  }
}

# 9. Application Load Balancer
resource "aws_lb" "ipower_alb" {
  name               = "ipower-motors-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ipower_alb.id]
  subnets            = [aws_subnet.ipower_public_1.id, aws_subnet.ipower_public_2.id]
  
  enable_deletion_protection = false
  
  tags = {
    Name = "IPOWER-MOTORS-ALB"
  }
}

resource "aws_lb_target_group" "ipower_backend" {
  name     = "ipower-motors-backend-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = aws_vpc.ipower_vpc.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "IPOWER-MOTORS-Backend-TG"
  }
}

resource "aws_lb_target_group_attachment" "ipower_backend" {
  target_group_arn = aws_lb_target_group.ipower_backend.arn
  target_id        = aws_instance.ipower_backend.id
  port             = 3001
}

resource "aws_lb_listener" "ipower_http" {
  load_balancer_arn = aws_lb.ipower_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "ipower_https" {
  load_balancer_arn = aws_lb.ipower_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ipower_backend.arn
  }
}

# 10. Monitoring et alertes
resource "aws_sns_topic" "ipower_alerts" {
  name = "ipower-motors-alerts"
  
  tags = {
    Name = "IPOWER-MOTORS-Alerts"
  }
}

resource "aws_sns_topic_subscription" "ipower_email" {
  topic_arn = aws_sns_topic.ipower_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

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
  }
}

resource "aws_cloudwatch_metric_alarm" "ipower_rds_cpu" {
  alarm_name          = "IPOWER-MOTORS-RDS-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU utilisation élevée sur RDS"
  alarm_actions       = [aws_sns_topic.ipower_alerts.arn]
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ipower_rds.id
  }
  
  tags = {
    Name = "IPOWER-MOTORS-RDS-CPU-Alarm"
  }
}

# Outputs
output "website_url" {
  description = "URL du site web"
  value       = "https://${var.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID de la distribution CloudFront"
  value       = aws_cloudfront_distribution.ipower_frontend.id
}

output "cloudfront_domain_name" {
  description = "Nom de domaine CloudFront"
  value       = aws_cloudfront_distribution.ipower_frontend.domain_name
}

output "alb_dns_name" {
  description = "Nom DNS du Load Balancer"
  value       = aws_lb.ipower_alb.dns_name
}

output "rds_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = aws_db_instance.ipower_rds.endpoint
}

output "ec2_public_ip" {
  description = "IP publique de l'instance EC2"
  value       = aws_instance.ipower_backend.public_ip
}

output "s3_frontend_bucket" {
  description = "Nom du bucket S3 frontend"
  value       = aws_s3_bucket.ipower_frontend.bucket
}

output "s3_documents_bucket" {
  description = "Nom du bucket S3 documents"
  value       = aws_s3_bucket.ipower_documents.bucket
}
