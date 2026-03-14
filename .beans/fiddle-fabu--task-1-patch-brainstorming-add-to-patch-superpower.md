---
# fiddle-fabu
title: 'Task 1: Patch brainstorming — add to patch-superpowers'
status: todo
type: task
priority: critical
tags:
    - worktree
created_at: 2026-03-14T18:36:43Z
updated_at: 2026-03-14T19:01:52Z
parent: fiddle-9qn1
---

Plan: docs/plans/2026-03-14-orchestrate-panel-integration.md Task 1

Files:
- Modify: skills/patch-superpowers/SKILL.md

Steps:
1. Read current patch-superpowers SKILL.md
2. Update overview: change "two cached skills" to "three cached skills: brainstorming, writing-plans, and executing-plans". Remove "Brainstorming needs no changes" line.
3. Update Step 1 find command grep pattern to include brainstorming
4. Update Step 2 to check all three files for patch marker
5. Add new Step 3 (Patch Brainstorming) with sub-steps 3a-3f:
   3a: Add ARGS line with --skip-panel and --from-orchestrate flags config table
   3b: Add panel enrichment item to checklist (renumber subsequent items)
   3c: Add panel enrichment node to process flow graph
   3d: Add --from-orchestrate check to process flow graph terminal state
   3e: Replace terminal state text with flag-dependent version
   3f: Replace Implementation subsection with flag-dependent version
   Append [BEANS-PATCHED] marker
6. Renumber old Steps 3,4,5 to Steps 4,5,6
7. Commit

Acceptance criteria:
- patch-superpowers has Step 3 for brainstorming with all 6 sub-steps
- Overview mentions three skills
- --from-orchestrate flag used (not event log detection)
- Steps renumbered correctly
