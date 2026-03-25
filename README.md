# Fiddle

Claude Code plugin for orchestrating a four-phase development lifecycle with multi-model support.

## Orchestrate

`/fiddle:orchestrate <topic>` chains four phases. Each phase is also a standalone skill.

**DISCOVER** [`/fiddle:discover`](skills/discover/SKILL.md) — Scan project docs, research the ecosystem via external providers (Claude + Codex), and challenge scope assumptions until every branch is resolved.

**DEFINE** [`/fiddle:define`](skills/define/SKILL.md) — Brainstorm approaches, run a multi-model adversarial panel (Claude + Codex + Gemini), challenge the chosen design, then produce an implementation plan with sized beans.

**DEVELOP** [`/fiddle:develop`](skills/develop/SKILL.md) — Execute beans in parallel via [ralph subs](skills/develop-subs/SKILL.md) or [ralph team](skills/develop-team/SKILL.md) (automated implement → review cycles), or hands-on. Holistic review via external providers (Claude + Codex) when done.

**DELIVER** [`/fiddle:deliver`](skills/deliver/SKILL.md) — Drift analysis via external providers (Claude + Codex), update technical docs, close the epic.

> [!NOTE]
> Any CLI that accepts a prompt on stdin works as a provider (Codex, Gemini, Copilot, etc). Configure per phase in [`orchestrate.conf`](orchestrate.conf).

## Skills

| Skill | Description |
|-------|-------------|
| [`fiddle:challenge`](skills/challenge/SKILL.md) | Walk the decision tree on any plan or design until shared understanding. |
| [`fiddle:panel`](skills/panel/SKILL.md) | Multi-model adversarial debate — Claude, Codex, Gemini argue positions and cross-review. |
| [`fiddle:discover-docs`](skills/discover-docs/SKILL.md) | Socratic dialogue to bootstrap or review project docs. |
| [`fiddle:deliver-docs`](skills/deliver-docs/SKILL.md) | Post-ship doc updates — SYSTEM.md, ADRs, BACKLOG. |
| [`fiddle:define-beans`](skills/define-beans/SKILL.md) | Task sizing rules for decomposing plans into beans. |
| [`fiddle:adr`](skills/adr/SKILL.md) | Create an architecture decision record. |
| [`fiddle:feedback`](skills/feedback/SKILL.md) | Append a user feedback signal. |
| [`fiddle:backlog`](skills/backlog/SKILL.md) | Append an idea or tech debt item. |
| [`fiddle:patch-superpowers`](skills/patch-superpowers/SKILL.md) | Re-apply beans integration patches after superpowers updates. |

## Configuration

Orchestrate reads [`orchestrate.conf`](orchestrate.conf) (HCL) from the project root. All blocks optional — defaults apply when omitted. See [`fiddle:orchestrate`](skills/orchestrate/SKILL.md) for the full reference.

## Install

Requires [superpowers](https://github.com/obra/superpowers) plugin.

```bash
# superpowers (dependency)
/plugin install superpowers

# fiddle — from marketplace
/plugin marketplace add github:peel/peel-marketplace
/plugin install fiddle

# fiddle — from source
claude --plugin-dir /path/to/fiddle
```

After install, run `/fiddle:patch-superpowers` to apply beans integration. Providers are auto-detected on session start.

### Optional: Clash (conflict detection)

When running parallel workers in worktrees, fiddle includes a PreToolUse hook that warns agents before writing to files that conflict with another worktree. This requires [clash](https://github.com/clash-sh/clash):

```bash
# via cargo
cargo install clash-sh

# via nix
nix profile install github:clash-sh/clash
```

The hook is advisory (never blocks) and silently skips if clash is not installed.
