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
    route53_zone_arns = optional(list(string), [])
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

variable "availability_zones" {
  description = "Number of availability zones when provisioning a network"
  type        = number
  default     = 3
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

variable "cluster_endpoint_public_access" {
  description = "Whether to enable public access to the EKS API server endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source."
  type        = any
  default     = {}
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
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

variable "nat_gateway_mode" {
  description = "The mode to use for the NAT gateway, when enable_gateway is true"
  type        = string
  default     = "single_az"
}

variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source."
  type        = any
  default     = {}
}

variable "private_subnet_netmask" {
  description = "The netmask for the private subnets"
  type        = number
  default     = 24
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs, if you want to use existing subnets"
  type        = list(string)
  default     = null
}

variable "public_subnet_netmask" {
  description = "The netmask for the public subnets"
  type        = number
  default     = 24
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "transit_gateway_id" {
  description = "The ID of the transit gateway to use"
  type        = string
  default     = null
}

variable "transit_gateway_routes" {
  description = "The routes to add to the transit gateway route table"
  type        = map(string)
  default = {
    "private" = "10.0.0.0/8"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the Wayfinder VPC."
  type        = string
  default     = "10.0.0.0/21"
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
  default     = null
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
    route53_zone_arns = optional(list(string), [])
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
