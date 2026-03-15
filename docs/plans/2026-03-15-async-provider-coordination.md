# Async Provider Coordination Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace synchronous blocking provider calls with parallel background tasks, standardized context template, and phase-appropriate timeout handling.

**Architecture:** All provider calls go through a dispatch procedure (`provider-dispatch.md`) that reads CLI config from `orchestrate.conf`, builds prompts from a template (`provider-context.md`), fires background Bash tasks, and collects results via TaskOutput with attended/unattended timeout strategies.

**Tech Stack:** Bash (CLI invocation), HCL (orchestrate.conf), Markdown (skill files, procedure docs)

---

### Task 1: Update orchestrate.conf with provider CLI definitions

**Files:**
- Modify: `orchestrate.conf`

**Step 1: Replace the providers block with explicit CLI definitions**

Replace the current flat provider arrays with nested blocks that include `command`, `flags`, and `timeout`:

```hcl
providers {
  codex {
    command = "codex exec"
    flags   = "--json -s read-only"
  }
  gemini {
    command = "gemini"
    flags   = "-o json --approval-mode auto_edit"
  }

  # Phase assignments (which providers participate)
  discover         = ["codex"]
  define           = ["codex", "gemini"]
  develop          = []
  develop_holistic = ["codex"]
  deliver          = ["codex"]

  # Timeout strategy per phase mode
  timeout {
    attended   = 120   # DISCOVER/DEFINE — soft timeout, escalate to user
    unattended = 90    # DEVELOP — hard timeout, kill and proceed
  }
}
```

Keep the existing `ralph {}` block unchanged.

**Step 2: Verify the config is well-formed**

Run: `cat orchestrate.conf`
Expected: both `providers {}` (with nested `codex {}`, `gemini {}`, `timeout {}`) and `ralph {}` blocks present, no syntax errors.

**Step 3: Commit**

```bash
git add orchestrate.conf
git commit -m "feat: add explicit provider CLI definitions to orchestrate.conf"
```

---

### Task 2: Create provider-context.md template

**Files:**
- Create: `skills/ralph-subs-implement/roles/provider-context.md`

**Step 1: Write the template file**

```markdown
# Provider Context

Respond with your analysis only — no preamble, no meta-commentary.

## Role
{PROVIDER_ROLE}

## Topic
{TOPIC}

## Approaches
{APPROACHES}

## Design Document
{DESIGN_DOC}

## Diff
{DIFF}

## Previous Feedback
{PREVIOUS_FEEDBACK}

## Instructions
{INSTRUCTIONS}
```

**Step 2: Verify placeholders are consistent**

Check that every placeholder uses `{UPPER_SNAKE_CASE}` format and matches the placeholders referenced in the design doc (`docs/plans/2026-03-15-async-provider-coordination-design.md`).

**Step 3: Commit**

```bash
git add skills/ralph-subs-implement/roles/provider-context.md
git commit -m "feat: add provider context template for standardized handoff"
```

---

### Task 3: Create provider-dispatch.md procedure

**Files:**
- Create: `skills/ralph-subs-implement/roles/provider-dispatch.md`

**Step 1: Write the dispatch procedure**

Create the file with these sections:

```markdown
# Provider Dispatch

On-demand procedure for calling external providers. Read this file only when you need to dispatch a provider call.

## Read Config

1. Read `orchestrate.conf` → `providers.<name>` block for `command` and `flags`
2. Read `providers.timeout` block for `attended` and `unattended` values
3. If provider not in config, skip it silently

## Build Prompt

1. Read `roles/provider-context.md`
2. Substitute placeholders with values from the calling context
3. Strip sections where the value is empty — do not send empty headers to the provider
4. Write the final prompt to a temp file:
   ```bash
   PROMPT_FILE=$(mktemp /tmp/provider-XXXX.md)
   cat <<'PROMPT_EOF' > "$PROMPT_FILE"
   <substituted template content>
   PROMPT_EOF
   ```

## Dispatch (Background)

Fire the provider CLI as a background Bash task:

```
task = Bash(
  run_in_background: true,
  command: "<command> <flags> < \"$PROMPT_FILE\""
)
```

Record the task ID and provider name. When dispatching multiple providers, fire ALL in a single message — true parallelism, no sequential blocking.

For Claude positions in panel debates, use Agent(run_in_background: true) as before — the dispatch procedure covers external CLI providers only.

## Collect Results

### Attended mode (DISCOVER, DEFINE)

For each task, call:
```
TaskOutput(task_id: <id>, timeout: <timeout.attended * 1000>)
```

If timeout fires before result, present to user:
- "`<provider>` has not responded after `<timeout>`s. Options: (1) keep waiting, (2) respawn, (3) kill and proceed without it"
- **Keep waiting**: re-call TaskOutput with extended timeout
- **Respawn**: TaskStop the hung task, re-run Dispatch for that provider only, collect again
- **Kill**: TaskStop and proceed with available results

### Unattended mode (DEVELOP)

For each task, call:
```
TaskOutput(task_id: <id>, timeout: <timeout.unattended * 1000>)
```

If timeout fires before result:
- TaskStop(task_id)
- Log: "`<provider>` timed out after `<timeout>`s, proceeding without"

First-past-the-post: when collecting multiple providers, process results as they arrive. If 2+ providers have returned and remaining providers time out, proceed with available results. Do not wait for stragglers.

## Parse Output

Read the result from TaskOutput. The output is the provider's raw response. Return it to the calling skill as-is — the caller handles synthesis and aggregation.

## Cleanup

```bash
rm -f "$PROMPT_FILE"
```
```

**Step 2: Verify cross-references**

Check that the procedure references `roles/provider-context.md` (Task 2) and `orchestrate.conf` provider blocks (Task 1) correctly.

**Step 3: Commit**

```bash
git add skills/ralph-subs-implement/roles/provider-dispatch.md
git commit -m "feat: add provider dispatch procedure for async CLI coordination"
```

---

### Task 4: Update panel/SKILL.md to use dispatch procedure

**Files:**
- Modify: `skills/panel/SKILL.md`

**Step 1: Replace Mode Detection section**

Replace the current provider availability check:
```
- **Codex**: Check if `mcp__codex__codex` tool exists → full mode
- **Gemini**: Check if `gemini` CLI is on PATH (`which gemini`) → full mode
```

With:
```
- Read `orchestrate.conf` → `providers` block. For each provider name in the phase assignment for `define`:
  - Check if the provider has a `command` + `flags` definition
  - Check if the CLI binary is on PATH: `which <first word of command>`
- If at least one external provider is available → full mode
- If NO external providers are available → degraded mode (Claude subagents only)
```

**Step 2: Replace Phase 1 — Independent Positions (full mode)**

Replace the three sequential provider calls with:

```
**Full mode:** Read `roles/provider-dispatch.md` → follow "Read Config" and "Build Prompt" for each configured provider. Spawn ALL in parallel in ONE message:

1. **Claude position** — spawn via Agent tool (unchanged):
   Agent(run_in_background: true, prompt: "You are arguing from a codebase/domain perspective. Topic: {topic}. Context: {context}. Produce a position paper...")

2. **External providers** — for each provider in the `define` phase list:
   - Build prompt from `roles/provider-context.md` with:
     - PROVIDER_ROLE: provider's assigned perspective (Codex → implementation depth, Gemini → ecosystem breadth)
     - TOPIC: the topic being debated
     - APPROACHES: the candidate approaches
     - INSTRUCTIONS: "Produce a position paper: what you recommend, why, key tradeoffs, risks."
   - Follow provider-dispatch → "Dispatch (Background)"

Collect ALL results via provider-dispatch → "Collect Results" with attended mode. Then proceed to Phase 2.
```

**Step 3: Replace Phase 2+ — Cross-Review (full mode)**

Replace the sequential cross-review calls with:

```
**Full mode:** For each participant, build prompt from `roles/provider-context.md` with:
- PROVIDER_ROLE: same as Phase 1
- TOPIC: same
- PREVIOUS_FEEDBACK: ALL positions from Phase 1 (or previous round)
- INSTRUCTIONS: "Critique the other positions: agreements, disagreements, new concerns."

Fire all via provider-dispatch in parallel. Collect with attended mode.
```

**Step 4: Remove MCP-specific references**

Remove all mentions of `mcp__codex__codex` from the file. Remove the inline `gemini -o json --approval-mode auto_edit` command strings. These are now handled by the dispatch procedure reading from config.

**Step 5: Verify the skill reads coherently end-to-end**

Read the full file. Check: Mode Detection → Phase 1 → Phase 2 → Synthesis flow is intact. All references to dispatch procedure and template are correct.

**Step 6: Commit**

```bash
git add skills/panel/SKILL.md
git commit -m "refactor: panel uses async provider dispatch instead of blocking MCP/CLI calls"
```

---

### Task 5: Update orchestrate/SKILL.md to use dispatch procedure

**Files:**
- Modify: `skills/orchestrate/SKILL.md`

**Step 1: Replace DISCOVER Step 2 (External Research)**

Replace the current section that has inline `mcp__codex__codex()` and `gemini` calls with:

```
### Step 2: External Research

If DISCOVER providers are configured in `orchestrate.conf`:

Read `roles/provider-dispatch.md` → follow the dispatch procedure for each provider in the `discover` phase list:

- Build prompt from `roles/provider-context.md` with:
  - PROVIDER_ROLE: "Research analyst"
  - TOPIC: <topic>
  - INSTRUCTIONS: "Research: ecosystem patterns, prior art, implementation approaches, potential pitfalls. Be specific and cite concrete examples."
  - (other placeholders empty — strip those sections)

Dispatch all providers in parallel. Collect with **attended mode**.

If a provider is not available on PATH, skip it. Claude proceeds with internal knowledge only.
```

**Step 2: Replace DEVELOP Step 3 (Holistic Review)**

Replace the current section with:

```
1. Run the external holistic review. If DEVELOP holistic providers are configured in `orchestrate.conf`:

   Read `roles/provider-dispatch.md` → follow the dispatch procedure for each provider in the `develop_holistic` phase list:

   - Build prompt from `roles/provider-context.md` with:
     - PROVIDER_ROLE: "Holistic reviewer"
     - TOPIC: "Epic holistic review for <epic-id>"
     - DESIGN_DOC: <design doc content>
     - DIFF: <git diff main...epic/<epic-id>>
     - INSTRUCTIONS: "Did the implementation match the design? Flag: inconsistencies, missed requirements, naming conflicts, dead code."

   Dispatch all providers in parallel. Collect with **unattended mode** (first-past-the-post).

2. If no provider is available, perform the holistic review yourself.
3. If holistic review creates fix beans → loop back to DEVELOP Step 1
4. If clean → transition to DELIVER
```

**Step 3: Replace DELIVER Step 1 (Drift Analysis)**

Replace the current section with:

```
### Step 1: Drift Analysis

If DELIVER providers are configured in `orchestrate.conf`:

Read `roles/provider-dispatch.md` → follow the dispatch procedure for each provider in the `deliver` phase list:

- Build prompt from `roles/provider-context.md` with:
  - PROVIDER_ROLE: "Drift analyst"
  - TOPIC: "Design vs implementation drift for <epic-id>"
  - DESIGN_DOC: <design doc content>
  - DIFF: <git diff main...HEAD>
  - INSTRUCTIONS: "Analyze: did the implementation match the design? Flag any drift, missing features, scope creep, or unintended changes."

Dispatch all providers in parallel. Collect with **attended mode**.

If no provider is available, perform the drift analysis yourself.
```

**Step 4: Remove all MCP-specific references**

Search the file for `mcp__codex__codex` and `gemini -o json` — remove all inline invocations. These are now handled by the dispatch procedure.

**Step 5: Verify the skill reads coherently**

Read the full file. Check that DISCOVER → DEFINE → DEVELOP → DELIVER flow is intact, all provider calls reference the dispatch procedure, and no orphaned MCP references remain.

**Step 6: Commit**

```bash
git add skills/orchestrate/SKILL.md
git commit -m "refactor: orchestrate uses async provider dispatch for all external calls"
```

---

### Task 6: Update session-start-check-providers.sh

**Files:**
- Modify: `hooks/session-start-check-providers.sh`

**Step 1: Write a test for the new behavior**

Create a temporary test script that validates the hook's output:

```bash
# Test: when codex is on PATH but gemini is not, should report gemini missing
# Test: when both are on PATH, should output nothing (exit 0 silently)
# Test: when neither is on PATH, should report both missing
```

Run the existing script to capture current behavior:
```bash
bash hooks/session-start-check-providers.sh
```

**Step 2: Replace MCP config checking with CLI PATH checking**

Remove the MCP config checking logic (the `jq -e '.mcpServers.codex'` checks against `.mcp.json` and `~/.claude.json`). Replace with simple PATH checks for both providers:

```bash
for provider in $PROVIDERS; do
  if ! command -v "$provider" &>/dev/null; then
    needs_setup+=("$provider (not installed)")
  fi
done
```

This is uniform — both codex and gemini are treated the same way. No more special-casing codex for MCP.

Update the nudge message from "Run /fiddle:init to configure" to "Install missing providers to enable multi-model features."

**Step 3: Verify the script works**

Run:
```bash
bash hooks/session-start-check-providers.sh
```
Expected: reports only genuinely missing CLI tools. No MCP config mentions.

**Step 4: Commit**

```bash
git add hooks/session-start-check-providers.sh
git commit -m "refactor: session-start hook checks CLI binaries instead of MCP config"
```

---

### Task 7: Simplify init/SKILL.md

**Files:**
- Modify: `skills/init/SKILL.md`

**Step 1: Remove MCP configuration flow**

Remove Steps 2-4 (Check existing configuration, Choose target, Write configuration) which deal with writing MCP server entries to `.mcp.json` or `~/.claude.json`.

Replace with a simplified flow:

```
### Step 1: Detect providers

Read `orchestrate.conf` to find declared providers. For each, check PATH:

- `which codex`
- `which gemini`

Report findings.

### Step 2: Verify config

Check that `orchestrate.conf` has `command` and `flags` for each installed provider. If missing, add default entries.

### Step 3: Auth reminders

For each installed provider:
- codex: `codex --login`
- gemini: `gemini auth`
```

Update the skill description from "Configure MCP servers and CLI providers" to "Verify CLI providers for fiddle's multi-model orchestration."

**Step 2: Verify the skill reads coherently**

Read the file. Check: no MCP references remain, flow is detect → verify config → auth.

**Step 3: Commit**

```bash
git add skills/init/SKILL.md
git commit -m "refactor: simplify init to CLI verification, remove MCP config flow"
```

---

### Task 8: Update SYSTEM.md and document AGENTS.md setup

**Files:**
- Modify: `docs/technical/SYSTEM.md`

**Step 1: Update SYSTEM.md**

In the Overview paragraph, remove "Codex via MCP" and replace with "Codex via CLI":
```
External providers (Codex via CLI, Gemini via CLI) participate in debate and review phases...
```

In the Data section, remove `.mcp.json` entry or update it to note it's no longer required for codex.

In the Components section, update:
- **Orchestrate** description: mention provider-dispatch procedure
- **Panel** description: mention async parallel provider calls
- **Init** description: "Verifies CLI providers are on PATH and authenticated"

Add to Invariants:
```
- Provider calls use the dispatch procedure (`roles/provider-dispatch.md`) — never inline CLI commands in skill files.
- All external provider calls fire as background Bash tasks — never synchronous blocking calls.
```

Remove from Data section:
```
**`.mcp.json`** (JSON) — Claude Code MCP server configuration. Written by `/fiddle:init`.
```

**Step 2: Add AGENTS.md setup note**

Add to the Setup section or a new "Setup" entry in SYSTEM.md:
```
Shared agent context: symlink CLAUDE.md to AGENTS.md so provider CLIs (codex, gemini) share the same project baseline when invoked from the project directory.
```

**Step 3: Verify no stale MCP references remain**

Search SYSTEM.md for "MCP", "mcp", ".mcp.json". Only legitimate references should remain (e.g., MCP as a concept for other tools, not codex-specific).

**Step 4: Commit**

```bash
git add docs/technical/SYSTEM.md
git commit -m "docs: update SYSTEM.md for CLI-only provider coordination"
```
