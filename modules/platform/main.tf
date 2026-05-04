## Provision a namespace for the ArgoCD
resource "kubectl_manifest" "namespace" {
  yaml_body = templatefile("${path.module}/assets/namespace.yaml", {})
}

## Provision the ArgoCD secrets
resource "kubectl_manifest" "admin_password" {
  count = var.argocd_admin_password != null ? 1 : 0

  yaml_body = templatefile("${path.module}/assets/secret.yaml", {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
    data = {
      password = var.argocd_admin_password
    }
  })

  depends_on = [
    kubectl_manifest.namespace
  ]
}

## Provision the ArgoCD Helm chart
resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = var.argocd_chart
  create_namespace = false
  namespace        = var.argocd_namespace
  repository       = var.argocd_helm_repository
  version          = var.argocd_version
  values           = concat([file("${path.module}/assets/values.yaml")], var.argocd_values)

  depends_on = [
    kubectl_manifest.namespace,
  ]
}

## Retrieve secrets from AWS Secrets Manager if secret_manager_arn is provided
data "aws_secretsmanager_secret_version" "repository_secrets" {
  for_each = {
    for k, v in var.repositories : k => v if v.secret_manager_arn != null
  }

  secret_id = each.value.secret_manager_arn
}

## Add repositories secrets into the argocd namespace if required
resource "kubectl_manifest" "repositories" {
  for_each = var.repositories

  yaml_body = templatefile("${path.module}/assets/repository.yaml", {
    name            = each.key
    url             = try(each.value.url, null)
    username        = try(coalesce(each.value.username, try(jsondecode(data.aws_secretsmanager_secret_version.repository_secrets[each.key].secret_string)["username"], null)), null)
    password        = try(coalesce(each.value.password, try(jsondecode(data.aws_secretsmanager_secret_version.repository_secrets[each.key].secret_string)["password"], null)), null)
    ssh_private_key = try(each.value.ssh_private_key, null)
    secret          = try(each.value.secret, null)
    type            = try(each.value.type, "repository")
  })

  depends_on = [
    helm_release.argocd,
    data.aws_secretsmanager_secret_version.repository_secrets,
  ]
}

## Provision the platform bootstrap. Note inclusion of the override is used to overload the
## revision held in the cluster definition; this is ONLY useful for development purposes, i.e
## locally validating the platform or running e2e tests, without having to commit changes to
## revisions in the cluster definition.
resource "kubectl_manifest" "bootstrap" {
  yaml_body = templatefile("${path.module}/assets/platform.yaml", {
    cluster_name           = try(var.cluster_name, "")
    cluster_type           = var.cluster_type
    platform_override      = try(var.revision_overrides.platform_revision, "")
    platform_repository    = var.platform_repository
    platform_revision      = var.platform_revision
    tenant_override        = try(var.revision_overrides.tenant_revision, "")
    tenant_repository      = var.tenant_repository
    tenant_repository_path = local.tenant_path
    tenant_revision        = var.tenant_revision
  })

  depends_on = [
    helm_release.argocd,
  ]
}
