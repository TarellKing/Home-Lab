terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3, same backend as the platform layer. Supplied at init via
  # -backend-config.
  backend "s3" {}
}
