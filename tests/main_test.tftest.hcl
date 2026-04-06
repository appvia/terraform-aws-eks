## Test variable validation for main EKS module
## These simple tests validate that all required and optional variables can be properly set

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDAI23456789012345"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

## Test 1: All required variables are settable
run "test_main_all_required_variables" {
  command = plan

  variables {
    cluster_name       = "production-eks"
    vpc_id             = "vpc-abc123def456"
    private_subnet_ids = ["subnet-123", "subnet-456"]
    tags = {
      Environment = "production"
      Team        = "platform"
    }
  }

  # Assertions
  assert {
    condition     = var.cluster_name == "production-eks"
    error_message = "cluster_name variable must be settable"
  }

  assert {
    condition     = var.vpc_id == "vpc-abc123def456"
    error_message = "vpc_id variable must be settable"
  }

  assert {
    condition     = length(var.private_subnet_ids) == 2
    error_message = "private_subnet_ids must accept a list"
  }

  assert {
    condition     = length(var.tags) == 2
    error_message = "tags must accept a map"
  }
}

## Test 2: Kubernetes version variable
run "test_main_kubernetes_version" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    kubernetes_version = "1.29"
  }

  assert {
    condition     = var.kubernetes_version == "1.29"
    error_message = "kubernetes_version must be settable"
  }
}

## Test 3: KMS key creation flag
run "test_main_create_kms_key" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    create_kms_key = true
  }

  assert {
    condition     = var.create_kms_key == true
    error_message = "create_kms_key must be settable"
  }
}

## Test 4: Endpoint access flags
run "test_main_endpoint_access" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    enable_private_access = true
    enable_public_access  = false
  }

  assert {
    condition     = var.enable_private_access == true
    error_message = "enable_private_access must be settable"
  }

  assert {
    condition     = var.enable_public_access == false
    error_message = "enable_public_access must be settable"
  }
}

## Test 5: Cluster logging configuration
run "test_main_cluster_logging" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    cluster_enabled_log_types = ["api", "audit"]
  }

  assert {
    condition     = length(var.cluster_enabled_log_types) == 2
    error_message = "cluster_enabled_log_types must accept a list"
  }

  assert {
    condition     = contains(var.cluster_enabled_log_types, "api")
    error_message = "cluster_enabled_log_types should contain expected values"
  }
}

## Test 6: EBS CSI driver configuration
run "test_main_ebs_csi_driver" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    ebs_csi_driver = {
      enable = true
    }
  }

  assert {
    condition     = var.ebs_csi_driver.enable == true
    error_message = "ebs_csi_driver.enable must be settable"
  }
}

## Test 7: EFS CSI driver configuration
run "test_main_efs_csi_driver" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    efs_csi_driver = {
      enable = true
    }
  }

  assert {
    condition     = var.efs_csi_driver.enable == true
    error_message = "efs_csi_driver.enable must be settable"
  }
}

## Test 8: Multiple add-ons configuration
run "test_main_addons" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    addons = {
      coredns = {
        most_recent = true
      }
      vpc-cni = {
        most_recent = true
      }
    }
  }

  assert {
    condition     = length(var.addons) == 2
    error_message = "addons must support multiple addons"
  }
}

## Test 9: Registries configuration
run "test_main_registries" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    registries = {
      docker = {
        name = "docker"
        url  = "docker.io"
      }
    }
  }

  assert {
    condition     = var.registries.docker.url == "docker.io"
    error_message = "registries must support url field"
  }
}

## Test 10: AWS Prometheus configuration
run "test_main_aws_prometheus" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    aws_prometheus = {
      enable = true
    }
  }

  assert {
    condition     = var.aws_prometheus.enable == true
    error_message = "aws_prometheus.enable must be settable"
  }
}

## Test 11: Karpenter enabled flag
run "test_main_karpenter" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    enable_karpenter = true
  }

  assert {
    condition     = var.enable_karpenter == true
    error_message = "enable_karpenter must be settable"
  }
}

## Test 12: Access entries configuration
run "test_main_access_entries" {
  command = plan

  variables {
    cluster_name       = "test"
    vpc_id             = "vpc-123"
    private_subnet_ids = ["subnet-123"]
    tags = {
      Env = "test"
    }
    access_entries = {
      admin = {
        principal_arn = "arn:aws:iam::123456789012:user/admin"
      }
    }
  }

  assert {
    condition     = can(var.access_entries.admin.principal_arn)
    error_message = "access_entries must support principal_arn field"
  }
}
