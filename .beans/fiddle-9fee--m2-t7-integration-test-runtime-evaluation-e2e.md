---
# fiddle-9fee
title: 'M2-T7: Integration test — runtime evaluation e2e'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:21:53Z
updated_at: 2026-03-30T07:19:38Z
parent: fiddle-seov
blocked_by:
    - fiddle-skbn
    - fiddle-zr8a
    - fiddle-rt3a
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m2.md Task 7

Integration test — runtime evaluation end-to-end. Test full loop with a running app using simple HTTP server.

Files:
- No new permanent files

Steps:
1. Create test config with runtime: temporary orchestrate.json with runtime configured for python3 HTTP server
2. Verify start-runtimes.sh + stop-runtimes.sh lifecycle: start server, verify ready check passes, verify evaluator can curl it, stop it
3. Verify evaluator can interact with running server: dispatch evaluator subagent with runtime-evidence skill loaded, verify it makes HTTP requests and includes results in scorecard evidence
4. Clean up: stop any running processes, restore original config


## Evaluation Log
BASE_SHA: bd86a77ba1e008248deaf23411f7d7bdecf10bb8
total_dispatches: 3

### Iteration 1 (2026-03-30T07:18:13Z)
dispatches: 1
**general:**
- correctness: 10/10
- domain_spec_fidelity: 9/10
- code_quality: 9/10
**Guidance:** "PASS_PENDING."

### Iteration 2 (2026-03-30T07:19:29Z)
dispatches: 2
**general:**
- correctness: 10/10
- domain_spec_fidelity: 9/10
- code_quality: 9/10
**Guidance:** "CONVERGED."


## Summary of Changes

Created `scripts/test-runtime-e2e.sh` — integration test for runtime evaluation e2e.

**Tests (19 assertions, 4 categories):**
1. Full lifecycle: start python3 HTTP server via start-runtimes.sh, curl it (200), stop via stop-runtimes.sh, verify dead
2. Runtime-evidence skill exists with HARD-GATE, Evidence Gathering, Failure Classification
3. Domain templates exist (frontend: Visual Quality/Craft, backend: API Contract Fidelity/Error Handling)
4. Develop SKILL.md references start-runtimes.sh, stop-runtimes.sh, runtime-evidence

**Evaluator convergence:** 2 iterations (correctness 10/7, domain spec fidelity 9/8, code quality 9/6).
