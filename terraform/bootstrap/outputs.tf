output "state_bucket" {
  description = "GitHub secret TF_STATE_BUCKET"
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "GitHub secret TF_LOCK_TABLE"
  value       = aws_dynamodb_table.lock.name
}

output "deploy_role_arn" {
  description = "GitHub secret AWS_DEPLOY_ROLE_ARN"
  value       = aws_iam_role.github_deploy.arn
}

output "aws_region" {
  value = var.aws_region
}
