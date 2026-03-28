---
# fiddle-kl3e
title: Provider dispatch shell script
status: completed
type: task
priority: high
created_at: 2026-03-25T21:22:12Z
updated_at: 2026-03-25T21:51:12Z
blocked_by:
    - fiddle-lxqf
---

Replace the 96-line provider-dispatch.md LLM ceremony with a dispatch-provider.sh script. Script takes provider name + role/topic/instructions/optional fields, handles: read orchestrate.conf, find provider command/flags, read provider-context.md template, substitute placeholders, strip empties, pipe to provider CLI. LLM reduces to one Bash(run_in_background) call per provider. Address HCL parsing (options: small parser, convert to YAML, or pass command/flags explicitly).

## Summary of Changes

- Converted `orchestrate.conf` (HCL) → `orchestrate.json` (JSON) for native `jq` parsing
- Created `hooks/dispatch-provider.sh` — handles config lookup, template substitution, empty section stripping, and provider execution in one command
- Simplified `provider-dispatch.md` from 96-line LLM ceremony to dispatch script reference + collection rules
- Updated all 11 skill files to reference `orchestrate.json`
- Updated all 4 phase skills (discover, define/panel, develop, deliver) to use `hooks/dispatch-provider.sh` instead of manual template filling
- Updated `session-start-check-providers.sh` to parse JSON via `jq`
- Removed `provider-context.md` references from callers (script handles template internally)
- Smoke tested: script correctly dispatches to codex end-to-end
