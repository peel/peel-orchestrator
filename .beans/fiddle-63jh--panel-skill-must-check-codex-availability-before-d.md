---
# fiddle-63jh
title: Panel skill must check Codex availability before degraded mode
status: completed
type: bug
priority: normal
created_at: 2026-03-26T08:18:13Z
updated_at: 2026-03-26T08:24:47Z
---

The panel skill falls back to degraded mode (two Claude subagents) without actually checking if Codex/providers are on PATH. The orchestrate.json reference lacks '(project root)' unlike other skills, and the provider check isn't a mandatory gate step. Fix: make the check a required numbered step with MUST language and explicit failure path.

## Summary of Changes

Fixed `skills/panel/SKILL.md` — restructured the Participants section into a mandatory 3-step Provider Gate:

1. **Step 1**: Read `orchestrate.json (project root)` with the Read tool, with Glob fallback if not at `./orchestrate.json`
2. **Step 2**: Parse providers and run `which` checks via Bash tool (MUST actually run, not guess)
3. **Step 3**: Select full vs degraded mode based on actual results

Key changes:
- Section renamed to "Provider Gate (MUST execute before Phase 1)"
- Added "Do NOT skip to degraded mode without completing them"
- Added "(project root)" to orchestrate.json reference (consistent with other skills)
- Added Glob fallback search before concluding file is missing
- Degraded mode now requires BOTH orchestrate.json missing AND no providers on PATH
- Explicit instruction to run `which` via Bash tool, not assume

### Follow-up: consolidated provider check into dispatch script

Added `--check` mode to `hooks/dispatch-provider.sh` that validates provider config + CLI availability in one call, returning JSON. Updated skill to use `--check` instead of independently parsing orchestrate.json. Single source of truth for provider knowledge is now the dispatch script.
