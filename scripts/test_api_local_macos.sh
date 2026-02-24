#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
OVERLAY_DIR="${BACKEND_DIR}/_overlay"

cd "${BACKEND_DIR}"

if [ ! -f artisan ]; then
  echo "backend/artisan introuvable. Lance d'abord: bash ./scripts/setup_local_macos.sh" >&2
  exit 1
fi

if [ ! -f composer.json ]; then
  echo "backend/composer.json introuvable." >&2
  exit 1
fi

if [ ! -f vendor/autoload.php ]; then
  composer install
fi

if [ -d "${OVERLAY_DIR}/tests" ] && [ ! -f ./tests/Feature/AuthEndpointsTest.php ]; then
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "${OVERLAY_DIR}/tests/" "./tests/"
  fi
fi

if command -v rsync >/dev/null 2>&1; then
  if [ -d "${OVERLAY_DIR}/routes" ]; then
    rsync -a "${OVERLAY_DIR}/routes/" "./routes/"
  fi

  if [ -d "${OVERLAY_DIR}/app" ]; then
    rsync -a "${OVERLAY_DIR}/app/" "./app/"
  fi

  if [ -d "${OVERLAY_DIR}/config" ]; then
    rsync -a "${OVERLAY_DIR}/config/" "./config/"
  fi

  if [ -d "${OVERLAY_DIR}/database" ]; then
    rm -f ./database/migrations/*create_users_table.php || true
    rm -f ./database/migrations/*create_cache_table.php || true
    rm -f ./database/migrations/*create_jobs_table.php || true
    rsync -a "${OVERLAY_DIR}/database/" "./database/"
  fi

  if [ -d "${OVERLAY_DIR}/bootstrap" ]; then
    rsync -a "${OVERLAY_DIR}/bootstrap/" "./bootstrap/"
  fi
fi

if [ -f .env.testing ]; then
  if ! grep -q '^APP_KEY=base64:' .env.testing; then
    php artisan key:generate --env=testing --force
  fi
fi

HAS_JWT_SUBJECT="$(php -r "require 'vendor/autoload.php'; echo interface_exists('Tymon\\\\JWTAuth\\\\Contracts\\\\JWTSubject') ? '1' : '0';")"
if [ "${HAS_JWT_SUBJECT}" != "1" ]; then
  composer require tymon/jwt-auth:^2.0 --no-interaction -W
fi

if [ -f .env.testing ]; then
  JWT_SECRET_VALUE="$(grep -E '^JWT_SECRET=' .env.testing | tail -n 1 | cut -d= -f2- || true)"
  if [ "${#JWT_SECRET_VALUE}" -lt 32 ]; then
    if php artisan list --format=json 2>/dev/null | grep -q '"name":"jwt:secret"'; then
      php artisan jwt:secret --env=testing --force
    else
      NEW_SECRET="$(php -r 'echo bin2hex(random_bytes(32));')"
      if grep -q '^JWT_SECRET=' .env.testing; then
        awk -v s="${NEW_SECRET}" 'BEGIN{done=0} /^JWT_SECRET=/{print "JWT_SECRET=" s; done=1; next} {print} END{if(done==0) print "JWT_SECRET=" s}' .env.testing > .env.testing.tmp
        mv .env.testing.tmp .env.testing
      else
        echo "JWT_SECRET=${NEW_SECRET}" >> .env.testing
      fi
    fi
  fi
fi

php artisan test
