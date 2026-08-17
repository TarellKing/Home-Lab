# =============================================================================
# Persistent IAM -- the honeypot instance role.
# =============================================================================
# Lives in the platform layer, not the honeynet layer, for two reasons:
#   1. IAM is eventually consistent. Destroying and immediately recreating a
#      role + instance profile with the same name races propagation and gives
#      flaky applies. Keeping it put makes honeynet rebuilds deterministic.
#   2. This role is a security boundary (an attacker who pops a container can
#      read the instance's credentials from IMDS). It should change on purpose,
#      not churn every time you rebuild the lab.

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "honeypot" {
  name               = "${local.name_prefix}-honeypot-instance"
  description        = "Role attached to honeypot EC2 instances. Assume it is attacker-reachable."
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Session Manager, so you get a shell on the box without ever opening SSH for
# yourself. (Port 22 may be open as bait, but that's the honeypot, not your door.)
resource "aws_iam_role_policy_attachment" "honeypot_ssm" {
  role       = aws_iam_role.honeypot.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# The only extra privilege: ship logs into this env's honeynet log groups.
# Deliberately narrow -- stolen credentials should find nothing else worth having.
data "aws_iam_policy_document" "honeypot" {
  statement {
    sid    = "ShipLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/honeynet/${var.environment}/*",
    ]
  }

  statement {
    sid       = "DescribeLogGroups"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  # Read the Datadog API key (SecureString) at boot. Scoped to this env's
  # honeynet parameter path. Note: an attacker who compromises the box can read
  # this too -- a Datadog API key is ingest-only (it can submit data, not read
  # yours), so the blast radius is log/metric spam, which is acceptable here.
  statement {
    sid       = "ReadHoneynetSsm"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:${local.partition}:ssm:${local.region}:${local.account_id}:parameter/honeynet/${var.environment}/*"]
  }

  # Decrypt SecureString params, limited to calls made via SSM.
  statement {
    sid       = "DecryptSsmParams"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${local.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "honeypot" {
  name   = "${local.name_prefix}-honeypot"
  role   = aws_iam_role.honeypot.id
  policy = data.aws_iam_policy_document.honeypot.json
}

resource "aws_iam_instance_profile" "honeypot" {
  name = "${local.name_prefix}-honeypot"
  role = aws_iam_role.honeypot.name
}
