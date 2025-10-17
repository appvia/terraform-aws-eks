variable "access_entries" {
  description = "Map of access entries to add to the cluster. This is required if you use a different IAM Role for Terraform Plan actions."
  type = map(object({
    ## The list of kubernetes groups to associate the principal with
    kubernetes_groups = optional(list(string))
    ## The list of kubernetes users to associate the principal with
    principal_arn = string
    ## The list of kubernetes users to associate the principal with
    policy_associations = optional(map(object({
      ## The policy arn to associate with the principal
      policy_arn = string
      ## The access scope for the policy i.e. cluster or namespace
      access_scope = object({
        ## The namespaces to apply the policy to
        namespaces = optional(list(string))
        ## The type of access scope i.e. cluster or namespace
        type = string
      })
    })))
  }))
  default = null
}

variable "ebs_csi_driver" {
  description = "The EBS CSI driver configuration"
  type = object({
    ## Indicates if we should enable the EBS CSI driver
    enabled = optional(bool, false)
    ## The KMS key ARNs to allow the EBS CSI driver to manage encrypted volumes
    kms_key_arns = optional(list(string), [])
    ## The version of the EBS CSI driver
    version = optional(string, "v1.51.0-eksbuild.1")
  })
  default = {}
}

variable "efs_csi_driver" {
  description = "The EFS CSI driver configuration"
  type = object({
    ## Indicates if we should enable the EFS CSI driver
    enabled = optional(bool, false)
    ## The version of the EFS CSI driver
    version = optional(string, "v1.6.0-eksbuild.1")
  })
  default = {}
}

variable "addons" {
  description = "Map of EKS addons to enable"
  type = map(object({
    ## The name of the EKS addon
    name = optional(string)
    ## Indicates if we should deploy the EKS addon before the compute nodes
    before_compute = optional(bool, false)
    ## Indicates if we should use the most recent version of the EKS addon
    most_recent = optional(bool, true)
    ## The version of the EKS addon
    addon_version = optional(string)
    ## The configuration values for the EKS addon
    configuration_values = optional(string)
    ## The pod identity association for the EKS addon
    pod_identity_association = optional(list(object({
      ## The role ARN for the EKS addon pod identity association
      role_arn = string
      ## The service account for the EKS addon
      service_account = string
    })))
    ## Indicates if we should preserve the EKS addon
    preserve = optional(bool, true)
    ## The resolve conflicts on create for the EKS addon
    resolve_conflicts_on_create = optional(string, "NONE")
    ## The resolve conflicts on update for the EKS addon
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    ## The service account role ARN for the EKS addon
    service_account_role_arn = optional(string)
    ## The timeouts for the EKS addon
    timeouts = optional(object({
      ## The timeout for the EKS addon create
      create = optional(string)
      ## The timeout for the EKS addon update
      update = optional(string)
      ## The timeout for the EKS addon delete
      delete = optional(string)
    }), {})
    ## The tags for the EKS addon
    tags = optional(map(string), {})
  }))
  default = null
}

variable "pod_identity" {
  description = "The pod identity configuration"
  type = map(object({
    ## Indicates if we should enable the pod identity
    enabled = optional(bool, true)
    ## The namespace to deploy the pod identity to
    description = optional(string, null)
    ## The service account to deploy the pod identity to
    service_account = optional(string, null)
    ## The managed policy ARNs to attach to the pod identity
    managed_policy_arns = optional(map(string), {})
    ## The permissions boundary ARN to use for the pod identity
    permissions_boundary_arn = optional(string, null)
    ## The namespace to deploy the pod identity to
    namespace = optional(string, null)
    ## The name of the pod identity role
    name = optional(string, null)
    ## Additional policy statements to attach to the pod identity role
    policy_statements = optional(list(object({
      sid       = optional(string, null)
      actions   = optional(list(string), [])
      resources = optional(list(string), [])
      effect    = optional(string, null)
    })), [])
  }))
  default = {}
}

variable "terranetes" {
  description = "The Terranetes platform configuration"
  type = object({
    ## Indicates if we should enable the Terranetes platform
    enabled = optional(bool, false)
    ## The namespace to deploy the Terranetes platform to
    namespace = optional(string, "terraform-system")
    ## The service account to deploy the Terranetes platform to
    service_account = optional(string, "terranetes-executor")
    ## The permissions boundary ARN to use for the Terranetes platform
    permissions_boundary_arn = optional(string, null)
    ## Managed policies to attach to the Terranetes platform
    managed_policy_arns = optional(map(string), {
      "AdministratorAccess" = "arn:aws:iam::aws:policy/AdministratorAccess"
    })
  })
  default = {}
}

variable "external_dns" {
  description = "The External DNS configuration"
  type = object({
    ## Indicates if we should enable the External DNS platform
    enabled = optional(bool, false)
    ## The namespace to deploy the External DNS platform to
    namespace = optional(string, "external-dns")
    ## The service account to deploy the External DNS platform to
    service_account = optional(string, "external-dns")
    ## The route53 zone ARNs to attach to the External DNS platform
    hosted_zone_arns = optional(list(string), [])
  })
  default = {}
}

variable "external_secrets" {
  description = "The External Secrets configuration"
  type = object({
    ## Indicates if we should enable the External Secrets platform
    enabled = optional(bool, false)
    ## The namespace to deploy the External Secrets platform to
    namespace = optional(string, "external-secrets")
    ## The service account to deploy the External Secrets platform to
    service_account = optional(string, "external-secrets")
    ## The secrets manager ARNs to attach to the External Secrets platform
    secrets_manager_arns = optional(list(string), ["arn:aws:secretsmanager:*:*"])
    ## The SSM parameter ARNs to attach to the External Secrets platform
    ssm_parameter_arns = optional(list(string), ["arn:aws:ssm:*:*:parameter/eks/*"])
  })
  default = {}
}

variable "aws_ack_iam" {
  description = "The AWS ACK IAM configuration"
  type = object({
    ## Indicates if we should enable the AWS ACK IAM platform
    enabled = optional(bool, false)
    ## The namespace to deploy the AWS ACK IAM platform to
    namespace = optional(string, "ack-system")
    ## The service account to deploy the AWS ACK IAM platform to
    service_account = optional(string, "ack-iam-controller")
    ## Managed policies to attach to the AWS ACK IAM platform
    managed_policy_arns = optional(map(string), {})
  })
  default = {}
}

variable "cloudwatch_observability" {
  description = "The CloudWatch Observability configuration"
  type = object({
    ## Indicates if we should enable the CloudWatch Observability platform
    enabled = optional(bool, false)
    ## The namespace to deploy the CloudWatch Observability platform to
    namespace = optional(string, "cloudwatch-observability")
    ## The service account to deploy the CloudWatch Observability platform to
    service_account = optional(string, "cloudwatch-observability")
  })
  default = {}
}

variable "cluster_name" {
  description = "Name of the Kubenetes cluster"
  type        = string
}

variable "cluster_enabled_log_types" {
  description = "List of log types to enable for the EKS cluster."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "create_kms_key" {
  description = "Whether to create a KMS key for the EKS cluster."
  type        = bool
  default     = true
}

variable "enable_public_access" {
  description = "Whether to enable public access to the EKS API server endpoint."
  type        = bool
  default     = false
}

variable "enable_private_access" {
  description = "Whether to enable private access to the EKS API server endpoint."
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Whether to enable cluster creator admin permissions (else create access entries for the cluster creator)"
  type        = bool
  default     = false
}

variable "enable_irsa" {
  description = "Whether to enable IRSA for the EKS cluster."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source."
  type        = any
  default     = {}
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "node_pools" {
  description = "Collection of nodepools to create via auto-mote karpenter"
  type        = list(string)
  default     = ["system"]
}

variable "kms_key_administrators" {
  description = "A list of IAM ARNs for EKS key administrators. If no value is provided, the current caller identity is used to ensure at least one key admin is available."
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "A list of IAM ARNs for EKS key users."
  type        = list(string)
  default     = []
}

variable "kms_key_service_users" {
  description = "A list of IAM ARNs for EKS key service users."
  type        = list(string)
  default     = []
}

variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs, if you want to use existing subnets"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
}

variable "cert_manager" {
  description = "The cert-manager configuration"
  type = object({
    ## Indicates if we should enable the cert-manager platform
    enabled = optional(bool, false)
    ## The namespace to deploy the cert-manager platform to
    namespace = optional(string, "cert-manager")
    ## The service account to deploy the cert-manager platform to
    service_account = optional(string, "cert-manager")
    ## Route53 zone id to use for the cert-manager platform
    hosted_zone_arns = optional(list(string), [])
  })
  default = {}
}

variable "argocd" {
  description = "The ArgoCD configuration"
  type = object({
    ## Indicates if we should enable the ArgoCD platform
    enabled = optional(bool, false)
    ## The namespace to deploy the ArgoCD platform to
    namespace = optional(string, "argocd")
    ## The service account to deploy the ArgoCD platform to
    service_account = optional(string, "argocd")
  })
  default = {}
}

variable "hub_account_roles_prefix" {
  description = "The prefix of the roles we are permitted to assume via the argocd pod identity"
  type        = string
  default     = "argocd-cross-account-*"
}

variable "hub_account_role" {
  description = "Indicates we should create a cross account role for the hub to assume"
  type        = string
  default     = "argocd-pod-identity-hub"
}

variable "hub_account_id" {
  description = "The AWS account ID of the hub account"
  type        = string
  default     = null
}
