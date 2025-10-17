## Data sources for the current AWS account and region
data "aws_caller_identity" "current" {}
## Data source for the current AWS region
data "aws_region" "current" {}

## Argocd assume role policy
data "aws_iam_policy_document" "argocd_cross_account_role_policy" {
  count = local.enable_cross_account_role ? 1 : 0

  statement {
    sid = "AllowAssumeRole"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:role/%s", try(var.hub_account_id, ""), try(var.hub_account_role, "argocd-pod-identity-hub"))]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
    effect = "Allow"
  }
}
