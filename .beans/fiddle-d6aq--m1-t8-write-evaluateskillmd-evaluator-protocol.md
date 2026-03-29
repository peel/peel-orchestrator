---
# fiddle-d6aq
title: 'M1-T8: Write evaluate/SKILL.md — evaluator protocol'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:20:02Z
updated_at: 2026-03-29T20:08:31Z
parent: fiddle-yzzk
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 8

Foundational skill for evaluator subagents. ~100-150 lines. Must include:
- HARD-GATE: score every dimension, evidence required
- Scorecard JSON output format (canonical schema)
- Distrust rules
- Scoring instructions: use domain template scales exactly
- Criteria evaluation: pass/fail per criterion with evidence
- Prior scorecard handling (iteration 2+)

Files:
- Create: skills/evaluate/SKILL.md

Steps:
1. Write the evaluator protocol skill
2. Verify line count (100-150)
3. Commit

## Summary of Changes

Created skills/evaluate/SKILL.md — evaluator protocol skill (138 lines). Covers: HARD-GATE for evidence, distrust rules, scoring instructions, criteria evaluation, antipattern checking, prior scorecard handling, canonical scorecard JSON schema, output contract.
