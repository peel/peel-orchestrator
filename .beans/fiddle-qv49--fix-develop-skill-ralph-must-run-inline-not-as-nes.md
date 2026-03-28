---
# fiddle-qv49
title: 'Fix develop skill: ralph must run inline, not as nested subagent'
status: completed
type: bug
priority: normal
created_at: 2026-03-26T13:58:24Z
updated_at: 2026-03-28T10:13:50Z
---

develop/SKILL.md spawns ralph-subs as a background subagent, but ralph needs to spawn its own subagents (implementers, review coordinators). Subagents cannot nest. Fix: both variants run inline in the main session.

## Summary of Changes

Designed the develop phase redesign spec through iterative brainstorming, panel debates, and multiple review passes.

Key decisions:
- Develop protocol composes superpowers skills (subagent-driven, executing-plans) with a thin wrapper adding beans state, stall detection, holistic review, and deferred finishing
- Swarm mode (develop-swarm) provides parallel worktree-per-bean execution with incremental rebase-before-review merge
- Three execution choices: subagent-driven (recommended), sequential (interactive), swarm (large epics)
- Review coordinator eliminated — swarm uses flat Review Pipeline procedure
- Coupling detection protocol: dependencies → path overlap heuristic → clash runtime safety net
- Restart resilience via durable bean tags (worktree-slot preserved, bg-task cleared)
- Conventional commits with Previously/Now format and Bean trailer
- Helper scripts for deterministic git operations in swarm mode
- Holistic review as quality gate inside develop, using existing provider-dispatch mechanism
