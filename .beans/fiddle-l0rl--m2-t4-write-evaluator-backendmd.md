---
# fiddle-l0rl
title: 'M2-T4: Write evaluator-backend.md'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:21:53Z
updated_at: 2026-03-30T07:06:27Z
parent: fiddle-seov
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m2.md Task 4
Design: docs/superpowers/specs/2026-03-29-calibrated-evaluator-system-design.md lines 173-247

Go API-focused backend evaluator template with full 1-10 scales.

Files:
- Create: skills/evaluate/evaluator-backend.md (~150-180 lines)

Steps:
1. Write evaluator-backend.md with full 1-10 scales from design spec for all four dimensions: Correctness (threshold 7), API Contract Fidelity (threshold 7), Error Handling (threshold 7), Domain Spec Fidelity (threshold 8)
2. Add Runtime Interaction section: start server, hit API endpoints, use curl/httpie for HTTP verification, check response shapes/status codes/headers, test error paths, verify database state if applicable
3. Verify line count: wc -l skills/evaluate/evaluator-backend.md — expect ~150-180 lines
4. Commit

Reference: existing skills/evaluate/evaluator-general.md for format conventions.


## Evaluation Log
BASE_SHA: 80ae0998c409829b51b0c99592425d6e3ce56fd1
total_dispatches: 3

### Iteration 1 (2026-03-30T07:05:21Z)
dispatches: 1
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "PASS_PENDING — need consecutive pass."

### Iteration 2 (2026-03-30T07:06:24Z)
dispatches: 2
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "CONVERGED."


## Summary of Changes

Created `skills/evaluate/evaluator-backend.md` (157 lines) — Go API-focused backend evaluator template.

**Dimensions:** Correctness (threshold 7), API Contract Fidelity (threshold 7), Error Handling (threshold 7), Domain Spec Fidelity (threshold 8) — all with complete 1-10 scales.

**Runtime Interaction section:** Launch, MCP tools (go-dev-mcp, curl), evidence gathering, what to check.

**Evaluator convergence:** 2 iterations (correctness 9/7, domain spec fidelity 9/8, code quality 8/6).
