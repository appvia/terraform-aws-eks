
locals {
  ## The account ID of the hub
  account_id = data.aws_caller_identity.current.account_id
  ## The SSO Administrator role ARN
  sso_role_name = "AWSReservedSSO_Administrator_fbb916977087a86f"

  ## EKS Access Entries for authentication
  access_entries = {
    admin = {
      principal_arn = format("arn:aws:iam::%s:role/aws-reserved/sso.amazonaws.com/eu-west-2/%s", local.account_id, local.sso_role_name)
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  ## Resource tags for all resources
  tags = {
    Environment = "Production"
    Product     = "EKS"
    Owner       = "Engineering"
  }
}

## Provision a EKS cluster for the hub
module "eks" {
  source = "../.."

  access_entries                 = local.access_entries
  cluster_enabled_log_types      = null
  cluster_endpoint_public_access = true
  cluster_name                   = "hub"
  enable_nat_gateway             = true
  nat_gateway_mode               = "single_az"
  private_subnet_netmask         = 24
  public_subnet_netmask          = 24
  tags                           = local.tags
  vpc_cidr                       = "10.90.0.0/21"
}
