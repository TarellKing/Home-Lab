output "audit_bucket_name" { value = aws_s3_bucket.audit.id }
output "vpc_flow_log_group_arn" { value = aws_cloudwatch_log_group.vpc_flow.arn }
output "decoy_app_log_group_name" { value = aws_cloudwatch_log_group.decoy_app.name }
