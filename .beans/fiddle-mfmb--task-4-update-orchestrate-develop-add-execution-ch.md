---
# fiddle-mfmb
title: 'Task 4: Update orchestrate DEVELOP — add execution choice'
status: todo
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-14T18:37:14Z
updated_at: 2026-03-14T18:37:14Z
parent: fiddle-9qn1
---

Plan: docs/plans/2026-03-14-orchestrate-panel-integration.md Task 4

Files:
- Modify: skills/orchestrate/SKILL.md (lines 246+)

Steps:
1. Read skills/orchestrate/SKILL.md from ## DEVELOP
2. Insert Step 0 (Execution Choice) between ## DEVELOP heading and ### Step 1: Spawn Ralph Subagent
3. Step 0 presents three options:
   - Ralph Subs (automated, this session) — spawn ralph-subs-implement as background subagent
   - Tmux Team (automated, parallel) — launch ralph-beans-implement with workers in tmux
   - Hands-on (manual) — user implements beans, signals when done, skip to holistic review
4. Wait for user choice, log choice to event log
5. Route: Ralph Subs → Step 1 as normal. Tmux Team → Step 1 with ralph-beans-implement variant. Hands-on → skip to Step 3 (Holistic Review)
6. Verify the section reads correctly
7. Commit

Acceptance criteria:
- DEVELOP has Step 0 before Step 1
- Three execution options listed
- Routing logic for each option documented
