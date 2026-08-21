output "role_arn" {
  description = "Role AWS assume temporairement par GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}
