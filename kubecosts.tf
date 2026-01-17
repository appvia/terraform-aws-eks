#
## Kubecost configuration
#
locals {
  ## Indicating if we should enable the Kubecost Agent platform
  enable_kubecosts_agent = try(var.kubecosts_agent.enable, false)
  ## Indicating if we should enable the Kubecost platform
  enable_kubecosts = try(var.kubecosts.enable, false)
  ## Indicating if we should enable cloud costs via Athena
  enable_kubecosts_cloud_costs = try(var.kubecosts.cloud_costs.enable, false)
  ## List of principals to allowed to write to the federated bucket - we always allow
  ## the root account and the kubecost pod identity
  allowed_principals = concat(
    [local.root_account_arn],
    try(var.kubecosts.federated_storage.allowed_principals, []),
  )
}

## IAM Bucket Policy for the Kubecost Federated Bucket
data "aws_iam_policy_document" "kubecost_federated_bucket_policy" {
  count = local.enable_kubecosts ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    principals {
      type = "AWS"
      identifiers = concat(
        [local.root_account_arn],
        [try(module.kubecost_pod_identity[0].iam_role_arn, null)],
      )
    }
    resources = [
      var.kubecosts.federated_storage.federated_bucket_arn,
      format("%s/*", var.kubecosts.federated_storage.federated_bucket_arn),
    ]
  }

  ## Allow all accounts within my organization, using the kubecost agent
  dynamic "statement" {
    for_each = toset(local.allowed_principals)
    content {
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
      resources = [
        var.kubecosts.federated_storage.federated_bucket_arn,
        format("%s/*", var.kubecosts.federated_storage.federated_bucket_arn),
      ]
    }
  }

  ## Allow additional principals to write to the federated bucket
  dynamic "statement" {
    for_each = toset(local.allowed_principals)
    content {
      effect  = "Allow"
      actions = ["s3:PutObject", "s3:GetObject"]
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
      resources = [
        format("%s/*", var.kubecosts.federated_storage.federated_bucket_arn),
      ]
    }
  }
}

## Provision the federated bucket for the Kubecost platform
module "kubecost_federated_bucket" {
  count   = local.enable_kubecosts && try(var.kubecosts.federated_storage.create_bucket, false) ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket                                = trim(var.kubecosts.federated_storage.federated_bucket_arn, "arn:aws:s3:::")
  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  attach_require_latest_tls_policy      = true
  force_destroy                         = true
  object_ownership                      = "BucketOwnerEnforced"
  policy                                = data.aws_iam_policy_document.kubecost_federated_bucket_policy[0].json
  tags                                  = local.tags

  lifecycle_rule = [
    {
      ## Indicates if we should enable the lifecycle rule
      enabled = true
      ## The id of the lifecycle rule
      id = "delete-non-current-versions"
      # Remove non-current versions after 7 days
      noncurrent_version_expiration = {
        ## The number of days to retain non-current versions
        days = 7
      }
    }
  ]

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = try(var.kubecosts.federated_storage.kms_key_arn, null)
        sse_algorithm     = try(var.kubecosts.federated_storage.kms_key_arn, null) != null ? "aws:kms" : "AES256"
      }
    }
  }
}

## Provision the pod identity for the Kubecost Platform
module "kubecost_pod_identity" {
  count   = local.enable_kubecosts ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.6.0"

  name = "kubecosts-${local.name}"
  ## The description for the iam role assumed by the Kubecost Platform
  description = "Pod identity for the Kubecost Platform for the ${local.name} cluster"
  ## Description for the custom policy for the Kubecost Platform
  custom_policy_description = "Permissions to access the S3 bucket for the Kubecost Platform for the ${local.name} cluster"
  ## Attach the custom policy to the Kubecost Platform pod identity
  attach_custom_policy = true
  ## The tags for the Kubecost Platform pod identity
  tags = local.tags
  ## Always use a prefix for the name
  use_name_prefix = true

  ## Default association for the Kubecost Platform pod identity
  association_defaults = {
    namespace       = var.kubecosts.namespace
    service_account = var.kubecosts.service_account
  }

  # Pod Identity Associations
  associations = {
    kubecost = {
      ## The name of the cluster to associate the Kubecost Platform pod identity with
      cluster_name = module.eks.cluster_name
    }
  }

  ## The policy statements for the Kubecost Platform pod identity
  policy_statements = concat([
    {
      sid     = "AllowS3Access"
      effect  = "Allow"
      actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = [
        "${var.kubecosts.federated_storage.federated_bucket_arn}/*"
      ]
    },
    {
      sid     = "AllowS3ListBucket"
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      resources = [
        var.kubecosts.federated_storage.federated_bucket_arn,
        format("%s/*", var.kubecosts.federated_storage.federated_bucket_arn),
      ]
    }
    ], local.enable_kubecosts_cloud_costs ? [
    {
      sid     = "AllowCURBucketAccess"
      effect  = "Allow"
      actions = ["s3:GetObject", "s3:ListBucket"]
      resources = [
        var.kubecosts.cloud_costs.federated_storage.cur_bucket_arn,
        format("%s/*", var.kubecosts.cloud_costs.federated_storage.cur_bucket_arn),
      ]
    },
    {
      sid     = "AllowAthenaBucketAccess"
      effect  = "Allow"
      actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
      resources = [
        var.kubecosts.cloud_costs.federated_storage.athena_bucket_arn,
        format("%s/*", var.kubecosts.cloud_costs.federated_storage.athena_bucket_arn),
      ]
    },
    {
      sid    = "AllowAthenaQueryExecution"
      effect = "Allow"
      actions = [
        "athena:BatchGetQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:GetWorkGroup",
        "athena:StartQueryExecution",
        "athena:StopQueryExecution",
      ]
      resources = ["*"]
    },
    {
      sid    = "AllowGlueReadOnly"
      effect = "Allow"
      actions = [
        "glue:GetDatabase",
        "glue:GetDatabases",
        "glue:GetPartition",
        "glue:GetPartitions",
        "glue:GetTable",
        "glue:GetTables"
      ]
      resources = ["*"]
    }
  ] : [])
}

## Provision the pod identity for the Kubecost Agent
module "kubecost_agent_pod_identity" {
  count   = local.enable_kubecosts_agent ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.6.0"

  name = "${local.name}-kubecost-agent"
  ## The description for the role assumed by the Kubecost Agent
  description = "Role assumed by the Kubecost Agent for the ${local.name} cluster"
  ## The description for the custom policy for the Kubecost Agent
  custom_policy_description = "Permissions to access the S3 bucket for the Kubecost Agent for the ${local.name} cluster"
  ## The tags for the Kubecost Agent pod identity
  tags = local.tags
  ## Always use a prefix for the name
  use_name_prefix = true
  ## Attach the custom policy to the Kubecost Agent pod identity
  attach_custom_policy = true

  ## Default association for the Kubecost Agent pod identity
  association_defaults = {
    namespace       = var.kubecosts_agent.namespace
    service_account = var.kubecosts_agent.service_account
  }

  # Pod Identity Associations
  associations = {
    kubecost = {
      ## The name of the cluster to associate the Kubecost Agent pod identity with
      cluster_name = module.eks.cluster_name
    }
  }

  policy_statements = [
    {
      sid     = "AllowS3ListBucket"
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      resources = [
        var.kubecosts_agent.federated_bucket_arn,
        format("%s/*", var.kubecosts_agent.federated_bucket_arn),
      ]
    },
    {
      sid     = "AllowS3Access"
      effect  = "Allow"
      actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = [
        format("%s/*", var.kubecosts_agent.federated_bucket_arn),
      ]
    }
  ]
}
