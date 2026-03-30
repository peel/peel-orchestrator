---
# fiddle-b3x4
title: 'M2-T5: Write runtime-evidence/SKILL.md'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:21:53Z
updated_at: 2026-03-30T07:10:30Z
parent: fiddle-seov
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m2.md Task 5

Foundational skill providing runtime evidence gathering guidance. Loaded alongside domain template into evaluator context.

Files:
- Create: skills/runtime-evidence/SKILL.md (~80-100 lines)

Steps:
1. Write skill with frontmatter: name: fiddle:runtime-evidence
2. Content: what runtime evidence means (interacting with RUNNING app, not just reading code)
3. HARD-GATE: if runtime configured, MUST interact with app before scoring
4. Evidence gathering: screenshots, HTTP responses, console output, interaction results
5. Evidence format: structured description of what was observed
6. Stack patterns (guidance, not requirements): Flutter (marionette MCP), Go API (curl, go-dev-mcp), Web frontend (browser tools, curl)
7. Failure classification: app failure = evaluation-relevant (Functionality 1-2), harness failure = escalate don't score
8. Verify line count: wc -l — expect 80-100 lines
9. Commit


## Evaluation Log
BASE_SHA: d890ff5aa0ab4cae75b9557099c5711b203ff4d2
total_dispatches: 3

### Iteration 1 (2026-03-30T07:09:30Z)
dispatches: 1
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 9/10
**Guidance:** "PASS_PENDING."

### Iteration 2 (2026-03-30T07:10:26Z)
dispatches: 2
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 9/10
**Guidance:** "CONVERGED."


## Summary of Changes

Created `skills/runtime-evidence/SKILL.md` (99 lines) — foundational skill for runtime evidence gathering.

**Sections:** HARD-GATE (must interact with running app), evidence gathering methods (5 types), evidence format (action/expected/observed/judgment), stack patterns (Flutter/Go API/Web), failure classification (app vs harness).

**Evaluator convergence:** 2 iterations (correctness 9/7, domain spec fidelity 9/8, code quality 9/6).
