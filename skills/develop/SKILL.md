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
    }
  }
}
```

Store `max_dispatches_per_task` for the convergence budget. Store `domains` for evaluator dispatch.

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
- `{ANTIPATTERNS}` — known antipatterns to avoid (empty if none)
- `{PRIOR_SCORECARD}` — previous evaluator scorecard (empty on first dispatch)
- `{PRIOR_GUIDANCE}` — specific fix instructions from evaluator (empty on first dispatch)
- `{WORK_DIR}` — worktree directory path

Increment `dispatch_count` after each dispatch.

### 1e. Handle Implementer Status

The implementer returns one of:
- **DONE** or **DONE_WITH_CONCERNS** → proceed to evaluation (step 1f)
- **BLOCKED** → mark bean `needs-attention` with reason, escalate to human, move to next bean
- **NEEDS_CONTEXT** → provide the requested context and re-dispatch (back to step 1d)

### 1f. Dispatch Per-Domain Evaluators

For EACH resolved domain (from `resolved-domains.json` produced in step 1c), dispatch an evaluator. Process domains in `runtime_order` if specified, otherwise in the order listed in the `domains` array.

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

#### Per-Domain Evaluator Dispatch

For each resolved domain, dispatch an evaluator subagent using `skills/evaluate/SKILL.md` protocol with that domain's template (e.g., `skills/evaluate/evaluator-general.md`, `evaluator-frontend.md`, or `evaluator-backend.md` — as specified in the resolved domain's `template` field).

Provide:
- The full diff since BASE_SHA: `git diff {BASE_SHA}...HEAD`
- The bean's acceptance criteria
- The domain template's scoring dimensions
- If runtime is configured: `skills/runtime-evidence/SKILL.md` content (loaded alongside domain template)
- If runtime is configured: runtime state (port, domain) so the evaluator can interact with the running app
- If `runtime_agent` or `stack_agents` are configured for the domain in orchestrate.json: read those agent files and include their content in the evaluator prompt context

Each evaluator returns a single scorecard JSON containing both per-dimension scores (under `.domains`) and pass/fail criteria (under `.criteria`). Save each domain's scorecard separately:

```bash
# Save per-domain scorecard
cat > scorecard-{domain}.json   # ← evaluator output for this domain

# Extract criteria array
jq '.criteria' scorecard-{domain}.json > criteria-{domain}.json
```

#### Runtime Stop (after all domains evaluated)

<HARD-GATE>
After ALL domain evaluators have completed:
  Run: scripts/stop-runtimes.sh --state <runtime-state-file>
Do NOT leave processes running after evaluation.
</HARD-GATE>

### 1g. Merge Cross-Domain Scorecards

After all domain evaluators return, merge their scorecards:

- **Union** scorecards across domains — each domain is scored independently
- The merged scorecard has all domains under `.domains`: `{"frontend": {...}, "backend": {...}}`
- **No shared dimensions** — `domain_spec_fidelity` in frontend is completely independent from `domain_spec_fidelity` in backend
- Each domain must independently meet its own thresholds

```bash
# Merge per-domain scorecards into a single merged scorecard
jq -s '
  { domains: (reduce .[] as $s ({}; . + ($s.domains // {}))) ,
    criteria: [.[] | .criteria[]?] }
' scorecard-*.json > scorecard.json

# Extract merged criteria
jq '.criteria' scorecard.json > criteria.json
```

On failure, the merged scorecard identifies which domain(s) failed. Pass the merged scorecard to `check-thresholds.sh` — it already handles multi-domain scorecards.

Both files (`scorecard.json` and `criteria.json`) are then passed to `check-thresholds.sh` in step 1h.

### 1h. Check Thresholds

<HARD-GATE>
After receiving evaluator scorecards, you MUST run:
  scripts/check-thresholds.sh --scorecard {scorecard_file} --criteria {criteria_file}
  scripts/check-convergence.sh --current {verdict_file} --history {history_file} --max-dispatches N --current-dispatches M
Act on the scripts' verdicts. Do NOT compute thresholds or convergence yourself.
</HARD-GATE>

Run `check-thresholds.sh` with the merged scorecard (from step 1g). It produces a verdict: `PASS` (exit 0) or `FAIL` (exit 1). The output includes a `dimensions` flat map (`{"frontend.correctness": 8, "backend.api_quality": 7, ...}`) with all per-domain dimension scores. On `FAIL`, the output identifies which domain(s) did not meet thresholds. This output can be passed directly to `check-convergence.sh` as the `--current` file and appended to the history array for future convergence checks.

### 1i. Check Convergence

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

### 1j. Log Evaluation

<HARD-GATE>
After every evaluation cycle, you MUST run:
  scripts/append-eval-log.sh --bean-id {id} --iteration {N} --scorecard {scorecard_file} --dispatches {count} --guidance {text}
Do NOT skip logging. Do NOT write the log entry manually.
</HARD-GATE>

### 1k. Act on Convergence Result

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

### 2b. Dispatch Holistic Reviewer

Dispatch a subagent using `skills/develop/holistic-review.md`. Provide:

- The full diff since the epic's base SHA (before any task started): `git diff {epic-base-sha}...HEAD`
- The design spec / plan document
- All task bean bodies (for spec requirements): `beans list --parent <epic-id> --json`
- Runtime state for ALL domains (ports, domain names, ready status)

The holistic reviewer produces a single JSON scorecard with:
- `domain: "holistic"` with dimensions: `integration`, `coherence`, `holistic_spec_fidelity`, `polish`, `runtime_health`
- `spec_coverage_matrix` — JSON array classifying every spec requirement as Full/Weak/Missing
- `remediation_beans` — JSON array of remediation tasks for gaps

Save the scorecard:

```bash
cat > scorecard-holistic.json   # ← holistic reviewer output
```

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
- **Single provider:** The evaluator scorecard IS the final scorecard. No `merge-scorecards.sh` needed (M4 adds multi-provider).
- ~~**No runtime:**~~ Runtime lifecycle added in M2. Start/stop runtimes around evaluator dispatch when domain has runtime configured.
- ~~**No holistic review:**~~ Holistic review added in M3. After per-task loop, dispatch holistic reviewer for cross-domain integration check with remediation loop.
- **No attended gate:** All evaluation is unattended. The `attended` config key is read but ignored (M5 adds attended mode).
- **No antipatterns:** No antipattern detection layer (M5 adds this).

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
