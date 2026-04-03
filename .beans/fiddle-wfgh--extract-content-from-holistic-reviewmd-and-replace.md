---
# fiddle-wfgh
title: Extract content from holistic-review.md and replace with references
status: completed
type: task
priority: normal
created_at: 2026-04-03T19:03:04Z
updated_at: 2026-04-03T19:14:54Z
parent: fiddle-rwyx
---

Replace dimension scales and output sections in holistic-review.md with references. Target: under 120 lines.

## Files
- Modify: `skills/develop/holistic-review.md`

- [x] Replace dimension scales with reference
- [ ] Replace output sections with reference
- [ ] Verify line count under 120
- [ ] Commit

```eval
domains: [general]
criteria:
  general:
    - id: holistic-line-count
      check: "holistic-review.md is under 120 lines"
    - id: holistic-hard-gate-preserved
      check: "HARD-GATE for runtime interaction remains inline at top"
    - id: holistic-red-flags-preserved
      check: "Red Flags section remains inline at end"
thresholds: {}
```
