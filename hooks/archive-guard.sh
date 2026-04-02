#!/usr/bin/env bash
# PreToolUse hook: reject reads targeting archive directories.
set -euo pipefail

if cat | grep -qE '\.beans/archive|\.archive'; then
  echo "Blocked: archive directories contain stale artifacts."
  exit 2
fi
