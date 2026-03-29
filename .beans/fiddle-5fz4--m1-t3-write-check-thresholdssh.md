---
# fiddle-5fz4
title: 'M1-T3: Write check-thresholds.sh'
status: todo
type: task
created_at: 2026-03-29T19:19:32Z
updated_at: 2026-03-29T19:19:32Z
parent: fiddle-yzzk
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 3

Compare scorecard dimensions against thresholds. Return structured PASS/FAIL verdict.
Exit 0 = all pass, 1 = at least one fail, 2 = invalid input.

Files:
- Create: scripts/check-thresholds.sh
- Create: scripts/test-check-thresholds.sh

Input: --scorecard, --config (orchestrate.json), --criteria
Output: JSON verdict with failing_dimensions, failing_criteria, passing_dimensions

Steps:
1. Write test (3 cases: all pass, dim fail, criterion fail)
2. Run test — verify fails
3. Write script
4. Run test — verify passes
5. Commit
