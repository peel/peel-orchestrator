---
# fiddle-w5gv
title: 'Task 3: Update orchestrate DEFINE phase'
status: todo
type: task
priority: high
tags:
    - worktree
created_at: 2026-03-14T18:37:04Z
updated_at: 2026-03-14T18:37:04Z
parent: fiddle-9qn1
---

Plan: docs/plans/2026-03-14-orchestrate-panel-integration.md Task 3

Files:
- Modify: skills/orchestrate/SKILL.md (lines 191-244)

Steps:
1. Read skills/orchestrate/SKILL.md lines 191-244
2. Replace the entire DEFINE section (from ## DEFINE to Fall through to DEVELOP) with simplified 4-step version:
   - Step 1: Brainstorming — Skill("superpowers:brainstorming"). Notes that it includes panel enrichment internally and returns control after design doc.
   - Step 2: Implementation Planning — Skill("superpowers:writing-plans"). Notes that it returns control after bean creation.
   - Step 3: Capture Epic ID — unchanged (beans list --json -t epic -s todo)
   - Step 4: Transition — unchanged (log events)
3. Verify the edit reads correctly
4. Commit

Acceptance criteria:
- DEFINE has 4 steps (no separate panel step)
- Step 1 mentions panel enrichment is internal to brainstorming
- Step 2 mentions orchestrate context detection
