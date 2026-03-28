---
# fiddle-tr3q
title: Update SKILL.md — replace event log with phase tags
status: completed
type: task
priority: high
tags:
    - worktree
created_at: 2026-03-14T20:35:09Z
updated_at: 2026-03-14T20:43:44Z
parent: fiddle-wtey
blocked_by:
    - fiddle-v3za
---

Plan: docs/plans/2026-03-14-orchestrate-parallel-sessions.md Task 2

Files:
- Modify: skills/orchestrate/SKILL.md

Steps:

1. Remove SETUP "Step 4: Initialize Event Log" section entirely (the mkdir and echo lines).

2. In SETUP Step 5, replace the event log phase write:
   OLD: `echo "PHASE:<phase>" >> .claude/orchestrate-events.log`
   NEW: `beans update <epic-id> --tag orchestrate-phase:<phase>`
   Note: only when epic exists (--epic was provided).

3. In DISCOVER Step 4, replace transition log:
   OLD: echo lines writing to orchestrate-events.log
   NEW: `beans update <epic-id> --remove-tag orchestrate-phase:DISCOVER --tag orchestrate-phase:DEFINE`
   Add note: skip if epic does not yet exist.

4. In DEFINE Step 4, replace transition log:
   OLD: echo lines writing to orchestrate-events.log
   NEW: `beans update <epic-id> --remove-tag orchestrate-phase:DEFINE --tag orchestrate-phase:DEVELOP`

5. In DEVELOP Step 0, remove the execution choice log (echo line).

6. In DEVELOP Step 1, remove the "ralph subagent returned" log block.

7. In DEVELOP Step 2 Case 2, remove the "ralph parked" log block.

8. In DEVELOP Step 4, replace transition:
   OLD: echo lines writing to orchestrate-events.log
   NEW: `beans update <epic-id> --remove-tag orchestrate-phase:DEVELOP --tag orchestrate-phase:DELIVER`

9. In DELIVER Step 3, remove the event log echo line (epic status completed is sufficient).

10. In CLEANUP, replace "Step 2: Remove Event Log" (rm -f line) with:
    "Step 2: Clean Phase Tag"
    `beans update <epic-id> --remove-tag orchestrate-phase:DELIVER`

11. In CLEANUP Step 3 summary, remove the "Total duration" line.

12. Verify: grep -n "orchestrate-events" skills/orchestrate/SKILL.md — expect no matches.

13. Commit:
```bash
git add skills/orchestrate/SKILL.md
git commit -m "refactor: replace orchestrate event log with bean phase tags"
```

Acceptance criteria:
- No references to orchestrate-events.log remain in SKILL.md
- Every phase transition uses beans update --tag/--remove-tag
- CLEANUP no longer deletes event log file
- Renumber SETUP steps (Step 4 removed, so Step 5 becomes Step 4)
