variable "repository_name" {
  description = "Nom du registre d'images Docker ECR"
  type        = string
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "dev"
}
