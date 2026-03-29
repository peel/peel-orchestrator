---
# fiddle-5fz4
title: 'M1-T3: Write check-thresholds.sh'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:19:32Z
updated_at: 2026-03-29T21:01:20Z
parent: fiddle-yzzk
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 3

Compare scorecard dimensions against thresholds. Return structured PASS/FAIL verdict.
Exit 0 = all pass, 1 = at least one fail, 2 = invalid input.

Files:
- Create: scripts/check-thresholds.sh
- Create: scripts/test-check-thresholds.sh

Input: --scorecard, --criteria
Output: JSON verdict with failing_dimensions, failing_criteria, passing_dimensions

Steps:
1. Write test (3 cases: all pass, dim fail, criterion fail)
2. Run test — verify fails
3. Write script
4. Run test — verify passes
5. Commit

## Summary of Changes
Created check-thresholds.sh and test-check-thresholds.sh. 7/7 tests pass. Exit 0=pass, 1=fail, 2=invalid.
