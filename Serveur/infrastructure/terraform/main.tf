# IPOWER MOTORS - Infrastructure AWS
# Configuration Terraform pour ipowerfrance.fr

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "ipower-motors-terraform-state"
    key    = "ipowerfrance.fr/terraform.tfstate"
    region = "eu-west-3"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "IPOWER-MOTORS"
      Environment = var.environment
      Domain      = "ipowerfrance.fr"
      ManagedBy   = "Terraform"
    }
  }
}

# VPC et réseau
module "vpc" {
  source = "./modules/vpc"
  
  environment = var.environment
  domain     = var.domain
}

# Base de données RDS
module "database" {
  source = "./modules/database"
  
  environment = var.environment
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

# Stockage S3
module "storage" {
  source = "./modules/storage"
  
  environment = var.environment
  domain     = var.domain
}

# Serveur EC2
module "ec2" {
  source = "./modules/ec2"
  
  environment = var.environment
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
}

# CloudFront pour le frontend
module "cloudfront" {
  source = "./modules/cloudfront"
  
  environment = var.environment
  domain     = var.domain
  s3_bucket  = module.storage.frontend_bucket_id
}
