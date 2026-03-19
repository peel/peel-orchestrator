---
name: fiddle:orchestrate
description: Use when starting a full development lifecycle for a feature or epic — chains discover, define, develop, deliver phases with multi-model support and reaction engine
argument-hint: <topic> [--epic <id>] [--skip-discover] [--skip-challenge] [--providers codex,gemini]
---

# Orchestrate

Automated outer loop: DISCOVER → DEFINE → DEVELOP → DELIVER. Sequences phase skills with configuration, status tracking, and resumption support.

Each phase is an independent skill (`fiddle:discover`, `fiddle:define`, `fiddle:develop`, `fiddle:deliver`) that can also be invoked standalone. Orchestrate's job is to sequence them, pass through configuration, and handle phase transitions.

ARGUMENTS: {ARGS}

## Configuration

### CLI Flags

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--epic <id>` | none | Resume an existing epic. Skips DISCOVER/DEFINE if beans exist |
| `--skip-discover` | false | Jump straight to DEFINE |
| `--skip-docs` | false | Passed through to discover phase — skip discover-docs |
| `--skip-challenge` | false | Passed through to discover and define phases |
| `--skip-panel` | false | Passed through to define phase |
| `--providers <list>` | per-phase defaults | Global provider override (comma-separated) |
| `--discover-providers <list>` | codex | Override DISCOVER phase providers |
| `--define-providers <list>` | codex,gemini | Override DEFINE phase providers |
| `--develop-providers <list>` | none | Override DEVELOP phase providers |
| `--develop-holistic-providers <list>` | codex | Override holistic review providers |
| `--deliver-providers <list>` | codex | Override DELIVER phase providers |
| `--workers <N>` | 2 | Passed through to develop phase |
| `--max-review-cycles <N>` | 3 | Passed through to develop phase |
| `--max-total-turns <N>` | 200 | Passed through to develop phase |

### Config File

Read `orchestrate.conf` (project root) if it exists. Format is HCL:

```hcl
providers {
  codex {
    command = "codex exec"
    flags   = "--json -s read-only"
  }
  gemini {
    command = "gemini"
    flags   = "-o json --approval-mode auto_edit"
  }

  discover         = ["codex"]
  define           = ["codex", "gemini"]
  develop          = []
  develop_holistic = ["codex"]
  deliver          = ["codex"]

  timeout {
    attended   = 120
    unattended = 90
  }
}

ralph {
  workers            = 2
  max_review_cycles  = 3
  max_impl_turns     = 50
  max_review_turns   = 30
  max_total_turns    = 200
  ci_max_retries     = 3
  stall_timeout_min  = 15
  stall_max_respawns = 2
}

models {
  # discover = "sonnet"
  # define   = "sonnet"
  # deliver  = "sonnet"

  # develop = "sonnet"
}

develop {
  # execution = "develop-subs"  // or "tmux-team", "hands-on", "hands-on-parallel"
}

plans {
  # path   = "docs"              // parent dir for specs/ and plans/ (default: docs/superpowers)
  # commit = true                // whether to git commit plan/spec files (default: true)
}
```

### Model Defaults

| Config key | Roles | Default |
|---|---|---|
| models.discover | All DISCOVER subagents | "default" (session model) |
| models.define | Panel advocates, brainstorming subagents | "default" |
| models.develop | Implementers, reviewers, ralph orchestrator | "default" |
| models.deliver | Drift analysis, docs review | "default" |

"default" means inherit the session model — the agent omits the `model:` parameter so the parent's model is used. Omitted keys are treated as "default".

### Provider Defaults

| Phase | Default Providers | Rationale |
|---|---|---|
| DISCOVER | codex | Research depth from two code-oriented models |
| DEFINE (panel) | codex, gemini | Maximum perspectives for architectural decisions |
| DEVELOP (ralph) | none | Ralph's single-pass domain-expert review handles this |
| DEVELOP (holistic) | codex | Outside perspective on the full epic |
| DELIVER | codex | Drift detection and docs review |

Claude is implicit — always present, never listed. When a phase lists "codex", the actual participants are Claude + Codex.

### Merge Order

Defaults → config file → CLI flags. Later values override earlier ones. `--providers` sets all phases; per-phase flags override that.

Orchestrate reads `orchestrate.conf` once during SETUP and computes final values. These are passed as CLI args to each phase skill. Phase skills also read `orchestrate.conf` for their own defaults when invoked standalone, but when called from orchestrate, the passed args take precedence.

## SETUP

Run this section immediately on invocation, before any phase.

### Step 1: Parse Configuration

1. Set provider defaults from the table above. Set model defaults from the Model Defaults table.
2. If `orchestrate.conf` exists (project root): read it with the Read tool. Parse each HCL block:
   - `providers {}` — override provider defaults for each phase
   - `ralph {}` — set workers, max_review_cycles, max_impl_turns, max_review_turns, max_total_turns, ci_max_retries, stall_timeout_min, stall_max_respawns
   - `models {}` — override model defaults for each phase. `develop` is a string key. "default" means omit the `model:` parameter to inherit the session model.
3. Parse CLI flags from `{ARGS}`. Override any config file values.
4. Store final config values for use throughout the session.

### Step 2: Validate Epic (if --epic)

If `--epic <id>` was provided:
```bash
beans show <id> --json
```
Confirm it exists and is type `epic` or `milestone`. If not found, stop and report error to user.

### Step 3: Create Status Pane

Split the current tmux window to create a status pane:
```bash
# Get current pane ID
CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
# Split horizontally (side by side), 40% width for status
tmux split-window -h -l 40% "bash scripts/orchestrate-status.sh <epic-id>"
# Return focus to the main pane
tmux select-pane -t "$CURRENT_PANE"
```

If the status script is not available yet (placeholder), skip this step silently.

### Step 4: Determine Phase

If `--epic <id>` was provided, detect the current phase from bean state for resumption:

```bash
beans list --parent <epic-id> --json
```

- **No child beans exist** → start at DEFINE
- **Child beans in `todo` or `in-progress`** → start at DEVELOP
- **All child beans `completed` or tagged `needs-attention`, AND no commit message containing "deliver-docs"** → start at DELIVER
- **Docs already evolved** (check `git log --oneline --grep="deliver-docs"`) → DONE. Report completion.

If no `--epic` was provided, start at DISCOVER (or DEFINE if `--skip-discover`).

Set the phase tag on the epic bean (if epic exists):
```bash
beans update <epic-id> --tag orchestrate-phase:<phase>
```

Jump to the determined phase section below.

## DISCOVER

Skip this phase if `--skip-discover` was set OR if `--epic` was provided and child beans already exist.

Build args for the discover phase:
- `<topic>`
- `--providers <discover-providers>` (if overridden from defaults)
- `--skip-docs` (if set)
- `--skip-challenge` (if set)

Invoke:
```
Skill(skill: "fiddle:discover", args: "<built args>")
```

Transition:
```bash
beans update <epic-id> --remove-tag orchestrate-phase:DISCOVER --tag orchestrate-phase:DEFINE
```

Note: if epic does not yet exist at end of DISCOVER, skip the tag update — DEFINE will set it after epic creation.

Fall through to DEFINE.

## DEFINE

Build args for the define phase:
- `<topic>`
- `--providers <define-providers>` (if overridden from defaults)
- `--skip-challenge` (if set)
- `--skip-panel` (if set)

Invoke:
```
Skill(skill: "fiddle:define", args: "<built args>")
```

### Capture Epic ID

If `--epic` was not provided at invocation:

```bash
# Find the newly created epic from the plan
beans list --json -t epic -s todo
```

Take the most recently created epic ID. Store it for the remaining phases.

Transition:
```bash
beans update <epic-id> --remove-tag orchestrate-phase:DEFINE --tag orchestrate-phase:DEVELOP
```

Fall through to DEVELOP.

## DEVELOP

Build args for the develop phase:
- `--epic <epic-id>`
- `--workers <workers>` (if overridden from defaults)
- `--max-review-cycles <max-review-cycles>` (if overridden from defaults)
- `--max-total-turns <max-total-turns>` (if overridden from defaults)

Invoke:
```
Skill(skill: "fiddle:develop", args: "<built args>")
```

Transition:
```bash
beans update <epic-id> --remove-tag orchestrate-phase:DEVELOP --tag orchestrate-phase:DELIVER
```

Fall through to DELIVER.

## DELIVER

Build args for the deliver phase:
- `--epic <epic-id>`
- `--providers <deliver-providers>` (if overridden from defaults)

Invoke:
```
Skill(skill: "fiddle:deliver", args: "<built args>")
```

## CLEANUP

### Step 1: Kill Status Pane

```bash
# Find and kill the status pane (it's running orchestrate-status.sh)
tmux list-panes -F '#{pane_id} #{pane_current_command}' | grep orchestrate-status | awk '{print $1}' | xargs -I{} tmux kill-pane -t {}
```

If the pane doesn't exist, skip silently.

### Step 2: Clean Phase Tag

```bash
beans update <epic-id> --remove-tag orchestrate-phase:DELIVER
```

### Step 3: Summary

Count final bean states:
```bash
beans list --parent <epic-id> --json
```

Report to user:
```
"Epic <epic-id> complete.
- <N> beans completed
- <M> beans needs-attention (unresolved)"
```

Remind the user: "Run `/fiddle:deliver-docs --epic <epic-id>` to update project docs." (if deliver-docs was not already run in DELIVER).
