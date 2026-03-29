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
  - **CLEAN:** Code is committed. Resume from evaluation (step 1e) if last verdict was not CONVERGED, or skip to next task if CONVERGED.
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

### 1c. Dispatch Implementer

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

### 1d. Handle Implementer Status

The implementer returns one of:
- **DONE** or **DONE_WITH_CONCERNS** → proceed to evaluation (step 1e)
- **BLOCKED** → mark bean `needs-attention` with reason, escalate to human, move to next bean
- **NEEDS_CONTEXT** → provide the requested context and re-dispatch (back to step 1c)

### 1e. Dispatch Evaluator

Dispatch an evaluator subagent using `skills/evaluate/SKILL.md` protocol with the `evaluator-general` domain template (`skills/evaluate/evaluator-general.md`).

Provide:
- The full diff since BASE_SHA: `git diff {BASE_SHA}...HEAD`
- The bean's acceptance criteria
- The domain template's scoring dimensions

The evaluator returns a single scorecard JSON containing both per-dimension scores (under `.domains`) and pass/fail criteria (under `.criteria`). Before running threshold checks, save and split the output:

```bash
# Save the full scorecard (used by --scorecard)
cat > scorecard.json   # ← full evaluator output

# Extract criteria array into a separate file (used by --criteria)
jq '.criteria' scorecard.json > criteria.json
```

Both files are then passed to `check-thresholds.sh` in step 1f.

### 1f. Check Thresholds

<HARD-GATE>
After receiving evaluator scorecards, you MUST run:
  scripts/check-thresholds.sh --scorecard {scorecard_file} --criteria {criteria_file}
  scripts/check-convergence.sh --current {verdict_file} --history {history_file} --max-dispatches N --current-dispatches M
Act on the scripts' verdicts. Do NOT compute thresholds or convergence yourself.
</HARD-GATE>

Run `check-thresholds.sh` first. It produces a verdict: `PASS` (exit 0) or `FAIL` (exit 1). The output includes a `dimensions` flat map (`{"general.correctness": 8, ...}`) with all dimension scores. This output can be passed directly to `check-convergence.sh` as the `--current` file and appended to the history array for future convergence checks.

### 1g. Check Convergence

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

### 1h. Log Evaluation

<HARD-GATE>
After every evaluation cycle, you MUST run:
  scripts/append-eval-log.sh --bean-id {id} --iteration {N} --scorecard {scorecard_file} --dispatches {count} --guidance {text}
Do NOT skip logging. Do NOT write the log entry manually.
</HARD-GATE>

### 1i. Act on Convergence Result

| Result | Action |
|---|---|
| **CONVERGED** | Mark bean `completed`. Proceed to next task. |
| **FAIL** | Dispatch fresh implementer with scorecard feedback showing failing dimensions and fix guidance. → Back to step 1c. |
| **PASS_PENDING** | Re-evaluate without re-implementing — scorecard may stabilize. → Back to step 1e. |
| **PASS_REGRESSED** | Dispatch fresh implementer with regression details (which dimensions regressed and by how much). → Back to step 1c. |
| **DISPATCHES_EXCEEDED** | Mark bean `needs-attention`. Escalate to human. Move to next bean. |

## Step 2: Completion

After all task beans are completed (or escalated):

```
Skill("fiddle:finish-branch")
```

User picks: merge, PR, keep, or discard. Worktree cleanup happens here.

## M1 Simplifications

These constraints scope the evaluator loop for Milestone 1. Later milestones remove them:

- **Single domain:** Only `general` domain. No `resolve-domains.sh` needed (M2 adds multi-domain).
- **Single provider:** The evaluator scorecard IS the final scorecard. No `merge-scorecards.sh` needed (M3 adds multi-provider).
- **No runtime:** Evaluator reviews code only. No `start-runtimes.sh` / `stop-runtimes.sh` (M2 adds runtime).
- **No attended gate:** All evaluation is unattended. The `attended` config key is read but ignored (M5 adds attended mode).
- **No antipatterns:** No antipattern detection layer (M5 adds this).

## Red Flags

- **Never** dispatch an implementer without the full bean body and acceptance criteria
- **Never** dispatch without injecting relevant codebase context
- **Never** ignore BLOCKED or NEEDS_CONTEXT — something must change before re-dispatch
- **Never** skip evaluation even if the implementer self-reports success
- **Never** manually compute thresholds or convergence — always use the scripts
- **Never** exceed the dispatch budget without escalating to human
- **Never** invoke `fiddle:finish-branch` before all beans are completed or escalated
- **Never** write evaluation log entries manually — always use `append-eval-log.sh`

## Restart Resilience

On session restart, develop re-derives state entirely from beans:

1. List epic's task beans via `beans list --parent <epic-id> --json`
2. Find any bean with `in-progress` status
3. For each in-progress bean: run `parse-eval-log.sh` + `assess-git-state.sh` (see step 1a)
4. Resume the per-task loop from the appropriate point
5. Skip already-`completed` beans
6. Process remaining `todo` beans normally

No session-scoped state to lose. All evaluation history lives on bean bodies.
