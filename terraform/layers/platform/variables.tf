variable "project" {
  description = "Project slug used for naming."
  type        = string
  default     = "home-lab-honeynet"
}

variable "environment" {
  description = "Environment slug. Appears in log group paths, so changing it starts a fresh logging namespace."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "log_retention_days" {
  description = "CloudWatch retention for honeynet logs."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Extra tags merged into every resource."
  type        = map(string)
  default     = {}
}
