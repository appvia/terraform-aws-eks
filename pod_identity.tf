

## Provision custom identity for each pod identity
module "pod_identity" {
  for_each = var.pod_identity
  source   = "terraform-aws-modules/eks-pod-identity/aws"
  version  = "~> 1.4.0"

  name                     = each.value.name
  additional_policy_arns   = try(each.value.managed_policy_arns, {})
  permissions_boundary_arn = try(each.value.permissions_boundary_arn, null)
  policy_statements        = try(each.value.policy_statements, [])
  tags                     = local.tags

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = try(each.value.namespace, null)
      service_account = try(each.value.service_account, null)
    }
  }
}

## Provision the pod identity for cert-manager in the hub cluster
module "aws_cert_manager_pod_identity" {
  count   = var.cert_manager.enabled ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name                          = "cert-manager-${local.name}"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = try(var.cert_manager.route53_zone_arns, [])
  tags                          = local.tags

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = try(var.cert_manager.namespace, null)
      service_account = try(var.cert_manager.service_account, null)
    }
  }
}

## Provision the pod identity for external dns
module "aws_external_dns_pod_identity" {
  count   = var.external_dns.enabled ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name                          = "external-dns-${local.name}"
  tags                          = local.tags
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = try(var.external_dns.hosted_zone_arns, [])

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = try(var.external_dns.namespace, null)
      service_account = try(var.external_dns.service_account, null)
    }
  }
}

## Provision the pod identity for argocd in the hub cluster
module "aws_argocd_pod_identity" {
  count   = var.argocd.enabled ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  attach_custom_policy      = true
  custom_policy_description = "Allow ArgoCD to assume role into spoke accounts"
  name                      = "argocd-pod-identity-${local.name}"
  tags                      = local.tags
  use_name_prefix           = false

  policy_statements = [
    {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      effect    = "Allow"
      resources = [format("arn:aws:iam::*:role/%s", var.hub_account_roles_prefix)]
      sid       = "AllowAssumeRole"
    }
  ]

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = try(var.argocd.namespace, null)
      service_account = try(var.argocd.service_account, null)
    }
  }
}

## Provision the pod identity for the Terranetes platform
module "aws_terranetes_pod_identity" {
  count   = var.terranetes.enabled ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name                      = "terranetes-${local.name}"
  additional_policy_arns    = try(var.terranetes.managed_policy_arns, {})
  custom_policy_description = "Provides the permisions for the terraform controller "
  permissions_boundary_arn  = try(var.terranetes.permissions_boundary_arn, null)
  tags                      = local.tags

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = try(var.terranetes.namespace, null)
      service_account = try(var.terranetes.service_account, null)
    }
  }
}

## Provision External secrets pod identity
module "aws_external_secrets_pod_identity" {
  count   = var.external_secrets.enabled ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name                                  = "external-secrets-${local.name}"
  attach_external_secrets_policy        = true
  external_secrets_create_permission    = true
  external_secrets_secrets_manager_arns = try(var.external_secrets.secrets_manager_arns, [])
  external_secrets_ssm_parameter_arns   = try(var.external_secrets.ssm_parameter_arns, [])
  tags                                  = local.tags

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = try(var.external_secrets.namespace, null)
      service_account = try(var.external_secrets.service_account, null)
    }
  }
}

## Provision AWS Awk IAM Controllers pod identity
module "aws_ack_iam_pod_identity" {
  count   = var.aws_ack_iam.enabled ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name                      = "ack-iam-${local.name}"
  additional_policy_arns    = try(var.aws_ack_iam.managed_policy_arns, {})
  custom_policy_description = "AWS IAM Controllers for the ACK system"
  tags                      = local.tags

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = try(var.aws_ack_iam.namespace, null)
      service_account = try(var.aws_ack_iam.service_account, null)
    }
  }
}

## Provision the pod identity for the CloudWatch Agent
module "aws_cloudwatch_observability_pod_identity" {
  count   = var.cloudwatch_observability.enabled ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  attach_aws_cloudwatch_observability_policy = true
  name                                       = "cloudwatch-${local.name}"
  tags                                       = local.tags
  use_name_prefix                            = false

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = try(var.cloudwatch_observability.namespace, null)
      service_account = try(var.cloudwatch_observability.service_account, null)
    }
  }
}
