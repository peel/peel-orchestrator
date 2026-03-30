---
# fiddle-16rn
title: 'M5-T3: Add calibration file loading'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:23:24Z
updated_at: 2026-03-30T10:39:22Z
parent: fiddle-fq08
blocked_by:
    - fiddle-88ir
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m5.md Task 3

Load project-specific calibration files into evaluator prompts alongside domain template.

Files:
- Modify: skills/develop/SKILL.md

Steps:
1. Update evaluator dispatch: check evaluators.domains.<domain>.calibration in config, if exists read file and include in evaluator context after domain template
2. Commit

See parent epic Contracts for Evaluator Context Loading Order.


## Evaluation Log
BASE_SHA: 52df16d7c90c90e6d295da41537ab6422b753c5f
total_dispatches: 3

### Iteration 1 (2026-03-30T10:37:48Z)
dispatches: 1
**general:**
- code_quality: 8/10
- correctness: 9/10
- domain_spec_fidelity: 9/10

### Iteration 2 (2026-03-30T10:39:22Z)
dispatches: 2
**general:**
- code_quality: 8/10
- correctness: 9/10
- domain_spec_fidelity: 9/10

## Summary of Changes

Added calibration file loading to develop/SKILL.md step 1f:
- Explicit 8-item numbered evaluator context loading order matching epic contract
- Calibration file loading at position 3 from evaluators.domains.<domain>.calibration config
- Bidirectional cross-references between step 1f (loading) and step 1i (writing)
- M1 Simplifications updated, Red Flags extended
- Converged in 2 iterations (scores: correctness 9, domain_spec_fidelity 9, code_quality 8)
