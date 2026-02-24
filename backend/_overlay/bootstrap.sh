#!/usr/bin/env sh
set -euo pipefail

cd /var/www/html

if [ -f "./_overlay/.env.example" ]; then
  cp "./_overlay/.env.example" ".env.example"
fi

composer require laravel/sanctum tymon/jwt-auth:^2.0 kreait/laravel-firebase:^6.0 beyondcode/laravel-websockets:^1.15 pusher/pusher-php-server:^7.2 knuckleswtf/scribe:^4.41 spatie/laravel-activitylog:^4.8 --no-interaction

php artisan vendor:publish --provider="Laravel\\Sanctum\\SanctumServiceProvider" --force
php artisan vendor:publish --provider="Tymon\\JWTAuth\\Providers\\LaravelServiceProvider" --force
php artisan vendor:publish --provider="Kreait\\Laravel\\Firebase\\ServiceProvider" --tag=config --force

php artisan jwt:secret --force

rm -f ./database/migrations/*create_users_table.php || true
rm -f ./database/migrations/*create_cache_table.php || true
rm -f ./database/migrations/*create_jobs_table.php || true

if [ -d "./_overlay/database" ]; then
  mkdir -p ./database
  cp -R ./_overlay/database/* ./database/
fi

if [ -d "./_overlay/app" ]; then
  mkdir -p ./app
  cp -R ./_overlay/app/* ./app/
fi

if [ -d "./_overlay/config" ]; then
  mkdir -p ./config
  cp -R ./_overlay/config/* ./config/
fi

if [ -d "./_overlay/routes" ]; then
  mkdir -p ./routes
  cp -R ./_overlay/routes/* ./routes/
fi

if [ -d "./_overlay/tests" ]; then
  mkdir -p ./tests
  cp -R ./_overlay/tests/* ./tests/
fi

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

php artisan migrate --force
