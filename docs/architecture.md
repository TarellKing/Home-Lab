# Architecture Notes

## Milestone 1: Safe Cloud Skeleton

This baseline creates the minimum shape of a small tech company cloud footprint:

- Public edge portal in a public subnet
- Private internal API placeholder in a private subnet
- Central audit/log bucket
- VPC Flow Logs and CloudTrail
- SSM-based administration, no SSH ingress by default

## Design Constraints

- No real data or credentials
- Dedicated non-production AWS account recommended
- Keep services cheap and disposable
- Prefer Terraform for cloud resources
- Prefer config management/images/containers over large Terraform `user_data`

## Future Milestones

1. Replace static nginx page with vulnerable-but-contained fake CRM.
2. Add synthetic S3 data and honey documents.
3. Add breadcrumb tokens that only permit synthetic resources.
4. Add CloudWatch metric filters and Sigma rules.
5. Add automated adversary simulation with randomized paths.
6. Add AI-assisted investigation notebooks/agents.
