
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
    GitRepo     = "https://github.com/appvia/terraform-aws-eks"
  }
}

## Provision a network for the cluster
module "network" {
  source  = "appvia/network/aws"
  version = "0.6.12"

  availability_zones     = 3
  name                   = "dev"
  private_subnet_netmask = 24
  public_subnet_netmask  = 24
  tags                   = local.tags
  transit_gateway_id     = "tgw-0c5994aa363b1e132"
  vpc_cidr               = "10.90.0.0/21"

  transit_gateway_routes = {
    private = "0.0.0.0/0"
  }
  private_subnet_tags = {
    "karpenter.sh/discovery"          = "dev"
    "kubernetes.io/cluster/dev"       = "owned"
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/dev" = "owned"
    "kubernetes.io/role/elb"    = "1"
  }

}

## Provision a EKS cluster for the hub
module "eks" {
  source = "../.."

  access_entries            = local.access_entries
  cluster_enabled_log_types = null
  cluster_name              = "dev"
  enable_public_access      = true
  enable_private_access     = true
  node_pools                = ["system", "general-purpose"]
  private_subnet_ids        = module.network.private_subnet_ids
  tags                      = local.tags
  vpc_id                    = module.network.vpc_id

  ## Enable Cert Manager
  cert_manager = {
    enable = true
  }
  ## Enable External Secrets
  external_secrets = {
    enable = true
  }
  ## Enable External DNS
  external_dns = {
    enable = true
  }

  ## Enable the Kubecost platform
  kubecosts = {
    enable                = true
    namespace             = "kubecost"
    service_account       = "kubecost"
    federated_bucket_name = "dev-federated-bucket"
    cloud_costs = {
      enable             = true
      cur_bucket_name    = "dev-cur-bucket"
      athena_bucket_name = "dev-athena-bucket"
    }
  }
}
