---
# fiddle-lxqf
title: Extract shared ralph loop into ralph-core.md
status: completed
type: task
priority: high
created_at: 2026-03-25T21:22:09Z
updated_at: 2026-03-25T21:36:19Z
---

Extract the ~90% shared logic between develop-subs and develop-team into a roles/ralph-core.md. Each variant becomes a thin wrapper specifying: setup differences (TeamCreate for team), spawn mechanism (Agent vs Agent+team_name), and event handling (TaskOutput vs SendMessage). Move reaction checks (CI escalation, stall detection, review overflow) to ralph-core so both variants benefit. Target: ~180 shared lines, ~40 per variant.

## Summary of Changes

Extracted shared ralph loop logic into `skills/ralph/ralph-core.md` and consolidated duplicate role files into `skills/ralph/roles/`. Both develop-subs and develop-team SKILL.md files are now thin wrappers (~75 lines each) that reference the shared core for configuration, setup, assess-and-act loop, result handling, and spawning. Role templates use `<!-- VARIANT:subs -->` / `<!-- VARIANT:team -->` conditional markers. Provider dispatch/context files moved to shared location. All active references updated. Reaction checks (CI escalation, stall detection, review overflow) now available to both variants. ~350 lines of duplication eliminated (1,241 → 888 lines, 12 → 9 files).
