---
# fiddle-bof6
title: Add fiddle:insights skill — synthesize feedback into planning context
status: completed
type: feature
priority: normal
created_at: 2026-04-01T20:41:08Z
updated_at: 2026-04-01T21:14:48Z
blocked_by:
    - fiddle-tfoh
---

New skill that synthesizes structured feedback entries into insight summaries and persona updates. Discover and brainstorm phases explicitly load and reference these artifacts during planning. Three pieces: synthesis logic, discover-phase consumption, brainstorm-phase consumption. Without the consume side, capture doesn't compound.

## Checklist

- [x] RED: Baseline test — ask agent to synthesize feedback without skill, document output
- [x] GREEN: Write fiddle:insights skill
- [x] GREEN: Verify agent produces structured insights and personas
- [x] GREEN: Update discover and brainstorm skills to consume insights
- [x] REFACTOR: Close loopholes, edge cases
- [x] Commit (pending)

## Summary of Changes

Created fiddle:insights skill that synthesizes structured feedback into standalone persona files (docs/product/personas/) and periodic insight summaries (docs/product/insights/). Includes signal strength thresholds, persona merge/split guidance, cross-referencing with product docs, and new-vs-recurring tracking. Updated discover phase to load personas and insights as research context. Updated brainstorm phase to reference insights when exploring approaches and evaluating tradeoffs.
