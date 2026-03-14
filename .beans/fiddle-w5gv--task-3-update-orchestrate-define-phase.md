---
# fiddle-w5gv
title: 'Task 3: Update orchestrate DEFINE phase'
status: todo
type: task
priority: high
tags:
    - worktree
created_at: 2026-03-14T18:37:04Z
updated_at: 2026-03-14T19:02:51Z
parent: fiddle-9qn1
---

Plan: docs/plans/2026-03-14-orchestrate-panel-integration.md Task 3

Files:
- Modify: skills/orchestrate/SKILL.md (DEFINE section, lines 191-244)

Steps:
1. Read skills/orchestrate/SKILL.md lines 191-244
2. Replace the entire DEFINE section with simplified 4-step version:
   - Step 1: Brainstorming — Skill("superpowers:brainstorming", args: "--from-orchestrate"). Notes panel enrichment is internal, --from-orchestrate causes return after design doc.
   - Step 2: Implementation Planning — Skill("superpowers:writing-plans", args: "--from-orchestrate"). Notes --from-orchestrate causes return after bean creation.
   - Step 3: Capture Epic ID — unchanged (beans list --json -t epic -s todo)
   - Step 4: Transition — unchanged (log events)
3. Verify the edit reads correctly
4. Commit

Acceptance criteria:
- DEFINE has 4 steps (no separate panel step)
- Both skill calls pass --from-orchestrate flag
- Step 1 mentions panel enrichment is internal to brainstorming
