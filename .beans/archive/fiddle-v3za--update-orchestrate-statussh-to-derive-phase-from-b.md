---
# fiddle-v3za
title: Update orchestrate-status.sh to derive phase from beans
status: completed
type: task
priority: high
tags:
    - worktree
created_at: 2026-03-14T20:34:53Z
updated_at: 2026-03-14T20:41:07Z
parent: fiddle-wtey
---

Plan: docs/plans/2026-03-14-orchestrate-parallel-sessions.md Task 1

Files:
- Modify: scripts/orchestrate-status.sh

Steps:

1. Replace get_phase() function (lines 19-25) to read orchestrate-phase tag from epic bean:

```bash
get_phase() {
  local tags
  tags=$(beans show "$EPIC_ID" --json 2>/dev/null | jq -r '(.tags // [])[]' 2>/dev/null)
  local phase
  phase=$(echo "$tags" | grep '^orchestrate-phase:' | tail -1 | cut -d: -f2)
  if [[ -n "$phase" ]]; then
    echo "$phase"
  else
    echo "SETUP"
  fi
}
```

2. Remove event log tail display block (lines 170-174) — the section that reads EVENT_LOG and displays recent events.

3. Remove unused variables EVENT_LOG (line 6) and EVENT_TAIL_LINES (line 7).

4. Verify syntax: `bash -n scripts/orchestrate-status.sh` — expect no output.

5. Commit:
```bash
git add scripts/orchestrate-status.sh
git commit -m "refactor: derive orchestrate phase from bean tag instead of event log"
```

Acceptance criteria:
- get_phase reads orchestrate-phase:* tag from epic bean
- No references to EVENT_LOG or orchestrate-events.log remain in the script
- Script passes bash -n syntax check
