<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](https://github.com/appvia/terraform-aws-module-template/actions/workflows/terraform.yml/badge.svg)

# Terraform Kubernetes Onboarding Module

## Description

This module is used to onboard a new Kubernetes cluster as a hub or spoke cluster, using the platform pattern outline in the [Kubernetes Platform](https://github.com/gambol99/kubernetes-platform). Please visit the following

- [Kubernetes Platform](https://gambol99.github.io/kubernetes-platform/) - the platform documentation
- [Kubernetes Platform Repository](https://github.com/gambol99/kubernetes-platform) - the platform repository
- [Platform Tenant Repository](https://github.com/gambol99/platform-tenant/) - an example tenant repository, consuming the platform and this module.

## Usage

The following example demonstrates how to use the module to provision the platform

```hcl
## Provision and bootstrap the platform using an tenant repository
module "platform" {
  count  = local.enable_platform ? 1 : 0
  source = "github.com/gambol99/terraform-aws-eks//modules/platform?ref=v0.1.1"

  ## Name of the cluster
  cluster_name = local.cluster_name
  # The type of cluster
  cluster_type = local.cluster_type
  # Any repositories to be provisioned
  repositories = var.argocd_repositories
  ## The platform repository
  platform_repository = local.platform_repository
  # The location of the platform repository
  platform_revision = local.platform_revision
  # The location of the tenant repository
  tenant_repository = local.tenant_repository
  # You pretty much always want to use the HEAD
  tenant_revision = local.tenant_revision
  ## The tenant repository path
  tenant_path = local.tenant_path

  depends_on = [
    module.eks
  ]
}
```

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 2.1.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_type"></a> [cluster\_type](#input\_cluster\_type) | The type of cluster we are onboarding i.e. hub or standalone | `string` | n/a | yes |
| <a name="input_argocd_admin_password"></a> [argocd\_admin\_password](#input\_argocd\_admin\_password) | Initial admin password for ArgoCD | `string` | `null` | no |
| <a name="input_argocd_chart"></a> [argocd\_chart](#input\_argocd\_chart) | The name of the chart to install | `string` | `"argo-cd"` | no |
| <a name="input_argocd_helm_repository"></a> [argocd\_helm\_repository](#input\_argocd\_helm\_repository) | The URL of the ArgoCD Helm repository | `string` | `"https://argoproj.github.io/argo-helm"` | no |
| <a name="input_argocd_namespace"></a> [argocd\_namespace](#input\_argocd\_namespace) | The namespace to install ArgoCD | `string` | `"argocd"` | no |
| <a name="input_argocd_values"></a> [argocd\_values](#input\_argocd\_values) | Additional values to add to the argocd Helm chart | `list(string)` | `[]` | no |
| <a name="input_argocd_version"></a> [argocd\_version](#input\_argocd\_version) | Version of ArgoCD Helm chart to install | `string` | `"7.8.5"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the cluster | `string` | `null` | no |
| <a name="input_platform_repository"></a> [platform\_repository](#input\_platform\_repository) | The URL for the platform repository | `string` | `"https://github.com/gambol99/kubernetes-platform"` | no |
| <a name="input_platform_revision"></a> [platform\_revision](#input\_platform\_revision) | The revision of the platform repository | `string` | `"HEAD"` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | A collection of repository secrets to add to the argocd namespace | <pre>map(object({<br/>    ## The description of the repository<br/>    description = string<br/>    ## The secret to use for the repository<br/>    secret = optional(string, null)<br/>    ## The secret manager ARN to use for the secret<br/>    secret_manager_arn = optional(string, null)<br/>    ## The URL of the repository<br/>    url = string<br/>    ## An optional username for the repository<br/>    username = optional(string, null)<br/>    ## An optional password for the repository<br/>    password = optional(string, null)<br/>    ## An optional SSH private key for the repository<br/>    ssh_private_key = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_revision_overrides"></a> [revision\_overrides](#input\_revision\_overrides) | Revision overrides permit the user to override the revision contained in cluster definition | <pre>object({<br/>    platform_revision = optional(string, null)<br/>    tenant_revision   = optional(string, null)<br/>  })</pre> | `null` | no |
| <a name="input_tenant_path"></a> [tenant\_path](#input\_tenant\_path) | The path inside the tenant repository | `string` | `""` | no |
| <a name="input_tenant_repository"></a> [tenant\_repository](#input\_tenant\_repository) | The URL of the tenant repository | `string` | `"https://github.com/gambol99/eks-tenant"` | no |
| <a name="input_tenant_revision"></a> [tenant\_revision](#input\_tenant\_revision) | The revision of the tenant repository | `string` | `"HEAD"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
