---
# fiddle-pg14
title: 'Task 1: Create helper scripts'
status: todo
type: task
tags:
    - worktree
created_at: 2026-03-28T11:12:19Z
updated_at: 2026-03-28T11:12:19Z
parent: fiddle-p0do
---

### Task 1: Create helper scripts for swarm git operations

**Files:**
- Create: `scripts/rebase-worker.sh`
- Create: `scripts/merge-to-integration.sh`
- Create: `scripts/detect-reviewers.sh`
- Create: `scripts/reset-slot.sh`
- Create: `scripts/post-rebase-verify.sh`

- [ ] **Step 1: Create `scripts/rebase-worker.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
cd "$WORKTREE"
git rebase "$INTEGRATION" 2>&1 && exit 0
# Rebase failed — list conflicting files
git diff --name-only --diff-filter=U
exit 1
```

`chmod +x scripts/rebase-worker.sh`

- [ ] **Step 2: Create `scripts/merge-to-integration.sh`**

```bash
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
```

`chmod +x scripts/merge-to-integration.sh`

- [ ] **Step 3: Create `scripts/detect-reviewers.sh`**

```bash
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
```

`chmod +x scripts/detect-reviewers.sh`

- [ ] **Step 4: Create `scripts/reset-slot.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
cd "$WORKTREE"
git reset --hard "$INTEGRATION"
git clean -fd
```

`chmod +x scripts/reset-slot.sh`

- [ ] **Step 5: Create `scripts/post-rebase-verify.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
VERIFY_CMD="$2"
cd "$WORKTREE"
echo "VERIFIED_AT:$(git rev-parse HEAD) TS:$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .verification-output.txt
eval "$VERIFY_CMD" >> .verification-output.txt 2>&1 && exit 0
exit 1
```

`chmod +x scripts/post-rebase-verify.sh`

- [ ] **Step 6: Test each script manually**

```bash
# Verify all scripts are executable
ls -la scripts/*.sh
# Verify syntax
bash -n scripts/rebase-worker.sh
bash -n scripts/merge-to-integration.sh
bash -n scripts/detect-reviewers.sh
bash -n scripts/reset-slot.sh
bash -n scripts/post-rebase-verify.sh
```

- [ ] **Step 7: Commit**

```bash
git add scripts/
git commit -m "feat: add helper scripts for swarm git operations

Previously git operations for rebase, merge, reviewer detection,
slot reset, and verification were inline agent commands prone to error.

Now five deterministic shell scripts handle these operations with
explicit exit codes and structured output.

Bean: <BEAN_ID>"
```

---
