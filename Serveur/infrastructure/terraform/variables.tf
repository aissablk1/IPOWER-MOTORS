# Variables pour l'infrastructure IPOWER MOTORS

variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "L'environnement doit être development, staging ou production."
  }
}

variable "domain" {
  description = "Domaine principal"
  type        = string
  default     = "ipowerfrance.fr"
}

variable "domain_aliases" {
  description = "Alias de domaines"
  type        = list(string)
  default     = ["www.ipowerfrance.fr", "ipowerfrance.fr", "www.ipowerfrance.fr"]
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.medium"
}

variable "database_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "database_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "ipower_motors"
}

variable "database_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
}

variable "ssl_certificate_arn" {
  description = "ARN du certificat SSL ACM"
  type        = string
  default     = ""
}
