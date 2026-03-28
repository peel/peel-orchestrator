---
name: fiddle:patch-superpowers
description: Use after updating the superpowers plugin to re-apply beans integration patches to brainstorming, writing-plans, executing-plans, and subagent-driven-development skills.
---

# Patch Superpowers for Beans Integration

## Overview

After updating the superpowers plugin, run this skill to re-apply beans integration. Patches four cached skills in-place: `brainstorming`, `writing-plans`, `executing-plans`, and `subagent-driven-development`. Also removes `finishing-a-development-branch` from execution skills and simplifies isolation tags.

**Announce:** "Patching superpowers for beans integration."

## Step 0: Reset Superpowers (user action)

Tell the user: "Before I patch, reinstall superpowers to get fresh files. Run: `! /plugin install superpowers`"

Wait for the user to confirm the reinstall completed before proceeding. Fresh files ensure all patches apply cleanly.

## Step 1: Find the Superpowers Cache

```bash
find "$CLAUDE_CONFIG_DIR/plugins/cache/superpowers-marketplace" -name "SKILL.md" | grep -E "(brainstorming|writing-plans|executing-plans|subagent-driven-development)/" | sort
```

All skills should be siblings under the same version directory.

## Step 2: Check Patch State

Read all four files. Check for the marker `[BEANS-PATCHED]` at the end of each. If Step 0 ran successfully, none should have the marker. If all are already patched (Step 0 was skipped), report "Already patched" and stop. Patch only the files that are missing the marker.

## Step 3: Patch Brainstorming

**Purpose:** Add panel enrichment after approach generation and orchestrate-aware terminal state via `--from-orchestrate` flag.

**3a.** After the frontmatter closing `---`, insert an ARGS line. Replace:

```
# Brainstorming Ideas Into Designs
```

With:

```
# Brainstorming Ideas Into Designs

ARGUMENTS: {ARGS}

## Configuration

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--skip-panel` | false | Skip panel enrichment after proposing approaches |
| `--from-orchestrate` | false | Return control after design doc instead of chaining to writing-plans |
```

**3b.** In the Checklist section, replace item 4:

```
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
```

With:

```
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Panel enrichment** — if `--skip-panel` not set and external providers available (codex MCP tool or gemini on PATH), invoke `fiddle:panel` with the proposed approaches. Present panel commentary (consensus, disagreements, tradeoffs) alongside the approaches when asking the user to pick.
```

Renumber subsequent items (old 5→6, 6→7, 7→8, 8→9, 9→10).

**3c.** In the Process Flow graph, insert the panel enrichment node. Replace:

```
    "Propose 2-3 approaches" -> "Present design sections";
```

With:

```
    "Propose 2-3 approaches" -> "Panel enrichment?" [label="--skip-panel not set\nand providers available"];
    "Propose 2-3 approaches" -> "Present design sections" [label="--skip-panel set\nor no providers"];
    "Panel enrichment?" -> "Present design sections";
```

Add the node declaration:
```
    "Panel enrichment?" [shape=diamond];
```

**3d.** In the Process Flow graph, replace the terminal transition. Replace:

```
    "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
```

With:

```
    "User reviews spec?" -> "--from-orchestrate?" [label="approved"];
    "--from-orchestrate?" -> "STOP" [label="flag set"];
    "--from-orchestrate?" -> "Invoke writing-plans skill" [label="flag not set"];
```

Add node declarations:
```
    "--from-orchestrate?" [shape=diamond];
    "STOP" [shape=doublecircle];
```

**3e.** Replace the terminal state text after the graph. Replace:

```
**The terminal state is invoking writing-plans.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The ONLY skill you invoke after brainstorming is writing-plans.
```

With:

```
**Terminal state:** After writing the design doc, check if `--from-orchestrate` was set in `{ARGS}`. If set, STOP — do not invoke writing-plans. Control returns to the caller. If not set (standalone use), invoke writing-plans as the next step. Do NOT invoke frontend-design, mcp-builder, or any other implementation skill.
```

**3f.** In the "After the Design" section, replace the Implementation subsection:

```
**Implementation:**
- Invoke the writing-plans skill to create a detailed implementation plan
- Do NOT invoke any other skill. writing-plans is the next step.
```

With:

```
**Implementation:**
- If `--from-orchestrate` is set: STOP here. Do not invoke writing-plans. Control returns to the caller.
- If not set: invoke the writing-plans skill to create a detailed implementation plan. Do NOT invoke any other skill.
```

**3g.** Patch the spec save path to be config-aware. Replace:

```
- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
  - (User preferences for spec location override this default)
```

With:

```
- Read `orchestrate.json` (project root). If `plans.path` is set, use `{plans.path}/specs`. Otherwise use `docs/superpowers/specs`.
- Write the validated design (spec) to `{specs_dir}/YYYY-MM-DD-<topic>-design.md`
  - (User preferences for spec location override both config and defaults)
- If `orchestrate.json` has `plans.commit = false`, skip the git commit of the spec file.
```

Append marker: `<!-- [BEANS-PATCHED] -->`

**Verify:** Read the patched brainstorming file and confirm:
- Has ARGS line with `--skip-panel` and `--from-orchestrate` flags
- Checklist has panel enrichment item
- Process flow has panel and `--from-orchestrate` nodes
- Terminal state is flag-dependent
- Has `[BEANS-PATCHED]` marker

## Step 4: Patch Writing-Plans

**Purpose:** Add ARGS processing, config-aware paths, and beans creation step.

**4a.** Add ARGS line and config reading. Replace:

```
**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)
```

With:

```
ARGUMENTS: {ARGS}

### Configuration

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--from-orchestrate` | false | Return control after beans instead of presenting execution handoff |

### Plans Config

Read `orchestrate.json` (project root) if it exists. Extract from `plans {}` block:
- `plans.path` — parent directory for specs and plans (default: `docs/superpowers`)
- `plans.commit` — whether to git commit plan/spec files (default: `true`)

**Save plans to:** `{plans.path}/plans/YYYY-MM-DD-<feature-name>.md` (resolved from config or superpowers default).
- User preferences for plan location override both config and defaults.
- If `plans.commit` is false, skip all `git add` and `git commit` steps for plan documents.
```

**4b.** Insert a new section BEFORE `## Execution Handoff`:

```markdown
## Create Beans from Plan

After saving the plan, create beans tasks from it. Beans are state-tracked pointers back to the plan.

**Bean sizing:** For each `### Task N:` heading, follow the `define-beans` skill to determine if it should be a task bean (1-2 TDD cycles) or a feature bean with child tasks (3+ TDD cycles).

Bean descriptions MUST be self-contained — include the complete step-by-step instructions from the plan so that automated agents can work from the bean body alone without reading the plan file. The plan file path is included for human reference only.

\```bash
# If multiple related tasks, create an epic parent first
beans create "Epic: <feature name>" --json -t epic -s todo -d "Implementation of <feature>. Plan: <plan-path>"

# Create a bean per task — inline the FULL task content from the plan
# <plan-path> is the actual path the plan was saved to above
beans create "Task N: <title>" --json -t task -s todo -p <priority> --parent <epic-id> -d "Plan: <plan-path> Task N

Files:
- <file list from plan>

Steps:
<paste the complete step-by-step instructions from the ### Task N section>

Acceptance criteria:
- <from plan>"

# Set dependencies (sequential by default unless clearly independent)
beans update <task-2-id> --blocked-by <task-1-id>
\```

**Bean body content:** Extract the full content of each `### Task N:` section — all steps, code snippets, expected outputs, commit instructions. The bean body is what the implementer agent receives as `{BEAN_BODY}`. If the body is incomplete, the agent will guess or fail.

**Priority:** critical > high > normal > low (based on how many others a task blocks).

All beans use worktrees by default when `--workers > 1`. No isolation tags needed.

**Verify (HARD GATE — do NOT proceed until all checks pass):**
\```bash
beans list
beans roadmap
\```

<HARD-GATE>
For EACH bean, run `beans show {id} --json | jq -r '.body' | wc -l`. If ANY bean body is under 10 lines, STOP. The bean body is a pointer, not self-contained content. Go back and replace it with the full task steps from the plan.

Bean bodies that say "Plan: ... Task N" or "See plan" are FAILURES. The implementer agent receives ONLY the bean body — it cannot read the plan file. Every step, code snippet, expected output, and commit instruction from the `### Task N:` section must be in the bean body.

After body check passes, spawn a coverage verification subagent. Do NOT proceed until it reports no gaps:

\```
Agent(
  subagent_type: "general-purpose",
  mode: "bypassPermissions",
  prompt: "Read the design doc at <spec-path>, the plan at <plan-path>, and the bean list from `beans list --parent <epic-id> --json`. For each bean, read its full body via `beans show {id} --json`.

  Verify:
    1. Every requirement in the design spec has at least one bean covering it
    2. Every task in the plan has a corresponding bean
    3. Bean bodies contain actual step-by-step instructions (not pointers)
    4. Bean bodies are not truncated (compare line count against plan task)
    5. Dependencies correctly reflect the plan's task ordering
    6. No design section is missing bean coverage

  Report: covered requirements, gaps found, truncations, and any drift.
  If ALL checks pass, report COVERAGE_COMPLETE.
  If ANY check fails, report COVERAGE_GAPS with specifics."
)
\```

If the subagent reports COVERAGE_GAPS: fix the gaps (create missing beans, flesh out truncated bodies, fix dependencies). Re-run the coverage check. Do NOT proceed until COVERAGE_COMPLETE.
</HARD-GATE>

**Commit beans to repository:**
\```bash
git add .beans/
git commit -m "Add beans for <epic-name>"
\```

**Restart safety:** Execution is interrupt-safe. On restart, `in-progress` beans are picked up first (resuming interrupted work), then `todo` beans. Completed beans are skipped. No manual cleanup needed after an interruption.
```

**4c.** Insert orchestrate-aware handoff before the Execution Handoff section. Add immediately before `## Execution Handoff`:

```markdown
## Orchestrate Context Check

Before presenting the execution handoff, check if `--from-orchestrate` was set in `{ARGS}`.

If set: STOP here. Do not present execution options. Report: "Plan complete. Beans created. Returning control to orchestrate." Control returns to the caller which will handle execution in the DEVELOP phase.

If not set: proceed to Execution Handoff below.
```

**4d.** Update the Execution Handoff:

Replace `Two execution options` with `Beans created. Four execution options`.

Insert before `**Which approach?"**`:
```
**3. Beans Batch (separate session)** - Open new session with executing-plans, batch execution using beans for state tracking

**4. Swarm (hands-off)** - Run `/fiddle:develop-swarm --epic <epic-id>` — automated parallel agents with implement/review cycles, no human checkpoints
```

After the `**If Inline Execution chosen:**` block, add:
```
**If Beans Batch chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans
- Beans are already created — executor uses `beans list --json` to find them

**If Swarm chosen:**
- Guide them to open new session (optionally in worktree)
- Run `/fiddle:develop-swarm --epic <epic-id>` with appropriate flags (e.g., `--workers 2`)
- The `--epic` flag scopes execution to only beans under this epic — safe when other beans exist
- Beans are self-contained — agents work from bean bodies directly, no plan file needed
- Fully automated: implement → review → fix cycles until all beans complete
```

Append marker: `<!-- [BEANS-PATCHED] -->`

## Step 5: Patch Executing-Plans

**Purpose:** Use `beans` CLI for state tracking instead of TodoWrite.

**5a.** In Step 1 (Load and Review Plan), replace:
```
4. If no concerns: Create TodoWrite and proceed
```
With:
```
4. If no concerns: Run `beans list --json` to load beans and proceed
```

**5b.** In Step 2 (Execute Batch), replace:
```
For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed
```
With:
```
For each actionable bean (`in-progress`, or `todo` with no unresolved `blocked-by`), prioritizing `in-progress` first:
1. If status is `todo`: `beans update {id} --status in-progress`
2. Read the bean description for plan file and task number
3. Read the corresponding task section from the plan markdown
4. Follow each step exactly (plan has bite-sized steps)
5. Run verifications as specified
6. `beans update {id} --status completed`
```

**5c.** In the Remember section, add these bullets:
```
- `beans update --status in-progress` before starting each bean
- `beans update --status completed` after finishing each bean
- Safe to restart — `in-progress` beans are picked up first, then `todo` beans
```

Append marker: `<!-- [BEANS-PATCHED] -->`

## Step 6: Patch Subagent-Driven-Development for Beans

**Purpose:** Replace TodoWrite usage with beans CLI for state tracking.

**6a.** In the Process Flow graph, replace the initial node. Replace:

```
    "Read plan, extract all tasks with full text, note context, create TodoWrite" [shape=box];
```

With:

```
    "Read plan, extract all tasks with full text, note context, load beans via beans list --json" [shape=box];
```

And replace the edge from this node:

```
    "Read plan, extract all tasks with full text, note context, create TodoWrite" -> "Dispatch implementer subagent (./implementer-prompt.md)";
```

With:

```
    "Read plan, extract all tasks with full text, note context, load beans via beans list --json" -> "Dispatch implementer subagent (./implementer-prompt.md)";
```

**6b.** In the Process Flow graph, replace the TodoWrite completion node. Replace:

```
        "Mark task complete in TodoWrite" [shape=box];
```

With:

```
        "beans update {id} --status completed" [shape=box];
```

And replace both edges referencing this node. Replace:

```
    "Code quality reviewer subagent approves?" -> "Mark task complete in TodoWrite" [label="yes"];
    "Mark task complete in TodoWrite" -> "More tasks remain?";
```

With:

```
    "Code quality reviewer subagent approves?" -> "beans update {id} --status completed" [label="yes"];
    "beans update {id} --status completed" -> "More tasks remain?";
```

**6c.** In the Example Workflow section, replace:

```
[Create TodoWrite with all tasks]
```

With:

```
[Load beans via beans list --json]
```

And replace:

```
[Mark Task 1 complete]
```

With:

```
[beans update {id} --status completed]
```

And replace:

```
[Mark Task 2 complete]
```

With:

```
[beans update {id} --status completed]
```

Append marker: `<!-- [BEANS-PATCHED] -->`

## Step 7: Remove finishing-a-development-branch

**Purpose:** Remove `finishing-a-development-branch` references from both `subagent-driven-development` and `executing-plans`. Execution skills should return control to the caller instead.

### 7a. Patch subagent-driven-development

In the Process Flow graph, remove the final reviewer and finishing nodes. Replace:

```
    "Dispatch final code reviewer subagent for entire implementation" [shape=box];
    "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];
```

With:

```
    "Return control to the caller" [shape=doublecircle];
```

Replace the edges from "More tasks remain?" onward. Replace:

```
    "More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
    "Dispatch final code reviewer subagent for entire implementation" -> "Use superpowers:finishing-a-development-branch";
```

With:

```
    "More tasks remain?" -> "Return control to the caller" [label="no"];
```

In the Example Workflow section, replace:

```
[After all tasks]
[Dispatch final code-reviewer]
Final reviewer: All requirements met, ready to merge

Done!
```

With:

```
[After all tasks — return control to the caller]
```

In the Integration section, remove `finishing-a-development-branch` from Required workflow skills. Replace:

```
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
```

With nothing (delete the line).

### 7b. Patch executing-plans

In Step 3, replace the entire section. Replace:

```
### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice
```

With:

```
### Step 3: Complete Development

After all tasks complete and verified:
- Return control to the caller. Do not invoke finishing-a-development-branch.
```

In the Integration section, remove `finishing-a-development-branch` from Required workflow skills. Replace:

```
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
```

With nothing (delete the line).

## Step 8: Remove Isolation Tags from Writing-Plans

This is already handled by the modified Step 4b content above. The `--tag worktree`/`--tag branch` isolation table and surrounding paragraphs have been replaced with a single line: "All beans use worktrees by default when `--workers > 1`. No isolation tags needed."

## Step 9: Verify

Read all four patched files and confirm:
- Brainstorming → has ARGS line with `--skip-panel` and `--from-orchestrate` flags, checklist has panel enrichment item, process flow has panel and `--from-orchestrate` nodes (intercepting after spec review), terminal state is flag-dependent, spec path is config-aware
- Writing-plans → has ARGS line with `--from-orchestrate` flag, reads `orchestrate.json` for `plans.path` (parent dir) and `plans.commit`, has "Create Beans from Plan" section with `<plan-path>` references (not hardcoded), has "Orchestrate Context Check" before handoff, handoff has 4 options (including Ralph Beans), no isolation tag table
- Executing-plans → Step 1 uses `beans list`, Step 2 uses `beans update`, Remember has beans bullets, Step 3 returns control (no finishing-a-development-branch)
- Subagent-driven-development → uses `beans list --json` instead of `create TodoWrite`, uses `beans update {id} --status completed` instead of `Mark task complete in TodoWrite`, no final code reviewer dispatch, no finishing-a-development-branch
- All four have `[BEANS-PATCHED]` marker

Report: "Superpowers patched. Flow: brainstorming (with panel enrichment) → writing-plans (with beans) → executing-plans OR develop-swarm."
