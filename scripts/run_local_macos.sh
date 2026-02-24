#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"

cd "${BACKEND_DIR}"

if [ ! -f artisan ]; then
  echo "backend/artisan introuvable. Lance d'abord: bash ./scripts/setup_local_macos.sh" >&2
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  MediConnect Pro – API Server v2.1                      ║"
echo "║  http://192.168.1.173:8080/api                          ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Dans d'autres terminaux, lance :                       ║"
echo "║  📡 php artisan reverb:start --debug  (WebSocket)       ║"
echo "║  🔄 php artisan horizon               (Queues)          ║"
echo "║  📅 php artisan schedule:work          (RGPD purge)     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

php artisan serve --host=0.0.0.0 --port=8080
