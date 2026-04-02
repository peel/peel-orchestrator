#!/usr/bin/env bash
# Scaffold a project for use with fiddle.
# Usage: init.sh [target-dir]
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
TARGET="${1:-.}"
PREFIX="$(basename "$(cd "$TARGET" && pwd)" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"

# --- Docs ---
if [[ -d "$TARGET/docs" ]] && [[ -n "$(ls -A "$TARGET/docs" 2>/dev/null)" ]]; then
  echo "DOCS_EXISTS"
else
  cp -r "$PLUGIN_ROOT/.docs/" "$TARGET/docs/"
  find "$TARGET/docs" -name .DS_Store -delete 2>/dev/null || true
  echo "DOCS_CREATED"
fi

# --- orchestrate.json ---
if [[ -f "$TARGET/orchestrate.json" ]]; then
  echo "ORCHESTRATE_EXISTS"
else
  cp "$PLUGIN_ROOT/orchestrate.json" "$TARGET/orchestrate.json"
  echo "ORCHESTRATE_CREATED"
fi

# --- Beans ---
if [[ -f "$TARGET/.beans.yml" ]]; then
  echo "BEANS_EXISTS"
else
  cd "$TARGET" && beans init --prefix "${PREFIX}-"
  echo "BEANS_CREATED:${PREFIX}"
fi
