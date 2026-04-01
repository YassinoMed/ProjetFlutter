#!/bin/sh
set -eu

umask 027

cd /var/www/html

mkdir -p \
  storage/app \
  storage/framework/cache \
  storage/framework/sessions \
  storage/framework/testing \
  storage/framework/views \
  storage/logs \
  bootstrap/cache

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

if [ "${APP_ENV:-local}" != "production" ] && [ -f artisan ] && ! grep -q "^APP_KEY=base64:" .env 2>/dev/null; then
  php artisan key:generate --force --no-interaction >/dev/null 2>&1 || true
fi

if [ -f artisan ] && [ ! -L public/storage ]; then
  php artisan storage:link >/dev/null 2>&1 || true
fi

if [ "${RUN_MIGRATIONS:-false}" = "true" ] && [ -f artisan ]; then
  php artisan migrate --force --no-interaction
fi

if [ "${CACHE_LARAVEL_BOOTSTRAP:-false}" = "true" ] && [ -f artisan ]; then
  php artisan config:cache
  php artisan route:cache
  php artisan view:cache
  php artisan event:cache
fi

exec "$@"
