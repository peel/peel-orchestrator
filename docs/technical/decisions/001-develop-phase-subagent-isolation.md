# 001 — Spawn ralph as background subagent for DEVELOP phase

**Date:** 2026-03-14
**Status:** accepted

## Context

The orchestrate skill invoked ralph via `Skill()`, meaning ralph ran in the leader's context. After DISCOVER and DEFINE consumed context, ralph's long-running implementation cycles (dozens of implementer/reviewer subagents) exhausted the remaining context window. This broke the DEVELOP → DELIVER transition — the leader couldn't continue to DELIVER because context was full. The reaction engine (CI failure, stall, review overflow checks) also ran in the leader's context between ralph turns, compounding the problem.

## Decision

Spawn ralph as a background subagent via `Agent()` instead of inline `Skill()`. The leader stays lean through all four phases. Ralph gets a fresh context window automatically. The reaction engine checks move into ralph's own "Assess and Act" loop. Ralph communicates completion state back to the leader via a `RALPH_STATUS` protocol (`COMPLETE` or `PARKED`). The standalone `reaction {}` config block is merged into `ralph {}`.

## Consequences

- The leader's context stays small enough to run all four phases without exhaustion.
- Ralph owns its own reaction checks, making it self-contained and testable in isolation.
- The leader can no longer inspect ralph's intermediate state — it only sees the final `RALPH_STATUS` output. If ralph's context is exhausted (`max_total_turns`), the leader must check bean state and ask the user whether to respawn.
- Respawning ralph after `PARKED` or context exhaustion creates a fresh subagent each time, so there's no accumulated context across respawns — ralph must re-derive state from beans on every spawn.
