# 003 — CLI-Only External Providers

**Date:** 2026-03-15
**Status:** accepted

## Context

Fiddle originally used Codex via MCP (as an MCP server) and Gemini via CLI. This meant codex required per-project MCP configuration (`.mcp.json`), which was fragile to maintain and required a dedicated init flow. Meanwhile, both tools offer full-featured CLI interfaces that run in the project directory with filesystem access.

## Decision

Drop Codex MCP in favor of `codex exec` CLI. All external providers are now CLI-only, invoked via a standardized dispatch procedure (`roles/provider-dispatch.md`) that reads explicit command/flags from `orchestrate.conf`, builds prompts from a template (`roles/provider-context.md`), and fires background Bash tasks for true parallelism.

## Consequences

- No per-project MCP configuration needed. One less setup step, one fewer failure mode.
- Uniform invocation pattern for all providers — adding a new provider means adding a config block, not a new integration type.
- Provider CLIs read the codebase directly from the project directory. No need to stuff codebase context into prompts.
- All provider calls are async (background Bash tasks) with event-driven collection — no synchronous blocking.
- MCP-specific features (tool calling, streaming) are no longer available for codex. If codex MCP gains capabilities that CLI lacks, this decision may need revisiting.
- The `/fiddle:init` skill no longer writes MCP config — it only verifies CLIs are on PATH.
