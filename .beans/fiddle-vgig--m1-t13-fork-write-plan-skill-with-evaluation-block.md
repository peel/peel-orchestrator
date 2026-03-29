---
# fiddle-vgig
title: 'M1-T13: Fork write-plan skill with Evaluation blocks'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:20:46Z
updated_at: 2026-03-29T20:27:39Z
parent: fiddle-yzzk
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 13

Fork superpowers writing-plans → skills/write-plan/SKILL.md.
Add Evaluation block requirement per task.

Files:
- Create: skills/write-plan/SKILL.md

Steps:
1. Copy from superpowers cache
2. Update frontmatter (fiddle:write-plan) and cross-references
3. Add Evaluation block section with eval YAML schema
4. Update plan header to reference fiddle:develop
5. Commit

## Summary of Changes

Forked writing-plans skill from superpowers 5.0.6 (GitHub upstream). 2 files: SKILL.md and plan-document-reviewer-prompt.md. Added Evaluation block requirement per task (fenced YAML eval blocks with domains, criteria, thresholds). Updated all cross-references to fiddle: namespace. Zero remaining superpowers references.
