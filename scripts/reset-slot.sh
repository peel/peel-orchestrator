#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
cd "$WORKTREE"
git reset --hard "$INTEGRATION"
git clean -fd
