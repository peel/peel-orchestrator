#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
cd "$WORKTREE"
git rebase "$INTEGRATION" 2>&1 && exit 0
git diff --name-only --diff-filter=U
exit 1
