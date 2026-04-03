---
# fiddle-q33c
title: Create develop-loop progressive disclosure reference files
status: completed
type: task
priority: normal
created_at: 2026-04-03T19:02:46Z
updated_at: 2026-04-03T19:07:10Z
parent: fiddle-rwyx
---

Create 4 reference files extracted from develop-loop/SKILL.md: restart-recovery, context-loading-order, scorecard-merge, attended-gate.

## Files
- Create: `skills/develop/develop-loop/restart-recovery.md`
- Create: `skills/develop/develop-loop/context-loading-order.md`
- Create: `skills/develop/develop-loop/scorecard-merge.md`
- Create: `skills/develop/develop-loop/attended-gate.md`

- [x] Create restart-recovery.md
- [ ] Create context-loading-order.md
- [ ] Create scorecard-merge.md
- [ ] Create attended-gate.md
- [ ] Commit

```eval
domains: [general]
criteria:
  general:
    - id: restart-recovery-exists
      check: "restart-recovery.md exists with HARD-GATE and CLEAN/DIRTY/CORRUPTED states"
    - id: context-loading-order-exists
      check: "context-loading-order.md exists with all 8 ordered items"
    - id: scorecard-merge-exists
      check: "scorecard-merge.md exists with provider merge and cross-domain merge sections"
    - id: attended-gate-exists
      check: "attended-gate.md exists with HARD-GATE and calibration anchor encoding"
thresholds: {}
```
