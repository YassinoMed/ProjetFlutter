#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

cd "$ROOT_DIR"
load_env_file "$(local_compose_env_file)"

APP_PORT="${APP_PORT:-8089}"
BASE_URL="http://127.0.0.1:${APP_PORT}"

check_http() {
  local url="$1"
  local label="$2"
  local code

  code="$(curl -fsS -o /dev/null -w '%{http_code}' "$url")"
  if [ "$code" != "200" ]; then
    echo "$label check failed with HTTP $code" >&2
    exit 1
  fi
}

check_http "${BASE_URL}/up" "Nginx/Laravel uptime"
check_http "${BASE_URL}/api/ops/health/live" "API live"
check_http "${BASE_URL}/api/ops/health/ready" "API ready"

echo "Health checks passed for ${BASE_URL}"
