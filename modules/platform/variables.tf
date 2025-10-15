variable "argocd_namespace" {
  description = "The namespace to install ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart" {
  description = "The name of the chart to install"
  type        = string
  default     = "argo-cd"
}

variable "argocd_admin_password" {
  description = "Initial admin password for ArgoCD"
  type        = string
  sensitive   = true
  default     = null
}

variable "argocd_helm_repository" {
  description = "The URL of the ArgoCD Helm repository"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "argocd_values" {
  description = "Additional values to add to the argocd Helm chart"
  type        = list(string)
  default     = []
}

variable "revision_overrides" {
  description = "Revision overrides permit the user to override the revision contained in cluster definition"
  type = object({
    platform_revision = optional(string, null)
    tenant_revision   = optional(string, null)
  })
  default = null
}

variable "repositories" {
  description = "A collection of repository secrets to add to the argocd namespace"
  type = map(object({
    ## The description of the repository
    description = string
    ## The secret to use for the repository
    secret = optional(string, null)
    ## The secret manager ARN to use for the secret
    secret_manager_arn = optional(string, null)
    ## The URL of the repository
    url = string
    ## An optional username for the repository
    username = optional(string, null)
    ## An optional password for the repository
    password = optional(string, null)
    ## An optional SSH private key for the repository
    ssh_private_key = optional(string, null)
  }))
  default = {}
}

variable "argocd_version" {
  description = "Version of ArgoCD Helm chart to install"
  type        = string
  default     = "7.8.5"
}

variable "cluster_type" {
  description = "The type of cluster we are onboarding i.e. hub or standalone"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = null
}

variable "platform_repository" {
  description = "The URL for the platform repository"
  type        = string
  default     = "https://github.com/gambol99/kubernetes-platform"
}

variable "platform_revision" {
  description = "The revision of the platform repository"
  type        = string
  default     = "HEAD"
}

variable "tenant_repository" {
  description = "The URL of the tenant repository"
  type        = string
  default     = "https://github.com/gambol99/eks-tenant"
}

variable "tenant_revision" {
  description = "The revision of the tenant repository"
  type        = string
  default     = "HEAD"
}

variable "tenant_path" {
  description = "The path inside the tenant repository"
  type        = string
  default     = ""
}
