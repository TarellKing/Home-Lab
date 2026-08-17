# Read the persistent platform layer's remote state. This is the seam that lets
# us destroy and recreate the honeynet without touching log groups or IAM.
data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket = var.platform_state_bucket
    key    = var.platform_state_key
    region = var.aws_region
  }
}

# Same catalog parse the platform layer used. Because both layers read the same
# files through the same module, the security group rules created here cannot
# drift from the log groups created there.
module "catalog" {
  source = "../../modules/catalog"

  services_file = "${path.root}/../../../catalog/services.yaml"
  hosts_file    = "${path.root}/../../../catalog/hosts.yaml"
  environment   = var.environment
}

# Default VPC + its subnets. Using the default VPC keeps the MVP to a single
# security group and instance -- no VPC/subnet/IGW/route-table to manage.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  platform    = data.terraform_remote_state.platform.outputs

  common_tags = merge(
    {
      Project   = var.project
      Env       = var.environment
      Layer     = "honeynet"
      ManagedBy = "terraform"
      Lifecycle = "disposable"
    },
    var.tags,
  )

  enabled_hosts = module.catalog.enabled_hosts

  # exposure -> the CIDR list its security group rule opens to.
  exposure_cidrs = {
    public   = ["0.0.0.0/0"]
    admin    = [var.admin_cidr]
    internal = [data.aws_vpc.default.cidr_block]
  }
}
