## Test platform module Github App credentials for repository configurations
## These tests validate that Github App credentials can be sourced inline or from AWS
## Secrets Manager, and that repositories without Github App credentials still render.

## Note the Github App identifiers are deliberately mocked as JSON numbers rather than
## strings; Secrets Manager payloads are frequently written that way, and the rendered
## manifest must still quote them because Secret.stringData is a map[string]string.
mock_provider "aws" {
  mock_data "aws_secretsmanager_secret_version" {
    defaults = {
      secret_string = <<EOF
      {
        "github_app_id": 12345,
        "github_app_installation_id": 67890,
        "github_app_private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA1234567890\n-----END RSA PRIVATE KEY-----\n"
      }
      EOF
    }
  }
}

## A repository carrying no Github App credentials must still render. This is a
## regression test; a bare (non-null) template condition made the module fail for
## every repository that did not use a Github App.
run "repository_without_github_app_credentials" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description = "Repository with no Github App credentials"
        url         = "https://github.com/example/platform.git"
        type        = "repo-creds"
      }
    }
  }

  assert {
    condition     = can(yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body))
    error_message = "Should render a valid manifest when no Github App credentials are supplied"
  }

  assert {
    condition     = lookup(yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData, "githubAppID", null) == null
    error_message = "Should not emit githubAppID when no Github App credentials are supplied"
  }

  assert {
    condition     = lookup(yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData, "githubAppInstallationID", null) == null
    error_message = "Should not emit githubAppInstallationID when no Github App credentials are supplied"
  }

  assert {
    condition     = lookup(yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData, "githubAppPrivateKey", null) == null
    error_message = "Should not emit githubAppPrivateKey when no Github App credentials are supplied"
  }
}

## Github App credentials supplied inline on the repository
run "github_app_credentials_inline" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description                = "Repository with inline Github App credentials"
        url                        = "https://github.com/example/platform.git"
        type                       = "repo-creds"
        github_app_id              = "111111"
        github_app_installation_id = "222222"
        github_app_private_key     = "-----BEGIN RSA PRIVATE KEY-----\nINLINEKEY\n-----END RSA PRIVATE KEY-----\n"
      }
    }
  }

  assert {
    condition     = length(data.aws_secretsmanager_secret_version.repository_secrets) == 0
    error_message = "Should not query Secrets Manager when credentials are supplied inline"
  }

  assert {
    condition     = yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppID == "111111"
    error_message = "Should render the inline Github App ID as a quoted string"
  }

  assert {
    condition     = yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppInstallationID == "222222"
    error_message = "Should render the inline Github App installation ID as a quoted string"
  }

  ## A private key that is not re-indented breaks the YAML block scalar, so decoding
  ## the manifest and reading the key back proves the indentation is correct.
  assert {
    condition     = strcontains(yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppPrivateKey, "-----BEGIN RSA PRIVATE KEY-----\nINLINEKEY\n-----END RSA PRIVATE KEY-----")
    error_message = "Should render the inline Github App private key as a multi-line block scalar"
  }
}

## Github App credentials sourced from AWS Secrets Manager
run "github_app_credentials_from_secrets_manager" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description        = "Repository with Github App credentials from Secrets Manager"
        url                = "https://github.com/example/platform.git"
        type               = "repo-creds"
        secret_manager_arn = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:test-repository-secret"
      }
    }
  }

  assert {
    condition     = data.aws_secretsmanager_secret_version.repository_secrets["platform"] != null
    error_message = "Should retrieve the secret from AWS Secrets Manager"
  }

  assert {
    condition     = yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppID == "12345"
    error_message = "Should source the Github App ID from Secrets Manager and quote it"
  }

  assert {
    condition     = yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppInstallationID == "67890"
    error_message = "Should source the Github App installation ID from Secrets Manager and quote it"
  }

  assert {
    condition     = strcontains(yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppPrivateKey, "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA1234567890\n-----END RSA PRIVATE KEY-----")
    error_message = "Should source the Github App private key from Secrets Manager"
  }
}

## Inline Github App credentials take precedence over the Secrets Manager payload
run "github_app_inline_overrides_secrets_manager" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description                = "Repository overriding the Secrets Manager payload"
        url                        = "https://github.com/example/platform.git"
        type                       = "repo-creds"
        secret_manager_arn         = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:test-repository-secret"
        github_app_id              = "999999"
        github_app_installation_id = "888888"
      }
    }
  }

  assert {
    condition     = yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppID == "999999"
    error_message = "Inline Github App ID should take precedence over Secrets Manager"
  }

  assert {
    condition     = yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppInstallationID == "888888"
    error_message = "Inline Github App installation ID should take precedence over Secrets Manager"
  }

  ## Only the private key was left unset, so it must still fall back to the secret
  assert {
    condition     = strcontains(yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppPrivateKey, "MIIEpAIBAAKCAQEA1234567890")
    error_message = "Should fall back to Secrets Manager for the unset Github App private key"
  }
}

## A mixture of Github App and username/password repositories in a single call
run "github_app_alongside_basic_auth_repositories" {
  command = plan

  module {
    source = "./modules/platform"
  }

  variables {
    cluster_name = "test-cluster"
    repositories = {
      "platform" = {
        description                = "Repository using a Github App"
        url                        = "https://github.com/example/platform.git"
        type                       = "repo-creds"
        github_app_id              = "111111"
        github_app_installation_id = "222222"
        github_app_private_key     = "-----BEGIN RSA PRIVATE KEY-----\nINLINEKEY\n-----END RSA PRIVATE KEY-----\n"
      }
      "tenant" = {
        description = "Repository using basic authentication"
        url         = "https://github.com/example/tenant.git"
        username    = "tenant-user"
        password    = "tenant-password"
      }
    }
  }

  assert {
    condition     = length(resource.kubectl_manifest.repositories) == 2
    error_message = "Should create both repository secrets"
  }

  assert {
    condition     = yamldecode(resource.kubectl_manifest.repositories["platform"].yaml_body).stringData.githubAppID == "111111"
    error_message = "Should render Github App credentials for the Github App repository"
  }

  assert {
    condition     = yamldecode(resource.kubectl_manifest.repositories["tenant"].yaml_body).stringData.username == "tenant-user"
    error_message = "Should render basic authentication for the username/password repository"
  }

  assert {
    condition     = lookup(yamldecode(resource.kubectl_manifest.repositories["tenant"].yaml_body).stringData, "githubAppID", null) == null
    error_message = "Should not leak Github App credentials onto the username/password repository"
  }
}
