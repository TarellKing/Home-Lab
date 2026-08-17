# Preconditions on this output are the catalog's schema check. A typo in
# catalog/*.yaml fails at plan time with a readable message instead of
# producing a half-built honeynet.
output "services" {
  description = "Normalized service definitions, keyed by service name."
  value       = local.services

  precondition {
    condition     = length(local.unknown_service_refs) == 0
    error_message = "hosts.yaml references services that do not exist in services.yaml: ${join(", ", local.unknown_service_refs)}"
  }

  precondition {
    condition     = length(local.invalid_exposures) == 0
    error_message = "Invalid `exposure` values (use public|admin|internal|none): ${join("; ", local.invalid_exposures)}"
  }

  precondition {
    condition     = length(local.invalid_subnets) == 0
    error_message = "Invalid `subnet` values (use public|private): ${join("; ", local.invalid_subnets)}"
  }

  precondition {
    condition     = length(local.colliding_hosts) == 0
    error_message = "These hosts have two enabled services claiming the same host port: ${join(", ", local.colliding_hosts)}"
  }

  precondition {
    condition     = length(local.unpinned_images) == 0
    error_message = "Pin every image to an explicit non-latest tag so findings stay reproducible. Unpinned: ${join(", ", local.unpinned_images)}"
  }
}

output "hosts" {
  description = "Normalized host definitions, keyed by host name."
  value       = local.hosts
}

output "enabled_hosts" {
  description = "Only hosts with enabled = true."
  value       = local.enabled_hosts
}

output "host_services" {
  description = "Resolved, enabled service objects for each enabled host."
  value       = local.host_services
}

output "log_groups" {
  description = <<-EOT
    Every CloudWatch log group the lab needs, keyed by a stable identifier.
    Includes disabled services and disabled hosts on purpose, so the logging
    pipeline outlives any individual honeynet deployment.
  EOT
  value       = local.all_log_groups
}

output "ingress_rules" {
  description = "Security group ingress rules derived from service port declarations."
  value       = local.ingress_rules
}

output "host_log_streams" {
  description = "OS-level log stream names collected on every host."
  value       = local.host_log_streams
}
