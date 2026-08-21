output "endpoint" {
  description = "Endpoint DNS privé de PostgreSQL"
  value       = aws_db_instance.postgres.address
}

output "port" {
  description = "Port PostgreSQL"
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "Nom de la base PostgreSQL"
  value       = aws_db_instance.postgres.db_name
}

output "password_parameter_name" {
  description = "Nom du paramètre SSM contenant le mot de passe PostgreSQL"
  value       = aws_ssm_parameter.db_password.name
}

output "password_parameter_arn" {
  description = "ARN du paramètre SSM contenant le mot de passe PostgreSQL"
  value       = aws_ssm_parameter.db_password.arn
}
