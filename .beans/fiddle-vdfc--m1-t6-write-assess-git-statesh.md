---
# fiddle-vdfc
title: 'M1-T6: Write assess-git-state.sh'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:20:02Z
updated_at: 2026-03-29T20:03:07Z
parent: fiddle-yzzk
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 6

Classify git state as CLEAN/DIRTY/CORRUPTED relative to a base commit.
Exit 0 = CLEAN, 1 = DIRTY, 2 = CORRUPTED.

Files:
- Create: scripts/assess-git-state.sh
- Create: scripts/test-assess-git-state.sh

Input: --base-sha
Output: JSON with state, head_sha, commits_ahead (or uncommitted_files, or reason)

Steps:
1. Write test (clean state, ahead state)
2. Run test — verify fails
3. Write script
4. Run test — verify passes
5. Commit

## Summary of Changes

Implemented assess-git-state.sh and test-assess-git-state.sh. Classifies git state as CLEAN (exit 0), DIRTY (exit 1), or CORRUPTED (exit 2) relative to a base SHA. 15/15 test assertions passing across 6 test cases. Fixed code review issues: invalid SHA validation, argument guard, robust filename parsing with cut -c4-.
