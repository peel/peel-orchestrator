#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
WORKER_BRANCH=$(cd "$WORKTREE" && git rev-parse --abbrev-ref HEAD)
INTEGRATION_DIR=$(git worktree list | grep "$INTEGRATION" | awk '{print $1}')
cd "$INTEGRATION_DIR"
git merge --ff-only "$WORKER_BRANCH" 2>&1 && exit 0
echo "ERROR: Not fast-forwardable. Rebase the worker first."
exit 1
