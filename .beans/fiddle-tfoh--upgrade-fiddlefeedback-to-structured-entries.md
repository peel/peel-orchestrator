---
# fiddle-tfoh
title: Upgrade fiddle:feedback to structured entries
status: completed
type: feature
priority: normal
created_at: 2026-04-01T20:41:06Z
updated_at: 2026-04-01T21:14:48Z
---

Replace append-only raw text with structured feedback entries: participant context, observation, implication, confidence level. Shared schema across projects, project-specific content. Opt-in — projects that don't need it just don't use the skill.

## Checklist

- [x] RED: Baseline test — run feedback scenario without upgrade, document output
- [x] GREEN: Write upgraded skill with structured entries
- [x] GREEN: Verify agent produces structured output
- [x] REFACTOR: Close loopholes, edge cases
- [x] Update docs/README.md and docs/product/FEEDBACK.md template
- [x] Commit (pending)

## Summary of Changes

Upgraded fiddle:feedback from raw append-only text to structured entries with Who, Context, Observation, Implication, and Confidence fields. Added multi-actor handling (one entry per actor with shared observation title). Updated FEEDBACK.md template to reflect the new format.
