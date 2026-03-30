---
name: fiddle:deliver
description: Run the DELIVER phase — drift analysis comparing design to implementation, documentation update via deliver-docs, evaluator evolve (calibration/antipattern updates), and epic closure. Requires a completed epic.
argument-hint: --epic <id>
---

# Deliver

Analyze design-vs-implementation drift, update documentation, and close the epic.

ARGUMENTS: {ARGS}

## Configuration

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--epic <id>` | **required** | The epic to deliver |

### Config File

Read `orchestrate.json` (project root) if it exists. Extract:
- `providers.phases.deliver` — provider list (default: `["codex"]`)
- Provider declarations (`providers.<name>.command`, `.flags`)
- `providers.timeout` — attended/unattended timeouts
- `models.deliver` — model override for drift analysis

## Steps

### Step 1: Validate Epic

```bash
beans show <epic-id> --json
```

Confirm it exists. Check child bean states — if beans are still `todo` or `in-progress`, warn: "Some beans are not complete. Proceed with delivery anyway?"

### Step 2: Drift Analysis

If providers are configured (default: codex), read `hooks/dispatch-provider.sh` for collection rules. For each provider:

```bash
# Write large content to temp files first
DESIGN_FILE=$(mktemp /tmp/design-XXXX.md)
DIFF_FILE=$(mktemp /tmp/diff-XXXX.txt)
# <write design doc to $DESIGN_FILE, git diff to $DIFF_FILE>

hooks/dispatch-provider.sh <provider> \
  --role "Drift analyst" \
  --topic "Design vs implementation drift for <epic-id>" \
  --design-doc-file "$DESIGN_FILE" \
  --diff-file "$DIFF_FILE" \
  --instructions "Analyze: did the implementation match the design? Flag any drift, missing features, scope creep, or unintended changes."
```

Fire all providers in parallel (`run_in_background: true`). Collect results in **attended** mode.

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

### Step 4: Evaluator Evolve

After documentation is confirmed, review the evaluation artifacts from this run.

#### 4a. Review Scorecards

Collect all evaluator scorecards produced during the epic (stored in `.beans/` eval-log beans).
Present them to the user:

```
"Here are the evaluator scorecards from this run:

[scorecard summary per task — dimension, score, evidence]

Where did the evaluator get it wrong?"
```

Wait for user corrections before proceeding.

#### 4b. Update Calibration

For each correction the user provides, append an anchor to the matching calibration file `docs/evaluator-calibration-<domain>.md`:

```markdown
## [dimension] — Correction (YYYY-MM-DD)
**Evaluator scored:** X/10 — "[evaluator evidence]"
**Human corrected to:** Y/10 — "[human reason]"
**Anchor:** For this project, score Y means: [human's description]
```

If the calibration file does not exist yet, create it with a top-level heading `# Evaluator Calibration — <domain>`.

#### 4c. Add Antipatterns

For each real failure found post-delivery (bugs, regressions, missed requirements), append to `docs/antipatterns-<domain>.md`:

```markdown
## [antipattern-id] (YYYY-MM-DD)
**Pattern:** What the failure looks like
**Example:** Concrete code/behavior from this run
**Fix:** How to avoid it
```

If the antipattern file does not exist yet, create it with a top-level heading `# Antipatterns — <domain>`.

#### 4d. Adjust Thresholds

If the evaluator was consistently too strict or too lenient across multiple tasks:
- Update the relevant threshold in `orchestrate.json` at `evaluators.domains.<domain>.thresholds`
- Present the change to the user for confirmation before writing

#### 4e. Review Iteration Counts

High iteration counts (>5 develop-evaluate cycles on a single task) suggest calibration gaps. Identify dimensions that caused the most iterations and focus calibration updates (4b) on those dimensions.

Present a summary:
```
"Evaluator evolve complete:
- Calibration anchors added: [count]
- Antipatterns recorded: [count]
- Threshold adjustments: [list or 'none']
- High-iteration tasks: [list or 'none']

Proceed to close epic?"
```

Wait for user confirmation.

### Step 5: Close Epic

After user confirms evaluator evolve:
```bash
beans update <epic-id> --status completed
```
