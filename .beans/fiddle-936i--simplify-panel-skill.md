---
# fiddle-936i
title: Simplify panel skill
status: completed
type: task
priority: normal
created_at: 2026-03-25T21:22:15Z
updated_at: 2026-03-25T21:53:34Z
---

Reduce panel internal complexity while keeping multi-provider debate core. Three changes: (1) Eliminate degraded mode duplication — one code path where provider list includes claude-subagents when no externals available. (2) Default cross-review rounds to 1 (positions + single cross-review + synthesis), keep --rounds flag for extended debate. (3) Remove anti-rationalization checks — simpler skill won't need them. Target: ~200 lines to ~120.

## Summary of Changes

Simplified panel skill from 200 to 156 lines:
1. Unified full/degraded modes into single flow via participants table — one protocol section instead of duplicated Phase 1/Phase 2 blocks per mode
2. Changed default rounds from 2 to 1 (positions + single cross-review + synthesis)
3. Removed 5-item anti-rationalization checks section
4. Collapsed Majority/No-consensus output sections into single Disagreement section that works for any participant count
