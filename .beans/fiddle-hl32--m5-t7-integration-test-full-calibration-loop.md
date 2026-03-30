---
# fiddle-hl32
title: 'M5-T7: Integration test — full calibration loop'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:23:24Z
updated_at: 2026-03-30T11:16:16Z
parent: fiddle-fq08
blocked_by:
    - fiddle-88ir
    - fiddle-xafx
    - fiddle-16rn
    - fiddle-rksw
    - fiddle-2evh
    - fiddle-sas3
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m5.md Task 7

Integration test — full calibration loop. Test compound learning across runs.

Files:
- No new permanent files

Steps:
1. Set evaluators.attended: true in orchestrate.json
2. Run evaluation, correct a score — verify correction encoded as calibration anchor
3. Run second evaluation — verify evaluator context includes calibration file with anchor
4. Add antipattern manually — verify both implementer and evaluator receive it
5. Clean up: restore original config


## Evaluation Log
BASE_SHA: b44a339546742cebc7f43f36221cfa5039352c48
total_dispatches: 6

### Iteration 1 (2026-03-30T11:10:44Z)
dispatches: 1
**general:**
- code_quality: 8/10
- correctness: 8/10
- domain_spec_fidelity: 7/10 (FAIL, threshold 8)
**Guidance:** "Update Red Flags line 614 to mention default-path fallback. Commit all changes."

### Iteration 2 (2026-03-30T11:14:35Z)
dispatches: 2
**general:**
- code_quality: 8/10
- correctness: 9/10
- domain_spec_fidelity: 9/10

### Iteration 3 (2026-03-30T11:16:16Z)
dispatches: 3
**general:**
- code_quality: 9/10
- correctness: 9/10
- domain_spec_fidelity: 9/10

## Summary of Changes

Integration test traced 3 flows (attended correction, antipattern, compound loop) and found 4 gaps:
1. append-eval-log.sh: Added missing --corrections parameter
2. develop/SKILL.md step 1f: Added default-path calibration fallback for same-session loop
3. deliver/SKILL.md steps 4b/4c: Added orchestrate.json wiring instructions
4. develop/SKILL.md Red Flags: Updated calibration rule to cover default path
Also cleaned up temp JSON files and added .gitignore patterns.
Converged in 3 iterations (scores: correctness 9, domain_spec_fidelity 9, code_quality 9)
