# Cloud Honeynet Mini Tech Company

A realistic, cost-conscious cloud honeynet that behaves like a small technology company rather than a static set of honeypots.

> **Safety intent:** this lab is intentionally deceptive and isolated. It should never store real secrets, real customer data, or production credentials.

## Goals

Observe realistic attack chains:

```text
Internet attacker
→ exposed service
→ application compromise
→ credential/token discovery
→ internal enumeration
→ lateral movement
→ fake data access/exfiltration
→ centralized telemetry
→ detection
→ AI-assisted investigation
```

Portfolio themes:

- Security engineering
- Cloud security
- Infrastructure as Code
- Detection engineering
- Platform engineering
- AI security / AI SecOps
- Agentic security automation

## Initial Architecture

The first milestone creates an AWS baseline:

- VPC with public and private subnets
- Internet-facing decoy application host
- Internal private host placeholder
- Strict security groups
- VPC Flow Logs
- CloudTrail
- Central S3 log bucket
- CloudWatch log groups
- IAM roles with intentionally scoped permissions for telemetry
- SSM Session Manager access instead of SSH by default

Future milestones will add:

- Fake SaaS apps and internal APIs
- Honey credentials and token breadcrumbs
- Synthetic company data
- Detection-as-code
- Automated adversary simulation
- AI-assisted investigation workflows

## Quick Start

Prerequisites:

- Terraform >= 1.6
- AWS CLI configured with a non-production AWS account/profile
- `make`

```bash
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
# edit tfvars for region/profile/cost controls
make lab-init
make lab-plan
make lab-up
make lab-status
make lab-down
```

## Cost Controls

Defaults are intentionally small:

- `t3.micro` EC2 instances
- One NAT-free VPC design initially
- S3 lifecycle expiration for logs
- No managed SIEM by default

Always run this in a dedicated AWS account and set billing alerts.

## Repository Layout

```text
terraform/             Infrastructure as Code
ansible/               Future machine configuration
services/              Decoy apps and breadcrumb services
detections/            Detection rules and analytics
docs/                  Architecture and operating notes
scripts/               Local helper scripts
```
