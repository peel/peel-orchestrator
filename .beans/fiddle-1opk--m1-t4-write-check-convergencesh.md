---
# fiddle-1opk
title: 'M1-T4: Write check-convergence.sh'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:19:32Z
updated_at: 2026-03-29T19:48:24Z
parent: fiddle-yzzk
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 4

Finding-stability convergence. Two consecutive passing evals with no regressions = converged.
Exit 0 = CONVERGED, 1 = FAIL/PASS_PENDING/PASS_REGRESSED, 2 = DISPATCHES_EXCEEDED.

Files:
- Create: scripts/check-convergence.sh
- Create: scripts/test-check-convergence.sh

Input: --current, --history, --max-dispatches, --current-dispatches
Output: JSON with status field

Steps:
1. Write test (5 cases: first pass, two consecutive, regression, fail, dispatches exceeded)
2. Run test — verify fails
3. Write script
4. Run test — verify passes
5. Commit

## Summary of Changes

Implemented check-convergence.sh and test-check-convergence.sh. Finding-stability convergence: two consecutive passing evaluations with no score regressions = CONVERGED. Five statuses: CONVERGED (exit 0), FAIL/PASS_PENDING/PASS_REGRESSED (exit 1), DISPATCHES_EXCEEDED (exit 2). 10/10 test assertions passing. Improved exit code capture pattern over plan spec.
