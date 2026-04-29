#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/dev/git-autopush.sh --message "feat: update README" [--all] [--dry-run] [--remote origin] [--branch main] [files...]

Examples:
  ./scripts/dev/git-autopush.sh --message "docs: update README" README.md
  ./scripts/dev/git-autopush.sh --message "chore: sync local tooling" --all
  ./scripts/dev/git-autopush.sh --message "docs: test push flow" --dry-run README.md

Notes:
  - Runs normal git commit/push, so pre-commit and pre-push hooks stay active.
  - Use --all to stage everything. Otherwise pass the files you want to stage.
EOF
}

MESSAGE=""
REMOTE="origin"
BRANCH="$(git branch --show-current)"
DRY_RUN=0
STAGE_ALL=0
FILES=()

while [ $# -gt 0 ]; do
  case "$1" in
    -m|--message)
      shift
      [ $# -gt 0 ] || { echo "Missing value for --message" >&2; exit 1; }
      MESSAGE="$1"
      ;;
    -r|--remote)
      shift
      [ $# -gt 0 ] || { echo "Missing value for --remote" >&2; exit 1; }
      REMOTE="$1"
      ;;
    -b|--branch)
      shift
      [ $# -gt 0 ] || { echo "Missing value for --branch" >&2; exit 1; }
      BRANCH="$1"
      ;;
    --all)
      STAGE_ALL=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        FILES+=("$1")
        shift
      done
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      FILES+=("$1")
      ;;
  esac
  shift
done

if [ -z "$MESSAGE" ]; then
  echo "A commit message is required." >&2
  usage >&2
  exit 1
fi

if [ -z "$BRANCH" ]; then
  echo "No current branch detected. Checkout a branch before autopush." >&2
  exit 1
fi

if [ "$STAGE_ALL" -eq 1 ]; then
  git add -A
else
  if [ "${#FILES[@]}" -eq 0 ]; then
    echo "Specify one or more files to stage, or use --all." >&2
    exit 1
  fi
  git add -- "${FILES[@]}"
fi

if git diff --cached --quiet; then
  echo "No staged changes to commit." >&2
  exit 1
fi

git commit -m "$MESSAGE"

if [ "$DRY_RUN" -eq 1 ]; then
  git push --dry-run "$REMOTE" "HEAD:$BRANCH"
else
  git push "$REMOTE" "HEAD:$BRANCH"
fi

echo "Autopush completed on $REMOTE/$BRANCH."
