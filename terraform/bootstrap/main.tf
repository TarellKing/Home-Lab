# =============================================================================
# BOOTSTRAP  --  run once, by hand, with admin/root credentials.
# =============================================================================
# Creates what must exist BEFORE GitHub Actions can deploy anything:
#   * S3 bucket holding Terraform state for the platform + honeynet layers
#   * DynamoDB table for state locking
#   * GitHub OIDC provider + scoped deploy role (no long-lived AWS keys)
#
# Not part of normal lab teardown -- you apply this once and leave it.
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge({
      Project   = var.project
      Layer     = "bootstrap"
      ManagedBy = "terraform"
      Lifecycle = "permanent"
    }, var.tags)
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  partition    = data.aws_partition.current.partition
  state_bucket = "${var.project}-tfstate-${local.account_id}-${random_string.suffix.result}"
  lock_table   = "${var.project}-tflock"

  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:${local.partition}:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"

  # github_allowed_subjects are suffixes of repo:${github_repository}.
  # extra_github_subjects are complete OIDC sub strings (another repository).
  allowed_subs = concat(
    [for s in var.github_allowed_subjects : "repo:${var.github_repository}:${s}"],
    var.extra_github_subjects,
  )
}

# -----------------------------------------------------------------------------
# Terraform state bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_bucket.json
}

# -----------------------------------------------------------------------------
# State lock table
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "lock" {
  name         = local.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# -----------------------------------------------------------------------------
# GitHub OIDC -- lets Actions assume a role with no stored AWS keys
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subs
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name                 = "${var.project}-github-deploy"
  description          = "Assumed by GitHub Actions to deploy the honeynet and cron. Trusts Home-Lab main and honeynet-dev, plus extra_github_subjects (cron main by default)."
  assume_role_policy   = data.aws_iam_policy_document.github_assume.json
  max_session_duration = 3600
}

# Scoped to the services this lab touches -- not AdministratorAccess. A leaked
# workflow token still cannot reach Organizations, Billing, or anything else.
data "aws_iam_policy_document" "deploy_permissions" {
  statement {
    sid    = "LabInfrastructure"
    effect = "Allow"
    actions = [
      "ec2:*",
      "logs:*",
      "s3:*",
      "dynamodb:*",
      "ssm:*",
      "cloudwatch:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "LabIam"
    effect = "Allow"
    actions = [
      "iam:*Role*",
      "iam:*RolePolicy*",
      "iam:*InstanceProfile*",
      "iam:*Policy*",
      "iam:Get*",
      "iam:List*",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
  }

  # cron Lambdas, EventBridge Scheduler, the monthly cost budget, and the
  # aws/ssm key used for SecureString parameters. kms is only via SSM.
  statement {
    sid    = "CronAutomation"
    effect = "Allow"
    actions = [
      "lambda:*",
      "scheduler:*",
      "budgets:*",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "SsmKeyViaSsm"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid     = "PassCronAndHomeLabRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/cron-*",
      "arn:${local.partition}:iam::${local.account_id}:role/home-lab-*",
    ]
  }

  # LabIam's iam:*Role* also matches PassRole. Deny it except for cron-* and
  # home-lab-* (the honeypot instance role and cron's Lambda/scheduler roles).
  statement {
    sid     = "LimitPassRole"
    effect  = "Deny"
    actions = ["iam:PassRole"]
    not_resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/cron-*",
      "arn:${local.partition}:iam::${local.account_id}:role/home-lab-*",
    ]
  }

  # Never let a workflow rewrite its own trust or delete the OIDC provider.
  statement {
    sid    = "ProtectBootstrap"
    effect = "Deny"
    actions = [
      "iam:UpdateAssumeRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
    ]
    resources = [
      aws_iam_role.github_deploy.arn,
      local.oidc_provider_arn,
    ]
  }
}

resource "aws_iam_policy" "deploy" {
  name   = "${var.project}-github-deploy"
  policy = data.aws_iam_policy_document.deploy_permissions.json
}

resource "aws_iam_role_policy_attachment" "deploy" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = aws_iam_policy.deploy.arn
}
