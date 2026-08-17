variable "services_file" {
  description = "Absolute path to catalog/services.yaml."
  type        = string
}

variable "hosts_file" {
  description = "Absolute path to catalog/hosts.yaml."
  type        = string
}

variable "environment" {
  description = "Environment slug, used in log group paths."
  type        = string
}
