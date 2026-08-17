data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  region      = data.aws_region.current.name

  common_tags = merge(
    {
      Project   = var.project
      Env       = var.environment
      Layer     = "platform"
      ManagedBy = "terraform"
      # Marks resources that must survive `destroy-honeynet`.
      Lifecycle = "persistent"
    },
    var.tags,
  )
}

# The catalog drives which log groups exist. This layer creates a group for
# every service and host in the catalog, whether enabled or not, so history
# survives toggling a service off or destroying the honeynet.
module "catalog" {
  source = "../../modules/catalog"

  services_file = "${path.root}/../../../catalog/services.yaml"
  hosts_file    = "${path.root}/../../../catalog/hosts.yaml"
  environment   = var.environment
}
