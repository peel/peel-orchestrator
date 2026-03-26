---
name: fiddle:develop-team
description: Execute beans tasks using agent teams with ralph loop pattern. Implementers and review coordinators are teammates; coordinators manage the review pipeline and report a single verdict. Supports configurable parallelism.
disable-model-invocation: true
argument-hint: [--epic <id>] [--workers 10] [--max-review-cycles 10] [--max-impl-turns 100] [--max-review-turns 100]
---

# Ralph — Team Variant

Read `skills/ralph/ralph-core.md` for the shared loop (configuration, setup, assess-and-act, result handling, spawning, rules). This file covers team-specific behavior only.

**Variant identifier:** When stripping `<!-- VARIANT:... -->` sections from role templates, keep `<!-- VARIANT:team -->` blocks and remove `<!-- VARIANT:subs -->` blocks.

## Variant Setup (after core setup step 4)

5. `TeamCreate` with team_name: `"develop-team-{unix-timestamp}"`
6. `TaskCreate` for each non-completed bean (subject: `"{bean-id}: {bean-title}"`, mirror `blocked-by` with `addBlockedBy`)
7. Fall through to "Assess and Act"

## Event Handling

Act IMMEDIATELY on each message. Do NOT wait for other teammates. Do NOT batch completions. Do NOT send shutdown_request mid-work.

**Implementer reports done:**
- Follow "Handling Results → Implementer Result" in `skills/ralph/ralph-core.md`
- On transition to review: `beans update {id} --remove-tag role:implement --remove-tag spawned-at --tag role:review`

**Review coordinator reports verdict:**
- Follow "Handling Results → Review Verdict" in `skills/ralph/ralph-core.md`
- On APPROVED: also mark team task completed

**Implementer requests integration test lock:**
- No holder → grant: `SendMessage(type: "message", recipient: <name>, content: "Integration test lock granted. Notify me when done.", summary: "Lock granted")`
- Holder exists → deny: `SendMessage(type: "message", recipient: <name>, content: "Lock held by {holder}. Use -short.", summary: "Lock denied")`
- Lock released → clear tag, notify queued requesters
- Track via bean tag: `integration-lock:{teammate-name}`

**Implementer idle (no prior message):** Stale — read `skills/ralph/roles/lead-procedures.md` → "Abandon Bean". STOP.

**Implementer idle (already reported):** IGNORE. STOP.

**Review coordinator idle (no prior verdict):** Stale review — coordinator hit max_turns. Find bean with `role:review` tag. If cycle >= max_review_cycles → "Abandon Bean". Otherwise: increment cycle, respawn review coordinator. STOP.

**Review coordinator idle (already reported verdict):** IGNORE. STOP.

**Noise messages ("Noted", "Acknowledged", etc.):** IGNORE. STOP.

**User interrupts (esc) or says to proceed:** "Assess and Act" immediately. Re-read tags, respawn agents for `in-progress` beans with no active agents.

## Agent Spawn Config

Both implementers and review coordinators are teammates (spawned with `team_name`). The coordinator internally spawns reviewer sub-tasks — the lead never spawns reviewers directly.

```
Agent(
  name: "impl-{bean-slug}[-fix{cycle}]",    # or "review-{bean-slug}-c{cycle}"
  subagent_type: "general-purpose",
  model: <models.develop>,  # from orchestrate.json; if "default", omit to inherit session model
  mode: "bypassPermissions",
  team_name: <team>,
  run_in_background: true,
  max_turns: <max-impl-turns or max-review-turns>,
  prompt: <substituted template>
)
```

## Feature Expansion Extra

When expanding features in "Assess and Act", also `TaskCreate` for new children discovered during expansion.
When completing features, also mark the team task completed.

## Additional Rules

- The lead spawns only two kinds of agents: **implementers** and **review coordinators**. Both are teammates (`team_name` present).
- Never send shutdown_request except during final Cleanup
