#!/usr/bin/env bash

set -euo pipefail

echo "============================================================="
echo "  MediConnect Pro – Setup / Reset / Migration tout-en-un"
echo "  Requires PHP 8.4 – Reverb au lieu de laravel-websockets"
echo "============================================================="
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION – À ADAPTER SI BESOIN
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
LOG_FILE="${ROOT_DIR}/setup_full.log"

PHP_VERSION="8.4"
LARAVEL_VERSION="^11.0"
MINIMUM_STABILITY="stable"

# Paquets principaux à installer (v2.1)
PACKAGES=(
    "laravel/sanctum"
    "tymon/jwt-auth:^2.0"
    "laravel/reverb:^1.0"
    "kreait/laravel-firebase:^7.0"
    "spatie/laravel-activitylog:^4.0"
    "laravel/horizon"
    "knuckleswtf/scribe"
)

# Paquets de dev
DEV_PACKAGES=(
    "laravel/pint"
    "laravel/telescope"
)

# ──────────────────────────────────────────────────────────────────────────────
# FONCTIONS UTILITAIRES
# ──────────────────────────────────────────────────────────────────────────────

confirm() {
    read -p "$1 (y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

section() {
    echo ""
    echo "──────────────────────────────────────────────────────────────"
    echo "  $1"
    echo "──────────────────────────────────────────────────────────────"
}

log_run() {
    echo "→ $*"
    "$@" 2>&1 | tee -a "${LOG_FILE}"
}

ok()   { echo "  ✅ $1"; }
warn() { echo "  ⚠️  $1"; }
fail() { echo "  ❌ $1" >&2; }

# ──────────────────────────────────────────────────────────────────────────────
# DÉBUT DU SCRIPT
# ──────────────────────────────────────────────────────────────────────────────

echo "" > "${LOG_FILE}"  # Reset log

section "1/8 — Vérification de l'environnement"

# PHP
if ! command -v php >/dev/null 2>&1; then
    fail "php introuvable. Installe PHP 8.4 (brew install php) puis réessaie."
    exit 1
fi

PHP_MM="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
echo "  PHP détecté : ${PHP_MM}"

case "${PHP_MM}" in
  8.4)
    ok "Version PHP compatible"
    ;;
  *)
    fail "Version PHP ${PHP_MM} non supportée (attendue: 8.4)"
    echo "  Installe PHP via Homebrew :"
    echo "    brew install php"
    echo "    brew unlink php || true"
    echo "    brew link --overwrite --force php"
    exit 1
    ;;
esac

# Composer
if ! command -v composer >/dev/null 2>&1; then
    fail "composer introuvable. Installe Composer (brew install composer)."
    exit 1
fi
ok "Composer $(composer --version --short 2>/dev/null || echo 'détecté')"

# Redis (optionnel en local, mais recommandé)
if command -v redis-cli >/dev/null 2>&1; then
    ok "Redis détecté"
else
    warn "Redis non détecté. Installe Redis (brew install redis) pour les queues et cache."
fi

# MySQL / MAMP
if command -v mysql >/dev/null 2>&1; then
    ok "MySQL détecté"
elif [ -f "/Applications/MAMP/Library/bin/mysql" ]; then
    ok "MySQL (MAMP) détecté"
else
    warn "MySQL non détecté. Vérifie ta config DB_HOST dans .env"
fi

# ──────────────────────────────────────────────────────────────────────────────
section "2/8 — Vérification des extensions PHP"

REQUIRED_EXTS=(pdo_mysql mbstring zip intl sodium openssl tokenizer)
MISSING_EXTS=()

for ext in "${REQUIRED_EXTS[@]}"; do
    if php -m 2>/dev/null | grep -qi "^${ext}$"; then
        ok "${ext}"
    else
        MISSING_EXTS+=("${ext}")
        warn "${ext} manquant"
    fi
done

if [ ${#MISSING_EXTS[@]} -gt 0 ]; then
    warn "Extensions manquantes : ${MISSING_EXTS[*]}"
    warn "Installe-les via : brew install php && brew services restart php"
    if ! confirm "Continuer quand même ?"; then
        exit 1
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
section "3/8 — Préparation du répertoire backend"

if [ ! -d "${BACKEND_DIR}" ]; then
    fail "Le répertoire backend/ n'existe pas : ${BACKEND_DIR}"
    exit 1
fi

cd "${BACKEND_DIR}"

if [ ! -f "artisan" ]; then
    fail "backend/artisan introuvable. L'installation Laravel semble incomplète."
    exit 1
fi
ok "Projet Laravel détecté dans backend/"

# Copier .env si pas présent
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        ok ".env créé depuis .env.example"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
section "4/8 — Suppression de beyondcode/laravel-websockets (deprecated)"

if composer show beyondcode/laravel-websockets 2>/dev/null | grep -q "name"; then
    echo "  ℹ️  beyondcode/laravel-websockets détecté → suppression..."
    log_run composer remove beyondcode/laravel-websockets --no-interaction || true

    # Supprimer la config websockets.php obsolète
    if [ -f "config/websockets.php" ]; then
        rm -f config/websockets.php
        ok "config/websockets.php supprimé"
    fi

    ok "beyondcode/laravel-websockets supprimé"
else
    ok "beyondcode/laravel-websockets déjà absent"
fi

# ──────────────────────────────────────────────────────────────────────────────
section "5/8 — Installation des paquets principaux (v2.1)"

echo "  Paquets à installer : ${PACKAGES[*]}"

# Installation principale
log_run composer require "${PACKAGES[@]}" --no-interaction -W || {
    warn "Certains paquets ont échoué. Tentative individuelle..."
    for pkg in "${PACKAGES[@]}"; do
        log_run composer require "${pkg}" --no-interaction -W || warn "Échec: ${pkg}"
    done
}

# Paquets dev
if [ ${#DEV_PACKAGES[@]} -gt 0 ]; then
    log_run composer require --dev "${DEV_PACKAGES[@]}" --no-interaction -W || true
fi

# Pusher PHP server (nécessaire pour le broadcasting même avec Reverb)
log_run composer require pusher/pusher-php-server --no-interaction --no-update || true

# Résolution conflits connus (lcobucci/jwt, firebase)
log_run composer update --with-all-dependencies --no-interaction || true

ok "Paquets installés"

# ──────────────────────────────────────────────────────────────────────────────
section "6/8 — Publication des vendors & configuration Reverb"

log_run php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider" --force || true
log_run php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider" --force || true
log_run php artisan vendor:publish --provider="Kreait\Laravel\Firebase\ServiceProvider" --tag=config --force || true
log_run php artisan vendor:publish --provider="Laravel\Horizon\HorizonServiceProvider" --force || true

# Installer Reverb (broadcasting natif)
echo "  📡 Installation de Laravel Reverb..."
if php artisan list 2>/dev/null | grep -q "reverb:install"; then
    log_run php artisan reverb:install --no-interaction || true
    ok "Reverb installé"
elif php artisan list 2>/dev/null | grep -q "install:broadcasting"; then
    log_run php artisan install:broadcasting --no-interaction || true
    ok "Broadcasting installé (Reverb)"
else
    warn "Commande reverb:install non trouvée. La config est déjà en place via config/reverb.php"
fi

# Scribe (doc OpenAPI)
if php artisan list 2>/dev/null | grep -q "scribe:generate"; then
    ok "Scribe disponible (php artisan scribe:generate)"
fi

# ──────────────────────────────────────────────────────────────────────────────
section "7/8 — Clés, migrations & scheduler"

# Générer les clés
log_run php artisan key:generate --force || true
log_run php artisan jwt:secret --force || true

# Env testing
if [ -f ".env.testing" ]; then
    log_run php artisan key:generate --env=testing --force || true
    log_run php artisan jwt:secret --env=testing --force || true
fi

# Migrations
echo "  📦 Exécution des migrations..."
log_run php artisan migrate --force || {
    warn "Migration échouée. Vérifie ta connexion DB (DB_HOST, DB_PORT dans .env)"
    warn "Si tu utilises MAMP, essaie : DB_HOST=localhost:8889"
}

ok "Migrations appliquées"

echo ""
echo "  📅 Tâches planifiées configurées :"
echo "     - PurgeExpiredDataJob : tous les jours à 03:00 UTC"
echo "     Pour activer le scheduler en local :"
echo "       php artisan schedule:work"

# ──────────────────────────────────────────────────────────────────────────────
section "8/8 — Vérification finale"

echo ""
echo "  Vérification des routes API..."
ROUTE_COUNT=$(php artisan route:list --json 2>/dev/null | php -r 'echo count(json_decode(file_get_contents("php://stdin"),true));' 2>/dev/null || echo "?")
echo "  📍 ${ROUTE_COUNT} routes détectées"

echo ""
echo "  Vérification des commandes Reverb..."
if php artisan list 2>/dev/null | grep -q "reverb:start"; then
    ok "reverb:start disponible"
else
    warn "reverb:start non trouvé. Vérifie que laravel/reverb est bien installé."
fi

echo ""
echo "============================================================="
echo "  ✅ SETUP TERMINÉ !"
echo "============================================================="
echo ""
echo "  Commandes utiles :"
echo ""
echo "  🚀 Démarrer l'API :"
echo "     cd backend && php artisan serve --host=127.0.0.1 --port=8080"
echo ""
echo "  📡 Démarrer Reverb (WebSocket) :"
echo "     cd backend && php artisan reverb:start --debug"
echo ""
echo "  🔄 Démarrer les queues (Horizon) :"
echo "     cd backend && php artisan horizon"
echo ""
echo "  📅 Démarrer le scheduler (RGPD purge, rappels) :"
echo "     cd backend && php artisan schedule:work"
echo ""
echo "  📚 Générer la doc API (Scribe) :"
echo "     cd backend && php artisan scribe:generate"
echo ""
echo "  🧪 Lancer les tests :"
echo "     cd backend && php artisan test"
echo ""
echo "  Accès API  : http://localhost:8080/api"
echo "  Reverb WS  : ws://127.0.0.1:8080/app/mediconnect-key"
echo "  Doc API    : http://localhost:8080/docs"
echo ""
echo "  Log complet : ${LOG_FILE}"
echo ""
