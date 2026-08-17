# =============================================================================
# Security group -- one per host, ingress derived entirely from the catalog.
# =============================================================================
# This is the "explicitly allow open access to honeypot services" piece. Every
# rule here traces back to a `ports:` entry in catalog/services.yaml. There is
# no second place to edit: declare a port on a service, and the box it runs on
# opens that port to the CIDR its `exposure` implies.

locals {
  # host name -> list of its ingress rules (from the shared catalog module).
  rules_by_host = {
    for hname in keys(local.enabled_hosts) : hname => [
      for r in values(module.catalog.ingress_rules) : r if r.host == hname
    ]
  }
}

resource "aws_security_group" "host" {
  for_each = local.enabled_hosts

  name        = "${local.name_prefix}-${each.key}"
  description = "Honeypot ${each.key}: ${each.value.description}"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = { for r in local.rules_by_host[each.key] : r.key => r }
    content {
      description = "${ingress.value.service} (${ingress.value.exposure}, weakness=${ingress.value.weakness})"
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = local.exposure_cidrs[ingress.value.exposure]
    }
  }

  # Honeypots need egress to pull images and ship logs. It also lets you watch
  # what a compromised box tries to reach -- outbound is itself a signal.
  egress {
    description = "all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${each.key}" })

  lifecycle {
    create_before_destroy = true
  }
}
