
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    ## Required by the platform module tests (tests/platform_*.tftest.hcl) so
    ## mock_provider "kubectl" resolves to alekc/kubectl rather than hashicorp/kubectl
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
  }
}
