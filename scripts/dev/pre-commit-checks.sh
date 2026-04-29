#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

cd "$ROOT_DIR"
load_env_file "$(local_compose_env_file)"

./scripts/dev/check-staged-secrets.sh

php_files=()
while IFS= read -r file; do
  [ -n "$file" ] && php_files+=("$file")
done < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.php$' || true)

if [ "${#php_files[@]}" -gt 0 ]; then
  for file in "${php_files[@]}"; do
    [ -f "$file" ] || continue
    php -l "$file" >/dev/null
  done
fi

sh_files=()
while IFS= read -r file; do
  [ -n "$file" ] && sh_files+=("$file")
done < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|bash)$|(^|/)(pre-commit|pre-push)$' || true)

if [ "${#sh_files[@]}" -gt 0 ]; then
  for file in "${sh_files[@]}"; do
    [ -f "$file" ] || continue
    bash -n "$file"
  done
fi

dart_files=()
while IFS= read -r file; do
  [ -n "$file" ] && dart_files+=("$file")
done < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.dart$' || true)

if [ "${#dart_files[@]}" -gt 0 ] && command -v dart >/dev/null 2>&1; then
  dart format --output=none --set-exit-if-changed "${dart_files[@]}"
fi

echo "Pre-commit checks passed."
