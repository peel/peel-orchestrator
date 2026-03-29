---
# fiddle-2809
title: 'Task 6: Rewrite develop/SKILL.md'
status: completed
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-28T11:12:19Z
updated_at: 2026-03-28T13:16:10Z
parent: fiddle-p0do
blocked_by:
    - fiddle-tzb0
    - fiddle-oexq
---

### Task 6: Rewrite develop/SKILL.md

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Read the current develop/SKILL.md fully**

- [ ] **Step 2: Rewrite with the develop protocol**

Replace the entire content. The new skill has:

**Frontmatter:**
```yaml
---
name: fiddle:develop
description: Run the DEVELOP phase — execute beans via superpowers (subagent-driven or sequential) or swarm mode, with holistic review and deferred finishing.
argument-hint: --epic <id> [--execution subagent|sequential|swarm] [--workers 2]
---
```

**Configuration:** Parse `--epic` (required), `--execution`, `--workers`, `--max-review-cycles` from args. Read `develop {}` from `orchestrate.json`, fall back to `ralph {}`.

**Develop protocol:** Steps 1-8 from the spec, with the dot diagram. Include:
- Step 1: VALIDATE — `beans show {epic-id} --json`, check child beans exist
- Step 2: WORKTREE — `Skill("superpowers:using-git-worktrees")`
- Step 3: EXECUTION CHOICE — hard gate, three options with `--execution` flag support
- Step 4: EXECUTE — delegate to superpowers or swarm, handle needs-attention and context exhaustion re-invocation
- Step 5: HOLISTIC REVIEW — dispatch via `skills/develop-swarm/roles/provider-dispatch.md` procedure. If no providers available, spawn reviewer subagent as fallback. Provide full diff + acceptance criteria. Max cycles from config.
- Step 6: Fix loop — create fix beans, back to step 4
- Step 7: FINISH — `Skill("superpowers:finishing-a-development-branch")`
- Step 8: RETURN — terminal states (merge/PR → deliver, keep → deliver, discard → abort, needs-attention → wait)

**Execution choices:** Three options:
- A: `Skill("superpowers:subagent-driven-development")` — recommended
- B: `Skill("superpowers:executing-plans")` — interactive
- C: `Read("skills/develop-swarm/SKILL.md")` → follow inline — parallel

**Stall detection:** Monitor bean state between execution turns. Read `spawned-at` tags, check elapsed vs `stall_timeout_min`.

**Red flags:** The full list from the spec.

- [ ] **Step 3: Verify no references to old names**

```bash
grep -i "ralph\|develop-subs\|develop-team\|tmux" skills/develop/SKILL.md || echo "Clean"
```

- [ ] **Step 4: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "refactor: rewrite develop skill with protocol + three execution modes

Previously develop had four execution modes including broken ralph-subs
and team variants with separate dispatch mechanisms.

Now develop implements a unified protocol (validate → worktree → execute
→ holistic review → finish) with three modes: subagent-driven
(recommended), sequential (interactive), and swarm (parallel).

Bean: <BEAN_ID>"
```

---
