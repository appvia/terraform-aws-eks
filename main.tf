
## Create IAM Role for ArgoCD cross-account access
resource "aws_iam_role" "argocd_cross_account_role" {
  count = local.enable_cross_account_role ? 1 : 0

  name               = "argocd-cross-account-${local.name}"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.argocd_cross_account_role_policy[0].json
}

# tfsec:ignore:aws-eks-no-public-cluster-access
# tfsec:ignore:aws-ec2-no-public-egress-sgr
# tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  access_entries                           = local.access_entries
  authentication_mode                      = "API"
  cluster_enabled_log_types                = var.cluster_enabled_log_types
  cluster_endpoint_private_access          = true
  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  enable_cluster_creator_admin_permissions = local.enable_cluster_creator_admin_permissions
  kms_key_administrators                   = var.kms_key_administrators
  subnet_ids                               = local.private_subnets_ids
  tags                                     = local.tags
  vpc_id                                   = local.vpc_id

  # NOTE - if creating multiple security groups with this module, only tag the
  # security group that Karpenter should utilize with the following tag
  # (i.e. - at most, only one security group should have this tag in your account)
  node_security_group_tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.name
  })

  ## Should we enable auto mode
  cluster_compute_config = {
    enabled    = true
    node_pools = var.node_pools
  }

  ## Additional Security Group Rules for the Cluster Security Group
  cluster_security_group_additional_rules = merge({
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }, var.cluster_security_group_additional_rules)

  ## Additional Security Group Rules for the Node Security Group
  node_security_group_additional_rules = merge({
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    allow_ingress_10080 = {
      description                   = "Control plane access 10080"
      protocol                      = "tcp"
      from_port                     = 10080
      to_port                       = 10080
      type                          = "ingress"
      source_cluster_security_group = true
    }
    allow_ingress_10443 = {
      description                   = "Control plane access 10443"
      protocol                      = "tcp"
      from_port                     = 10443
      to_port                       = 10443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }, var.node_security_group_additional_rules)
}
