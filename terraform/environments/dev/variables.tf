variable "project" {
  description = "Project name used for naming resources."
  type        = string
  default     = "mini-techco-honeynet"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for the lab."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional local AWS CLI profile. Leave blank for default provider chain."
  type        = string
  default     = ""
}

variable "allowed_admin_cidr" {
  description = "CIDR allowed to reach optional admin endpoints. Keep narrow."
  type        = string
  default     = "127.0.0.1/32"
}

variable "instance_type" {
  description = "Small EC2 instance type for cost control."
  type        = string
  default     = "t3.micro"
}

variable "create_internal_instance" {
  description = "Create a private internal host placeholder."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}
