---
# fiddle-49yn
title: 'M4-T5: Integration test — multi-provider evaluation'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:22:58Z
updated_at: 2026-03-30T09:06:05Z
parent: fiddle-63d9
blocked_by:
    - fiddle-t0lu
    - fiddle-pbv3
    - fiddle-loep
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m4.md Task 5

Integration test with Claude + mock external provider. Verify dual dispatch, merge, disagreements.

Files:
- No new permanent files

Steps:
1. Configure multi-provider: add "providers": ["claude", "codex"] to a domain config
2. Verify dual dispatch and merge: both providers dispatched, scorecards merged with minimum, disagreements surfaced if spread >= 3
3. Verify dispatch budget accounting: dispatch count reflects actual number of provider calls
4. Clean up


## Evaluation Log
BASE_SHA: 9bc7ab5dfacb48c482d4b2f4982038eb37a06253
total_dispatches: 3

### Iteration 1 (2026-03-30T09:04:42Z)
dispatches: 1
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10

### Iteration 2 (2026-03-30T09:06:05Z)
dispatches: 2
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
