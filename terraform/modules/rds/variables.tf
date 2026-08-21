variable "environment" {
  description = "Nom de l'environnement"
  type        = string
}

variable "app_name" {
  description = "Nom de l'application"
  type        = string
}

variable "db_subnet_ids" {
  description = "Subnets privés dédiés à la base de données"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security Group autorisé à joindre PostgreSQL"
  type        = string
}

variable "db_username" {
  description = "Utilisateur PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "Nom de la base PostgreSQL"
  type        = string
  default     = "lab_ghislain"
}

variable "db_password" {
  description = "Mot de passe PostgreSQL fourni hors du code Terraform"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Classe de l'instance RDS"
  type        = string
  default     = "db.t3.micro"
}
