---
# fiddle-btwg
title: 'M1-T9: Write implementer-prompt.md'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:20:46Z
updated_at: 2026-03-29T20:11:07Z
parent: fiddle-yzzk
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 9

Dispatch template for implementer subagents. Based on superpowers implementer prompt, adapted for evaluator system.

Files:
- Create: skills/develop/implementer-prompt.md

Placeholders: {TASK_TEXT}, {CONTEXT}, {EVAL_BLOCK}, {ANTIPATTERNS}, {PRIOR_SCORECARD}, {PRIOR_GUIDANCE}, {ITERATION}, {WORK_DIR}
References fiddle:tdd and fiddle:verify skills.
Report format: DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT.
~80-100 lines.

Steps:
1. Write implementer prompt template
2. Verify placeholder count and line count
3. Commit

## Summary of Changes

Created skills/develop/implementer-prompt.md — dispatch template for implementer subagents (100 lines). 8 placeholders: TASK_TEXT, CONTEXT, EVAL_BLOCK, ANTIPATTERNS, PRIOR_SCORECARD, PRIOR_GUIDANCE, ITERATION, WORK_DIR. References fiddle:tdd and fiddle:verify. Adapted from superpowers version with evaluation-specific sections.
