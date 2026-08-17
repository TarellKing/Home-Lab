#!/usr/bin/env bash
set -euo pipefail
for bin in terraform aws make; do
  command -v "$bin" >/dev/null || { echo "missing: $bin"; exit 1; }
done
terraform version
aws --version
