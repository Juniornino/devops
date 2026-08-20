variable "vpc_cidr" {
  description = "Plage d'adresses CIDR pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Nom de l'environnement (ex: dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "public_subnet_cidrs" {
  description = "Liste des plages CIDR pour les sous-réseaux publics"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Liste des plages CIDR pour les sous-réseaux privés"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Liste des plages CIDR pour les sous-réseaux de base de données isolés"
  type        = list(string)
  default     = ["10.0.100.0/24", "10.0.200.0/24"]
}

variable "availability_zones" {
  description = "Zones de disponibilité AWS (AZs)"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"] # Paris
}

variable "enable_nat_gateway" {
  description = "Activer la NAT Gateway pour autoriser les sous-réseaux privés à accéder à Internet"
  type        = bool
  default     = true
}
