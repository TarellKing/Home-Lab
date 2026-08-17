# Token Breadcrumbs

Design notes for future honey credentials/tokens.

Rules:

- Never use real credentials.
- Tokens should be scoped to synthetic resources only.
- Every use should be high-signal telemetry.
- Rotate/destroy tokens through Terraform when possible.
