# 002 — Run ralph inline instead of as nested subagent

**Date:** 2026-03-26
**Status:** superseded by 004
**Supersedes:** 001

## Context

ADR 001 spawned ralph as a background subagent to save the leader's context window. However, ralph needs to spawn its own subagents (implementers, review coordinators), and subagents cannot reliably spawn sub-subagents — the nested agent gets stuck. This made the "Ralph Subs" execution mode non-functional.

## Decision

Both ralph variants (subs and team) now run **inline** in the main session. The orchestrator IS ralph. The difference between variants is only the worker dispatch mechanism:

- **Subs:** workers are background subagents via `Agent()` (no team_name)
- **Team:** workers are team members via `TeamCreate`/`SendMessage`

The `RALPH_STATUS` machine-readable exit protocol is removed since ralph no longer exits — it runs in the same session as the develop skill.

## Consequences

- Both execution modes work correctly — no subagent nesting.
- The leader's context is consumed by ralph's "Assess and Act" loop. With 1M context this is acceptable for most epics. For very large epics, the user can respawn a fresh session.
- The develop skill is simpler — no RALPH_STATUS parsing, no TaskOutput waiting.
- Ralph can interact with the user directly during the loop (e.g., presenting diffs after implementer completion) instead of batching everything to the end.
