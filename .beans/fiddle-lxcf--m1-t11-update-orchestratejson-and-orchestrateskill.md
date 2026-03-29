---
# fiddle-lxcf
title: 'M1-T11: Update orchestrate.json and orchestrate/SKILL.md'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:20:46Z
updated_at: 2026-03-29T20:17:11Z
parent: fiddle-yzzk
blocked_by:
    - fiddle-6qy2
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 11

Add evaluators config section. Remove develop.execution key and mode selection.

Files:
- Modify: orchestrate.json
- Modify: skills/orchestrate/SKILL.md

Steps:
1. Replace develop block with evaluators block in orchestrate.json
2. Remove --execution flag and mode selection from orchestrate/SKILL.md
3. Verify JSON valid
4. Commit

## Summary of Changes

Updated orchestrate.json: replaced develop block with evaluators block (attended, max_dispatches_per_task, domains.general). Updated skills/orchestrate/SKILL.md: removed --execution flag and mode selection, simplified develop invocation.
