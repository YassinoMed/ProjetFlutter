#!/bin/sh
set -eu

cd /var/www/html

if [ ! -f artisan ]; then
  composer create-project laravel/laravel . "^11.0" --no-interaction --prefer-dist
fi

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

if [ -f artisan ]; then
  php artisan key:generate --force || true
fi

if [ -f ./_overlay/bootstrap.sh ] && [ ! -f ./.mediconnect_pro_bootstrapped ]; then
  sh ./_overlay/bootstrap.sh
  touch ./.mediconnect_pro_bootstrapped
fi

exec "$@"