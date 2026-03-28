#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
CHECKLISTS_DIR="${3:-skills/develop-swarm/checklists}"

cd "$WORKTREE"
FILES=$(git diff "$INTEGRATION"...HEAD --name-only 2>/dev/null || true)
[ -z "$FILES" ] && exit 0

DETECTED=""
for ext in $(echo "$FILES" | sed 's/.*\.//' | sort -u); do
  case "$ext" in
    go) [ -f "$CHECKLISTS_DIR/go.md" ] && DETECTED="$DETECTED go" ;;
    ts|svelte) [ -f "$CHECKLISTS_DIR/typescript.md" ] && DETECTED="$DETECTED typescript" ;;
    dart) [ -f "$CHECKLISTS_DIR/dart.md" ] && DETECTED="$DETECTED dart" ;;
  esac
done

echo "$DETECTED" | tr ' ' '\n' | sort -u | grep .
