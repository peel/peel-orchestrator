---
# fiddle-p0do
title: 'Epic: Develop phase redesign'
status: completed
type: epic
priority: normal
created_at: 2026-03-28T10:37:25Z
updated_at: 2026-03-28T15:12:12Z
---

Implementation of develop phase redesign. Spec: docs/superpowers/specs/2026-03-26-develop-redesign.md. Plan: docs/superpowers/plans/2026-03-28-develop-redesign.md

## Summary of Changes

Implemented the develop phase redesign across 9 tasks:
- T1: 5 helper scripts for swarm git operations
- T2: Enriched implementer + reviewer templates for develop-swarm
- T3: Checklists, provider templates, and lead-procedures with Review Pipeline
- T4: develop-swarm/SKILL.md orchestration loop (489 lines)
- T5: Superpowers patches (beans for subagent-driven, remove finishing, remove isolation tags)
- T6: Rewritten develop/SKILL.md with unified protocol + 3 execution modes
- T7: Updated orchestrate/SKILL.md + orchestrate.json config migration
- T8: SYSTEM.md update, ADR 004, deleted develop-subs/develop-team/ralph
- T9: Smoke test, fixed dangling references in discover + deliver skills
- Added Step 0 reset to patch-superpowers for clean re-patching
