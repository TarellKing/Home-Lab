output "instances" {
  description = "Deployed honeypot hosts: public IP, instance id, and the SG protecting each."
  value = {
    for hname, inst in aws_instance.host : hname => {
      instance_id = inst.id
      public_ip   = inst.public_ip
      private_ip  = inst.private_ip
      services    = local.enabled_hosts[hname].services
      sg_id       = aws_security_group.host[hname].id
    }
  }
}

output "open_ports" {
  description = "Every ingress rule that got opened, so you can eyeball the exposure."
  value = {
    for k, r in module.catalog.ingress_rules :
    k => "${r.protocol}/${r.port} -> ${r.exposure} (${r.service})"
  }
}

output "connect_hint" {
  description = "How to get a shell on a box without SSH."
  value       = "Use Session Manager: aws ssm start-session --target <instance_id> --region ${var.aws_region}"
}
