#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

cd "$ROOT_DIR"
load_env_file "$(local_compose_env_file)"

WITH_VOLUMES=0
WITH_OBSERVABILITY=0

for arg in "$@"; do
  case "$arg" in
    --volumes)
      WITH_VOLUMES=1
      ;;
    --with-observability)
      WITH_OBSERVABILITY=1
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

COMPOSE_ARGS=(-f docker-compose.yml -f docker-compose.local.yml)
if [ "$WITH_OBSERVABILITY" -eq 1 ]; then
  COMPOSE_ARGS+=(-f docker-compose.observability.yml)
fi

DOWN_ARGS=(down --remove-orphans)
if [ "$WITH_VOLUMES" -eq 1 ]; then
  DOWN_ARGS+=(-v)
fi

compose_with_env "$(local_compose_env_file)" "${COMPOSE_ARGS[@]}" "${DOWN_ARGS[@]}"
