---
# fiddle-fq08
title: 'M5: Calibration + Evolve'
status: todo
type: epic
priority: normal
created_at: 2026-03-29T19:17:56Z
updated_at: 2026-03-30T06:34:51Z
blocked_by:
    - fiddle-63d9
---

The compound learning loop — attended mode refines evaluator calibration through human corrections, antipatterns accumulate from real failures, the evolve step encodes improvements for future runs. Attended mode shows scorecards to human before acting. Corrections become calibration anchors in project-specific files. Antipattern files loaded by implementer and evaluator.

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m5.md
Design: docs/superpowers/specs/2026-03-29-calibrated-evaluator-system-design.md
Depends on: M4 (fiddle-63d9)

## Contracts

### Calibration File Format (docs/evaluator-calibration-<domain>.md)
```markdown
## [dimension] — Correction (YYYY-MM-DD)
**Evaluator scored:** X/10 — "[evaluator evidence]"
**Human corrected to:** Y/10 — "[human reason]"
**Anchor:** For this project, score Y means: [human's description]
```
Config: evaluators.domains.<domain>.calibration in orchestrate.json

### Antipattern File Format (docs/antipatterns-<domain>.md)
One antipattern per entry:
```markdown
## [antipattern-id] (YYYY-MM-DD)
**Pattern:** What the failure looks like
**Example:** Concrete code/behavior from prior run
**Fix:** How to avoid it
```
Config: evaluators.domains.<domain>.antipatterns in orchestrate.json

### Attended Gate Protocol
1. Show merged scorecard to human (highlight below-threshold, disagreements)
2. Human confirms or corrects scores
3. Corrections encoded as calibration anchors
4. Human-corrected scores used for threshold/convergence check

### Evaluator Context Loading Order
1. skills/evaluate/SKILL.md (protocol)
2. skills/evaluate/evaluator-<domain>.md (domain template)
3. docs/evaluator-calibration-<domain>.md (project calibration, if exists)
4. skills/runtime-evidence/SKILL.md (if runtime configured)
5. runtime_agent / stack_agents content (if configured)
6. Task criteria from eval block
7. Prior scorecards (if iteration 2+)
8. Antipatterns file (if configured)

### Evolve Step Outputs
- Updated calibration files with new anchors
- Updated antipattern files with new entries
- Adjusted thresholds in orchestrate.json (if needed)

## Deliverables
- [ ] Attended mode gate in develop skill
- [ ] Antipattern loading (implementer + evaluator)
- [ ] Calibration file loading into evaluator context
- [ ] Brainstorm calibration extraction
- [ ] Deliver evolve step enrichment
- [ ] Documentation: attended/unattended toggle
- [ ] Integration test
