output "vpc_id" {
  description = "ID du VPC crée"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Liste des IDs des sous-réseaux publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Liste des IDs des sous-réseaux privés applicatifs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Liste des IDs des sous-réseaux privés base de données"
  value       = aws_subnet.database[*].id
}

output "alb_security_group_id" {
  description = "ID du Security Group du Load Balancer"
  value       = aws_security_group.alb_sg.id
}

output "bastion_security_group_id" {
  description = "ID du Security Group Bastion"
  value       = aws_security_group.bastion_sg.id
}

output "app_security_group_id" {
  description = "ID du Security Group Applicatif"
  value       = aws_security_group.app_sg.id
}

output "db_security_group_id" {
  description = "ID du Security Group de la base de données"
  value       = aws_security_group.db_sg.id
}
