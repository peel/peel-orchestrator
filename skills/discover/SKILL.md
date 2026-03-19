---
name: fiddle:discover
description: Run the DISCOVER phase — gather project context via discover-docs, research ecosystem with external providers, and challenge scope assumptions. Use standalone or as part of orchestrate.
argument-hint: <topic> [--skip-docs] [--skip-challenge] [--providers codex]
---

# Discover

Gather project context, research the ecosystem, and challenge scope assumptions before defining a solution.

ARGUMENTS: {ARGS}

## Configuration

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--skip-docs` | false | Skip discover-docs — go straight to research and challenge |
| `--skip-challenge` | false | Skip the challenge step after scope confirmation |
| `--providers <list>` | from config | Override provider list for this phase |

### Config File

Read `orchestrate.conf` (project root) if it exists. Extract:
- `providers.discover` — default provider list for this phase (default: `["codex"]`)
- Provider declarations (`providers.<name>.command`, `.flags`) for each provider
- `providers.timeout` — attended/unattended timeouts

CLI `--providers` overrides the config file value.

## Steps

### Step 1: Docs Discovery

Skip if `--skip-docs` was set.

Invoke discover-docs to gather project context and identify gaps:
```
Skill(skill: "fiddle:discover-docs", args: "<topic>")
```

This reads existing docs, CLAUDE.md, beans, and relevant source files. It produces a structured summary of what exists, what's relevant, and what gaps remain.

### Step 2: External Research

If providers are configured (default: codex):

Read the provider dispatch and context procedures (resolve relative to this skill's base directory):
- `../develop-subs/roles/provider-dispatch.md`
- `../develop-subs/roles/provider-context.md`

Follow the dispatch procedure for each provider with these template values:

- `PROVIDER_ROLE` = "Research analyst"
- `TOPIC` = `<topic>`
- `INSTRUCTIONS` = "Research: ecosystem patterns, prior art, implementation approaches, potential pitfalls. Be specific and cite concrete examples."

Dispatch all providers in parallel. Collect results in **attended** mode.

If no provider CLI is available, skip and proceed with Claude's internal knowledge only.

### Step 3: Challenge Scope

Skip if `--skip-challenge` was set.

Invoke the challenge skill to confirm scope and stress-test assumptions:
```
Skill(skill: "fiddle:challenge", args: "--phase discover")
```

This opens by synthesizing findings and confirming scope with the user, then walks the decision tree on assumptions and constraints — resolving every branch before moving forward. It self-serves answers from the codebase and only asks the user about genuine ambiguity.
