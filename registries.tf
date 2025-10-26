#
## Provision pull-through cache for registries
##


## First we provision any credentials for the registries
resource "aws_secretsmanager_secret" "registries" {
  for_each = {
    for k, v in var.registries : k => v if v.credentials != null
  }

  name = try(each.value.credentials.secret_name, format("%s-credentials", lower(each.value.name)))
  tags = merge(local.tags, {
    "RegistryName" = each.value.name
    "RegistryURL"  = each.value.url
  })
}

## Provision the credentials within aws secrets manager
resource "aws_secretsmanager_secret_version" "registries" {
  for_each = {
    for k, v in var.registries : k => v if v.credentials != null
  }

  secret_id = aws_secretsmanager_secret.registries[each.key].id
  secret_string = jsonencode({
    username = try(each.value.credentials.username, null)
    password = try(each.value.credentials.password, null)
  })
}

## Provision the pull-through cache for the registry
resource "aws_ecr_pull_through_cache_rule" "registries" {
  for_each = var.registries

  credential_arn        = try(each.value.credentials_arn, null) != null ? each.value.credentials_arn : try(aws_secretsmanager_secret.registries[each.key].arn, null)
  ecr_repository_prefix = each.value.name
  upstream_registry_url = each.value.url
}
