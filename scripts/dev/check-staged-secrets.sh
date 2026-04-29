#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if git diff --cached --quiet; then
  exit 0
fi

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks protect --staged --redact --verbose --config "$ROOT_DIR/.gitleaks.toml"
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  docker run --rm \
    -v "$ROOT_DIR:/repo" \
    -w /repo \
    zricethezav/gitleaks:latest \
    protect --staged --redact --verbose --config /repo/.gitleaks.toml
  exit 0
fi

if git diff --cached -U0 | grep -E \
  '(AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z\-_]{35}|ghp_[A-Za-z0-9]{36,255}|xox[baprs]-[A-Za-z0-9-]{10,255}|-----BEGIN (RSA|EC|OPENSSH|PGP)? ?PRIVATE KEY-----)' \
  >/dev/null; then
  echo "Potential secret detected in staged changes."
  exit 1
fi
