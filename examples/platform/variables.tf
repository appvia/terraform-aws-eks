
variable "tags" {
  description = "The tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "sso_role_name" {
  description = "The SSO Administrator role ARN"
  type        = string
  default     = "AWSReservedSSO_Administrator_fbb916977087a86f"
}

variable "hub_account_id" {
  description = "When using a hub deployment options, this is the account where argocd is running"
  type        = string
  default     = null
}

variable "argocd_repositories" {
  description = "A collection of repository secrets to add to the argocd namespace"
  type = map(object({
    ## The description of the repository
    description = string
    ## The secret to use for the repository
    secret = optional(string, null)
    ## The secret manager ARN to use for the secret
    secret_manager_arn = optional(string, null)
    ## An optional SSH private key for the repository
    ssh_private_key = optional(string, null)
    ## The URL of the repository
    url = string
    ## An optional username for the repository
    username = optional(string, null)
    ## An optional password for the repository
    password = optional(string, null)
  }))
  default = {}
}

