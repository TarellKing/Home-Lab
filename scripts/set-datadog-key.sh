#!/usr/bin/env bash
# =============================================================================
# Load the Datadog API key from .env into SSM Parameter Store (SecureString).
#
#   ./scripts/set-datadog-key.sh
#
# Run this ONCE before deploying with datadog_enabled=true. The key is stored
# out-of-band (not in Terraform, not in state, not in user_data). Honeypot
# instances read it from SSM at boot via their instance role.
#
# Re-run it any time you rotate the key. It persists across lab teardown, so you
# only redo it if you rotate or change accounts/regions.
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
ENVIRONMENT="${ENVIRONMENT:-dev}"
REGION="${AWS_REGION:-us-east-1}"
PARAM="/honeynet/$ENVIRONMENT/datadog/api-key"

[[ -f "$ENV_FILE" ]] || { echo "!! no .env at $ENV_FILE (expected datadog_api_key=...)" >&2; exit 1; }

# Pull datadog_api_key without echoing it.
KEY="$(grep -E '^[[:space:]]*datadog_api_key[[:space:]]*=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '"'"'"' \r\n' || true)"
[[ -n "$KEY" ]] || { echo "!! datadog_api_key not found (or empty) in .env" >&2; exit 1; }

aws ssm put-parameter \
  --name "$PARAM" \
  --type SecureString \
  --value "$KEY" \
  --overwrite \
  --region "$REGION" \
  --description "Datadog API key for the honeynet ($ENVIRONMENT). Ingest-only." >/dev/null

echo "✓ stored Datadog API key in SSM: $PARAM ($REGION)"
echo "  instances read it at boot; deploy with datadog_enabled=true (the default)."
