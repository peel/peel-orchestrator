---
# fiddle-28nz
title: 'Task 8: Update docs, create ADR, delete old files'
status: todo
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-28T11:12:19Z
updated_at: 2026-03-28T11:12:33Z
parent: fiddle-p0do
blocked_by:
    - fiddle-aogq
---

### Task 8: Update docs, create ADR, delete old files

**Files:**
- Modify: `docs/technical/SYSTEM.md`
- Create: `docs/technical/decisions/004-develop-redesign.md`
- Delete: `skills/develop-subs/`
- Delete: `skills/develop-team/`
- Delete: `skills/ralph/`

- [ ] **Step 1: Update SYSTEM.md**

Update the component descriptions:
- **Develop** — rewrite to describe the new protocol + three execution modes
- **Swarm** — new entry describing `develop-swarm/SKILL.md`
- Remove references to `develop-subs`, `develop-team`, `ralph-core.md`, review coordinator

- [ ] **Step 2: Create ADR 004**

```markdown
# 004 — Develop phase redesign: superpowers composition with swarm option

**Date:** 2026-03-28
**Status:** accepted
**Supersedes:** 001, 002

## Context

The develop phase had three problems: subagent nesting (coordinator → reviewer)
broke in practice, merge conflicts deferred to cleanup, and two variants
(develop-subs/develop-team) duplicated logic.

## Decision

Replace with a unified develop protocol that composes superpowers skills
(subagent-driven-development, executing-plans) with beans-based state tracking,
holistic review, and deferred finishing. A separate swarm mode provides parallel
worktree-per-bean execution for large epics.

## Consequences

- One develop entry point instead of three (develop + develop-subs + develop-team)
- No subagent nesting — swarm uses flat subagents with inline review pipeline
- Incremental rebase-before-review merge replaces deferred batch merge
- Superpowers skills patched to skip finishing (develop owns the lifecycle)
- Three execution choices: subagent-driven (recommended), sequential, swarm
```

- [ ] **Step 3: Delete old skill directories**

```bash
rm -rf skills/develop-subs/
rm -rf skills/develop-team/
rm -rf skills/ralph/
```

- [ ] **Step 4: Verify no dangling references**

```bash
grep -r "develop-subs\|develop-team\|skills/ralph/\|review-coordinator" skills/ hooks/ docs/ orchestrate.json | grep -v ".beans/" || echo "Clean"
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: delete old develop variants and update docs

Previously skills/develop-subs/, skills/develop-team/, and skills/ralph/
provided two parallel execution variants with shared ralph-core logic.

Now these are replaced by develop-swarm/ (parallel) and superpowers
composition (sequential). ADR 003 documents the decision.

Bean: <BEAN_ID>"
```

---
