#
## AWS Managed Prometheus
#

## Provision the AWS Managed Prometheus workspace
module "amazon_managed_service_prometheus_pod_identity" {
  count   = var.aws_prometheus.enable ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.4.2"

  amazon_managed_service_prometheus_policy_name    = "${local.name}-aws-prometheus"
  amazon_managed_service_prometheus_workspace_arns = var.aws_prometheus.workspaces
  attach_amazon_managed_service_prometheus_policy  = true
  tags                                             = local.tags

  ## Default association for the AWS Managed Prometheus pod identity
  association_defaults = {
    namespace       = var.aws_prometheus.namespace
    service_account = var.aws_prometheus.service_account
  }

  ## Associations for the AWS Managed Prometheus pod identity
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
    }
  }
}
