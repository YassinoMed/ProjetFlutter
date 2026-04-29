#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_COMPOSE_ENV_EXAMPLE="$ROOT_DIR/.env.compose.local.example"
PROD_COMPOSE_ENV_EXAMPLE="$ROOT_DIR/.env.compose.prod.example"

load_env_file() {
  local env_file="${1:-}"

  [ -n "$env_file" ] || return 0
  [ -f "$env_file" ] || return 0

  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
}

local_compose_env_file() {
  if [ -f "$ROOT_DIR/.env" ]; then
    printf '%s\n' "$ROOT_DIR/.env"
    return
  fi

  printf '%s\n' "$LOCAL_COMPOSE_ENV_EXAMPLE"
}

prod_compose_env_file() {
  if [ -f "$ROOT_DIR/.env.compose.prod" ]; then
    printf '%s\n' "$ROOT_DIR/.env.compose.prod"
    return
  fi

  printf '%s\n' "$PROD_COMPOSE_ENV_EXAMPLE"
}

compose_with_env() {
  local env_file="$1"
  shift

  docker compose --env-file "$env_file" "$@"
}

validate_compose_configs() {
  local local_env_file
  local prod_env_file

  local_env_file="$(local_compose_env_file)"
  prod_env_file="$(prod_compose_env_file)"

  compose_with_env "$local_env_file" -f docker-compose.yml -f docker-compose.local.yml config -q
  compose_with_env "$local_env_file" -f docker-compose.yml -f docker-compose.local.yml -f docker-compose.observability.yml config -q
  compose_with_env "$prod_env_file" -f docker-compose.yml -f docker-compose.prod.yml config -q
}
