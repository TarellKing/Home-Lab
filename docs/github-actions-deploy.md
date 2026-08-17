# GitHub Actions Deployment

This repo includes two workflows:

- `terraform-ci`: runs fmt/init/validate on pushes and PRs without AWS credentials.
- `deploy-honeynet`: manual deployment workflow for `plan`, `apply`, or `destroy`.

## Required GitHub Secret

Set this repository secret:

- `AWS_GITHUB_ACTIONS_ROLE_ARN`: ARN of an AWS IAM role trusted by GitHub OIDC.

## Recommended GitHub Environment

Create an environment named `honeynet-dev` and require manual approval for it. This keeps `apply`/`destroy` from running accidentally.

## AWS Role Trust Policy Sketch

Restrict the trust policy to this repository and branch/environment. Example shape:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<OWNER>/<REPO>:*"
        }
      }
    }
  ]
}
```

For early experimentation, use least-privilege as much as practical, but expect to iterate because Terraform creates networking, IAM, EC2, CloudTrail, CloudWatch, and S3 resources.
