#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

cd "$ROOT_DIR"
load_env_file "$(local_compose_env_file)"

./scripts/dev/check-staged-secrets.sh

collect_outgoing_files() {
  local upstream_ref

  if upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"; then
    git diff --name-only --diff-filter=ACMR "${upstream_ref}..HEAD"
    return
  fi

  if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    git diff --name-only --diff-filter=ACMR HEAD~1..HEAD
    return
  fi

  git diff-tree --no-commit-id --name-only -r HEAD
}

is_docs_only_push() {
  local files=("$@")
  local file

  [ "${#files[@]}" -gt 0 ] || return 1

  for file in "${files[@]}"; do
    case "$file" in
      README.md|docs/*|*.md|*.mdx|*.txt|*.rst|*.adoc)
        ;;
      *)
        return 1
        ;;
    esac
  done

  return 0
}

outgoing_files=()
while IFS= read -r file; do
  [ -n "$file" ] && outgoing_files+=("$file")
done < <(collect_outgoing_files)

if [ "${#outgoing_files[@]}" -gt 0 ] && is_docs_only_push "${outgoing_files[@]}"; then
  echo "Docs-only push detected; skipping heavy backend/frontend quality checks."
  if command -v docker >/dev/null 2>&1; then
    validate_compose_configs
  fi

  echo "Pre-push checks passed."
  exit 0
fi

backend_changed=0
frontend_changed=0
backend_php_files=()
backend_phpstan_targets=()
frontend_dart_targets=()

if [ "${#outgoing_files[@]}" -gt 0 ]; then
  for file in "${outgoing_files[@]}"; do
    case "$file" in
      backend/*)
        backend_changed=1
        ;;
      frontend/*)
        frontend_changed=1
        ;;
    esac

    if [[ "$file" =~ ^backend/.+\.php$ ]] && [ -f "$file" ]; then
      backend_php_files+=("${file#backend/}")
    fi

    if [[ "$file" =~ ^backend/app/.+\.php$ ]] && [ -f "$file" ]; then
      backend_phpstan_targets+=("${file#backend/}")
    fi

    if [[ "$file" =~ ^frontend/.+\.dart$ ]] && [ -f "$file" ]; then
      frontend_dart_targets+=("${file#frontend/}")
    fi
  done
fi

if [ "$backend_changed" -eq 1 ]; then
  if [ ! -x backend/vendor/bin/pint ] || [ ! -x backend/vendor/bin/phpstan ]; then
    echo "Backend dev dependencies are missing. Run: cd backend && composer install" >&2
    exit 1
  fi

  if [ "${#backend_php_files[@]}" -gt 0 ]; then
    (cd backend && ./vendor/bin/pint --test "${backend_php_files[@]}")
  fi

  if [ "${#backend_phpstan_targets[@]}" -gt 0 ]; then
    (cd backend && ./vendor/bin/phpstan analyse --memory-limit=1G "${backend_phpstan_targets[@]}")
  fi

  if [ -f backend/artisan ]; then
    (cd backend && php artisan test --stop-on-failure)
  fi
fi

if [ "$frontend_changed" -eq 1 ]; then
  if ! command -v flutter >/dev/null 2>&1; then
    echo "Flutter SDK is required for frontend pre-push checks." >&2
    exit 1
  fi

  (cd frontend && flutter pub get)

  if [ "${#frontend_dart_targets[@]}" -gt 0 ]; then
    (cd frontend && flutter analyze "${frontend_dart_targets[@]}")
  else
    (cd frontend && flutter analyze)
  fi

  (cd frontend && flutter test)
fi

if command -v docker >/dev/null 2>&1; then
  validate_compose_configs
fi

echo "Pre-push checks passed."
