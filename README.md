# Fiddle

Claude Code plugin for automated development lifecycle. Chains discover, define, develop, deliver phases with multi-model support and a reaction engine.

## Orchestrate

`/fiddle:orchestrate <topic>` runs the full lifecycle. Each phase is an independent skill that can also be invoked standalone:

| Phase | Steps |
|-------|-------|
| **DISCOVER** [`/fiddle:discover`](skills/discover/SKILL.md) | [discover-docs](skills/discover-docs/SKILL.md)  →  providers  →  [challenge](skills/challenge/SKILL.md) |
| **DEFINE** [`/fiddle:define`](skills/define/SKILL.md) | brainstorming  →  [panel](skills/panel/SKILL.md)  →  [challenge](skills/challenge/SKILL.md)  →  writing-plans  →  [define-beans](skills/define-beans/SKILL.md) |
| **DEVELOP** [`/fiddle:develop`](skills/develop/SKILL.md) | [ralph subs](skills/develop-subs/SKILL.md) \|\| [ralph team](skills/develop-team/SKILL.md) \|\| hands-on \|\| hands-on parallel  →  holistic review |
| **DELIVER** [`/fiddle:deliver`](skills/deliver/SKILL.md) | drift analysis  →  [deliver-docs](skills/deliver-docs/SKILL.md)  →  close epic |

## All Skills

### Phase skills

Independently invocable phases. Orchestrate sequences them, but each works standalone.

| Skill | Use when you want to... |
|-------|------------------------|
| [`fiddle:orchestrate`](skills/orchestrate/SKILL.md) | Run the full lifecycle from idea to shipped code. |
| [`fiddle:discover`](skills/discover/SKILL.md) | Research a topic, confirm scope, and challenge assumptions. |
| [`fiddle:define`](skills/define/SKILL.md) | Turn confirmed scope into a validated design and implementation plan with beans. |
| [`fiddle:develop`](skills/develop/SKILL.md) | Execute an existing plan — spawn ralph workers, review, and holistic check. |
| [`fiddle:deliver`](skills/deliver/SKILL.md) | Analyze drift, update docs, and close an epic after development is done. |

### Supporting skills

| Skill | Use when you want to... |
|-------|------------------------|
| [`fiddle:challenge`](skills/challenge/SKILL.md) | Challenge any plan or design by walking every branch of the decision tree. |
| [`fiddle:panel`](skills/panel/SKILL.md) | Get multi-model adversarial analysis on architectural approaches. |
| [`fiddle:discover-docs`](skills/discover-docs/SKILL.md) | Bootstrap or review curated project docs (VISION, MARKET, SYSTEM, etc). |
| [`fiddle:deliver-docs`](skills/deliver-docs/SKILL.md) | Update technical docs, create ADRs, and append to BACKLOG after shipping. |
| [`fiddle:define-beans`](skills/define-beans/SKILL.md) | Apply task sizing rules when decomposing plans into beans. |
| [`fiddle:adr`](skills/adr/SKILL.md) | Create an architecture decision record. |
| [`fiddle:feedback`](skills/feedback/SKILL.md) | Append a user feedback signal to the feedback log. |
| [`fiddle:backlog`](skills/backlog/SKILL.md) | Append an idea, tech debt, or observation to the backlog. |
| [`fiddle:patch-superpowers`](skills/patch-superpowers/SKILL.md) | Re-apply beans integration patches after superpowers updates. |

## Configuration

Orchestrate reads [`orchestrate.conf`](orchestrate.conf) (HCL) from the project root. Phase skills also read it for standalone defaults. All blocks are optional — defaults apply when omitted. See [`fiddle:orchestrate`](skills/orchestrate/SKILL.md) for the full config reference.

Merge order: defaults → config file → CLI flags. `--providers` sets all phases; per-phase flags override.

## External Providers

Orchestrate and panel use external models for multi-perspective analysis:

| Provider | Interface | Auth |
|----------|-----------|------|
| Codex | MCP server (`codex mcp`) | `codex --login` |
| Gemini | CLI (`gemini`) | `gemini auth` |

Both optional — skills fall back to Claude-only subagents without them.

## Install

`claude --plugin-dir /path/to/fiddle` or `/plugin install fiddle` via [marketplace](https://github.com/peel/peel-marketplace). Providers are auto-detected on session start.
