## Test platform module secret_manager_arn functionality
## These tests validate that the secret_manager_arn feature works correctly for repository configurations

mock_provider "aws" {
  mock_data "aws_secretsmanager_secret_version" {
    defaults = {
      secret_string = jsonencode({
        password = "secret-password-from-secrets-manager"
        username = "test-user"
      })
    }
  }
}

run "setup_secrets_manager" {
  command = apply

  module {
    source = "./modules/platform/tests/fixtures"
  }
}

run "platform_with_secret_manager_arn_only" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description        = "Platform repository"
        url                = "https://github.com/example/platform.git"
        secret_manager_arn = run.setup_secrets_manager.secret_manager_arn
      }
    }
  }

  assert {
    condition     = data.aws_secretsmanager_secret_version.repository_secrets["platform"] != null
    error_message = "Should retrieve secret from AWS Secrets Manager"
  }

  assert {
    condition     = contains(keys(resource.kubectl_manifest.repositories), "platform")
    error_message = "Should create repository secret"
  }
}

run "platform_with_secret_manager_arn_and_password" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description        = "Platform repository"
        url                = "https://github.com/example/platform.git"
        password           = "local-password"
        secret_manager_arn = run.setup_secrets_manager.secret_manager_arn
      }
    }
  }

  assert {
    condition     = data.aws_secretsmanager_secret_version.repository_secrets["platform"] != null
    error_message = "Should retrieve secret from AWS Secrets Manager"
  }

  assert {
    condition     = contains(keys(resource.kubectl_manifest.repositories), "platform")
    error_message = "Should create repository secret"
  }
}

run "platform_with_secret_manager_arn_and_username" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description        = "Platform repository"
        url                = "https://github.com/example/platform.git"
        username           = "test-user"
        secret_manager_arn = run.setup_secrets_manager.secret_manager_arn
      }
    }
  }

  assert {
    condition     = data.aws_secretsmanager_secret_version.repository_secrets["platform"] != null
    error_message = "Should retrieve secret from AWS Secrets Manager"
  }

  assert {
    condition     = contains(keys(resource.kubectl_manifest.repositories), "platform")
    error_message = "Should create repository secret with username"
  }
}

run "platform_without_secret_manager_arn" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description = "Platform repository"
        url         = "https://github.com/example/platform.git"
        password    = "inline-password"
      }
    }
  }

  assert {
    condition     = length(data.aws_secretsmanager_secret_version.repository_secrets) == 0
    error_message = "Should not attempt to retrieve from Secrets Manager when secret_manager_arn is null"
  }

  assert {
    condition     = contains(keys(resource.kubectl_manifest.repositories), "platform")
    error_message = "Should create repository secret with inline password"
  }
}

run "platform_multiple_repositories_mixed_sources" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description        = "Platform repository with Secrets Manager"
        url                = "https://github.com/example/platform.git"
        secret_manager_arn = run.setup_secrets_manager.secret_manager_arn
      }
      "tenant" = {
        description = "Tenant repository with inline credentials"
        url         = "https://github.com/example/tenant.git"
        password    = "inline-password"
        username    = "tenant-user"
      }
    }
  }

  assert {
    condition     = length(data.aws_secretsmanager_secret_version.repository_secrets) == 1
    error_message = "Should only retrieve one secret from Secrets Manager"
  }

  assert {
    condition     = data.aws_secretsmanager_secret_version.repository_secrets["platform"] != null
    error_message = "Should retrieve platform secret from Secrets Manager"
  }

  assert {
    condition     = length(resource.kubectl_manifest.repositories) == 2
    error_message = "Should create both repository secrets"
  }
}

run "platform_secret_manager_arn_with_ssh_key" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description        = "Platform repository with SSH key"
        url                = "git@github.com:example/platform.git"
        ssh_private_key    = join("", [
          "-----BEGIN RSA PRIVATE KEY-----",
          "\n",
          "MIIEpAIBAAKCAQEA1234567890",
          "\n",
          "-----END RSA PRIVATE KEY-----"
        ])
        secret_manager_arn = run.setup_secrets_manager.secret_manager_arn
      }
    }
  }

  assert {
    condition     = data.aws_secretsmanager_secret_version.repository_secrets["platform"] != null
    error_message = "Should retrieve secret from AWS Secrets Manager"
  }

  assert {
    condition     = contains(keys(resource.kubectl_manifest.repositories), "platform")
    error_message = "Should create repository secret with SSH key"
  }
}
