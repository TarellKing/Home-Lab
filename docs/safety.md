# Safety Model

- Use a dedicated AWS account.
- Do not connect this lab to home, work, or production networks.
- Do not store real secrets or personal data.
- Prefer SSM Session Manager over inbound SSH.
- Scope honey credentials to synthetic resources only.
- Keep Terraform destroyable; avoid irreversible dependencies.
- Set AWS Budget alerts before deploying.
