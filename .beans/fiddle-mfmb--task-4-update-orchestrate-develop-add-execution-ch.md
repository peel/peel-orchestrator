---
# fiddle-mfmb
title: 'Task 4: Update orchestrate DEVELOP — add execution choice'
status: todo
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-14T18:37:14Z
updated_at: 2026-03-14T19:03:01Z
parent: fiddle-9qn1
---

Plan: docs/plans/2026-03-14-orchestrate-panel-integration.md Task 4

Files:
- Modify: skills/orchestrate/SKILL.md (DEVELOP section + Configuration section)

Steps:
1. Read skills/orchestrate/SKILL.md from ## DEVELOP
2. Insert Step 0 (Execution Choice) between ## DEVELOP and ### Step 1: Spawn Ralph Subagent
3. Step 0 checks orchestrate.conf for develop.execution setting first, falls back to interactive prompt:
   - Ralph Subs (automated, this session) — spawn ralph-subs-implement as background subagent
   - Tmux Team (automated, parallel) — launch ralph-beans-implement with workers in tmux
   - Hands-on (manual) — user implements beans, signals when done, skip to holistic review
4. Wait for user choice (or use config value), log choice to event log
5. Route: Ralph Subs -> Step 1 as normal. Tmux Team -> Step 1 with ralph-beans-implement. Hands-on -> skip to Step 3 (Holistic Review)
6. Update Config File section HCL example to include develop { execution = "ralph-subs" }
7. Verify the section reads correctly
8. Commit

Acceptance criteria:
- DEVELOP has Step 0 before Step 1
- Three execution options with config override
- Config file section documents develop.execution
- Routing logic for each option documented
