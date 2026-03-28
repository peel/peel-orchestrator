---
# fiddle-kr74
title: Replace broken progress reporting with crops report + lifecycle hooks
status: completed
type: task
priority: normal
created_at: 2026-03-26T12:07:19Z
updated_at: 2026-03-26T12:13:40Z
---

Remove ## Progress body-append from implementer/review-coordinator roles. Replace timestamp-based stall detection with spawn-epoch tags. Add decision protocol to implementer prompt (crops report decisions). Add PostToolUse hook for automatic progress on git commit. Add SubagentStop gate for decision enforcement. Git-based continuation for respawned agents.


## Summary of Changes

Replaced broken `## Progress` body-append mechanism with three-layer crops report architecture:
1. **Agent contract**: decision protocol in implementer.md with `crops report decisions`
2. **Hook telemetry**: PostToolUse hook auto-reports progress on git commit
3. **SubagentStop gate**: blocks implementer stop if no decisions recorded

Also replaced timestamp-based stall detection with spawn-epoch tags (`spawned-at:EPOCH`).
