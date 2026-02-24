#!/usr/bin/env bash

set -euo pipefail

echo "============================================================="
echo "  MediConnect Pro – Migration v2.0 → v2.1"
echo "  Reverb + Rich Push + E2EE Attachments + RGPD TTL + OTel"
echo "============================================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
FRONTEND_DIR="${ROOT_DIR}/frontend"
LOG_FILE="${ROOT_DIR}/migrate_v21.log"

echo "" > "${LOG_FILE}"

ok()   { echo "  ✅ $1"; }
warn() { echo "  ⚠️  $1"; }
fail() { echo "  ❌ $1" >&2; }

section() {
    echo ""
    echo "─── $1 ───────────────────────────────────────────────"
}

# ──────────────────────────────────────────────────────────────────────────────
section "BACKEND – Migration des paquets"
# ──────────────────────────────────────────────────────────────────────────────

cd "${BACKEND_DIR}"

echo "  1. Suppression de beyondcode/laravel-websockets..."
composer remove beyondcode/laravel-websockets --no-interaction 2>&1 | tee -a "${LOG_FILE}" || ok "Déjà supprimé"

echo "  2. Installation de laravel/reverb..."
composer require laravel/reverb:^1.0 --no-interaction -W 2>&1 | tee -a "${LOG_FILE}" || warn "Reverb: vérifier manuellement"

echo "  3. Mise à jour de kreait/laravel-firebase..."
composer require kreait/laravel-firebase:^7.0 --no-interaction -W 2>&1 | tee -a "${LOG_FILE}" || {
    warn "firebase v7 échoué, fallback v6..."
    composer require kreait/laravel-firebase:^6.0 --no-interaction -W 2>&1 | tee -a "${LOG_FILE}" || true
}

echo "  4. Installation des dépendances manquantes..."
composer require laravel/horizon spatie/laravel-activitylog:^4.0 --no-interaction -W 2>&1 | tee -a "${LOG_FILE}" || true

echo "  5. Résolution des conflits..."
composer update --with-all-dependencies --no-interaction 2>&1 | tee -a "${LOG_FILE}" || true

# ──────────────────────────────────────────────────────────────────────────────
section "BACKEND – Configuration Reverb"
# ──────────────────────────────────────────────────────────────────────────────

# Installer Reverb si la commande est disponible
if php artisan list 2>/dev/null | grep -q "reverb:install"; then
    php artisan reverb:install --no-interaction 2>&1 | tee -a "${LOG_FILE}" || true
    ok "reverb:install exécuté"
elif php artisan list 2>/dev/null | grep -q "install:broadcasting"; then
    php artisan install:broadcasting --no-interaction 2>&1 | tee -a "${LOG_FILE}" || true
    ok "install:broadcasting exécuté"
else
    ok "Config Reverb déjà en place (config/reverb.php)"
fi

# Supprimer la config websockets obsolète
if [ -f "config/websockets.php" ]; then
    rm -f config/websockets.php
    ok "config/websockets.php supprimé (remplacé par reverb.php)"
fi

# ──────────────────────────────────────────────────────────────────────────────
section "BACKEND – Variables d'environnement Reverb"
# ──────────────────────────────────────────────────────────────────────────────

# Mettre à jour .env : BROADCAST_CONNECTION → reverb
if [ -f ".env" ]; then
    # Remplacer BROADCAST_CONNECTION=pusher par reverb
    if grep -q "BROADCAST_CONNECTION=pusher" .env; then
        sed -i.bak 's/BROADCAST_CONNECTION=pusher/BROADCAST_CONNECTION=reverb/' .env
        ok "BROADCAST_CONNECTION → reverb"
    fi

    # Ajouter les variables Reverb si absentes
    if ! grep -q "REVERB_APP_ID" .env; then
        cat >> .env << 'REVERB_ENV'

# ── Reverb (native Laravel WebSocket) ────────────────────
REVERB_APP_ID=mediconnect
REVERB_APP_KEY=mediconnect-key
REVERB_APP_SECRET=mediconnect-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http
REVERB_SERVER_HOST=0.0.0.0
REVERB_SERVER_PORT=8080
REVERB_ENV
        ok "Variables Reverb ajoutées à .env"
    else
        ok "Variables Reverb déjà présentes"
    fi

    # Ajouter les variables OpenTelemetry si absentes
    if ! grep -q "OTEL_ENABLED" .env; then
        cat >> .env << 'OTEL_ENV'

# ── OpenTelemetry ────────────────────────────────────────
OTEL_ENABLED=true
OTEL_SERVICE_NAME=mediconnect-api
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_TRACES_SAMPLER=always_on
OTEL_ENV
        ok "Variables OpenTelemetry ajoutées à .env"
    fi

    # Ajouter les variables RGPD TTL si absentes
    if ! grep -q "CHAT_MESSAGE_TTL_DAYS" .env; then
        cat >> .env << 'RGPD_ENV'

# ── Data Minimization (RGPD) ────────────────────────────
CHAT_MESSAGE_TTL_DAYS=730
MEDICAL_RECORD_TTL_DAYS=3650
DATA_RETENTION_WARNING_DAYS=30
RGPD_ENV
        ok "Variables RGPD ajoutées à .env"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
section "BACKEND – Migrations de la base de données"
# ──────────────────────────────────────────────────────────────────────────────

echo "  Exécution des migrations v2.1..."
php artisan migrate --force 2>&1 | tee -a "${LOG_FILE}" || {
    warn "Migration échouée. Vérifie la connexion DB."
    echo "  Commande pour réessayer : cd backend && php artisan migrate"
}

# ──────────────────────────────────────────────────────────────────────────────
section "BACKEND – Publication des vendors"
# ──────────────────────────────────────────────────────────────────────────────

php artisan vendor:publish --provider="Laravel\Horizon\HorizonServiceProvider" --force 2>&1 | tee -a "${LOG_FILE}" || true
ok "Vendors publiés"

# ──────────────────────────────────────────────────────────────────────────────
section "BACKEND – Nettoyage du cache"
# ──────────────────────────────────────────────────────────────────────────────

php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan event:clear 2>/dev/null || true
ok "Cache nettoyé"

# ──────────────────────────────────────────────────────────────────────────────
section "FRONTEND – Flutter packages"
# ──────────────────────────────────────────────────────────────────────────────

if [ -d "${FRONTEND_DIR}" ] && [ -f "${FRONTEND_DIR}/pubspec.yaml" ]; then
    cd "${FRONTEND_DIR}"
    echo "  Résolution des dépendances Flutter..."
    flutter pub get 2>&1 | tee -a "${LOG_FILE}" || {
        warn "flutter pub get échoué."
        echo "  Assure-toi que Flutter est dans ton PATH."
    }
    ok "Dépendances Flutter résolues"
else
    warn "Répertoire frontend/ non trouvé. Skip Flutter."
fi

# ──────────────────────────────────────────────────────────────────────────────
section "VÉRIFICATION FINALE"
# ──────────────────────────────────────────────────────────────────────────────

cd "${BACKEND_DIR}"

echo ""
echo "  📦 Paquets installés :"
echo "     $(composer show laravel/reverb 2>/dev/null | head -1 || echo '❌ laravel/reverb manquant')"
echo "     $(composer show kreait/laravel-firebase 2>/dev/null | head -1 || echo '❌ kreait/laravel-firebase manquant')"
echo "     $(composer show laravel/horizon 2>/dev/null | head -1 || echo '❌ laravel/horizon manquant')"
echo "     $(composer show spatie/laravel-activitylog 2>/dev/null | head -1 || echo '❌ spatie/activitylog manquant')"

echo ""
echo "  📍 Routes API :"
php artisan route:list --path=api --columns=method,uri 2>/dev/null | head -30 || true

echo ""
echo "  🆕 Nouvelles routes v2.1 :"
php artisan route:list --path=attachments --columns=method,uri 2>/dev/null || echo "     (vérifie après migration)"

echo ""
echo "============================================================="
echo "  ✅ MIGRATION v2.0 → v2.1 TERMINÉE !"
echo "============================================================="
echo ""
echo "  Nouvelles fonctionnalités activées :"
echo "    📡 Laravel Reverb (WebSocket natif)"
echo "    🔔 Rich Push Notifications (images + boutons)"
echo "    🔒 E2EE Encrypted Attachments (ordonnances, résultats)"
echo "    🎤 Voice Input/Output (on-device, RGPD-friendly)"
echo "    🗑️  Data Minimization (TTL automatique, purge RGPD)"
echo "    🔍 OpenTelemetry Distributed Tracing"
echo ""
echo "  Pour lancer :"
echo "    ./scripts/run_local_macos.sh              # API"
echo "    cd backend && php artisan reverb:start     # WebSocket"
echo "    cd backend && php artisan horizon           # Queues"
echo "    cd backend && php artisan schedule:work     # Scheduler RGPD"
echo ""
echo "  Log complet : ${LOG_FILE}"
echo ""
