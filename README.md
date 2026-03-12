# Peel Orchestrator

Claude Code plugin for automated development lifecycle. Chains discover, define, develop, deliver phases with multi-model support and a reaction engine.

## Orchestrate

`/peel:orchestrate <topic>` runs the full lifecycle. Each phase invokes other skills:

```
DISCOVER
  └─ peel:docs-discover        — scan project docs, code, beans
  └─ Codex MCP / Gemini CLI    — external research (optional)
  └─ Socratic dialogue          — confirm scope with user

DEFINE
  └─ superpowers:brainstorming  — explore intent, produce 2-3 approaches
  └─ peel:panel                 — adversarial debate across models
  └─ superpowers:writing-plans  — implementation plan + bean decomposition
     └─ peel:bean-decomposition — task sizing rules

DEVELOP
  └─ peel:ralph-subs-implement  — parallel bean implementation
     └─ implementers (sonnet)   — write code in worktrees
     └─ review coordinators     — tiered review (haiku → sonnet)
  └─ reaction engine            — CI failure, stall, review overflow detection
  └─ holistic review (opus)     — cross-bean consistency check

DELIVER
  └─ Codex MCP / Gemini CLI    — drift analysis vs design doc (optional)
  └─ peel:docs-evolve           — update SYSTEM.md, ADRs, BACKLOG
  └─ close epic
```

## All Skills

| Skill | Purpose |
|-------|---------|
| `peel:orchestrate` | Full lifecycle orchestrator (DISCOVER → DEFINE → DEVELOP → DELIVER) |
| `peel:panel` | Multi-model adversarial analysis with cross-review and synthesis |
| `peel:ralph-subs-implement` | Parallel bean implementation with subagents and tiered review |
| `peel:ralph-beans-implement` | Team-based bean implementation variant |
| `peel:docs-discover` | Socratic dialogue to bootstrap or review project docs |
| `peel:docs-evolve` | Post-ship update of technical docs, ADRs, backlog |
| `peel:bean-decomposition` | Task sizing rules for implementation plans |
| `peel:adr` | Create architecture decision record |
| `peel:feedback` | Append user feedback signal |
| `peel:backlog` | Append idea or debt item |
| `peel:patch-superpowers` | Re-apply beans integration patches to superpowers skills |

## External Providers

Orchestrate and panel use external models for multi-perspective analysis:

| Provider | Interface | Auth |
|----------|-----------|------|
| Codex | MCP server (`codex mcp`) | `codex --login` |
| Gemini | CLI (`gemini`) | `gemini auth` |

Both optional — skills fall back to Claude-only subagents without them.

## Hooks

- `task-completed-verify.sh` — gates task completion with build/test verification

## Install

Add the peel marketplace, then install:

```
# In Claude Code settings, add marketplace:
github:peel/peel-marketplace
```
