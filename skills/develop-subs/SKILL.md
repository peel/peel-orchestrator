---
name: fiddle:develop-subs
description: Execute beans tasks using subagents with ralph loop pattern. Implementers and review coordinators are background subagents; coordinators manage the review pipeline and return a verdict. Supports configurable parallelism.
disable-model-invocation: true
argument-hint: [--epic <id>] [--workers 10] [--max-review-cycles 10] [--max-impl-turns 100] [--max-review-turns 100] [--ci-max-retries 3] [--stall-timeout-min 15] [--stall-max-respawns 2] [--caller <name>]
---

# Ralph — Subagent Variant

Read `skills/ralph/ralph-core.md` for the shared loop (configuration, setup, assess-and-act, result handling, spawning, rules). This file covers subagent-specific behavior only.

**Variant identifier:** When stripping `<!-- VARIANT:... -->` sections from role templates, keep `<!-- VARIANT:subs -->` blocks and remove `<!-- VARIANT:team -->` blocks.

## Additional Configuration

- `--caller <name>` (default: none) — when set, output machine-readable `RALPH_STATUS` on exit

## Variant Setup (after core setup step 4)

No additional setup required. Fall through to "Assess and Act".

## Event Handling

You are notified when background tasks finish. The notification includes the task name and ID. For each:

1. Identify the bean from the task name (`impl-{bean-slug}` or `review-{bean-slug}-c{cycle}`)
2. Read the result: `TaskOutput(task_id: <id>, block: false, timeout: 5000)`
3. Confirm via `BEANS_LIST` — check bean's role tag: `role:implement` or `role:review`
4. Follow "Handling Results" in `skills/ralph/ralph-core.md`

**Additional tag management on implementer → review transition:**
```bash
beans update {id} --remove-tag role:implement --remove-tag bg-task:{old_task_id} --remove-tag ci-retries --remove-tag stall-respawns --tag role:review
```

**On review coordinator spawn:** Update bg-task tag:
```bash
beans update {id} --remove-tag bg-task:{old_task_id} --tag bg-task:{new_task_id}
```

**User interrupts (esc) or says to proceed:** "Assess and Act" immediately. For `in-progress` beans with `bg-task:*` tag, check task status via `TaskOutput(block: false)`. If completed, process result. If no active task, respawn.

## Agent Spawn Config

All agents are subagents (no `team_name`). The coordinator internally spawns reviewer sub-tasks — the lead never spawns reviewers directly.

```
Agent(
  name: "impl-{bean-slug}[-fix{cycle}]",    # or "review-{bean-slug}-c{cycle}"
  subagent_type: "general-purpose",
  model: <models.develop>,  # from orchestrate.json; if "default", omit to inherit session model
  mode: "bypassPermissions",
  run_in_background: true,
  max_turns: <max-impl-turns or max-review-turns>,
  prompt: <substituted template>
)
beans update {id} --tag bg-task:{task_id}
```

## Completion

**If needs-attention beans exist:**
```
RALPH_STATUS: PARKED
Needs-attention beans:
- <bean-id>: <title> — <reason from tags/event log>
- ...
```

**If all beans completed:**
- Run "Epic Holistic Review" from `skills/ralph/roles/lead-procedures.md`, then "Cleanup"
- If `--caller` was set: output `RALPH_STATUS: COMPLETE\nCompleted: <N> beans, Needs-attention: <M> beans`
- If no `--caller` flag: remind the user: "Epic complete. Run `/fiddle:deliver-docs --epic <id>` to update project docs."

## Additional Rules

- Tag beans with `bg-task:{task_id}` on spawn, remove on completion
- No `team_name` — all agents are subagents returning results directly
