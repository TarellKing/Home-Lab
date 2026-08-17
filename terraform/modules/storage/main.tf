resource "aws_s3_bucket" "fake_data" {
  bucket_prefix = "${var.name_prefix}-fake-data-"
  force_destroy = true
  tags = { DataClassification = "synthetic-honeydata" }
}
resource "aws_s3_bucket_public_access_block" "fake_data" {
  bucket = aws_s3_bucket.fake_data.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "fake_data" {
  bucket = aws_s3_bucket.fake_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
