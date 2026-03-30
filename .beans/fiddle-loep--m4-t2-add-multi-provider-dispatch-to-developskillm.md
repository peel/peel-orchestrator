---
# fiddle-loep
title: 'M4-T2: Add multi-provider dispatch to develop/SKILL.md'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:22:58Z
updated_at: 2026-03-30T08:45:32Z
parent: fiddle-63d9
blocked_by:
    - fiddle-a6vv
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m4.md Task 2

Dispatch evaluators per provider for each domain. Merge before threshold check.

Files:
- Modify: skills/develop/SKILL.md
- Modify: skills/develop/provider-context.md

Steps:
1. Add per-provider dispatch: read providers array from domain config (default ["claude"]), claude via Agent, external via hooks/dispatch-provider.sh
2. Add merge HARD-GATE: after all provider scorecards collected, must run merge-scorecards.sh
3. Update dispatch budget tracking: each provider dispatch = 1 toward budget, append-eval-log --dispatches must reflect actual count
4. Update provider-context.md: add scorecard JSON schema requirements, demand valid JSON scorecard as last content block
5. Commit

See parent epic Contracts for Provider Dispatch and Dispatch Budget.


## Evaluation Log
BASE_SHA: 37275ff056ff77a79f9db530f2389bd7d03c194b
total_dispatches: 3

### Iteration 1 (2026-03-30T08:44:11Z)
dispatches: 1
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10

### Iteration 2 (2026-03-30T08:45:32Z)
dispatches: 2
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
