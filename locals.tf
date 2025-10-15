
locals {
  ## Current AWS account ID
  account_id = data.aws_caller_identity.current.account_id
  ## Environment name
  name = var.cluster_name
  ## Current AWS region
  region = data.aws_region.current.region
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
}
