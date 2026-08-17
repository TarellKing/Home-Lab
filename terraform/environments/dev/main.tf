module "network" {
  source = "../../modules/network"

  name_prefix         = local.name_prefix
  vpc_cidr            = "10.42.0.0/16"
  public_subnet_cidr  = "10.42.10.0/24"
  private_subnet_cidr = "10.42.20.0/24"
}

module "logging" {
  source = "../../modules/logging"

  name_prefix        = local.name_prefix
  log_retention_days = var.log_retention_days
}

module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix
}

module "storage" {
  source = "../../modules/storage"

  name_prefix = local.name_prefix
}

module "compute" {
  source = "../../modules/compute"

  name_prefix              = local.name_prefix
  vpc_id                   = module.network.vpc_id
  public_subnet_id         = module.network.public_subnet_id
  private_subnet_id        = module.network.private_subnet_id
  instance_profile_name    = module.iam.instance_profile_name
  instance_type            = var.instance_type
  allowed_admin_cidr       = var.allowed_admin_cidr
  create_internal_instance = var.create_internal_instance
  decoy_log_group_name     = module.logging.decoy_app_log_group_name
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = module.iam.vpc_flow_logs_role_arn
  log_destination = module.logging.vpc_flow_log_group_arn
  traffic_type    = "ALL"
  vpc_id          = module.network.vpc_id
}

resource "aws_cloudtrail" "lab" {
  name                          = "${local.name_prefix}-trail"
  s3_bucket_name                = module.logging.audit_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}
