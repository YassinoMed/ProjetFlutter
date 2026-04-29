#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# MediConnect Pro – Setup local macOS (v2.1 – Reverb + E2EE + RGPD)
# Requires PHP 8.4
# ──────────────────────────────────────────────────────────────────────────────

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
TMP_DIR="${BACKEND_DIR}/.laravel_tmp"
OVERLAY_DIR="${BACKEND_DIR}/_overlay"
LOG_FILE="${ROOT_DIR}/setup_local_macos.log"

cd "${ROOT_DIR}"

# ── PHP version check ──────────────────────────────────────────
if ! command -v php >/dev/null 2>&1; then
  echo "php introuvable. Installe PHP 8.4 (brew install php) puis réessaie." >&2
  exit 1
fi

PHP_MM="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
case "${PHP_MM}" in
  8.4)
    ;;
  *)
    echo "Version PHP détectée: ${PHP_MM} (attendue: 8.4)." >&2
    echo "Installe et active PHP 8.4 via Homebrew :" >&2
    echo "  brew install php" >&2
    echo "  brew unlink php || true" >&2
    echo "  brew link --overwrite --force php" >&2
    exit 1
    ;;
esac

if ! command -v composer >/dev/null 2>&1; then
  echo "composer introuvable. Installe Composer (brew install composer) puis réessaie." >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync introuvable. Installe rsync (brew install rsync) puis réessaie." >&2
  exit 1
fi

# ── Create backend dir if needed ───────────────────────────────
mkdir -p "${BACKEND_DIR}"

if [ ! -f "${BACKEND_DIR}/artisan" ]; then
  rm -rf "${TMP_DIR}"
  mkdir -p "${TMP_DIR}"

  cd "${BACKEND_DIR}"
  composer create-project laravel/laravel "${TMP_DIR}" "^11.0" --no-interaction --prefer-dist

  rsync -a "${TMP_DIR}/" "${BACKEND_DIR}/" \
    --exclude "_overlay" \
    --exclude ".laravel_tmp" \
    --exclude ".husky" \
    --exclude "package.json" \
    --exclude ".prettierrc.json" \
    --exclude ".prettierignore"
fi

cd "${BACKEND_DIR}"

if [ ! -f "${BACKEND_DIR}/composer.json" ]; then
  echo "backend/composer.json introuvable. L'initialisation Laravel a échoué." >&2
  exit 1
fi

# ── ENV setup ──────────────────────────────────────────────────
if [ -f "${OVERLAY_DIR}/.env.example" ]; then
  cp "${OVERLAY_DIR}/.env.example" "${BACKEND_DIR}/.env.example"
fi

if [ ! -f "${BACKEND_DIR}/.env" ]; then
  if [ -f "${OVERLAY_DIR}/.env.local.example" ]; then
    cp "${OVERLAY_DIR}/.env.local.example" "${BACKEND_DIR}/.env"
  else
    cp "${BACKEND_DIR}/.env.example" "${BACKEND_DIR}/.env"
  fi
fi

if [ -f "${OVERLAY_DIR}/.env.testing" ]; then
  cp "${OVERLAY_DIR}/.env.testing" "${BACKEND_DIR}/.env.testing"
fi

# ── Composer install ───────────────────────────────────────────
composer install 2>&1 | tee -a "${LOG_FILE}"

# ── Remove deprecated websockets package ───────────────────────
if composer show beyondcode/laravel-websockets 2>/dev/null | grep -q "name"; then
  echo "Suppression de beyondcode/laravel-websockets (deprecated)..."
  composer remove beyondcode/laravel-websockets --no-interaction 2>&1 | tee -a "${LOG_FILE}" || true
  rm -f config/websockets.php || true
fi

# ── Install required packages (v2.1: Reverb instead of websockets) ──
if ! composer require \
    laravel/sanctum \
    tymon/jwt-auth:^2.0 \
    laravel/reverb:^1.0 \
    kreait/laravel-firebase:^6.0 \
    spatie/laravel-activitylog:^4.0 \
    --no-interaction -W 2>&1 | tee -a "${LOG_FILE}"; then
  echo "composer require a échoué. Log: ${LOG_FILE}" >&2
  echo "Vérifie les extensions PHP: php -m | egrep 'sodium|zip|intl|pdo_mysql'" >&2
  exit 1
fi

# ── Publish vendors ───────────────────────────────────────────
php artisan vendor:publish --provider="Laravel\\Sanctum\\SanctumServiceProvider" --force
php artisan vendor:publish --provider="Tymon\\JWTAuth\\Providers\\LaravelServiceProvider" --force
php artisan vendor:publish --provider="Kreait\\Laravel\\Firebase\\ServiceProvider" --tag=config --force

# ── Install Reverb broadcasting ───────────────────────────────
if php artisan list 2>/dev/null | grep -q "reverb:install"; then
  php artisan reverb:install --no-interaction 2>&1 | tee -a "${LOG_FILE}" || true
elif php artisan list 2>/dev/null | grep -q "install:broadcasting"; then
  php artisan install:broadcasting --no-interaction 2>&1 | tee -a "${LOG_FILE}" || true
fi

# ── Remove default Laravel migrations (handled by overlay) ────
rm -f ./database/migrations/*create_users_table.php || true
rm -f ./database/migrations/*create_cache_table.php || true
rm -f ./database/migrations/*create_jobs_table.php || true

# ── Apply overlays ────────────────────────────────────────────
rsync -a "${OVERLAY_DIR}/database/" "./database/"
rsync -a "${OVERLAY_DIR}/app/" "./app/"
rsync -a "${OVERLAY_DIR}/config/" "./config/"
rsync -a "${OVERLAY_DIR}/routes/" "./routes/"
rsync -a "${OVERLAY_DIR}/tests/" "./tests/"
if [ -d "${OVERLAY_DIR}/bootstrap" ]; then
  rsync -a "${OVERLAY_DIR}/bootstrap/" "./bootstrap/"
fi

# ── Generate keys ─────────────────────────────────────────────
php artisan key:generate --force || true
php artisan jwt:secret --force || true

if [ -f "${BACKEND_DIR}/.env.testing" ]; then
  php artisan key:generate --env=testing --force || true
  if php artisan list --format=json 2>/dev/null | grep -q '"name":"jwt:secret"'; then
    php artisan jwt:secret --env=testing --force || true
  fi
fi

# ── Update .env with Reverb + OTEL + RGPD vars ───────────────
if [ -f ".env" ]; then
  # Switch BROADCAST_CONNECTION to reverb
  if grep -q "BROADCAST_CONNECTION=pusher" .env; then
    sed -i.bak 's/BROADCAST_CONNECTION=pusher/BROADCAST_CONNECTION=reverb/' .env
  fi

  # Add Reverb vars if missing
  if ! grep -q "REVERB_APP_ID" .env; then
    cat >> .env << 'EOF'

# ── Reverb ───────────────────────────────────────────────
REVERB_APP_ID=mediconnect
REVERB_APP_KEY=mediconnect-key
REVERB_APP_SECRET=mediconnect-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http
EOF
  fi

  # Add OTEL vars if missing
  if ! grep -q "OTEL_ENABLED" .env; then
    cat >> .env << 'EOF'

# ── OpenTelemetry ────────────────────────────────────────
OTEL_ENABLED=true
OTEL_SERVICE_NAME=mediconnect-api
EOF
  fi

  # Add RGPD TTL vars if missing
  if ! grep -q "CHAT_MESSAGE_TTL_DAYS" .env; then
    cat >> .env << 'EOF'

# ── RGPD Data Minimization ──────────────────────────────
CHAT_MESSAGE_TTL_DAYS=730
MEDICAL_RECORD_TTL_DAYS=3650
EOF
  fi
fi

# ── Migrate ───────────────────────────────────────────────────
php artisan migrate

echo ""
echo "============================================================="
echo "  ✅ Backend prêt (v2.1 – Reverb + E2EE + RGPD)"
echo "============================================================="
echo ""
echo "  Lance l'API :        ./scripts/run_local_macos.sh"
echo "  Lance Reverb :       cd backend && php artisan reverb:start --debug"
echo "  Lance le scheduler : cd backend && php artisan schedule:work"
echo ""
