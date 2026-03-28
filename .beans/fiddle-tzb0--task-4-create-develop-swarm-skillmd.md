---
# fiddle-tzb0
title: 'Task 4: Create develop-swarm SKILL.md'
status: todo
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-28T11:12:19Z
updated_at: 2026-03-28T11:12:33Z
parent: fiddle-p0do
blocked_by:
    - fiddle-pg14
    - fiddle-ph6c
    - fiddle-crh0
---

### Task 4: Create develop-swarm/SKILL.md

**Files:**
- Create: `skills/develop-swarm/SKILL.md`

- [ ] **Step 1: Write the skill file**

The SKILL.md contains:
- Frontmatter: `name: fiddle:develop-swarm`, `description`, `disable-model-invocation: true`, `argument-hint`
- Configuration section (parse flags from args)
- Setup section (compute MAIN_BEANS_PATH, worker slot setup, verify-cmd discovery)
- Orchestration loop (assess-and-act): SCAN → REACTION CHECKS → FEATURE EXPANSION → DISPATCH → PROCESS RESULTS → COMPLETION
- Per-bean lifecycle (steps 1-9 with script calls)
- Coupling Detection Protocol (three-layer: dependency → path overlap → clash)
- Swarm restart rules
- Bean tag schema reference
- Red flags

Source all content from the spec's "Swarm Mode" section. The skill is read inline by develop/SKILL.md — it is NOT invoked via Skill().

- [ ] **Step 2: Verify references**

```bash
# Check all script references exist
grep "scripts/" skills/develop-swarm/SKILL.md | while read line; do
  script=$(echo "$line" | grep -o 'scripts/[a-z-]*.sh')
  [ -f "$script" ] && echo "OK: $script" || echo "MISSING: $script"
done

# Check role references
grep "roles/" skills/develop-swarm/SKILL.md | while read line; do
  role=$(echo "$line" | grep -o 'roles/[a-z-]*.md')
  [ -f "skills/develop-swarm/$role" ] && echo "OK: $role" || echo "MISSING: $role"
done
```

- [ ] **Step 3: Commit**

```bash
git add skills/develop-swarm/SKILL.md
git commit -m "feat: create develop-swarm orchestration skill

Previously parallel execution used develop-subs (broken nesting)
or develop-team (team variant) with shared ralph-core.

Now develop-swarm provides a single orchestration loop with flat
subagents, incremental rebase-before-review merge, coupling detection,
and durable restart via bean tags.

Bean: <BEAN_ID>"
```

---
