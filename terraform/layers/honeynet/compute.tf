# =============================================================================
# The honeypot instances.
# =============================================================================
# One EC2 box per enabled host. Everything that makes it a honeypot -- which
# containers run, which ports they publish, which log files ship where -- is
# rendered from the catalog into the instance's user_data. So:
#
#   * add a service to a host in catalog/hosts.yaml  -> apply -> it appears
#   * bump an image tag in catalog/services.yaml     -> apply -> box rebuilds
#
# You never edit this file to change what the honeypot runs.

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  # Where rendered config lives on the host.
  host_config_root = "/opt/honeynet/config"

  # ---------------------------------------------------------------------------
  # docker-compose, per host, built straight from the resolved catalog.
  # jsonencode produces a valid compose file (compose is a YAML superset of JSON).
  # ---------------------------------------------------------------------------
  compose = {
    for hname, svcs in module.catalog.host_services : hname => {
      services = {
        for s in svcs : s.name => merge(
          {
            image        = s.image
            restart      = "unless-stopped"
            network_mode = "bridge"
            ports        = [for p in s.ports : "${p.host}:${p.container}/${p.protocol}"]
            volumes = concat(
              # surface container log files onto the host so the agent can tail them
              [for m in s.log_mounts : "/var/log/honeypot/${s.name}${m.container_dir}:${m.container_dir}"],
              # inject the misconfig/vuln config files, read-only
              [for cm in s.config_mounts : "${local.host_config_root}/${s.name}/${basename(cm.file)}:${cm.target}:${cm.read_only ? "ro" : "rw"}"],
            )
          },
          s.command != null ? { command = s.command } : {},
          length(keys(s.env)) > 0 ? { environment = s.env } : {},
          # Container stdout/stderr stays on Docker's default json-file driver so
          # an external log forwarder can collect it. It is NOT shipped to
          # CloudWatch -- only structured file logs (via the agent) are.
        )
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Config file contents to drop on each host: "<service>/<file>" => text.
  # ---------------------------------------------------------------------------
  host_config_files = {
    for hname, svcs in module.catalog.host_services : hname => merge([
      for s in svcs : {
        for cm in s.config_mounts :
        "${s.name}/${basename(cm.file)}" => file("${path.root}/../../../services/${s.config_dir}/${cm.file}")
      }
    ]...)
  }

  # ---------------------------------------------------------------------------
  # CloudWatch agent config, per host: tail the surfaced service log files plus
  # the host's own OS logs, each into its persistent catalog log group.
  # ---------------------------------------------------------------------------
  host_os_log_files = {
    messages   = "/var/log/messages"
    secure     = "/var/log/secure"
    cloud-init = "/var/log/cloud-init-output.log"
    audit      = "/var/log/audit/audit.log"
  }

  agent_config = {
    for hname, svcs in module.catalog.host_services : hname => jsonencode({
      agent = { run_as_user = "root" }
      logs = {
        logs_collected = {
          files = {
            collect_list = concat(
              # service log files
              flatten([
                for s in svcs : [
                  for l in s.logs : {
                    file_path         = l.host_path
                    log_group_name    = local.platform.log_group_names["${s.name}/${l.name}"]
                    log_stream_name   = "${hname}"
                    retention_in_days = -1
                  }
                ]
              ]),
              # host OS logs
              [
                for stream, path in local.host_os_log_files : {
                  file_path         = path
                  log_group_name    = local.platform.log_group_names["${hname}/${stream}"]
                  log_stream_name   = "${hname}"
                  retention_in_days = -1
                }
              ],
            )
          }
        }
      }
    })
  }
}

resource "aws_instance" "host" {
  for_each = local.enabled_hosts

  ami                    = data.aws_ami.al2023.id
  instance_type          = each.value.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.host[each.key].id]
  iam_instance_profile   = local.platform.instance_profile_name

  associate_public_ip_address = each.value.subnet == "public"

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    hostname     = each.key
    region       = var.aws_region
    compose_json = jsonencode(local.compose[each.key])
    agent_config = local.agent_config[each.key]
    config_files = local.host_config_files[each.key]
    config_root  = local.host_config_root
  }))

  # New user_data (new services / bumped image) replaces the box. That's the
  # intended update path for the MVP: apply, ~2 min, fresh honeypot.
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    encrypted   = true
    volume_size = each.value.root_volume_gb
  }

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-${each.key}"
    Weakness = each.value.description
  })
}
