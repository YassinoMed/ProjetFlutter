#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

cd "$ROOT_DIR"
load_env_file "$(local_compose_env_file)"

BACKEND_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --backend-only)
      BACKEND_ONLY=1
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

./scripts/dev/local-up.sh --without-test-services

compose_with_env "$(local_compose_env_file)" -f docker-compose.yml -f docker-compose.local.yml --profile test up -d postgres-test redis-test

compose_with_env "$(local_compose_env_file)" -f docker-compose.yml -f docker-compose.local.yml run --rm \
  -e APP_ENV=testing \
  -e DB_CONNECTION=pgsql \
  -e DB_HOST=postgres-test \
  -e DB_PORT=5432 \
  -e DB_DATABASE="${DB_TEST_DATABASE:-mediconnect_test}" \
  -e DB_USERNAME="${DB_TEST_USERNAME:-mediconnect_test}" \
  -e DB_PASSWORD="${DB_TEST_PASSWORD:-secret}" \
  -e DB_SSLMODE=disable \
  -e REDIS_HOST=redis-test \
  -e REDIS_PORT=6379 \
  -e REDIS_PASSWORD="${REDIS_TEST_PASSWORD:-redis-test-secret}" \
  -e CACHE_STORE=array \
  -e SESSION_DRIVER=array \
  -e QUEUE_CONNECTION=sync \
  app php artisan test --stop-on-failure

if [ "$BACKEND_ONLY" -eq 0 ]; then
  (
    cd frontend
    flutter pub get
    flutter analyze
    flutter test
  )
fi

./scripts/dev/local-health-check.sh

echo "Local validation completed successfully."
