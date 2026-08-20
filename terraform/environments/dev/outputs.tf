output "vpc_id" {
  description = "ID du VPC créé"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "IDs des sous-réseaux publics"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnets" {
  description = "IDs des sous-réseaux privés applicatifs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnets" {
  description = "IDs des sous-réseaux privés base de données"
  value       = module.vpc.database_subnet_ids
}

output "application_url" {
  description = "URL publique de l'application via le Load Balancer (ALB)"
  value       = "http://${module.compute.alb_dns_name}"
}

output "bastion_ip" {
  description = "IP publique du Bastion SSH"
  value       = module.compute.bastion_public_ip
}

output "ecr_backend_url" {
  description = "URL de l'ECR pour le backend NestJS"
  value       = module.ecr_backend.repository_url
}

output "ecr_frontend_url" {
  description = "URL de l'ECR pour le frontend React"
  value       = module.ecr_frontend.repository_url
}
