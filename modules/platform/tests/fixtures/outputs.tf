output "secret_manager_arn" {
  description = "ARN of the test secret manager secret"
  value       = aws_secretsmanager_secret.repository_secret.arn
}
