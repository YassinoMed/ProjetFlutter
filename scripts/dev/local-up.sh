#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

cd "$ROOT_DIR"

WITH_OBSERVABILITY=0
WITH_TEST_SERVICES=1

for arg in "$@"; do
  case "$arg" in
    --with-observability)
      WITH_OBSERVABILITY=1
      ;;
    --without-test-services)
      WITH_TEST_SERVICES=0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [ ! -f "$ROOT_DIR/.env" ] && [ -f "$ROOT_DIR/.env.compose.local.example" ]; then
  cp "$ROOT_DIR/.env.compose.local.example" "$ROOT_DIR/.env"
  echo "Created root .env from .env.compose.local.example"
fi

if [ ! -f "$ROOT_DIR/backend/.env" ]; then
  cp "$ROOT_DIR/backend/.env.example" "$ROOT_DIR/backend/.env"
  echo "Created backend/.env from backend/.env.example"
fi

load_env_file "$(local_compose_env_file)"

if ! docker network inspect mediconnect >/dev/null 2>&1; then
  docker network create mediconnect >/dev/null
  echo "Created shared docker network: mediconnect"
fi

is_port_busy() {
  local port="$1"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(0.2)
result = sock.connect_ex(("127.0.0.1", port))
sock.close()
sys.exit(0 if result == 0 else 1)
PY
    return $?
  fi

  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi

  return 1
}

if [ -z "${MAILPIT_SMTP_PORT_FORWARD:-}" ] && is_port_busy 1025; then
  export MAILPIT_SMTP_PORT_FORWARD=2025
  echo "Port 1025 busy, using MAILPIT_SMTP_PORT_FORWARD=${MAILPIT_SMTP_PORT_FORWARD}"
fi

if [ -z "${MAILPIT_UI_PORT_FORWARD:-}" ] && is_port_busy 8025; then
  export MAILPIT_UI_PORT_FORWARD=18025
  echo "Port 8025 busy, using MAILPIT_UI_PORT_FORWARD=${MAILPIT_UI_PORT_FORWARD}"
fi

COMPOSE_ARGS=(-f docker-compose.yml -f docker-compose.local.yml)

compose_with_env "$(local_compose_env_file)" "${COMPOSE_ARGS[@]}" up -d --build nginx app queue scheduler reverb postgres redis mailpit coturn minio

if [ "$WITH_TEST_SERVICES" -eq 1 ]; then
  compose_with_env "$(local_compose_env_file)" "${COMPOSE_ARGS[@]}" --profile test up -d postgres-test redis-test
fi

if [ "$WITH_OBSERVABILITY" -eq 1 ]; then
  compose_with_env "$(local_compose_env_file)" "${COMPOSE_ARGS[@]}" -f docker-compose.observability.yml up -d
fi

echo "Local stack is starting."
echo "Run ./scripts/dev/local-health-check.sh to verify readiness."
