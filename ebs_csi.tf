
locals {
  ## Indicates if we should attach the EBS CSI driver policy to the EKS cluster
  enable_ebs_csi_driver = try(var.ebs_csi_driver.enable, false) ? true : false
}

module "aws_ebs_csi_pod_identity" {
  count   = local.enable_ebs_csi_driver ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.6.0"

  name                      = "${local.name}-ebs-csi-driver"
  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = try(var.ebs_csi_driver.kms_key_arns, [])
  aws_ebs_csi_policy_name   = format("%s-ebs-csi-driver", local.name)
  description               = "Pod identity for the EBS CSI driver for the ${local.name} cluster"
  tags                      = local.tags

  ## Default association for the EBS CSI driver pod identity
  association_defaults = {
    namespace       = var.ebs_csi_driver.namespace
    service_account = var.ebs_csi_driver.service_account
  }

  ## Associations for the EBS CSI driver pod identity
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}

## Enable the EBS CSI driver
resource "aws_eks_addon" "ebs_csi_driver" {
  count = local.enable_ebs_csi_driver ? 1 : 0

  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.ebs_csi_driver.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = local.tags

  pod_identity_association {
    role_arn        = module.aws_ebs_csi_pod_identity[0].iam_role_arn
    service_account = var.ebs_csi_driver.service_account
  }
}
