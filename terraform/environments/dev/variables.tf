variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Plage CIDR pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_name" {
  description = "Nom de l'application"
  type        = string
  default     = "nestjs-ecommerce"
}

variable "db_password" {
  description = "Mot de passe RDS PostgreSQL fourni via TF_VAR_db_password"
  type        = string
  sensitive   = true
}
