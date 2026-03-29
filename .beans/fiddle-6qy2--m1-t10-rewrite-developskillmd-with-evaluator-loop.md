---
# fiddle-6qy2
title: 'M1-T10: Rewrite develop/SKILL.md with evaluator loop'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:20:46Z
updated_at: 2026-03-29T20:15:34Z
parent: fiddle-yzzk
blocked_by:
    - fiddle-mz3o
    - fiddle-5fz4
    - fiddle-1opk
    - fiddle-udtj
    - fiddle-vdfc
    - fiddle-d6aq
    - fiddle-btwg
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 10

Core orchestrating skill. Single execution mode: implement → evaluate → converge.
~200-250 lines. References all scripts and foundational skills.

Files:
- Rewrite: skills/develop/SKILL.md

Must include:
- Step 0: validate epic, worktree setup, read orchestrate.json
- Step 1: per-task loop (dispatch implementer, dispatch evaluator, run scripts, iterate)
- Step 2: completion (finish-branch)
- HARD-GATE blocks for: script usage, dispatch budget, eval log, restart
- Restart handling via parse-eval-log.sh + assess-git-state.sh
- M1 simplifications: single domain, single provider, no runtime, no attended gate

Steps:
1. Read current develop/SKILL.md
2. Write new version
3. Verify structure (line count, HARD-GATE count, script references)
4. Commit

## Summary of Changes

Rewrote skills/develop/SKILL.md from three-mode system to single evaluator loop (201 lines). Step 0: validate/worktree/config. Step 1: per-task implement→evaluate→converge loop. Step 2: finish-branch. 4 HARD-GATEs, all 5 scripts referenced, restart resilience, M1 simplifications noted.
