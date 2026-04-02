#!/usr/bin/env bash
# Archive completed/scrapped beans and delivered plan files.
# Moves to ignored directories, removes from git index.
# Usage: archive.sh [--plans-for-epic <epic-id>]
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
ARCHIVE_DIR="$PROJECT_DIR/.archive"
epic_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plans-for-epic) epic_id="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# --- Beans ---
beans archive --json 2>/dev/null
archived_beans=$(find "$PROJECT_DIR/.beans/archive" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

# Remove archived beans from git index (keep locally)
if [[ "$archived_beans" -gt 0 ]]; then
  git rm --cached --quiet "$PROJECT_DIR/.beans/archive/"*.md 2>/dev/null || true
  echo "BEANS_ARCHIVED:$archived_beans"
else
  echo "BEANS_NONE"
fi

# --- Plans ---
if [[ -n "$epic_id" ]]; then
  # Find plan files matching the epic's date/topic pattern
  mkdir -p "$ARCHIVE_DIR/plans"
  plan_count=0

  for plan_dir in "$PROJECT_DIR/docs/plans" "$PROJECT_DIR/docs/superpowers/plans"; do
    if [[ -d "$plan_dir" ]]; then
      for f in "$plan_dir"/*.md; do
        [[ -f "$f" ]] || continue
        mv "$f" "$ARCHIVE_DIR/plans/"
        git rm --cached --quiet "$f" 2>/dev/null || true
        plan_count=$((plan_count + 1))
      done
    fi
  done

  if [[ "$plan_count" -gt 0 ]]; then
    echo "PLANS_ARCHIVED:$plan_count"
  else
    echo "PLANS_NONE"
  fi
else
  echo "PLANS_SKIPPED"
fi
