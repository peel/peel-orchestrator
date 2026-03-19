---
name: fiddle:develop
description: Run the DEVELOP phase — execute implementation plan via ralph (subs or team), handle failures and respawn loops, run holistic review. Requires an epic with beans ready.
argument-hint: --epic <id> [--workers 2] [--max-review-cycles 3] [--max-total-turns 200]
---

# Develop

Execute an implementation plan by spawning ralph workers, handling failures, and running holistic review when all beans are complete.

ARGUMENTS: {ARGS}

## Configuration

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--epic <id>` | **required** | The epic to develop |
| `--workers <N>` | from config | Parallel worker count for ralph |
| `--max-review-cycles <N>` | from config | Max review cycles before escalating |
| `--max-total-turns <N>` | from config | Max agent turns for ralph subagent |
| `--execution <mode>` | from config | Pre-select execution mode (skip prompt) |

### Config File

Read `orchestrate.conf` (project root) if it exists. Extract:
- `ralph {}` block — workers, max_review_cycles, max_impl_turns, max_review_turns, max_total_turns, ci_max_retries, stall_timeout_min, stall_max_respawns
- `models.develop` — model for implementers, reviewers, ralph orchestrator
- `providers.develop_holistic` — provider list for holistic review (default: `["codex"]`)
- Provider declarations for holistic review providers
- `develop.execution` — pre-configured execution mode

CLI flags override config file values. Defaults when no config:
- workers: 2, max_review_cycles: 3, max_impl_turns: 50, max_review_turns: 30, max_total_turns: 200
- ci_max_retries: 3, stall_timeout_min: 15, stall_max_respawns: 2

## Steps

### Step 0: Validate Epic

```bash
beans show <epic-id> --json
```

Confirm it exists and has child beans. If no child beans, stop: "No beans found for this epic. Run `/fiddle:define` first."

### Step 1: Execution Choice

Check for `--execution` flag or `develop.execution` in config. If set, use that value without prompting. If not set, present options and **wait for the user to pick a number**:

```
"Beans are ready. Pick an execution mode (1-4):

1. Ralph Subs — automated background subagent with implement/review cycles
2. Tmux Team — parallel workers in tmux panes via conductor agent
3. Hands-on (this session) — superpowers:subagent-driven-development with human checkpoints
4. Hands-on (parallel session) — superpowers:executing-plans in a new session"
```

<HARD-GATE>
Do NOT proceed until the user has explicitly chosen 1, 2, 3, or 4. Do NOT assume a default. Do NOT auto-select. Wait for their response.
</HARD-GATE>

- **If Ralph Subs:** proceed to Step 2 as normal.
- **If Tmux Team:** proceed to Step 2 but use `develop-team` (team variant) instead of `develop-subs`.
- **If Hands-on (this session):** invoke `Skill(skill: "superpowers:subagent-driven-development")`. When execution completes, proceed to Step 4 (Holistic Review).
- **If Hands-on (parallel session):** guide the user to open a new session and run `superpowers:executing-plans`. Wait for the user to signal completion, then proceed to Step 4 (Holistic Review).

### Step 2: Spawn Ralph

Which variant depends on the execution choice:
- **Ralph Subs (option 1):** `../develop-subs/SKILL.md` (resolve relative to this skill's base directory)
- **Tmux Team (option 2):** `../develop-team/SKILL.md`

Use the Read tool to load the SKILL.md file. Do NOT use the Skill tool — these skills have `disable-model-invocation` since they are agent prompts, not directly invocable skills.

<HARD-GATE>
The two variants use COMPLETELY DIFFERENT dispatch mechanisms. Do NOT mix them up.
- Ralph Subs → spawn as a background **subagent** via `Agent()`
- Tmux Team → execute **inline in this session** (it needs TeamCreate/SendMessage which only work in the main session)
</HARD-GATE>

**Ralph Subs dispatch:**

```
ralph_task = Agent(
  name: "ralph-develop-<epic-id>",
  subagent_type: "general-purpose",
  model: <models.develop>,  # if "default", omit model parameter to inherit session model
  mode: "bypassPermissions",
  run_in_background: true,
  max_turns: <max_total_turns>,
  prompt: "<contents of develop-subs/SKILL.md, with the following args substituted:>
    --epic <epic-id> --workers <workers> --max-review-cycles <max_review_cycles>
    --max-impl-turns <max_impl_turns> --max-review-turns <max_review_turns>
    --ci-max-retries <ci_max_retries> --stall-timeout-min <stall_timeout_min>
    --stall-max-respawns <stall_max_respawns> --caller orchestrate"
)
```

Wait for the result:
```
result = TaskOutput(task_id: ralph_task.id, block: true, timeout: 3600000)
```

**Tmux Team dispatch:**

Read develop-team/SKILL.md and follow its instructions directly in this session. You ARE the team lead. Execute the Setup, then the "Assess and Act" loop. The SKILL.md uses TeamCreate, TaskCreate, and SendMessage — these only work in the main session, NOT inside a subagent.

Pass these args to the instructions:
```
--epic <epic-id> --workers <workers> --max-review-cycles <max_review_cycles>
--max-impl-turns <max_impl_turns> --max-review-turns <max_review_turns>
```

When all beans are complete or parked, proceed to Step 3.

For `critical` and `high` priority beans (either variant): include in the prompt an instruction for the review coordinator to additionally request a code review from configured DEVELOP providers via the provider-dispatch procedure.

### Step 3: Handle Ralph Result

**Tmux Team:** You are already in the session — skip parsing. If all beans are complete, proceed to Step 4. If beans are parked with `needs-attention`, present them to the user (same as Case 2 below). After the user addresses them, loop back to Step 2 and resume the develop-team instructions.

**Ralph Subs:** Parse the `result` from Step 2:

**Case 1 — `RALPH_STATUS: COMPLETE`:**
Ralph finished all beans successfully. Proceed to Step 4 (Holistic Review).

**Case 2 — `RALPH_STATUS: PARKED`:**
Some beans need attention. Parse the needs-attention bean list from the result.

Present to user:
```
"Waiting on your input for N beans:
- <bean-id>: <title> — <reason>
- ...

You can: fix the issue and remove needs-attention tag, scrub the bean, or rework the scope."
```

Wait for the user to address the parked beans. When they respond, respawn ralph — loop back to Step 2. **Re-use the identical SKILL.md prompt from the first spawn** — do NOT write a custom or simplified prompt. Ralph discovers current state from `beans list`.

**Case 3 — Empty result, error, or max_turns exhausted:**
Check bean state:
```bash
beans list --parent <epic-id> --json
```

Present bean summary to user (completed, in-progress, todo, needs-attention counts). Ask: "Ralph's context was exhausted. Respawn to continue, or proceed to holistic review with current state?"

- If user says respawn → loop to Step 2. **Re-use the identical SKILL.md prompt** — do NOT write a simplified prompt.
- If user says proceed → Step 4

### Step 4: Holistic Review

When all epic beans are `completed` or `needs-attention` (none in `todo` or `in-progress`):

1. If holistic review providers are configured, read the provider dispatch and context procedures (resolve relative to this skill's base directory):
   - `../develop-subs/roles/provider-dispatch.md`
   - `../develop-subs/roles/provider-context.md`

   Follow the dispatch procedure for each provider with:

   - `PROVIDER_ROLE` = "Holistic reviewer"
   - `TOPIC` = "Epic holistic review for `<epic-id>`"
   - `DESIGN_DOC` = `<design doc content>`
   - `DIFF` = `<git diff main...HEAD>`
   - `INSTRUCTIONS` = "Did the implementation match the design? Flag: inconsistencies, missed requirements, naming conflicts, dead code."

   Dispatch all providers in parallel. Collect results in **unattended** mode (first-past-the-post).

2. If no provider is available, perform the holistic review yourself: read the design doc, review the full diff, and compare.
3. If holistic review creates fix beans → loop to Step 2. **Re-use the identical SKILL.md prompt from the original spawn** — Ralph discovers new beans via `beans list`. Do NOT write a custom prompt for fix cycles.
4. If clean → done.
