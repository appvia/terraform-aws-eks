
locals {
  ## Current AWS account ID
  account_id = data.aws_caller_identity.current.account_id
  ## Environment name
  name = var.cluster_name
  ## Current AWS region
  region = data.aws_region.current.region
  ## The root account ARN
  root_account_arn = "arn:aws:iam::${local.account_id}:root"
  ## Tags applied to all resources
  tags = merge(var.tags, { Provisioner = "Terraform" })
  ## Indicates if we should enable cross account role
  enable_cross_account_role = var.hub_account_id != null ? true : false
  ## The access entries for the cluster
  access_entries = merge(
    ## The access entries provided by the user
    var.access_entries,
    ## This is only added if the hub account id is set
    var.hub_account_id != null ? {
      hub = {
        principal_arn = aws_iam_role.argocd_cross_account_role[0].arn
        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {}
  )

  # The defaults for external secret is no arns are defined
  external_secrets_arns = try(var.external_secrets.secrets_manager_arns, null) != null ? var.external_secrets.secrets_manager_arns : [format("aws:arn:secretsmanager:%s:%s:secret:*", local.region, local.account_id)]
  # The defaults for external secrets parameter store
  external_secrets_parameter_arns = try(var.external_secrets.ssm_parameter_arns, null) != null ? var.external_secrets.ssm_parameter_arns : [format("aws:arn:ssm:%s:%s:parameter/eks/*", local.region, local.account_id)]
}
