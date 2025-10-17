#
## Used to enable the EFS CSI driver on the EKS cluster 
#

locals {
  ## Indicates if we should enable the EFS CSI driver
  enable_efs_csi_driver = try(var.efs_csi_driver.enabled, false) ? true : false
  ## The name of the EFS CSI driver policy
  efs_csi_policy_name_prefix = "${var.cluster_name}-efs-csi-driver"
}

## Attach the EFS CSI driver policy to the EKS cluster
module "aws_efs_csi_pod_identity" {
  count   = local.enable_efs_csi_driver ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.2.0"

  name                      = "${local.efs_csi_policy_name_prefix}-pod-identity"
  attach_aws_efs_csi_policy = true
  aws_efs_csi_policy_name   = local.efs_csi_policy_name_prefix
  description               = "Pod identity for the EFS CSI driver for the ${var.cluster_name} cluster"
  tags                      = local.tags
}

## Attach the EFS CSI driver policy to the EKS cluster
resource "aws_eks_addon" "efs_csi_driver" {
  count = local.enable_efs_csi_driver ? 1 : 0

  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-efs-csi-driver"
  addon_version               = var.efs_csi_driver.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = local.tags

  pod_identity_association {
    role_arn = module.aws_efs_csi_pod_identity[0].iam_role_arn
    service_account = var.efs_csi_driver.service_account
  }
}