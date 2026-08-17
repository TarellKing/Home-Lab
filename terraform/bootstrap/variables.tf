variable "project" {
  description = "Project slug used to name bootstrap resources."
  type        = string
  default     = "home-lab-honeynet"
}

variable "aws_region" {
  description = "Region that holds the Terraform state bucket and lock table."
  type        = string
  default     = "us-east-1"
}

variable "github_repository" {
  description = "GitHub repo allowed to assume the deploy role, as owner/name."
  type        = string
  default     = "TarellKing/Home-Lab"

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must be in owner/name form."
  }
}

variable "github_allowed_subjects" {
  description = <<-EOT
    OIDC `sub` patterns permitted to assume the deploy role. Defaults restrict
    to the main branch and to the honeynet GitHub Environments, so a PR from a
    fork can never obtain credentials. The environment subjects are what let the
    deploy workflow run from any branch as long as it uses that environment.
  EOT
  type        = list(string)
  default = [
    "ref:refs/heads/main",
    "environment:honeynet-dev",
  ]
}

variable "create_oidc_provider" {
  description = <<-EOT
    Create the GitHub OIDC provider. This account ALREADY has one (only a single
    provider per issuer URL is allowed), so the default is false. Set true only
    in a fresh account that has never used GitHub OIDC.
  EOT
  type    = bool
  default = false
}

variable "tags" {
  description = "Tags applied to bootstrap resources."
  type        = map(string)
  default     = {}
}
