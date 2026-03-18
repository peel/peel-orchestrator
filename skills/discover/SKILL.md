---
name: fiddle:discover
description: Run the DISCOVER phase — gather project context via docs-discover, research ecosystem with external providers, confirm scope through Socratic dialogue, and stress-test assumptions via grill. Use standalone or as part of orchestrate.
argument-hint: <topic> [--skip-docs] [--skip-grill] [--providers codex]
---

# Discover

Gather project context, research the ecosystem, confirm scope through dialogue, and stress-test assumptions before defining a solution.

ARGUMENTS: {ARGS}

## Configuration

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--skip-docs` | false | Skip docs-discover — go straight to research, dialogue, and grill |
| `--skip-grill` | false | Skip the grill step after scope confirmation |
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

Invoke docs-discover to gather project context and identify gaps:
```
Skill(skill: "fiddle:docs-discover", args: "<topic>")
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

### Step 3: Socratic Dialogue

Present findings to the user as a Socratic dialogue — synthesize the evidence and ask clarifying questions:

1. Summarize what you found (project context + external research)
2. Identify key decisions that need to be made
3. Ask the user to confirm the scope: "Based on this research, the scope appears to be: [X]. Does this match your intent? Any adjustments?"

Wait for user confirmation before proceeding.

### Step 4: Grill Scope

Skip if `--skip-grill` was set.

Invoke the grill skill to stress-test the scope:
```
Skill(skill: "fiddle:grill", args: "--phase discover")
```

This walks the decision tree on scope, assumptions, and constraints — resolving every branch before moving forward. It self-serves answers from the codebase and only asks the user about genuine ambiguity.
