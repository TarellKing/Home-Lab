data "aws_ami" "amazon_linux" {
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

resource "aws_security_group" "decoy" {
  name        = "${var.name_prefix}-decoy-sg"
  description = "Internet-facing decoy service"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP decoy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS decoy placeholder"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Optional admin testing"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-decoy-sg" }
}

resource "aws_security_group" "internal" {
  name        = "${var.name_prefix}-internal-sg"
  description = "Private internal host, reachable from decoy tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Internal app from decoy"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.decoy.id]
  }

  ingress {
    description     = "ICMP from decoy"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.decoy.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-internal-sg" }
}

locals {
  decoy_user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf install -y nginx amazon-cloudwatch-agent
    cat >/usr/share/nginx/html/index.html <<'HTML'
    <html><head><title>Northstar Forge Status</title></head><body>
    <h1>Northstar Forge Engineering Portal</h1>
    <p>Status: maintenance window in progress.</p>
    <p>API: /api/v1/status</p>
    </body></html>
    HTML
    systemctl enable --now nginx
  EOT
}

resource "aws_instance" "decoy" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.decoy.id]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = true
  user_data                   = local.decoy_user_data

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
  }

  tags = {
    Name = "${var.name_prefix}-edge-portal-01"
    Role = "decoy-edge"
  }
}

resource "aws_instance" "internal" {
  count                       = var.create_internal_instance ? 1 : 0
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [aws_security_group.internal.id]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
  }

  tags = {
    Name = "${var.name_prefix}-internal-api-01"
    Role = "internal-decoy"
  }
}
