
locals {
  ## Indicates if we should attach the EBS CSI driver policy to the EKS cluster
  enable_ebs_csi_driver = try(var.ebs_csi_driver.enabled, false) ? true : false
  ## The name of the EBS CSI driver policy
  ebs_csi_policy_name_prefix = "${var.cluster_name}-ebs-csi-driver"
}

## IAM policy document for the EBS CSI driver assume role
data "aws_iam_policy_document" "ebs_csi_assume" {
  count = local.enable_ebs_csi_driver ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

## IAM policy document for the EBS CSI driver
data "aws_iam_policy_document" "ebs_csi" {
  count = local.enable_ebs_csi_driver ? 1 : 0

  statement {
    actions = [
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DetachVolume",
      "ec2:EnableFastSnapshotRestores",
      "ec2:ModifyVolume",
    ]

    resources = ["*"]
  }

  statement {
    actions   = ["ec2:CopyVolumes"]
    resources = ["arn:${local.partition}:ec2:*:*:volume/vol-*"]
  }

  statement {
    actions = ["ec2:CreateTags"]

    resources = [
      "arn:${local.partition}:ec2:*:*:volume/*",
      "arn:${local.partition}:ec2:*:*:snapshot/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CopyVolumes",
        "CreateSnapshot",
        "CreateVolume",
      ]
    }
  }

  statement {
    actions = ["ec2:DeleteTags"]

    resources = [
      "arn:${local.partition}:ec2:*:*:snapshot/*",
      "arn:${local.partition}:ec2:*:*:volume/*",
    ]
  }

  statement {
    actions = [
      "ec2:CreateVolume",
      "ec2:CopyVolumes",
    ]
    resources = ["arn:${local.partition}:ec2:*:*:volume/*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    actions = [
      "ec2:CreateVolume",
      "ec2:CopyVolumes",
    ]
    resources = ["arn:${local.partition}:ec2:*:*:volume/*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    actions   = ["ec2:CreateVolume"]
    resources = ["arn:${local.partition}:ec2:*:*:snapshot/*"]
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/created-for/pvc/name"
      values   = ["*"]
    }
  }

  statement {
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  statement {
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  dynamic "statement" {
    for_each = length(var.ebs_csi_driver.kms_key_arns) > 0 ? [1] : []

    content {
      actions = [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant",
      ]

      resources = var.ebs_csi_driver.kms_key_arns

      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = [true]
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.ebs_csi_driver.kms_key_arns) > 0 ? [1] : []

    content {
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]

      resources = var.ebs_csi_driver.kms_key_arns
    }
  }
}

## IAM role for the EBS CSI driver
resource "aws_iam_role" "ebs_csi_driver" {
  count = local.enable_ebs_csi_driver ? 1 : 0

  name                  = "${local.ebs_csi_policy_name_prefix}-role"
  description           = "IAM role for the EBS CSI driver for the ${var.cluster_name} cluster"
  assume_role_policy    = data.aws_iam_policy_document.ebs_csi_assume[0].json
  force_detach_policies = true
  max_session_duration  = 3600
  path                  = "/"
  tags                  = local.tags
}

## IAM policy for the EBS CSI driver
resource "aws_iam_policy" "ebs_csi" {
  count = local.enable_ebs_csi_driver ? 1 : 0

  name_prefix = "${local.ebs_csi_policy_name_prefix}-"
  description = "Permissions to manage EBS volumes via the container storage interface (CSI) driver"
  path        = "/"
  policy      = data.aws_iam_policy_document.ebs_csi[0].json
  tags        = local.tags
}

## IAM role policy attachment for the EBS CSI driver
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = local.enable_ebs_csi_driver ? 1 : 0

  role       = aws_iam_role.ebs_csi_driver[0].name
  policy_arn = aws_iam_policy.ebs_csi[0].arn
}