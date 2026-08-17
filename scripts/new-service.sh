#!/usr/bin/env bash
# =============================================================================
# Scaffold a new honeypot service.
#
#   ./scripts/new-service.sh <service-name>
#
# Creates services/<name>/ for any config files, prints a ready-to-paste catalog
# stub, and reminds you of the two edits + validate step. It does NOT edit the
# catalog for you -- you paste the stub so you see exactly what you're adding.
# =============================================================================
set -euo pipefail

NAME="${1:-}"
if [[ -z "$NAME" || ! "$NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "usage: $0 <service-name>   (lowercase letters, digits, hyphens)" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SVC_DIR="$ROOT/services/$NAME"

if grep -q "^  $NAME:" "$ROOT/catalog/services.yaml" 2>/dev/null; then
  echo "!! '$NAME' already exists in catalog/services.yaml" >&2
  exit 1
fi

mkdir -p "$SVC_DIR"
echo "✓ created $SVC_DIR  (put any config files that inject the weakness here)"
echo

cat <<EOF
--- 1. paste into catalog/services.yaml under 'services:' and edit ---------------

  $NAME:
    enabled: true
    description: "<one line: what it is and why it's attackable>"
    image: <image>:<pinned-tag>          # NEVER :latest
    weakness:
      class: misconfig                    # cve | misconfig | weak-creds | none
      notes: "<what an attacker can actually do>"
    # config_mounts:                      # uncomment if you need to inject a bad config
    #   - { file: <file-in-services/$NAME/>, target: <path-inside-container> }
    ports:
      - { container: <port>, host: <port>, protocol: tcp, exposure: internal }
      #   exposure: public   -> 0.0.0.0/0 (internet bait)
      #            admin      -> your admin_cidr only
      #            internal   -> other honeynet hosts (lateral-movement target)
    logs: []                              # add file logs here if the app writes them
    env: {}

--- 2. add it to a host in catalog/hosts.yaml ------------------------------------

  under a host's 'services:' list, add:
      - $NAME

--- 3. validate + deploy ---------------------------------------------------------

  make validate            # runs the catalog schema checks (typos fail here)
  make platform-apply      # creates its log groups (only if you declared file logs)
  make honeynet-apply      # rebuilds the host with the new service

Full reference: docs/adding-a-service.md
EOF
