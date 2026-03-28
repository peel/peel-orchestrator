# 004 — Develop phase redesign: superpowers composition with swarm option

**Date:** 2026-03-28
**Status:** accepted
**Supersedes:** 001, 002

## Context

The develop phase had three problems: subagent nesting (coordinator spawning
reviewer sub-subagents) broke in practice, merge conflicts were deferred to
a batch cleanup step, and two variants (develop-subs/develop-team) duplicated
logic.

## Decision

Replace with a unified develop protocol that composes superpowers skills
(subagent-driven-development, executing-plans) with beans-based state tracking,
holistic review, and deferred finishing. A separate swarm mode provides parallel
worktree-per-bean execution for large epics with flat subagents and incremental
rebase-before-review merge.

## Consequences

- One develop entry point instead of three (develop + develop-subs + develop-team)
- No subagent nesting — swarm uses flat subagents with inline review pipeline
- Incremental rebase-before-review merge replaces deferred batch merge
- Superpowers skills patched to skip finishing (develop owns the lifecycle)
- Three execution choices: subagent-driven (recommended), sequential, swarm
