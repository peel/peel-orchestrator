---
# fiddle-rksw
title: 'M5-T5: Enrich deliver evolve step'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:23:24Z
updated_at: 2026-03-30T10:55:54Z
parent: fiddle-fq08
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m5.md Task 5

Enrich deliver skill's evolve step to cover evaluator artifact updates.

Files:
- Modify: skills/deliver/SKILL.md

Steps:
1. Add evaluator evolve section after existing evolve/feedback: review scorecards (ask human where evaluator got it wrong), update calibration (add anchors), add antipatterns (from real failures), adjust thresholds (if consistently too strict/lenient), review iteration counts (high counts suggest calibration gaps)
2. Commit

See parent epic Contracts for Evolve Step Outputs.


## Evaluation Log
BASE_SHA: d0774fa18e6633879cfca26fb5d880eb57b0134a
total_dispatches: 6

### Iteration 1 (2026-03-30T10:49:46Z)
dispatches: 1
**general:**
- code_quality: 9/10
- correctness: 9/10
- domain_spec_fidelity: 9/10

### Iteration 2 (2026-03-30T10:52:57Z)
dispatches: 2
**general:**
- code_quality: 9/10
- correctness: 9/10
- domain_spec_fidelity: 8/10
**Guidance:** "Antipattern format in step 4c uses structured multi-line format but plan says 'one line per antipattern with date'. Align with epic contract format."

### Iteration 3 (2026-03-30T10:55:54Z)
dispatches: 3
**general:**
- code_quality: 9/10
- correctness: 9/10
- domain_spec_fidelity: 9/10

## Summary of Changes

Added Evaluator Evolve section (Step 4) to deliver/SKILL.md:
- 4a: Review scorecards — present to human, collect corrections
- 4b: Update calibration — append anchors in epic contract format
- 4c: Add antipatterns — append entries in epic contract format
- 4d: Adjust thresholds — update orchestrate.json if evaluator too strict/lenient
- 4e: Review iteration counts — flag >5 iterations as calibration gaps
- Close Epic renumbered to Step 5 (after evolve completes)
- Converged in 3 iterations (scores: correctness 9, domain_spec_fidelity 9, code_quality 9)
