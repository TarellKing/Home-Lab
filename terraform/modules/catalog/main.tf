# =============================================================================
# CATALOG MODULE  --  pure computation, creates no AWS resources.
# =============================================================================
# Parses catalog/*.yaml into normalized structures, applying defaults and
# validating references. BOTH layers consume this module, which is the whole
# point: the platform layer builds log groups from the same parse that the
# honeynet layer builds security group rules from, so the two can never drift.
# =============================================================================

locals {
  raw = {
    services = try(yamldecode(file(var.services_file)).services, {})
    hosts    = try(yamldecode(file(var.hosts_file)).hosts, {})
  }

  # ---------------------------------------------------------------------------
  # Normalized services -- every optional field resolved to a concrete value so
  # downstream code never has to write try() again.
  #
  # Built in two passes because `log_mounts` is derived from `logs`, and an
  # object cannot reference itself while being constructed.
  # ---------------------------------------------------------------------------
  services_base = {
    for name, s in local.raw.services : name => {
      name        = name
      enabled     = try(s.enabled, true)
      description = try(s.description, "")
      image       = s.image

      weakness = {
        class = try(s.weakness.class, "none")
        ref   = try(s.weakness.ref, "")
        notes = trimspace(try(s.weakness.notes, ""))
      }

      config_dir = try(s.config_dir, "")

      # Single-file bind mounts that inject the weakness (bad httpd.conf, a
      # my.cnf with the query log on, a redis.conf with auth removed).
      # `file` is relative to services/<config_dir>/.
      config_mounts = [
        for m in try(s.config_mounts, []) : {
          file      = m.file
          target    = m.target
          read_only = try(m.read_only, true)
        }
      ]

      ports = [
        for p in try(s.ports, []) : {
          container = p.container
          host      = p.host
          protocol  = lower(try(p.protocol, "tcp"))
          exposure  = lower(try(p.exposure, "none"))
        }
      ]

      # A log file is surfaced by mirroring its container path under a
      # per-service root on the host:
      #     container /var/log/mysql/error.log
      #     host      /var/log/honeypot/mysql-default-creds/var/log/mysql/error.log
      # The mount is on the DIRECTORY (bind-mounting a file that does not exist
      # yet fails), and the agent tails the mirrored file from the host side.
      logs = [
        for l in try(s.logs, []) : {
          name           = l.name
          container_path = l.container_path
          container_dir  = dirname(l.container_path)
          format         = try(l.format, "raw")
          host_path      = "/var/log/honeypot/${name}${l.container_path}"
          host_dir       = "/var/log/honeypot/${name}${dirname(l.container_path)}"
        }
      ]

      env     = try(s.env, {})
      command = try(s.command, null)
    }
  }

  services = {
    for name, s in local.services_base : name => merge(s, {
      log_mounts = distinct([
        for l in s.logs : {
          host_dir      = l.host_dir
          container_dir = l.container_dir
        }
      ])
    })
  }

  # ---------------------------------------------------------------------------
  # Normalized hosts
  # ---------------------------------------------------------------------------
  hosts = {
    for name, h in local.raw.hosts : name => {
      name           = name
      enabled        = try(h.enabled, true)
      description    = try(h.description, "")
      instance_type  = try(h.instance_type, "t3.micro")
      subnet         = lower(try(h.subnet, "public"))
      root_volume_gb = try(h.root_volume_gb, 20)
      services       = try(h.services, [])
    }
  }

  enabled_hosts = { for k, v in local.hosts : k => v if v.enabled }

  # ---------------------------------------------------------------------------
  # LOG GROUPS
  # ---------------------------------------------------------------------------
  # Built for EVERY service and EVERY host, including disabled ones. That is
  # deliberate: log groups live in the persistent platform layer, so toggling a
  # service off (or destroying the whole honeynet) never deletes its history and
  # never breaks a dashboard, metric filter, or SIEM subscription pointed at it.
  # ---------------------------------------------------------------------------
  service_file_log_groups = merge(concat([{}], [
    for sname, s in local.services : {
      for l in s.logs : "${sname}/${l.name}" => {
        kind    = "service-file"
        service = sname
        stream  = l.name
        format  = l.format
        path    = "/honeynet/${var.environment}/service/${sname}/${l.name}"
      }
    }
  ])...)

  # NOTE: container stdout is intentionally NOT shipped to CloudWatch. It is left
  # on Docker's default json-file driver so an external log forwarder can collect
  # it. Only structured application FILE logs (below) and host OS logs land in
  # CloudWatch, which keeps queries clean.

  # OS-level telemetry collected on every host regardless of what runs on it.
  host_log_streams = ["messages", "secure", "cloud-init", "docker", "audit"]

  host_log_groups = merge(concat([{}], [
    for hname, h in local.hosts : {
      for stream in local.host_log_streams : "${hname}/${stream}" => {
        kind    = "host"
        service = hname
        stream  = stream
        format  = "syslog"
        path    = "/honeynet/${var.environment}/host/${hname}/${stream}"
      }
    }
  ])...)

  all_log_groups = merge(
    local.service_file_log_groups,
    local.host_log_groups,
  )

  # ---------------------------------------------------------------------------
  # SECURITY GROUP INGRESS RULES -- derived from the same `ports` blocks that
  # produce the published container ports. Declaring a port in the catalog is
  # what opens the firewall; there is no second place to remember.
  # ---------------------------------------------------------------------------
  rule_list = flatten([
    for hname, h in local.enabled_hosts : [
      for sname in h.services : [
        for p in local.services[sname].ports : {
          key      = "${hname}--${sname}--${p.protocol}-${p.host}"
          host     = hname
          service  = sname
          port     = p.host
          protocol = p.protocol
          exposure = p.exposure
          weakness = local.services[sname].weakness.class
        }
        if local.services[sname].enabled && p.exposure != "none"
      ]
    ]
  ])

  ingress_rules = { for r in local.rule_list : r.key => r }

  # ---------------------------------------------------------------------------
  # Per-host resolved service objects, for rendering compose + agent config.
  # ---------------------------------------------------------------------------
  host_services = {
    for hname, h in local.enabled_hosts : hname => [
      for sname in h.services : local.services[sname]
      if try(local.services[sname].enabled, false)
    ]
  }

  # ---------------------------------------------------------------------------
  # VALIDATION -- surfaced through output preconditions below.
  # ---------------------------------------------------------------------------
  unknown_service_refs = flatten([
    for hname, h in local.hosts : [
      for sname in h.services : "${hname} -> ${sname}"
      if !contains(keys(local.services), sname)
    ]
  ])

  # Two services on one host fighting over the same host port.
  host_port_usage = {
    for hname, h in local.enabled_hosts : hname => flatten([
      for sname in h.services : [
        for p in try(local.services[sname].ports, []) : "${p.protocol}/${p.host}"
        if try(local.services[sname].enabled, false)
      ]
    ])
  }

  colliding_hosts = [
    for hname, ports in local.host_port_usage : hname
    if length(ports) != length(distinct(ports))
  ]

  invalid_exposures = flatten([
    for sname, s in local.services : [
      for p in s.ports : "${sname}:${p.host} has exposure '${p.exposure}'"
      if !contains(["public", "admin", "internal", "none"], p.exposure)
    ]
  ])

  invalid_subnets = [
    for hname, h in local.hosts : "${hname} has subnet '${h.subnet}'"
    if !contains(["public", "private"], h.subnet)
  ]

  # An image pinned to :latest makes findings irreproducible.
  unpinned_images = [
    for sname, s in local.services : sname
    if !can(regex(":", s.image)) || endswith(s.image, ":latest")
  ]
}
