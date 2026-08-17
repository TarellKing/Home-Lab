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

  # SSM SecureString holding the Datadog API key. Created out-of-band by
  # scripts/set-datadog-key.sh, so the key never lands in Terraform state or in
  # the instance user_data -- which matters because this box gets compromised.
  datadog_ssm_param = "/honeynet/${var.environment}/datadog/api-key"

  # The Datadog agent, run as a container on every host. container_collect_all
  # tails every OTHER container's stdout/stderr; the /var/log/honeypot mount +
  # the logs config in user_data also give it the file-based service logs. The
  # API key is injected via env_file (/opt/honeynet/dd.env), written at boot.
  datadog_service = var.datadog_enabled ? {
    datadog-agent = {
      image          = "gcr.io/datadoghq/agent:7"
      restart        = "unless-stopped"
      container_name = "datadog-agent"
      pid            = "host"
      env_file       = ["/opt/honeynet/dd.env"]
      environment = {
        DD_SITE                              = var.datadog_site
        DD_LOGS_ENABLED                      = "true"
        DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL = "true"
        DD_CONTAINER_EXCLUDE                 = "name:datadog-agent"
        DD_LOGS_CONFIG_USE_HTTP              = "true"
        DD_TAGS                              = "env:${var.environment} honeynet:true"
      }
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro",
        "/proc/:/host/proc/:ro",
        "/sys/fs/cgroup/:/host/sys/fs/cgroup:ro",
        "/var/lib/docker/containers:/var/lib/docker/containers:ro",
        # honeypot file logs (apache access/error, mysql query log, ...) so the
        # agent can tail them too, per the conf.d dropped in by user_data.
        "/var/log/honeypot:/var/log/honeypot:ro",
        "/opt/honeynet/datadog-conf.d:/etc/datadog-agent/conf.d/honeypot.d:ro",
      ]
    }
  } : {}

  # Explicit Datadog file-log config per host, rendered from the catalog (same
  # source as the CloudWatch agent). Exact paths beat a wildcard: honeypot log
  # files sit at varying depths and don't all end in .log (Apache's access_log).
  # Each file gets its own service/source so you can query per honeypot service.
  # (Container stdout is handled separately by container_collect_all.)
  datadog_logs_config = {
    for hname, svcs in module.catalog.host_services : hname => jsonencode({
      logs = flatten([
        for s in svcs : [
          for l in s.logs : {
            type    = "file"
            path    = l.host_path
            service = s.name
            source  = "honeypot"
            tags    = ["honeynet:true", "weakness:${s.weakness.class}", "stream:${l.name}"]
          }
        ]
      ])
    })
  }

  # ---------------------------------------------------------------------------
  # docker-compose, per host, built straight from the resolved catalog.
  # jsonencode produces a valid compose file (compose is a YAML superset of JSON).
  # ---------------------------------------------------------------------------
  compose = {
    for hname, svcs in module.catalog.host_services : hname => {
      services = merge(local.datadog_service, {
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
          # Container stdout/stderr stays on Docker's default json-file driver.
          # The Datadog agent (container_collect_all) is the forwarder that
          # picks it up; it is NOT shipped to CloudWatch.
        )
      })
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
    hostname            = each.key
    region              = var.aws_region
    compose_json        = jsonencode(local.compose[each.key])
    agent_config        = local.agent_config[each.key]
    config_files        = local.host_config_files[each.key]
    config_root         = local.host_config_root
    datadog_enabled     = var.datadog_enabled
    datadog_ssm_param   = local.datadog_ssm_param
    datadog_logs_config = local.datadog_logs_config[each.key]
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
