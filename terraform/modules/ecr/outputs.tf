output "repository_url" {
  description = "URL unique du registre ECR (a utiliser avec 'docker push')"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  description = "ARN du registre ECR"
  value       = aws_ecr_repository.app.arn
}
