---
name: fiddle:develop
description: Execute an epic via the evaluator loop — validate beans, implement per-task, holistic review, finish.
argument-hint: --epic <id>
---

# Develop — Evaluator Loop

Execute an implementation plan by iterating: validate → implement per-task → holistic review → finish.

**Announce:** "I'm using fiddle:develop to implement this epic via the evaluator loop."

ARGUMENTS: {ARGS}

## Iron Laws

These apply to EVERY task. There are no exceptions.

1. Every task gets evaluated through the full loop. No exceptions for domain, complexity, or task type.
2. Every evaluation uses the full chain: domain resolution → implementer → evaluator → scorecard merge → convergence scripts.
3. "General" domain is not "optional" domain. No configured runtime does not mean no evaluation.
4. Implementer success is not evaluation. Self-reported passing is not convergence.
5. If you are thinking "this is straightforward enough to skip," that thought is the signal to not skip.

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

## Step 1: Bean Body Validation

<HARD-GATE>
Before entering the per-task loop, validate EVERY task/bug bean under the epic.
For each bean, the body MUST contain:
  1. An eval block (fenced ```eval block, or `domains:` + `criteria:` pattern)
  2. A files section (at least one line matching `- Create:`, `- Modify:`, `- Test:`, or `Files:`)
  3. A steps checklist (at least one `- [ ]` checkbox item)

If ANY bean fails validation, STOP. Report which beans failed and what is missing:
  "Bean <id> has an incomplete body. Implementer agents work from the bean body alone —
  thin bodies produce thin implementations.
  Missing: [eval block | files section | steps checklist]
  Fix the bean body before proceeding."

Do NOT enter the per-task loop with incomplete beans.
Do NOT silently skip validation.
Feature beans that are purely containers for child task beans are exempt.
</HARD-GATE>

## Step 2: Per-Task Loop

Process each task bean sequentially. For each bean:

```
Skill("fiddle:develop-loop", args: "--bean <bean-id> --epic <epic-id>")
```

The develop-loop sub-skill handles the full evaluation cycle for one bean: dispatch implementer, dispatch evaluators, merge scorecards, check convergence, iterate until converged or budget exceeded.

Each bean returns as either `completed` or `needs-attention` (escalated). Skip beans already marked `completed`.

## Step 3: Holistic Review

After all task beans are processed (completed or escalated):

```
Skill("fiddle:develop-holistic", args: "--epic <epic-id>")
```

The develop-holistic sub-skill assesses the full system as an integrated whole, creates remediation beans if needed, and iterates until the holistic review converges or is escalated.

<HARD-GATE>
Holistic review is mandatory. Do NOT skip to Step 4.
Do NOT invoke finish-branch before holistic review has CONVERGED or been escalated.
</HARD-GATE>

## Step 4: Completion

```
Skill("fiddle:finish-branch")
```

User picks: merge, PR, keep, or discard. Worktree cleanup happens here.

## Restart Resilience

On session restart, develop re-derives state entirely from beans:

1. List epic's task beans via `beans list --parent <epic-id> --json`
2. Find any bean with `in-progress` status
3. For in-progress beans: invoke `Skill("fiddle:develop-loop", args: "--bean <id> --epic <epic-id>")` — the loop handles its own restart detection via parse-eval-log.sh + assess-git-state.sh
4. Skip already-`completed` beans
5. Process remaining `todo` beans normally
6. After all task beans are processed, check if holistic review already ran by looking for `scorecard-holistic.json` and holistic history file. If in progress or not started, invoke `Skill("fiddle:develop-holistic", args: "--epic <epic-id>")`

No session-scoped state to lose. All evaluation history lives on bean bodies.
