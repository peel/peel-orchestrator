---
# fiddle-u6qk
title: 'M3-T6: Integration test — multi-domain + holistic'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:22:17Z
updated_at: 2026-03-30T08:07:59Z
parent: fiddle-3ehs
blocked_by:
    - fiddle-i1x0
    - fiddle-pirt
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m3.md Task 6

Integration test with frontend+backend domains. Verify per-domain evaluation, holistic review, coverage matrix.

Files:
- No new permanent files

Steps:
1. Configure two domains in orchestrate.json (frontend + backend with simple HTTP servers)
2. Create multi-domain test task bean with eval block: domains [frontend, backend]
3. Verify per-domain evaluation: both domains evaluated independently, merge is union
4. Verify holistic review: runs after all tasks, produces coverage matrix, scores holistic dimensions
5. Clean up


## Evaluation Log
BASE_SHA: 6f861a77e5b1cfe97e5ded7dbf58b5d140397a5d
total_dispatches: 3

### Iteration 1 (2026-03-30T08:06:26Z)
dispatches: 1
**general:**
- correctness: 8/10
- domain_spec_fidelity: 8/10
- code_quality: 8/10
**Guidance:** "All 4 verification areas covered. 117 assertions pass."

### Iteration 2 (2026-03-30T08:07:55Z)
dispatches: 2
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "Converged."

## Summary of Changes

Created scripts/test-multi-domain-holistic.sh — 117-assertion integration test covering:
- resolve-domains.sh integration (frontend+backend from config)
- Cross-domain scorecard merge (union semantics, jq command from SKILL.md)
- Holistic review (5 dimensions, thresholds, coverage matrix, remediation beans)
- SKILL.md structural verification (Step 2, references, wiring)
- Domain independence (same dimension scored independently per domain)
- End-to-end flow (resolve → evaluate → merge → check-thresholds)

15 test groups, 117 passed, 0 failed.

Converged after 2 evaluator iterations (1 implementer dispatch).
