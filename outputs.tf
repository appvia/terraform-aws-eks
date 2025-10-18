output "cluster_endpoint" {
  description = "The endpoint for the EKS Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}

output "account_id" {
  description = "The AWS account ID."
  value       = local.account_id
}

output "cross_account_role_arn" {
  description = "The cross account arn when we are using a hub"
  value       = local.enable_cross_account_role ? try(aws_iam_role.argocd_cross_account_role[0].arn, null) : null
}

output "region" {
  description = "The AWS region in which the cluster is provisioned"
  value       = local.region
}

output "ebs_csi_driver_pod_identity_arn" {
  description = "The ARN of the EBS CSI driver pod identity"
  value       = local.enable_ebs_csi_driver ? module.aws_ebs_csi_pod_identity[0].iam_role_arn : null
}

output "efs_csi_driver_pod_identity_arn" {
  description = "The ARN of the EFS CSI driver pod identity"
  value       = local.enable_efs_csi_driver ? module.aws_efs_csi_pod_identity[0].iam_role_arn : null
}