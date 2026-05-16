output "account_id" {
  description = "The AWS account ID."
  value       = local.account_id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}

output "cluster_primary_security_group_id" {
  description = "The ID of the primary security group for the EKS cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "cluster_security_group_id" {
  description = "The ID of the security group for the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "cross_account_role_arn" {
  description = "The cross account arn when we are using a hub"
  value       = local.enable_cross_account_role ? try(aws_iam_role.argocd_cross_account_role[0].arn, null) : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encrypting secrets in the EKS cluster"
  value       = module.eks.kms_key_arn
}

output "kms_key_id" {
  description = "The ID of the KMS key used for encrypting secrets in the EKS cluster"
  value       = module.eks.kms_key_id
}

output "node_security_group_id" {
  description = "The ID of the security group for the EKS cluster nodes"
  value       = module.eks.node_security_group_id
}

output "region" {
  description = "The AWS region in which the cluster is provisioned"
  value       = local.region
}

