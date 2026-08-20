variable "environment" {
  description = "Nom de l'environnement (ex: dev, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "ID du VPC dans lequel déployer les instances"
  type        = string
}

variable "public_subnet_ids" {
  description = "Liste des IDs des sous-réseaux publics (pour ALB et Bastion)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Liste des IDs des sous-réseaux privés (pour l'application NestJS/Docker)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID du Security Group du Load Balancer"
  type        = string
}

variable "bastion_security_group_id" {
  description = "ID du Security Group Bastion"
  type        = string
}

variable "app_security_group_id" {
  description = "ID du Security Group Applicatif"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2 pour les serveurs applicatifs"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "Clé publique SSH pour accéder aux instances EC2"
  type        = string
  default     = ""
}
