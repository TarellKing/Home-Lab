variable "project" {
  description = "Project slug. Must match the platform layer."
  type        = string
  default     = "home-lab-honeynet"
}

variable "environment" {
  description = "Environment slug. Must match the platform layer."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region. Must match the platform layer."
  type        = string
  default     = "us-east-1"
}

variable "admin_cidr" {
  description = <<-EOT
    YOUR public IP as a /32, for any service with exposure = "admin".
    Never widen this to 0.0.0.0/0 -- admin ports are for you; the bait ports
    (exposure = "public") are the ones open to the whole internet on purpose.
    Find yours with:  curl -s https://checkip.amazonaws.com
  EOT
  type        = string
  default     = "127.0.0.1/32"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR, e.g. 203.0.113.4/32."
  }
}

variable "platform_state_bucket" {
  description = "S3 bucket holding the platform layer's state. Pass via TF_VAR_platform_state_bucket."
  type        = string
}

variable "platform_state_key" {
  description = "Key of the platform layer's state object."
  type        = string
  default     = "honeynet/platform/dev.tfstate"
}

variable "datadog_enabled" {
  description = <<-EOT
    Run the Datadog agent (as a container) on every honeypot host, collecting all
    container logs. Requires the API key to be in SSM first -- run
    scripts/set-datadog-key.sh once before deploying.
  EOT
  type        = bool
  default     = true
}

variable "datadog_site" {
  description = <<-EOT
    Your Datadog site. US1=datadoghq.com, US3=us3.datadoghq.com,
    US5=us5.datadoghq.com, EU=datadoghq.eu, AP1=ap1.datadoghq.com.
    Wrong site = agent connects but you never see the logs.
  EOT
  type        = string
  default     = "datadoghq.com"
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
