---
# fiddle-jj30
title: 'Epic: Async provider coordination'
status: completed
type: epic
priority: normal
created_at: 2026-03-15T13:42:17Z
updated_at: 2026-03-15T15:27:21Z
---

Replace synchronous blocking provider calls (Codex MCP, inline Gemini CLI) with parallel background tasks using CLI-only invocation, event-driven collection, and standardized context transfer. Design: docs/plans/2026-03-15-async-provider-coordination-design.md Plan: docs/plans/2026-03-15-async-provider-coordination.md

## Summary of Changes

Replaced synchronous blocking provider calls (Codex MCP, inline Gemini CLI) with parallel background tasks using CLI-only invocation, event-driven collection via TaskOutput, and a standardized context transfer protocol.

Key deliverables:
- orchestrate.conf: explicit provider CLI definitions + timeout config
- provider-context.md: standardized prompt template for all provider calls
- provider-dispatch.md: dispatch procedure with attended/unattended timeout modes
- Panel and orchestrate skills updated to use async dispatch
- Session-start hook and init skill simplified for CLI-only
- ADR 003: CLI-only external providers decision
- 3 follow-up items added to BACKLOG
