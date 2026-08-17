terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3 (created by terraform/bootstrap). The bucket/key/region
  # and lock table are supplied at init time via -backend-config, so nothing
  # account-specific is committed here.
  backend "s3" {}
}
