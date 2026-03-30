---
name: fiddle:develop
description: Execute an epic via the evaluator loop — implement, evaluate, converge per task bean, with script-enforced thresholds and convergence.
argument-hint: --epic <id>
---

# Develop — Evaluator Loop

Execute an implementation plan by iterating: dispatch implementer → dispatch evaluator → run convergence scripts → repeat until converged or budget exceeded.

**Announce:** "I'm using fiddle:develop to implement this epic via the evaluator loop."

ARGUMENTS: {ARGS}

## Step 0: Validate and Setup

### 0a. Validate Epic

```bash
beans show <epic-id> --json
```

Confirm the epic exists and has child task beans. If no child beans → stop: "No task beans found for this epic. Run `/fiddle:define` first."

### 0b. Worktree Setup

```
Skill("fiddle:worktrees")
```

Creates an isolated worktree for the epic. All subsequent work happens in this worktree.

### 0c. Read Evaluator Config

Read `orchestrate.json` from project root. Extract the `evaluators` block:

```json
{
  "evaluators": {
    "attended": false,
    "max_dispatches_per_task": 60,
    "domains": {
      "general": { "template": "evaluator-general", "providers": ["claude"] }
    },
    "holistic": {
      "providers": ["claude"],
      "max_iterations": 3
    }
  }
}
```

Store `max_dispatches_per_task` for the convergence budget. Store `domains` for evaluator dispatch. Store `evaluators.holistic.providers` for holistic review dispatch (default: `["claude"]`).

## Step 1: Per-Task Loop

Process each task bean sequentially. For each bean:

### 1a. Restart Check

If a bean is already `in-progress` (session restart or crash recovery):

<HARD-GATE>
On session restart or when encountering an in-progress bean, you MUST run:
  scripts/parse-eval-log.sh --bean-id {id}
  scripts/assess-git-state.sh --base-sha {sha}
Resume based on script output. Do NOT guess state from memory or context.
</HARD-GATE>

**Interpreting restart state:**
- `parse-eval-log.sh` returns `{base_sha, total_dispatches, iteration_count, last_verdict, last_guidance}`.
- `assess-git-state.sh` returns `{state: CLEAN|DIRTY|CORRUPTED}`.
  - **CLEAN:** Code is committed. Resume from domain resolution and evaluation (step 1c) if last verdict was not CONVERGED, or skip to next task if CONVERGED.
  - **DIRTY:** Uncommitted changes exist. Commit or stash them, then resume from evaluation.
  - **CORRUPTED:** Merge conflict or broken state. Escalate to human — mark bean `needs-attention`.

### 1b. Initialize Evaluation Log

For a fresh task bean (not a restart), record the starting point:

```bash
BASE_SHA=$(git rev-parse HEAD)
scripts/append-eval-log.sh --bean-id {id} --init --base-sha "$BASE_SHA"
beans update {id} --status in-progress
```

Set `dispatch_count=0` and `iteration=0`.

### 1c. Resolve Domains

<HARD-GATE>
Before dispatching any evaluator, you MUST run:
  scripts/resolve-domains.sh --domains "{task domains}" --config orchestrate.json
Use the script's output to configure evaluators. Do NOT resolve domains manually.
</HARD-GATE>

Read the task bean's eval block to extract `domains` (e.g., `domains: [frontend, backend]`). If no `domains` are specified in the eval block, default to `"general"`.

Run:
```bash
scripts/resolve-domains.sh --domains "frontend,backend" --config orchestrate.json > resolved-domains.json
```

The script outputs a JSON array of resolved domain objects:
```json
[
  {"domain": "frontend", "template": "evaluator-frontend", "runtime": ["flutter run ..."], "ready_check": {...}, "resolved_via": "config"},
  {"domain": "backend", "template": "evaluator-backend", "runtime": ["mix phx.server"], "ready_check": {...}, "resolved_via": "config"},
  {"domain": "general", "template": "evaluator-general", "resolved_via": "fallback"}
]
```

Store the resolved domains list for use in step 1f (per-domain evaluator dispatch).

Also extract `runtime_order` from the task's eval block if present (e.g., `runtime_order: [backend, frontend]`). If not specified, default to the order listed in the `domains` array.

### 1d. Dispatch Implementer

Dispatch a subagent using the template at `skills/develop/implementer-prompt.md`. Fill placeholders:
- `{ITERATION}` — iteration number (1 on first dispatch)
- `{TASK_TEXT}` — full bean body (title, description, acceptance criteria)
- `{CONTEXT}` — relevant file paths, architecture notes, codebase context
- `{EVAL_BLOCK}` — the task's Evaluation block criteria
- `{ANTIPATTERNS}` — known antipatterns to avoid (see antipattern loading below; empty if none configured)
- `{PRIOR_SCORECARD}` — previous evaluator scorecard (empty on first dispatch)
- `{PRIOR_GUIDANCE}` — specific fix instructions from evaluator (empty on first dispatch)
- `{WORK_DIR}` — worktree directory path

#### Antipattern Loading

For each resolved domain from step 1c, check `evaluators.domains.<domain>.antipatterns` in `orchestrate.json`. If the key exists, read the file at that path (relative to project root). Concatenate antipattern content from all resolved domains into a single block and inject into the `{ANTIPATTERNS}` placeholder. If no domain has an `antipatterns` key configured, leave `{ANTIPATTERNS}` empty (the section header still appears but with no content).

Increment `dispatch_count` after each dispatch.

### 1e. Handle Implementer Status

The implementer returns one of:
- **DONE** or **DONE_WITH_CONCERNS** → proceed to evaluation (step 1f)
- **BLOCKED** → mark bean `needs-attention` with reason, escalate to human, move to next bean
- **NEEDS_CONTEXT** → provide the requested context and re-dispatch (back to step 1d)

### 1f. Dispatch Per-Domain, Per-Provider Evaluators

For EACH resolved domain (from `resolved-domains.json` produced in step 1c), dispatch evaluators for EACH provider. Process domains in `runtime_order` if specified, otherwise in the order listed in the `domains` array.

#### Runtime Start (per domain)

<HARD-GATE>
If a domain has runtime configured (i.e., the resolved domain entry has a "runtime" array):
  1. Run: scripts/start-runtimes.sh --domains <resolved-domains-file>
     Start runtimes in runtime_order sequence. If runtime_order is [backend, frontend], start backend first, wait for ready, then start frontend.
  2. If exit 0: runtime is ready. Proceed to evaluator dispatch.
  3. If exit 3 (harness failure): retry once. If retry fails, escalate to human without counting against dispatch budget.
  4. If exit 1 or 2: this is an app/config issue. Include the error in evaluator context.
Do NOT skip runtime start. Do NOT proceed to evaluator dispatch if runtime is required but not started.
</HARD-GATE>

#### Per-Domain, Per-Provider Evaluator Dispatch

For each resolved domain, read the `providers` array from the resolved domain config (e.g., `{"domain": "general", "providers": ["claude", "codex"], ...}`). If no `providers` array is present, default to `["claude"]`.

For each provider in the domain's `providers` array, dispatch an evaluator:

**If provider is `claude`:** Dispatch an evaluator subagent using `skills/evaluate/SKILL.md` protocol with that domain's template (e.g., `skills/evaluate/evaluator-general.md`, `evaluator-frontend.md`, or `evaluator-backend.md` — as specified in the resolved domain's `template` field).

**If provider is external (not `claude`):** Dispatch via the provider hook:

```bash
hooks/dispatch-provider.sh <provider> \
  --role evaluator \
  --topic "Evaluate domain: {domain}" \
  --instructions "$(cat skills/evaluate/{template}.md)" \
  --diff-file <diff-file> \
  --design-doc-file <design-doc-file>
```

The external provider receives the same context as the claude evaluator: evaluation protocol, domain template, calibration data, diff, and criteria. The external provider MUST return a valid JSON scorecard as its last content block (see `skills/develop/provider-context.md` for schema requirements).

**Each provider dispatch counts as 1 toward the dispatch budget**, regardless of provider type. For example, 2 providers x 2 domains = 4 dispatches per iteration.

Provide to all evaluators (claude and external) in the following **context loading order**:

1. **Evaluation protocol** — `skills/evaluate/SKILL.md`
2. **Domain template** — `skills/evaluate/evaluator-<domain>.md` (as specified in the resolved domain's `template` field, e.g., `evaluator-general.md`, `evaluator-frontend.md`)
3. **Project calibration** (if exists) — read `evaluators.domains.<domain>.calibration` from `orchestrate.json`. If the key is present, read the file at that path (relative to project root) and include its content immediately after the domain template. If the key is absent, check whether the default path `docs/evaluator-calibration-<domain>.md` exists (this file is created when the attended gate writes anchors in step 1i). If the default file exists, load it. If neither the config key nor the default file exists, skip.
4. **Runtime evidence** (if runtime configured) — `skills/runtime-evidence/SKILL.md` content, plus runtime state (port, domain) so the evaluator can interact with the running app
5. **Runtime/stack agents** (if configured) — if `runtime_agent` or `stack_agents` are configured for the domain in orchestrate.json, read those agent files and include their content
6. **Task criteria** — the bean's acceptance criteria and the domain template's scoring dimensions
7. **Prior scorecards** (if iteration 2+) — the full diff since BASE_SHA (`git diff {BASE_SHA}...HEAD`) and the previous iteration's scorecard with evaluator guidance
8. **Antipatterns** (if configured) — if `evaluators.domains.<domain>.antipatterns` is configured in orchestrate.json, read the antipatterns file and inject its content into the evaluator's `{ANTIPATTERNS}` placeholder. This is loaded last in the evaluator context.

Each evaluator (regardless of provider) returns a single scorecard JSON containing both per-dimension scores (under `.domains`) and pass/fail criteria (under `.criteria`). The scorecard MUST include a `"provider"` field identifying which provider produced it. Save each provider's scorecard per domain separately:

```bash
# Save per-provider, per-domain scorecard
cat > scorecard-{domain}-{provider}.json   # ← evaluator output for this domain+provider

# Increment dispatch_count for EACH provider dispatch
dispatch_count=$((dispatch_count + 1))
```

#### Runtime Stop (after all domains evaluated)

<HARD-GATE>
After ALL domain evaluators (all providers, all domains) have completed:
  Run: scripts/stop-runtimes.sh --state <runtime-state-file>
Do NOT leave processes running after evaluation.
</HARD-GATE>

### 1g. Merge Provider Scorecards

After all provider scorecards are collected for each domain, merge them before threshold checks.

<HARD-GATE>
After receiving ALL provider scorecards for a domain, you MUST run:
  scripts/merge-scorecards.sh < scorecards-array.json > scorecard-{domain}.json 2> disagreements-{domain}.json
Use the merged scorecard for threshold checks. Do NOT merge scores yourself.
</HARD-GATE>

For each domain, build a JSON array of all provider scorecards for that domain, then pipe to `merge-scorecards.sh`:

```bash
# Collect all provider scorecards for a domain into a JSON array
jq -s '.' scorecard-{domain}-*.json | \
  scripts/merge-scorecards.sh > scorecard-{domain}.json 2> disagreements-{domain}.json
```

The merged scorecard uses conservative (min) scoring: for each dimension, the final score is the minimum across providers. Each dimension includes `provider_scores` showing per-provider breakdown:

```json
{
  "domains": {
    "general": {
      "dimensions": {
        "correctness": {"score": 7, "threshold": 7, "provider_scores": {"claude": 8, "codex": 7}}
      }
    }
  }
}
```

Disagreements (spread >= 3 between providers on any dimension) are written to `disagreements-{domain}.json`. Include disagreement data in evaluator feedback when re-dispatching implementers.

After merging all domains, combine disagreement files for the eval log:

```bash
# Merge per-domain disagreement files into a single array
jq -s 'add // []' disagreements-*.json > disagreements.json
```

Pass the combined `disagreements.json` to `append-eval-log.sh` in step 1l.

If a domain has only one provider, `merge-scorecards.sh` still runs (single-element array) to ensure consistent scorecard format.

### 1h. Merge Cross-Domain Scorecards

After all domain evaluators return, merge their scorecards:

- **Union** scorecards across domains — each domain is scored independently
- The merged scorecard has all domains under `.domains`: `{"frontend": {...}, "backend": {...}}`
- **No shared dimensions** — `domain_spec_fidelity` in frontend is completely independent from `domain_spec_fidelity` in backend
- Each domain must independently meet its own thresholds

```bash
# Merge per-domain (already provider-merged) scorecards into a single cross-domain scorecard.
# Use only scorecard-{domain}.json files (not scorecard-{domain}-{provider}.json raw files).
jq -s '
  { domains: (reduce .[] as $s ({}; . + ($s.domains // {}))) ,
    criteria: [.[] | .criteria[]?] }
' scorecard-general.json scorecard-frontend.json ... > scorecard.json

# Extract merged criteria
jq '.criteria' scorecard.json > criteria.json
```

List only the per-domain merged scorecards (one per resolved domain from step 1g). Do NOT include raw per-provider scorecards (`scorecard-{domain}-{provider}.json`) in this merge.

On failure, the merged scorecard identifies which domain(s) failed. Pass the merged scorecard to `check-thresholds.sh` — it already handles multi-domain scorecards.

Both files (`scorecard.json` and `criteria.json`) are then passed to the attended gate (step 1i) and subsequently to `check-thresholds.sh` (step 1j).

### 1i. Attended Scorecard Gate

<HARD-GATE>
IF evaluators.attended is true in orchestrate.json:
  After merging cross-domain scorecards (step 1h), before threshold checks, you MUST present the merged scorecard to the human for review.

  1. Show the full merged scorecard with ALL dimension scores across ALL domains.
  2. Highlight any dimension scoring BELOW its threshold (show score and threshold).
  3. Highlight any provider disagreements from disagreements.json (show dimension, provider scores, spread).
  4. Ask: "Do you agree with these scores? Correct any you disagree with, or confirm to proceed."

  If the human corrects a score:
    a. Record the correction: {domain, dimension, evaluator_score, human_score, reason}
    b. Update the merged scorecard (scorecard.json) with the human's corrected score for that dimension.
    c. Encode the correction as a calibration anchor in the project's calibration file (see below).
    d. Use the corrected scorecard for ALL subsequent threshold and convergence checks.

  If the human confirms: proceed with evaluator scores unchanged.

Do NOT skip the attended gate when evaluators.attended is true.
Do NOT proceed to threshold checks without human confirmation when attended mode is active.
</HARD-GATE>

#### Calibration Anchor Encoding

When the human corrects a score during attended review, append a calibration anchor to the project's calibration file for that domain.

**Locate the calibration file:** Read `evaluators.domains.<domain>.calibration` from `orchestrate.json`. If the key is present, use that path. If absent, default to `docs/evaluator-calibration-<domain>.md`. Create the file if it does not exist.

**Append the anchor in this format:**

```markdown
## [dimension] — Correction (YYYY-MM-DD)
**Evaluator scored:** X/10 — "[evaluator evidence from scorecard]"
**Human corrected to:** Y/10 — "[human's stated reason]"
**Anchor:** For this project, score Y means: [human's description of what that score level looks like]
```

Ask the human for their reason and description when they correct a score. The anchor becomes part of the evaluator's context on future dispatches (loaded at position 3 in the context loading order — see step 1f).

**Example interaction:**

```
Attended Scorecard Review — Iteration 2

Domain: general
  correctness:        8/10 (threshold: 7) ✓
  domain_spec_fidelity: 5/10 (threshold: 8) ✗ BELOW THRESHOLD
  code_quality:       7/10 (threshold: 6) ✓

Provider disagreements:
  general.domain_spec_fidelity — spread 3
    claude: 8, codex: 5

Do you agree with these scores? Correct any you disagree with, or confirm to proceed.
```

If human corrects `domain_spec_fidelity` to 7 with reason "spec coverage is adequate, missing only optional features":

```markdown
## domain_spec_fidelity — Correction (2026-03-30)
**Evaluator scored:** 5/10 — "[evaluator's evidence text]"
**Human corrected to:** 7/10 — "spec coverage is adequate, missing only optional features"
**Anchor:** For this project, score 7 means: all required spec items implemented, only optional/nice-to-have items missing
```

When `evaluators.attended` is false, skip this step entirely — proceed directly to threshold checks (step 1j).

### 1j. Check Thresholds

<HARD-GATE>
After the attended gate (step 1i) or directly after scorecard merge (when unattended), you MUST run:
  scripts/check-thresholds.sh --scorecard {scorecard_file} --criteria {criteria_file}
  scripts/check-convergence.sh --current {verdict_file} --history {history_file} --max-dispatches N --current-dispatches M
Act on the scripts' verdicts. Do NOT compute thresholds or convergence yourself.
</HARD-GATE>

Run `check-thresholds.sh` with the merged scorecard (from step 1h, potentially corrected in step 1i). It produces a verdict: `PASS` (exit 0) or `FAIL` (exit 1). The output includes a `dimensions` flat map (`{"frontend.correctness": 8, "backend.api_quality": 7, ...}`) with all per-domain dimension scores. On `FAIL`, the output identifies which domain(s) did not meet thresholds. This output can be passed directly to `check-convergence.sh` as the `--current` file and appended to the history array for future convergence checks.

### 1k. Check Convergence

Run `check-convergence.sh` with the `--current` file (the check-thresholds.sh output, which includes the `dimensions` flat map), the `--history` file (a JSON array of prior check-thresholds.sh outputs), and dispatch budget.

Possible outcomes:
- **CONVERGED** (exit 0) — two consecutive passes with no regressions
- **FAIL** (exit 1, status FAIL) — thresholds not met
- **PASS_PENDING** (exit 1, status PASS_PENDING) — passed but only once, need consecutive pass
- **PASS_REGRESSED** (exit 1, status PASS_REGRESSED) — passed but regressed on previously-passing dimensions
- **DISPATCHES_EXCEEDED** (exit 2) — budget exhausted

<HARD-GATE>
If check-convergence.sh returns DISPATCHES_EXCEEDED (exit 2), you MUST stop and ask the human.
Do NOT continue iterating. Do NOT lower thresholds. Do NOT rationalize.
</HARD-GATE>

### 1l. Log Evaluation

<HARD-GATE>
After every evaluation cycle, you MUST run:
  scripts/append-eval-log.sh --bean-id {id} --iteration {N} --scorecard {scorecard_file} --dispatches {count} --guidance {text} --disagreements disagreements.json
The --dispatches {count} MUST reflect actual provider dispatches (each provider dispatch = 1), not just iterations.
For example, 2 providers x 2 domains = 4 dispatches per iteration.
The --disagreements parameter is optional. Pass the combined disagreements file from step 1g. If the file contains a non-empty array, disagreement details are appended to the iteration entry.
If the attended gate (step 1i) produced human corrections, include them in the log entry by passing --corrections {corrections_json} with the array of {domain, dimension, evaluator_score, human_score, reason} objects.
Do NOT skip logging. Do NOT write the log entry manually.
</HARD-GATE>

### 1m. Act on Convergence Result

| Result | Action |
|---|---|
| **CONVERGED** | Mark bean `completed`. Proceed to next task. |
| **FAIL** | Dispatch fresh implementer with scorecard feedback showing failing dimensions (including which domain(s) failed) and fix guidance. → Back to step 1d. |
| **PASS_PENDING** | Re-evaluate without re-implementing — scorecard may stabilize. → Back to step 1f. |
| **PASS_REGRESSED** | Dispatch fresh implementer with regression details (which dimensions in which domains regressed and by how much). → Back to step 1d. |
| **DISPATCHES_EXCEEDED** | Mark bean `needs-attention`. Escalate to human. Move to next bean. |

## Step 2: Holistic Review

After the per-task loop completes, run a holistic review to assess the full system as an integrated whole. This catches cross-domain issues that per-task evaluation cannot see.

**Note:** The user can also trigger holistic review mid-stream (before all tasks finish) for an early integration check. When triggered mid-stream, run steps 2a-2c on the current state, report results, but do NOT enter the remediation loop — report findings and resume the per-task loop.

### 2a. Pre-flight

All task beans must be `completed` or `needs-attention` (escalated). Check:

```bash
beans list --parent <epic-id> --json
```

If any task bean is still `todo` or `in-progress`, go back to Step 1 to process it first.

Start ALL domain runtimes for the full set of domains across all tasks. Collect every unique domain from all task beans' eval blocks and start them:

```bash
scripts/start-runtimes.sh --domains <all-domains-resolved.json>
```

<HARD-GATE>
ALL domain runtimes must be running before holistic review begins.
If start-runtimes.sh fails (exit 3, harness failure): retry once. If retry fails, escalate to human.
If start-runtimes.sh fails (exit 1 or 2, app/config issue): include the error in holistic reviewer context and proceed — Runtime Health will reflect the failure.
Do NOT skip runtime start. Do NOT dispatch holistic review without attempting to start all runtimes.
</HARD-GATE>

### 2b. Dispatch Holistic Reviewer (Per-Provider)

Read `evaluators.holistic.providers` from `orchestrate.json`. If the key is absent, default to `["claude"]`.

For each provider in the holistic providers list, dispatch a holistic reviewer:

**If provider is `claude`:** Dispatch a subagent using `skills/develop/holistic-review.md`.

**If provider is external (not `claude`):** Dispatch via the provider hook:

```bash
hooks/dispatch-provider.sh <provider> \
  --role holistic-reviewer \
  --topic "Holistic review: cross-domain integration assessment" \
  --instructions "$(cat skills/develop/holistic-review.md)" \
  --diff-file <diff-file> \
  --design-doc-file <design-doc-file>
```

Provide to ALL holistic reviewers (claude and external):

- The full diff since the epic's base SHA (before any task started): `git diff {epic-base-sha}...HEAD`
- The design spec / plan document
- All task bean bodies (for spec requirements): `beans list --parent <epic-id> --json`
- Runtime state for ALL domains (ports, domain names, ready status)

Each holistic reviewer produces a single JSON scorecard with:
- `domain: "holistic"` with dimensions: `integration`, `coherence`, `holistic_spec_fidelity`, `polish`, `runtime_health`
- `spec_coverage_matrix` — JSON array classifying every spec requirement as Full/Weak/Missing
- `remediation_beans` — JSON array of remediation tasks for gaps

The scorecard MUST include a `"provider"` field identifying which provider produced it.

**Each holistic provider dispatch counts as 1 toward the holistic dispatch budget.** Track `holistic_dispatch_count` across iterations. For example, 2 providers = 2 dispatches per holistic iteration. The `--current-dispatches` passed to `check-convergence.sh` in step 2c reflects total holistic provider dispatches (not just iteration count).

Save each provider's scorecard separately:

```bash
cat > scorecard-holistic-{provider}.json   # ← holistic reviewer output for this provider
```

### 2b-2. Merge Holistic Provider Scorecards

After all holistic provider scorecards are collected, merge them before threshold checks.

<HARD-GATE>
After receiving ALL holistic provider scorecards, you MUST run:
  scripts/merge-scorecards.sh < scorecards-array.json > scorecard-holistic.json 2> disagreements-holistic.json
Use the merged scorecard for threshold checks. Do NOT merge scores yourself.
</HARD-GATE>

Build a JSON array of all holistic provider scorecards and pipe to `merge-scorecards.sh`:

```bash
# Collect all holistic provider scorecards into a JSON array
jq -s '.' scorecard-holistic-*.json | \
  scripts/merge-scorecards.sh > scorecard-holistic.json 2> disagreements-holistic.json
```

The merged scorecard uses conservative (min) scoring: for each dimension, the final score is the minimum across providers. Each dimension includes `provider_scores` showing per-provider breakdown.

**Coverage matrix merge:** Union all requirements from all providers' `spec_coverage_matrix` arrays. For each requirement, coverage = min across providers using the ordering Full > Weak > Missing. If ANY provider marks a requirement as Missing, the merged result is Missing. If any marks Weak and none marks Missing, the merged result is Weak.

```json
{
  "spec_coverage_matrix": [
    {"requirement": "R1", "coverage": "Missing", "provider_coverage": {"claude": "Full", "codex": "Missing"}},
    {"requirement": "R2", "coverage": "Full", "provider_coverage": {"claude": "Full", "codex": "Full"}}
  ]
}
```

**Remediation bean merge:** Union all providers' `remediation_beans` arrays. Deduplicate by requirement — if multiple providers produce remediation beans for the same requirement, keep the one with the most specific description (longest body). Each merged remediation bean includes a `source_providers` field listing which providers flagged it.

Disagreements (spread >= 3 between providers on any dimension) are written to `disagreements-holistic.json`. Include disagreement data in evaluator feedback when re-dispatching holistic review.

If only one provider is configured, `merge-scorecards.sh` still runs (single-element array) to ensure consistent scorecard format.

### 2c. Check Holistic Thresholds

<HARD-GATE>
After receiving the holistic scorecard, you MUST run:
  scripts/check-thresholds.sh --scorecard scorecard-holistic.json --criteria criteria-holistic.json
  scripts/check-convergence.sh --current {verdict_file} --history {holistic_history_file} --max-dispatches {max_iterations} --current-dispatches {current_iteration}
Act on the scripts' verdicts. Do NOT compute thresholds or convergence yourself.
</HARD-GATE>

Holistic thresholds default to those in `skills/develop/holistic-review.md`:
- Integration: 7
- Coherence: 7
- Holistic Spec Fidelity: 8
- Polish: 6
- Runtime Health: 9

These are overridden by `evaluators.holistic.thresholds` in `orchestrate.json` if present.

The holistic review uses the same convergence protocol as per-task evaluation (two consecutive passes needed). The `check-convergence.sh` call uses a holistic-specific history file to track holistic dispatch history separately from per-task dispatch history.

The dispatch budget for holistic review is `evaluators.holistic.max_iterations` from `orchestrate.json` (default 3).

### 2d. Handle Remediation

If holistic review **FAILS**:

1. Check the `remediation_beans` array in the holistic scorecard
2. If non-empty, create remediation task beans:
   ```bash
   # For each remediation bean in the array:
   beans create --parent <epic-id> --title "Fix: ..." --body "<description>" --eval "<eval block>"
   ```
3. Each remediation bean is a child of the epic, traced back to its source (spec coverage gap or failing dimension)
4. Run the per-task loop (Step 1) on just the remediation beans
5. After remediation beans complete, re-run holistic review (back to step 2a)

Track the holistic iteration count. Increment on each holistic review cycle.

<HARD-GATE>
If holistic review has been run `evaluators.holistic.max_iterations` times (default 3) and still fails:
  STOP. Mark the epic as `needs-attention`. Escalate to human with:
  - The latest holistic scorecard
  - The spec coverage matrix showing remaining gaps
  - The list of dimensions still below threshold
  - The full remediation history (which beans were created and their outcomes)
Do NOT continue iterating. Do NOT lower thresholds. Do NOT rationalize.
</HARD-GATE>

| Result | Action |
|---|---|
| **CONVERGED** | Holistic review passed (two consecutive passes). Proceed to step 2e. |
| **FAIL** | Generate remediation beans → run per-task loop (Step 1) on them → re-run holistic review (back to 2a). |
| **PASS_PENDING** | Re-run holistic review without remediation — scorecard may stabilize. → Back to 2b. |
| **PASS_REGRESSED** | Generate remediation beans targeting regressed dimensions → run per-task loop → re-run holistic review. → Back to 2a. |
| **DISPATCHES_EXCEEDED** | Max holistic iterations reached. Escalate to human. |

### 2e. Stop Runtimes

<HARD-GATE>
After holistic review completes (CONVERGED or escalated):
  Run: scripts/stop-runtimes.sh --state <runtime-state-file>
Do NOT leave processes running after holistic review.
</HARD-GATE>

## Step 3: Completion

After all task beans are completed (or escalated) and holistic review has passed (or been escalated):

```
Skill("fiddle:finish-branch")
```

User picks: merge, PR, keep, or discard. Worktree cleanup happens here.

## M1 Simplifications

These constraints scope the evaluator loop for Milestone 1. Later milestones remove them:

- ~~**Single domain:**~~ Multi-domain support added in M3. Domain resolution via `resolve-domains.sh`, per-domain evaluator dispatch, and cross-domain scorecard merge are now active.
- ~~**Single provider:**~~ Multi-provider evaluation added in M4. Per-provider dispatch via Agent (claude) or `hooks/dispatch-provider.sh` (external), with `merge-scorecards.sh` merging provider scorecards before threshold checks.
- ~~**No runtime:**~~ Runtime lifecycle added in M2. Start/stop runtimes around evaluator dispatch when domain has runtime configured.
- ~~**No holistic review:**~~ Holistic review added in M3. After per-task loop, dispatch holistic reviewer for cross-domain integration check with remediation loop.
- ~~**No attended gate:**~~ Attended mode gate added in M5 (step 1i). When `evaluators.attended: true`, the full merged scorecard is shown to the human before threshold checks. Human corrections update scores and encode calibration anchors in project calibration files (`docs/evaluator-calibration-<domain>.md`).
- ~~**No calibration loading:**~~ Calibration file loading added in M5 (step 1f, context position 3). When `evaluators.domains.<domain>.calibration` is configured in orchestrate.json, the file is loaded and included in evaluator context after the domain template. If the config key is absent, the default path `docs/evaluator-calibration-<domain>.md` is checked and loaded if it exists. Calibration anchors written by the attended gate (step 1i) are picked up on future evaluator dispatches.
- ~~**No antipatterns:**~~ Antipattern loading and checking added in M5. Antipattern files are read from `evaluators.domains.<domain>.antipatterns` in orchestrate.json and injected into both implementer and evaluator prompts. Evaluators treat detected antipatterns as grounds for failing the task.

## Red Flags

- **Never** dispatch an evaluator without first running `resolve-domains.sh` — domain resolution is a HARD-GATE
- **Never** dispatch an implementer without the full bean body and acceptance criteria
- **Never** dispatch without injecting relevant codebase context
- **Never** ignore BLOCKED or NEEDS_CONTEXT — something must change before re-dispatch
- **Never** skip evaluation even if the implementer self-reports success
- **Never** manually compute thresholds or convergence — always use the scripts
- **Never** exceed the dispatch budget without escalating to human
- **Never** invoke `fiddle:finish-branch` before all beans are completed or escalated AND holistic review has passed or been escalated
- **Never** write evaluation log entries manually — always use `append-eval-log.sh`
- **Never** skip holistic review after the per-task loop — it is required before completion
- **Never** exceed `max_iterations` for holistic review without escalating to human
- **Never** dispatch holistic review without starting all domain runtimes first
- **Never** leave runtimes running after holistic review completes
- **Never** skip `merge-scorecards.sh` when multiple providers produce scorecards — merging is a HARD-GATE (applies to both per-task and holistic scorecards)
- **Never** merge provider scores manually — always use the merge script
- **Never** skip holistic provider scorecard merging — even with one provider, `merge-scorecards.sh` must run for consistent format
- **Never** merge coverage matrices manually — use min(Full > Weak > Missing) rule: any provider marks Missing means Missing
- **Never** skip the attended scorecard gate (step 1i) when `evaluators.attended` is true — human review before threshold checks is a HARD-GATE
- **Never** proceed to threshold checks without human confirmation when attended mode is active
- **Never** discard human score corrections — corrected scores must update the scorecard AND encode calibration anchors
- **Never** skip calibration file loading when `evaluators.domains.<domain>.calibration` is configured OR when the default path `docs/evaluator-calibration-<domain>.md` exists — the calibration file must be loaded at position 3 in the context loading order, immediately after the domain template

## Restart Resilience

On session restart, develop re-derives state entirely from beans:

1. List epic's task beans via `beans list --parent <epic-id> --json`
2. Find any bean with `in-progress` status
3. For each in-progress bean: run `parse-eval-log.sh` + `assess-git-state.sh` (see step 1a)
4. Resume the per-task loop from the appropriate point
5. Skip already-`completed` beans
6. Process remaining `todo` beans normally
7. After all task beans are processed, check if holistic review has already been run by looking for `scorecard-holistic.json` and the holistic history file. If holistic review was in progress, resume from step 2a. If it had converged, proceed to step 3.

No session-scoped state to lose. All evaluation history lives on bean bodies.
