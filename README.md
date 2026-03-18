# Fiddle

Claude Code plugin for automated development lifecycle. Chains discover, define, develop, deliver phases with multi-model support and a reaction engine.

## Orchestrate

`/fiddle:orchestrate <topic>` runs the full lifecycle. Each phase is an independent skill that can also be invoked standalone:

```
DISCOVER  (/fiddle:discover)
  └─ fiddle:docs-discover       — scan project docs, code, beans
  └─ external providers         — ecosystem research (optional)
  └─ Socratic dialogue          — confirm scope with user
  └─ fiddle:grill --phase discover — stress-test scope assumptions

DEFINE  (/fiddle:define)
  └─ superpowers:brainstorming  — explore intent, produce 2-3 approaches
  └─ fiddle:panel               — adversarial debate across models
  └─ fiddle:grill --phase define — stress-test chosen design
  └─ superpowers:writing-plans  — implementation plan + bean decomposition
     └─ fiddle:bean-decomposition — task sizing rules

DEVELOP  (/fiddle:develop)
  └─ fiddle:develop-subs        — parallel bean implementation
     └─ implementers (sonnet)   — write code in worktrees
     └─ review coordinators     — tiered review (haiku → sonnet)
  └─ reaction engine            — CI failure, stall, review overflow detection
  └─ holistic review (opus)     — cross-bean consistency check

DELIVER  (/fiddle:deliver)
  └─ external providers         — drift analysis vs design doc (optional)
  └─ fiddle:docs-evolve         — update SYSTEM.md, ADRs, BACKLOG
  └─ close epic
```

## All Skills

### Phase skills

Independently invocable phases. Orchestrate sequences them, but each works standalone.

| Skill | Use when you want to... |
|-------|------------------------|
| `fiddle:orchestrate` | Run the full lifecycle from idea to shipped code. |
| `fiddle:discover` | Research a topic, confirm scope, and stress-test assumptions. |
| `fiddle:define` | Turn confirmed scope into a validated design and implementation plan with beans. |
| `fiddle:develop` | Execute an existing plan — spawn ralph workers, review, and holistic check. |
| `fiddle:deliver` | Analyze drift, update docs, and close an epic after development is done. |

### Supporting skills

| Skill | Use when you want to... |
|-------|------------------------|
| `fiddle:grill` | Stress-test any plan or design by walking every branch of the decision tree. |
| `fiddle:panel` | Get multi-model adversarial analysis on architectural approaches. |
| `fiddle:docs-discover` | Bootstrap or review curated project docs (VISION, MARKET, SYSTEM, etc). |
| `fiddle:docs-evolve` | Update technical docs, create ADRs, and append to BACKLOG after shipping. |
| `fiddle:bean-decomposition` | Apply task sizing rules when decomposing plans into beans. |
| `fiddle:develop-subs` | Ralph agent prompt for parallel bean implementation with subagents. |
| `fiddle:develop-team` | Ralph agent prompt for team-based parallel implementation variant. |
| `fiddle:adr` | Create an architecture decision record. |
| `fiddle:feedback` | Append a user feedback signal to the feedback log. |
| `fiddle:backlog` | Append an idea, tech debt, or observation to the backlog. |
| `fiddle:patch-superpowers` | Re-apply beans integration patches after superpowers updates. |
| `fiddle:init` | Auto-detect and configure external providers (Codex, Gemini). |

## Configuration

Orchestrate reads `orchestrate.conf` (HCL) from the project root. Phase skills also read it for standalone defaults. All blocks are optional — defaults apply when omitted.

```hcl
providers {
  discover         = ["codex"]
  define           = ["codex", "gemini"]
  develop          = []
  develop_holistic = ["codex"]
  deliver          = ["codex"]
}

ralph {
  workers           = 2
  max_review_cycles = 3
  max_impl_turns    = 50
  max_review_turns  = 30
}

reaction {
  ci_max_retries      = 3
  stall_timeout_min   = 15
  stall_max_respawns  = 2
}
```

Merge order: defaults → config file → CLI flags. `--providers` sets all phases; per-phase flags override.

## External Providers

Orchestrate and panel use external models for multi-perspective analysis:

| Provider | Interface | Auth |
|----------|-----------|------|
| Codex | MCP server (`codex mcp`) | `codex --login` |
| Gemini | CLI (`gemini`) | `gemini auth` |

Both optional — skills fall back to Claude-only subagents without them.

## Setup

Run `/fiddle:init` to auto-detect and configure external providers. The SessionStart hook will remind you if providers are installed but unconfigured.

## Hooks

- `task-completed-verify.sh` — gates task completion with build/test verification

## Install

Development:

```bash
claude --plugin-dir /path/to/fiddle
```

Via marketplace:

```
/plugin marketplace add github:peel/peel-marketplace
/plugin install fiddle
```
