# =============================================================================
# The platform/honeynet contract.
# =============================================================================
# The honeynet layer reads these via terraform_remote_state. Treat this file as
# a published interface: adding is free, renaming breaks the other layer.

output "instance_profile_name" {
  description = "Instance profile attached to every honeypot host."
  value       = aws_iam_instance_profile.honeypot.name
}

output "log_group_names" {
  description = "Catalog key -> CloudWatch log group name. The honeynet renders the agent config from this."
  value       = { for k, v in aws_cloudwatch_log_group.honeynet : k => v.name }
}

output "environment" {
  value       = var.environment
  description = "Environment slug this platform serves."
}

output "aws_region" {
  value       = var.aws_region
  description = "Region."
}
