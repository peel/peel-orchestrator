---
# fiddle-xafx
title: 'M5-T2: Add antipattern loading and checking'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:23:24Z
updated_at: 2026-03-30T10:33:49Z
parent: fiddle-fq08
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m5.md Task 2

Load antipattern files into implementer and evaluator prompts. Evaluator checks for known antipatterns.

Files:
- Modify: skills/develop/SKILL.md
- Modify: skills/develop/implementer-prompt.md
- Modify: skills/evaluate/SKILL.md

Steps:
1. Update implementer-prompt.md: add "Known Antipatterns — Avoid These" section with {ANTIPATTERNS} placeholder
2. Update evaluate/SKILL.md: add antipattern check section — check each antipattern against implementation, report in scorecard antipatterns_detected, any detected = task fail
3. Update develop/SKILL.md: read antipatterns file from domain config, pass content to both implementer and evaluator prompts
4. Commit

See parent epic Contracts for Antipattern File Format.


## Evaluation Log
BASE_SHA: d6e63904ea0c5b53a217ab790136f37b17a78b03
total_dispatches: 3

### Iteration 1 (2026-03-30T10:32:32Z)
dispatches: 1
**general:**
- code_quality: 8/10
- correctness: 9/10
- domain_spec_fidelity: 9/10

### Iteration 2 (2026-03-30T10:33:49Z)
dispatches: 2
**general:**
- code_quality: 8/10
- correctness: 9/10
- domain_spec_fidelity: 9/10

## Summary of Changes

Added antipattern loading and checking across three files:
- implementer-prompt.md: Enhanced Known Antipatterns section with 'real failures from prior runs' instruction
- evaluate/SKILL.md: Added {ANTIPATTERNS} placeholder and 'grounds for failing' enforcement rule
- develop/SKILL.md: Added antipattern file loading from evaluators.domains.<domain>.antipatterns config, injection into both implementer and evaluator prompts
- M1 Simplifications updated (No antipatterns struck through)
- Converged in 2 iterations (scores: correctness 9, domain_spec_fidelity 9, code_quality 8)
