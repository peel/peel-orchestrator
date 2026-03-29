#!/usr/bin/env bash
# PostToolUse hook: auto-report progress on git commit via crops report
set -euo pipefail

INPUT=$(cat)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // ""')

# Only fire on git commit commands
echo "$TOOL_INPUT" | grep -qE 'git commit' || exit 0

# Extract bean ID from commit message (format: "bean-id: description")
BEAN_ID=$(git log -1 --format='%s' 2>/dev/null | grep -oE '^[a-z]+-[a-z0-9]+' || true)
[ -z "$BEAN_ID" ] && exit 0

# Derive beans path from CWD (walk up to find .beans.yml)
_d="$PWD"; BEANS_DIR=""
while [ "$_d" != "/" ]; do
  [ -f "$_d/.beans.yml" ] && BEANS_DIR="$_d/.beans" && break
  _d="$(dirname "$_d")"
done
[ -z "$BEANS_DIR" ] && exit 0

# Verify it's a real bean
beans --beans-path "$BEANS_DIR" show "$BEAN_ID" --json >/dev/null 2>&1 || exit 0

SUMMARY=$(git log -1 --format='%s' 2>/dev/null)
FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | tr '\n' ',' | sed 's/,$//')

crops report progress "$BEAN_ID" \
  --status "in-progress" \
  --summary "$SUMMARY" \
  --files-changed "$FILES" 2>/dev/null || true
