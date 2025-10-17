
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
  version = "21.4.0"

  access_entries                           = local.access_entries
  addons                                   = var.addons
  authentication_mode                      = "API"
  create_auto_mode_iam_resources           = true
  create_kms_key                           = var.create_kms_key
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  enable_irsa                              = var.enable_irsa
  enabled_log_types                        = var.cluster_enabled_log_types
  endpoint_private_access                  = var.enable_private_access
  endpoint_public_access                   = var.enable_public_access
  endpoint_public_access_cidrs             = var.endpoint_public_access_cidrs
  kms_key_administrators                   = var.kms_key_administrators
  kms_key_description                      = format("KMS key for the %s EKS cluster", var.cluster_name)
  kms_key_owners                           = [format("arn:aws:iam::%s:root", local.account_id)]
  kms_key_service_users                    = var.kms_key_service_users
  kms_key_users                            = var.kms_key_users
  kubernetes_version                       = var.kubernetes_version
  name                                     = var.cluster_name
  subnet_ids                               = var.private_subnet_ids
  tags                                     = local.tags
  vpc_id                                   = var.vpc_id

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # NOTE - if creating multiple security groups with this module, only tag the
  # security group that Karpenter should utilize with the following tag
  # (i.e. - at most, only one security group should have this tag in your account)
  node_security_group_tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.name
  })

  ## Should we enable auto mode
  compute_config = {
    enabled    = true
    node_pools = var.node_pools
  }

  ## Additional Security Group Rules for the Cluster Security Group
  security_group_additional_rules = merge({
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }, var.security_group_additional_rules)

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
