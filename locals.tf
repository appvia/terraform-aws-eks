
locals {
  ## Current AWS account ID
  account_id = data.aws_caller_identity.current.account_id
  ## Indicator if the network should be created
  create_network = var.vpc_id == null ? true : false
  ## Environment name
  name = var.cluster_name
  ## List of subnets to create the node groups on
  private_subnets_ids = local.create_network ? module.vpc[0].private_subnet_ids : var.private_subnet_ids
  ## Current AWS region
  region = data.aws_region.current.name
  ## Tags applied to all resources
  tags = merge(var.tags, { Provisioner = "Terraform" })
  ## The vpc id to use for the cluster
  vpc_id = local.create_network ? module.vpc[0].vpc_id : var.vpc_id
  ## Indicates if we should provision the local admin user
  enable_cluster_creator_admin_permissions = var.access_entries == null ? true : false
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
