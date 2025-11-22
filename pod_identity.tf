

## Provision custom identity for each pod identity
module "pod_identity" {
  for_each = var.pod_identity
  source   = "terraform-aws-modules/eks-pod-identity/aws"
  version  = "2.2.0"

  name                     = each.value.name
  description              = try(each.value.description, null) != null ? try(each.value.description, null) : "Pod identity for the ${each.value.name} platform for the ${local.name} cluster"
  additional_policy_arns   = try(each.value.managed_policy_arns, {})
  permissions_boundary_arn = try(each.value.permissions_boundary_arn, null)
  policy_statements        = try(each.value.policy_statements, [])
  tags                     = local.tags

  ## Default association for the pod identity
  association_defaults = {
    namespace       = each.value.namespace
    service_account = each.value.service_account
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}

## Provision the pod identity for cert-manager in the hub cluster
module "aws_cert_manager_pod_identity" {
  count   = var.cert_manager.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                          = "cert-manager-${local.name}"
  description                   = "Pod identity for cert-manager for the ${local.name} cluster"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = try(var.cert_manager.hosted_zone_arns, [])
  cert_manager_policy_name      = format("cert-manager-%s", local.name)
  tags                          = local.tags

  ## Default association for the cert-manager pod identity
  association_defaults = {
    namespace       = try(var.cert_manager.namespace, "cert-manager")
    service_account = try(var.cert_manager.service_account, "cert-manager")
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}

## Provision the pod identity for external dns
module "aws_external_dns_pod_identity" {
  count   = var.external_dns.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                          = "external-dns-${local.name}"
  description                   = "Pod identity for external dns for the ${local.name} cluster"
  tags                          = local.tags
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = try(var.external_dns.hosted_zone_arns, [])
  external_dns_policy_name      = format("external-dns-%s", local.name)

  ## Default association for the external DNS pod identity
  association_defaults = {
    namespace       = try(var.external_dns.namespace, "external-dns")
    service_account = try(var.external_dns.service_account, "external-dns")
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}

## Provision the pod identity for argocd in the hub cluster
module "aws_argocd_pod_identity" {
  count   = var.argocd.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                      = "argocd-pod-identity-${local.name}"
  description               = "Pod identity for argocd for the ${local.name} cluster"
  attach_custom_policy      = true
  custom_policy_description = "Allow ArgoCD to assume role into spoke accounts"
  tags                      = local.tags

  ## Default association for the argocd pod identity
  association_defaults = {
    namespace       = try(var.argocd.namespace, "argocd")
    service_account = try(var.argocd.service_account, "argocd")
  }

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
      cluster_name = module.eks.cluster_name
    }
  }
}

## Provision the pod identity for the Terranetes platform
module "aws_terranetes_pod_identity" {
  count   = var.terranetes.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                      = "terranetes-${local.name}"
  description               = "Pod identity for the Terranetes platform for the ${local.name} cluster"
  additional_policy_arns    = try(var.terranetes.managed_policy_arns, {})
  custom_policy_description = "Provides the permisions for the terraform controller "
  permissions_boundary_arn  = try(var.terranetes.permissions_boundary_arn, null)
  tags                      = local.tags

  ## Default association for the Terranetes pod identity
  association_defaults = {
    namespace       = try(var.terranetes.namespace, "terraform-system")
    service_account = try(var.terranetes.service_account, "terranetes-executor")
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}

## Provision External secrets pod identity
module "aws_external_secrets_pod_identity" {
  count   = var.external_secrets.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                                  = "external-secrets-${local.name}"
  description                           = "Pod identity for the External Secrets platform for the ${local.name} cluster"
  attach_external_secrets_policy        = true
  external_secrets_create_permission    = true
  external_secrets_secrets_manager_arns = try(var.external_secrets.secrets_manager_arns, [])
  external_secrets_ssm_parameter_arns   = try(var.external_secrets.ssm_parameter_arns, [])
  external_secrets_policy_name          = format("external-secrets-%s", local.name)
  tags                                  = local.tags

  ## Default association for the External Secrets pod identity
  association_defaults = {
    namespace       = try(var.external_secrets.namespace, "external-secrets")
    service_account = try(var.external_secrets.service_account, "external-secrets")
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}

## Provision AWS Awk IAM Controllers pod identity
module "aws_ack_iam_pod_identity" {
  count   = var.aws_ack_iam.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                      = "ack-iam-${local.name}"
  description               = "Pod identity for the AWS ACK IAM platform for the ${local.name} cluster"
  additional_policy_arns    = try(var.aws_ack_iam.managed_policy_arns, {})
  custom_policy_description = "AWS IAM Controllers for the ACK system for the ${local.name} cluster"
  tags                      = local.tags

  ## Default association for the AWS ACK IAM pod identity
  association_defaults = {
    namespace       = try(var.aws_ack_iam.namespace, "ack-system")
    service_account = try(var.aws_ack_iam.service_account, "ack-iam-controller")
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}

## Provision the pod identity for the AWS EKS ACK Controller
module "aws_eks_ack_controller_pod_identity" {
  count   = var.aws_eks_ack.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                      = "eks-ack-controller-${local.name}"
  description               = "Pod identity for the AWS EKS ACK Controller for the ${local.name} cluster"
  additional_policy_arns    = try(var.aws_eks_ack.managed_policy_arns, {})
  attach_custom_policy      = true
  custom_policy_description = "Permissions to create and manage the AWS EKS ACK Controller for the ${local.name} cluster"
  tags                      = local.tags

  policy_statements = [
    {
      sid    = "AllowPodIdentityAssociation"
      effect = "Allow"
      actions = [
        "eks:CreatePodIdentityAssociation",
        "eks:DeletePodIdentityAssociation",
        "eks:DescribePodIdentityAssociation",
        "eks:ListPodIdentityAssociations",
        "eks:TagResource",
        "eks:UntagResource",
        "eks:UpdatePodIdentityAssociation",
        "iam:GetRole",
        "iam:PassRole",
      ]
      resources = ["*"]
    }
  ]

  ## Default association for the AWS EKS ACK Controller pod identity
  association_defaults = {
    namespace       = try(var.aws_eks_ack.namespace, "ack-system")
    service_account = try(var.aws_eks_ack.service_account, "ack-eks-controller")
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}

## Provision the pod identity for the CloudWatch Agent
module "aws_cloudwatch_observability_pod_identity" {
  count   = var.cloudwatch_observability.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                                       = "cloudwatch-${local.name}"
  description                                = "Pod identity for the CloudWatch Agent for the ${local.name} cluster"
  attach_aws_cloudwatch_observability_policy = true
  tags                                       = local.tags

  ## Default association for the CloudWatch Agent pod identity
  association_defaults = {
    namespace       = try(var.cloudwatch_observability.namespace, "cloudwatch-observability")
    service_account = try(var.cloudwatch_observability.service_account, "cloudwatch-observability")
  }

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}
