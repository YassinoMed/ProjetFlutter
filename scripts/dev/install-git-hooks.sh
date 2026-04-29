#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

git -C "$ROOT_DIR" config core.hooksPath .githooks

echo "Git hooks path configured to .githooks"
echo "Pre-commit and pre-push checks are now active for this repository."
