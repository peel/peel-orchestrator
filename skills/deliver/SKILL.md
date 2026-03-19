---
name: fiddle:deliver
description: Run the DELIVER phase — drift analysis comparing design to implementation, documentation update via deliver-docs, and epic closure. Requires a completed epic.
argument-hint: --epic <id> [--providers codex]
---

# Deliver

Analyze design-vs-implementation drift, update documentation, and close the epic.

ARGUMENTS: {ARGS}

## Configuration

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--epic <id>` | **required** | The epic to deliver |
| `--providers <list>` | from config | Override provider list for this phase |

### Config File

Read `orchestrate.conf` (project root) if it exists. Extract:
- `providers.deliver` — default provider list (default: `["codex"]`)
- Provider declarations (`providers.<name>.command`, `.flags`)
- `providers.timeout` — attended/unattended timeouts
- `models.deliver` — model override for drift analysis

CLI `--providers` overrides the config file value.

## Steps

### Step 1: Validate Epic

```bash
beans show <epic-id> --json
```

Confirm it exists. Check child bean states — if beans are still `todo` or `in-progress`, warn: "Some beans are not complete. Proceed with delivery anyway?"

### Step 2: Drift Analysis

If providers are configured (default: codex), read the provider dispatch and context procedures (resolve relative to this skill's base directory):
- `../develop-subs/roles/provider-dispatch.md`
- `../develop-subs/roles/provider-context.md`

Follow the dispatch procedure for each provider with:

- `PROVIDER_ROLE` = "Drift analyst"
- `TOPIC` = "Design vs implementation drift for `<epic-id>`"
- `DESIGN_DOC` = `<read the design doc referenced in the epic bean body>`
- `DIFF` = `<git diff main...HEAD>`
- `INSTRUCTIONS` = "Analyze: did the implementation match the design? Flag any drift, missing features, scope creep, or unintended changes."

Dispatch all providers in parallel. Collect results in **attended** mode.

If no provider CLI is available, perform the drift analysis yourself: read the design doc, review the full diff, and compare.

Present the drift analysis to the user:
```
"Drift analysis complete:
- Implemented as designed: [list]
- Drift detected: [list with explanations]
- Missing from design: [list]
- Added beyond design: [list]

Proceed with documentation update?"
```

Wait for user confirmation before proceeding.

### Step 3: Documentation Update

Invoke deliver-docs:
```
Skill(skill: "fiddle:deliver-docs", args: "--epic <epic-id>")
```

This updates SYSTEM.md, creates ADRs for architectural decisions, and appends to BACKLOG.md.

Present the deliver-docs results to the user for confirmation. Wait for approval.

### Step 4: Close Epic

After user confirms documentation:
```bash
beans update <epic-id> --status completed
```
