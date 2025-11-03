
locals {
  ## The cluster_name of the cluster
  cluster_name = "dev"
  ## The cluster type
  cluster_type = "standalone"
  ## The platform repository
  platform_repository = "https://github.com/appvia/kubernetes-platform"
  ## The platform revision
  platform_revision = "main"
  ## The tenant repository
  tenant_repository = "https://github.com/appvia/kubernetes-platform"
  ## The tenant revision
  tenant_revision = "main"
  ## The tenant path
  tenant_path = "release/standalone-aws"
}

## Provision a network for the cluster
module "network" {
  source  = "appvia/network/aws"
  version = "0.6.13"

  availability_zones     = 3
  name                   = local.cluster_name
  private_subnet_netmask = 24
  public_subnet_netmask  = 24
  tags                   = local.tags
  transit_gateway_id     = "tgw-0c5994aa363b1e132"
  vpc_cidr               = "10.90.0.0/21"

  transit_gateway_routes = {
    private = "0.0.0.0/0"
  }

  private_subnet_tags = {
    "karpenter.sh/discovery"                      = local.cluster_name
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/dev" = "owned"
    "kubernetes.io/role/elb"    = "1"
  }
}

## Provision a EKS cluster for the hub
module "eks" {
  source = "../../"

  access_entries            = local.access_entries
  cluster_enabled_log_types = null
  cluster_name              = local.cluster_name
  enable_private_access     = true
  enable_public_access      = true
  hub_account_id            = var.hub_account_id
  node_pools                = ["system"]
  private_subnet_ids        = module.network.private_subnet_ids
  tags                      = local.tags
  vpc_id                    = module.network.vpc_id
}

## Provision and bootstrap the platform using an tenant repository
module "platform" {
  source = "../../modules/platform"

  ## Name of the cluster
  cluster_name = local.cluster_name
  # The type of cluster
  cluster_type = local.cluster_type
  # Any repositories to be provisioned
  repositories = var.argocd_repositories
  ## The platform repository
  platform_repository = local.platform_repository
  # The location of the platform repository
  platform_revision = local.platform_revision
  # The location of the tenant repository
  tenant_repository = local.tenant_repository
  # You pretty much always want to use the HEAD
  tenant_revision = local.tenant_revision
  ## The tenant repository path
  tenant_path = local.tenant_path

  depends_on = [
    module.eks
  ]
}
