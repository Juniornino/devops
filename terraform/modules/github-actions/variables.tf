variable "environment" {
  description = "Nom de l'environnement deploye"
  type        = string
}

variable "aws_region" {
  description = "Region AWS utilisee par la pipeline"
  type        = string
}

variable "github_owner" {
  description = "Proprietaire du depot GitHub"
  type        = string
}

variable "github_repository" {
  description = "Nom du depot GitHub"
  type        = string
}

variable "github_branch" {
  description = "Branche autorisee a deployer"
  type        = string
  default     = "main"
}

variable "ecr_repository_arns" {
  description = "Depots ECR dans lesquels la pipeline peut publier"
  type        = list(string)
}

variable "app_instance_ids" {
  description = "Instances EC2 que la pipeline peut redeployer via SSM"
  type        = list(string)
}
