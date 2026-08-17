terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # No backend block on purpose. Bootstrap CREATES the remote backend that every
  # other layer uses, so it cannot itself live in that backend. Its state is a
  # local file in this directory -- keep it (it is gitignored).
}
