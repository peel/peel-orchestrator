---
name: fiddle:patch-superpowers
description: Use after updating the superpowers plugin to re-apply beans integration patches to writing-plans and executing-plans skills.
---

# Patch Superpowers for Beans Integration

## Overview

After updating the superpowers plugin, run this skill to re-apply beans integration. Patches three cached skills in-place: `brainstorming`, `writing-plans`, and `executing-plans`.

**Announce:** "Patching superpowers for beans integration."

## Step 1: Find the Superpowers Cache

```bash
find "$CLAUDE_CONFIG_DIR/plugins/cache/superpowers-marketplace" -name "SKILL.md" | grep -E "(brainstorming|writing-plans|executing-plans)/" | sort
```

All skills should be siblings under the same version directory.

## Step 2: Check Patch State

Read all three files. Check for the marker `[BEANS-PATCHED]` at the end of each. If all are already patched, report "Already patched" and stop. Patch only the files that are missing the marker.

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

**3b.** In the Checklist section, replace item 3:

```
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
```

With:

```
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Panel enrichment** — if `--skip-panel` not set and external providers available (codex MCP tool or gemini on PATH), invoke `fiddle:panel` with the proposed approaches. Present panel commentary (consensus, disagreements, tradeoffs) alongside the approaches when asking the user to pick.
```

Renumber subsequent items (old 4→5, 5→6, 6→7).

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

**3d.** In the Process Flow graph, replace the terminal state. Replace:

```
    "Write design doc" -> "Invoke writing-plans skill";
```

With:

```
    "Write design doc" -> "--from-orchestrate?" [label="check flag"];
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

Append marker: `<!-- [BEANS-PATCHED] -->`

**Verify:** Read the patched brainstorming file and confirm:
- Has ARGS line with `--skip-panel` and `--from-orchestrate` flags
- Checklist has panel enrichment item
- Process flow has panel and `--from-orchestrate` nodes
- Terminal state is flag-dependent
- Has `[BEANS-PATCHED]` marker

## Step 4: Patch Writing-Plans

**Purpose:** Add beans creation step after saving the plan.

**4a.** Insert a new section BEFORE `## Execution Handoff`:

```markdown
## Create Beans from Plan

After saving the plan, create beans tasks from it. Beans are state-tracked pointers back to the plan.

**Bean sizing:** For each `### Task N:` heading, follow the `bean-decomposition` skill to determine if it should be a task bean (1-2 TDD cycles) or a feature bean with child tasks (3+ TDD cycles).

Bean descriptions MUST be self-contained — include the complete step-by-step instructions from the plan so that automated agents can work from the bean body alone without reading the plan file. The plan file path is included for human reference only.

\```bash
# If multiple related tasks, create an epic parent first
beans create "Epic: <feature name>" --json -t epic -s todo -d "Implementation of <feature>. Plan: docs/plans/<filename>.md"

# Create a bean per task — inline the FULL task content from the plan
# Use --tag worktree or --tag branch per isolation rules below
beans create "Task N: <title>" --json -t task -s todo -p <priority> --parent <epic-id> --tag <isolation> -d "Plan: docs/plans/<filename>.md Task N

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

**Isolation tags:** Each bean gets `--tag worktree` (default) or `--tag branch`. This controls how `ralph-beans-implement` runs it:

| Tag | Behavior | Use when |
|-----|----------|----------|
| `worktree` | Isolated `.worktrees/worker-{N}` dir. Fully parallel, no git locks needed. **Use by default.** | Almost always. Independent work with no coordination overhead. |
| `branch` | Main checkout, serialized (only ONE at a time), requires team lead git lock coordination. | Only for trivial single-file changes (updating a version, toggling a flag) where worktree setup cost isn't justified. |

**Default to `worktree` for every bean.** The parallelism gain far outweighs the worktree setup cost. Only use `branch` when a bean is so trivial that isolation adds no value.

**Verify:**
\```bash
beans list
beans roadmap
\```

Check: bean bodies contain full task steps (not just "See plan"), valid DAG, ready beans exist, each bean sized for one session.

**Commit beans to repository:**
\```bash
git add .beans/
git commit -m "Add beans for <epic-name>"
\```

**Restart safety:** Execution is interrupt-safe. On restart, `in-progress` beans are picked up first (resuming interrupted work), then `todo` beans. Completed beans are skipped. No manual cleanup needed after an interruption.
```

**4b.** Update the Execution Handoff:

Replace `Two execution options` with `Beans created. Four execution options`.

Insert before `**Which approach?"**`:
```
**3. Beans Batch (separate session)** - Open new session with executing-plans, batch execution using beans for state tracking

**4. Ralph Beans (hands-off)** - Run `/fiddle:ralph-beans-implement --epic <epic-id>` — automated parallel agents with implement/review cycles, no human checkpoints
```

After the `**If Parallel Session chosen:**` block, add:
```
**If Beans Batch chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans
- Beans are already created — executor uses `beans list --json` to find them

**If Ralph Beans chosen:**
- Guide them to open new session (optionally in worktree)
- Run `/fiddle:ralph-beans-implement --epic <epic-id>` with appropriate flags (e.g., `--workers 2`)
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

## Step 6: Verify

Read all three patched files and confirm:
- Brainstorming → has ARGS line with `--skip-panel` and `--from-orchestrate` flags, checklist has panel enrichment item, process flow has panel and `--from-orchestrate` nodes, terminal state is flag-dependent
- Writing-plans → has "Create Beans from Plan" section with self-contained bean bodies, handoff has 4 options (including Ralph Beans)
- Executing-plans → Step 1 uses `beans list`, Step 2 uses `beans update`, Remember has beans bullets
- All three have `[BEANS-PATCHED]` marker

Report: "Superpowers patched. Flow: brainstorming (with panel enrichment) → writing-plans (with beans) → executing-plans OR ralph-beans-implement."
