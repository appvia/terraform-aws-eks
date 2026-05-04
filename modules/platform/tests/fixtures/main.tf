## Fixture for testing - Creates mock resources for testing

# Mock secret manager secret for testing
resource "aws_secretsmanager_secret" "repository_secret" {
  name                    = "test-repository-secret"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "repository_secret" {
  secret_id = aws_secretsmanager_secret.repository_secret.id
  secret_string = jsonencode({
    username = "test-user"
    password = "test-password"
  })
}
