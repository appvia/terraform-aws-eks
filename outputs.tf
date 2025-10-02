output "cluster_endpoint" {
  description = "The endpoint for the Wayfinder EKS Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data for the Wayfinder EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_name" {
  description = "The name of the Wayfinder EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the Wayfinder EKS cluster"
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
