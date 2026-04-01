#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${BACKUP_DIR:-./backups/postgres}"
mkdir -p "${BACKUP_DIR}"

: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:=5432}"
: "${DB_DATABASE:?DB_DATABASE is required}"
: "${DB_USERNAME:?DB_USERNAME is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"

export PGPASSWORD="${DB_PASSWORD}"

pg_dump \
  --host="${DB_HOST}" \
  --port="${DB_PORT}" \
  --username="${DB_USERNAME}" \
  --format=custom \
  --file="${BACKUP_DIR}/${DB_DATABASE}-${TIMESTAMP}.dump" \
  "${DB_DATABASE}"

find "${BACKUP_DIR}" -type f -name '*.dump' -mtime +"${BACKUP_RETENTION_DAYS:-14}" -delete

echo "Backup created: ${BACKUP_DIR}/${DB_DATABASE}-${TIMESTAMP}.dump"
