---
# fiddle-4z86
title: 'Task 9: Run patches and smoke test'
status: todo
type: task
priority: normal
created_at: 2026-03-28T11:12:20Z
updated_at: 2026-03-28T11:12:33Z
parent: fiddle-p0do
blocked_by:
    - fiddle-28nz
---

### Task 9: Run patch-superpowers and smoke test

**Files:**
- No new files — validation only

- [ ] **Step 1: Run patch-superpowers**

```bash
# Invoke the updated patch skill to apply all patches
# This patches the cached superpowers skills in-place
```

Use `Skill("fiddle:patch-superpowers")` to apply all patches including the new ones (patches 6-8).

- [ ] **Step 2: Verify patches applied**

```bash
# Check subagent-driven-development is beans-patched
grep "BEANS-PATCHED" ~/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/subagent-driven-development/SKILL.md

# Check executing-plans still beans-patched
grep "BEANS-PATCHED" ~/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/executing-plans/SKILL.md

# Check finishing removed
grep -c "finishing-a-development-branch" ~/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/subagent-driven-development/SKILL.md
# Expected: 0 or only in comments
```

- [ ] **Step 3: Verify develop skill loads**

```bash
# Check the skill is discoverable
