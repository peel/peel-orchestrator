---
# fiddle-5czr
title: 'M1-T14: Integration test — evaluator loop end-to-end'
status: todo
type: task
priority: normal
created_at: 2026-03-29T19:20:46Z
updated_at: 2026-03-29T19:21:05Z
parent: fiddle-yzzk
blocked_by:
    - fiddle-6qy2
    - fiddle-lxcf
    - fiddle-4xxg
    - fiddle-vgig
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 14

Verify the full pipeline works: create test bean, run scripts together, verify convergence, verify restart recovery.

No new files — verification only.

Steps:
1. Create test task bean with eval block
2. Verify scripts work together (init log, fail scorecard, check thresholds, check convergence, append log, pass scorecard, converge)
3. Verify restart recovery (parse-eval-log + assess-git-state)
4. Clean up test bean
