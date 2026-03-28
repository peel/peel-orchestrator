#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
VERIFY_CMD="$2"
cd "$WORKTREE"
echo "VERIFIED_AT:$(git rev-parse HEAD) TS:$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .verification-output.txt
eval "$VERIFY_CMD" >> .verification-output.txt 2>&1 && exit 0
exit 1
