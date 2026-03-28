---
# fiddle-crh0
title: 'Task 3: Move checklists and create lead-procedures'
status: todo
type: task
tags:
    - worktree
created_at: 2026-03-28T11:12:19Z
updated_at: 2026-03-28T11:12:19Z
parent: fiddle-p0do
---

### Task 3: Move checklists and create lead-procedures

**Files:**
- Create: `skills/develop-swarm/checklists/go.md` (copy from `skills/ralph/checklists/go.md`)
- Create: `skills/develop-swarm/checklists/typescript.md` (copy)
- Create: `skills/develop-swarm/checklists/dart.md` (copy)
- Create: `skills/develop-swarm/roles/lead-procedures.md`

- [ ] **Step 1: Copy checklists and provider templates**

```bash
mkdir -p skills/develop-swarm/checklists
mkdir -p skills/develop-swarm/roles
cp skills/ralph/checklists/*.md skills/develop-swarm/checklists/
cp skills/ralph/roles/provider-dispatch.md skills/develop-swarm/roles/
cp skills/ralph/roles/provider-context.md skills/develop-swarm/roles/
```

Provider-dispatch and provider-context are used by the holistic review (develop protocol step 5) and the swarm review pipeline. They must be relocated before deleting `skills/ralph/`.

- [ ] **Step 2: Create `skills/develop-swarm/roles/lead-procedures.md`**

Write the new lead-procedures with three procedures: Review Pipeline, Conflict Resolution, and Cleanup. Source content from the spec sections.

**Review Pipeline** — from spec "Review Pipeline" section. Steps 1-5 with explicit tool calls.

**Conflict Resolution** — from spec "Conflict Resolution" section. Five-step git-based procedure.

**Cleanup** — simplified from current lead-procedures.md:
1. Stop running background tasks
2. Remove worker worktrees and scratch branches
3. Hand integration branch to develop protocol step 7

Remove from current lead-procedures.md:
- Lead Verification (replaced by implementer-written verification + post-rebase-verify.sh)
- Worktree Setup (develop protocol owns this via using-git-worktrees)
- Epic Holistic Review (moved to develop protocol step 5)
- `branch`-tag handling
- Batch merge from Cleanup

**Abandon Bean** — keep as-is from current lead-procedures.md.

**Token Optimization** — keep as-is, update path references from `skills/ralph/` to `skills/develop-swarm/`.

- [ ] **Step 3: Verify no stale references**

```bash
grep -r "skills/ralph/" skills/develop-swarm/ || echo "Clean"
grep -r "review-coordinator" skills/develop-swarm/ || echo "Clean"
```

- [ ] **Step 4: Commit**

```bash
git add skills/develop-swarm/
git commit -m "feat: add checklists and lead-procedures for develop-swarm

Previously checklists and procedures lived in skills/ralph/ with
variant-specific sections and batch-merge cleanup.

Now develop-swarm has clean checklists, Review Pipeline procedure
replacing the coordinator, Conflict Resolution procedure, and
simplified Cleanup without batch merge.

Bean: <BEAN_ID>"
```

---
