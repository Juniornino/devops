output "alb_dns_name" {
  description = "Nom DNS public du Load Balancer (URL d'accès a l'application)"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "Adresse IP publique du Bastion Host"
  value       = aws_instance.bastion.public_ip
}

output "app_instance_private_ips" {
  description = "Adresses IP privées des instances applicatives EC2"
  value       = aws_instance.app_server[*].private_ip
}

output "target_group_arn" {
  description = "ARN du Target Group de l'ALB"
  value       = aws_lb_target_group.app_tg.arn
}
