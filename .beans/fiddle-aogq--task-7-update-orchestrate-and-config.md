---
# fiddle-aogq
title: 'Task 7: Update orchestrate and config'
status: completed
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-28T11:12:19Z
updated_at: 2026-03-28T13:26:37Z
parent: fiddle-p0do
blocked_by:
    - fiddle-2809
---

### Task 7: Update orchestrate and config

**Files:**
- Modify: `skills/orchestrate/SKILL.md`
- Modify: `orchestrate.json`

- [ ] **Step 1: Update orchestrate/SKILL.md**

1. Remove `--max-total-turns` from CLI flags table (line 30)
2. Update config parsing to read `develop {}` with `ralph {}` fallback
3. Remove `--max-total-turns` from the arg-building block in the DEVELOP section
4. Add `--execution` passthrough if `develop.execution` is set in config
5. Update any references to "Ralph Subs"/"Tmux Team" with new execution mode names

- [ ] **Step 2: Update orchestrate.json**

```json
{
  "providers": { ... },
  "develop": {
    "execution": "subagent",
    "workers": 2,
    "max_review_cycles": 3,
    "max_impl_turns": 50,
    "stall_timeout_min": 15,
    "stall_max_respawns": 2
  },
  "models": {},
  "plans": {}
}
```

Remove the `ralph` key. Move values to `develop`. Remove `max_review_turns`, `max_total_turns`, `ci_max_retries`.

- [ ] **Step 3: Commit**

```bash
git add skills/orchestrate/SKILL.md orchestrate.json
git commit -m "refactor: update orchestrate for develop redesign

Previously orchestrate passed --max-total-turns and read from the ralph
config block.

Now orchestrate reads from develop config (ralph fallback), passes
--execution flag, and no longer references max-total-turns.

Bean: <BEAN_ID>"
```

---
