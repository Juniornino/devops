terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Exemple de configuration du Backend Distant (AWS S3 + DynamoDB)
  # Décommenter et adapter en production :
  # backend "s3" {
  #   bucket         = "mon-projet-terraform-state-ghislain"
  #   key            = "dev/terraform.tfstate"
  #   region         = "eu-west-3"
  #   dynamodb_table = "terraform-state-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Lab-DevOps-NestJS"
      ManagedBy   = "Terraform"
    }
  }
}
