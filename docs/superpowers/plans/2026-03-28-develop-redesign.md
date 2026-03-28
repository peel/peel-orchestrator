# Develop Phase Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken develop-subs/develop-team/ralph architecture with a superpowers-composing develop protocol + parallel swarm mode.

**Architecture:** Develop protocol wraps superpowers skills (patched for beans + no finishing). Swarm mode adds parallel worktree-per-bean execution with incremental merge. Three execution choices: subagent-driven (recommended), sequential (interactive), swarm (parallel).

**Tech Stack:** Markdown skill files, Bash helper scripts, beans CLI

**Spec:** `docs/superpowers/specs/2026-03-26-develop-redesign.md`

---

### Task 1: Create helper scripts for swarm git operations

**Files:**
- Create: `scripts/rebase-worker.sh`
- Create: `scripts/merge-to-integration.sh`
- Create: `scripts/detect-reviewers.sh`
- Create: `scripts/reset-slot.sh`
- Create: `scripts/post-rebase-verify.sh`

- [ ] **Step 1: Create `scripts/rebase-worker.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
cd "$WORKTREE"
git rebase "$INTEGRATION" 2>&1 && exit 0
# Rebase failed — list conflicting files
git diff --name-only --diff-filter=U
exit 1
```

`chmod +x scripts/rebase-worker.sh`

- [ ] **Step 2: Create `scripts/merge-to-integration.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
WORKER_BRANCH=$(cd "$WORKTREE" && git rev-parse --abbrev-ref HEAD)
INTEGRATION_DIR=$(git worktree list | grep "$INTEGRATION" | awk '{print $1}')
cd "$INTEGRATION_DIR"
git merge --ff-only "$WORKER_BRANCH" 2>&1 && exit 0
echo "ERROR: Not fast-forwardable. Rebase the worker first."
exit 1
```

`chmod +x scripts/merge-to-integration.sh`

- [ ] **Step 3: Create `scripts/detect-reviewers.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
CHECKLISTS_DIR="${3:-skills/develop-swarm/checklists}"

cd "$WORKTREE"
FILES=$(git diff "$INTEGRATION"...HEAD --name-only 2>/dev/null || true)
[ -z "$FILES" ] && exit 0

DETECTED=""
for ext in $(echo "$FILES" | sed 's/.*\.//' | sort -u); do
  case "$ext" in
    go) [ -f "$CHECKLISTS_DIR/go.md" ] && DETECTED="$DETECTED go" ;;
    ts|svelte) [ -f "$CHECKLISTS_DIR/typescript.md" ] && DETECTED="$DETECTED typescript" ;;
    dart) [ -f "$CHECKLISTS_DIR/dart.md" ] && DETECTED="$DETECTED dart" ;;
  esac
done

echo "$DETECTED" | tr ' ' '\n' | sort -u | grep .
```

`chmod +x scripts/detect-reviewers.sh`

- [ ] **Step 4: Create `scripts/reset-slot.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
INTEGRATION="$2"
cd "$WORKTREE"
git reset --hard "$INTEGRATION"
git clean -fd
```

`chmod +x scripts/reset-slot.sh`

- [ ] **Step 5: Create `scripts/post-rebase-verify.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
WORKTREE="$1"
VERIFY_CMD="$2"
cd "$WORKTREE"
echo "VERIFIED_AT:$(git rev-parse HEAD) TS:$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .verification-output.txt
eval "$VERIFY_CMD" >> .verification-output.txt 2>&1 && exit 0
exit 1
```

`chmod +x scripts/post-rebase-verify.sh`

- [ ] **Step 6: Test each script manually**

```bash
# Verify all scripts are executable
ls -la scripts/*.sh
# Verify syntax
bash -n scripts/rebase-worker.sh
bash -n scripts/merge-to-integration.sh
bash -n scripts/detect-reviewers.sh
bash -n scripts/reset-slot.sh
bash -n scripts/post-rebase-verify.sh
```

- [ ] **Step 7: Commit**

```bash
git add scripts/
git commit -m "feat: add helper scripts for swarm git operations

Previously git operations for rebase, merge, reviewer detection,
slot reset, and verification were inline agent commands prone to error.

Now five deterministic shell scripts handle these operations with
explicit exit codes and structured output.

Bean: <BEAN_ID>"
```

---

### Task 2: Create develop-swarm role templates

**Files:**
- Create: `skills/develop-swarm/roles/implementer.md`
- Create: `skills/develop-swarm/roles/reviewer.md`

- [ ] **Step 1: Create `skills/develop-swarm/roles/implementer.md`**

Copy `skills/ralph/roles/implementer.md` as base. Apply these changes:

1. Strip all `<!-- VARIANT:subs -->`, `<!-- VARIANT:team -->`, `<!-- END VARIANT:* -->` blocks and their contents
2. Strip the `<!-- CONDITIONAL -->` Git Coordination section entirely (swarm always uses worktrees)
3. Preserve `{BEANS_ROOT}` and `{MAIN_BEANS_PATH}` placeholders in Command Execution Rules — the lead still injects these so the implementer can call `beans` from the worktree
3. Add `{CODEBASE_CONTEXT}` placeholder section after `## Workspace`:

```markdown
## Codebase Context

{CODEBASE_CONTEXT}
```

4. Add "Before You Begin" section between step 2 (read codebase) and step 3 (TDD):

```markdown
### Before You Begin

Before writing any code, verify you understand the task:
- Are the acceptance criteria clear? If not, report NEEDS_CONTEXT.
- Do you understand which files to modify? If not, report NEEDS_CONTEXT.
- Are there dependencies or constraints not mentioned? If not obvious, report NEEDS_CONTEXT.

Questions before work are cheap. Discovering confusion mid-implementation is expensive.
```

5. Add "Self-Review Checklist" before the commit step (step 7):

```markdown
### Self-Review Checklist

Before committing, verify:
- **Completeness:** Does the implementation cover all acceptance criteria?
- **Quality:** Would this pass code review? Any shortcuts taken?
- **Discipline:** Did I follow TDD? Any production code without a failing test?
- **Testing:** Edge cases covered? Tests verify behavior, not implementation?
```

6. Add "When You're Stuck" section before "If Blocked":

```markdown
## When You're Stuck

Report BLOCKED if any of these apply:
- Reading file after file without making progress on the actual task
- Spending more than 5 turns on a single failing test
- Realizing the task requires changes outside the bean's scope
- Discovering the acceptance criteria are contradictory or incomplete
```

7. Replace the commit message format (step 7) with conventional commits:

```markdown
7. Commit your changes:
   ```
   git commit -m "feat: brief description

   Previously <state before>.

   Now <state after>.

   Bean: {BEAN_ID}"
   ```
```

8. Replace the output section (step 9) with status protocol:

```markdown
9. Output your status as your final response. The FIRST LINE must be exactly
   one of: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED.

   DONE — followed by diff + summary
   DONE_WITH_CONCERNS — followed by diff + summary + concerns
   NEEDS_CONTEXT — followed by what information you need
   BLOCKED — followed by the specific blocker
```

- [ ] **Step 2: Create `skills/develop-swarm/roles/reviewer.md`**

Copy `skills/ralph/roles/reviewer.md` as base. Apply these changes:

1. Remove the "Verification Output" section that references lead-provided `.verification-output.txt` — the implementer writes this directly now
2. Update to reference implementer-written verification:

```markdown
## Verification Output

The implementer wrote verification results to:
`{WORKTREE_PATH}/.verification-output.txt`

Read this file. Validate the `VERIFIED_AT` commit SHA matches `git rev-parse HEAD`.
If mismatch, flag as ISSUES with "Verification output is stale."
```

3. No VARIANT blocks to strip — the existing reviewer.md already outputs verdict directly (the VARIANT blocks are in review-coordinator.md, not reviewer.md)

- [ ] **Step 3: Verify files are well-formed**

```bash
# Check no leftover VARIANT markers
grep -r "VARIANT" skills/develop-swarm/roles/ || echo "Clean"
# Check placeholders exist
grep -c "BEAN_ID\|BEAN_BODY\|WORKTREE_PATH\|CODEBASE_CONTEXT" skills/develop-swarm/roles/implementer.md
```

- [ ] **Step 4: Commit**

```bash
git add skills/develop-swarm/roles/
git commit -m "feat: create develop-swarm role templates

Previously implementer and reviewer templates lived in skills/ralph/roles/
with VARIANT blocks for subs/team modes.

Now develop-swarm has clean templates with status protocol, self-review
checklist, before-you-begin section, and conventional commit format.

Bean: <BEAN_ID>"
```

---

### Task 3: Move checklists and create lead-procedures

**Files:**
- Create: `skills/develop-swarm/checklists/go.md` (copy from `skills/ralph/checklists/go.md`)
- Create: `skills/develop-swarm/checklists/typescript.md` (copy)
- Create: `skills/develop-swarm/checklists/dart.md` (copy)
- Create: `skills/develop-swarm/roles/lead-procedures.md`

- [ ] **Step 1: Copy checklists and provider templates**

```bash
mkdir -p skills/develop-swarm/checklists
mkdir -p skills/develop-swarm/roles
cp skills/ralph/checklists/*.md skills/develop-swarm/checklists/
cp skills/ralph/roles/provider-dispatch.md skills/develop-swarm/roles/
cp skills/ralph/roles/provider-context.md skills/develop-swarm/roles/
```

Provider-dispatch and provider-context are used by the holistic review (develop protocol step 5) and the swarm review pipeline. They must be relocated before deleting `skills/ralph/`.

- [ ] **Step 2: Create `skills/develop-swarm/roles/lead-procedures.md`**

Write the new lead-procedures with three procedures: Review Pipeline, Conflict Resolution, and Cleanup. Source content from the spec sections.

**Review Pipeline** — from spec "Review Pipeline" section. Steps 1-5 with explicit tool calls.

**Conflict Resolution** — from spec "Conflict Resolution" section. Five-step git-based procedure.

**Cleanup** — simplified from current lead-procedures.md:
1. Stop running background tasks
2. Remove worker worktrees and scratch branches
3. Hand integration branch to develop protocol step 7

Remove from current lead-procedures.md:
- Lead Verification (replaced by implementer-written verification + post-rebase-verify.sh)
- Worktree Setup (develop protocol owns this via using-git-worktrees)
- Epic Holistic Review (moved to develop protocol step 5)
- `branch`-tag handling
- Batch merge from Cleanup

**Abandon Bean** — keep as-is from current lead-procedures.md.

**Token Optimization** — keep as-is, update path references from `skills/ralph/` to `skills/develop-swarm/`.

- [ ] **Step 3: Verify no stale references**

```bash
grep -r "skills/ralph/" skills/develop-swarm/ || echo "Clean"
grep -r "review-coordinator" skills/develop-swarm/ || echo "Clean"
```

- [ ] **Step 4: Commit**

```bash
git add skills/develop-swarm/
git commit -m "feat: add checklists and lead-procedures for develop-swarm

Previously checklists and procedures lived in skills/ralph/ with
variant-specific sections and batch-merge cleanup.

Now develop-swarm has clean checklists, Review Pipeline procedure
replacing the coordinator, Conflict Resolution procedure, and
simplified Cleanup without batch merge.

Bean: <BEAN_ID>"
```

---

### Task 4: Create develop-swarm/SKILL.md

**Files:**
- Create: `skills/develop-swarm/SKILL.md`

- [ ] **Step 1: Write the skill file**

The SKILL.md contains:
- Frontmatter: `name: fiddle:develop-swarm`, `description`, `disable-model-invocation: true`, `argument-hint`
- Configuration section (parse flags from args)
- Setup section (compute MAIN_BEANS_PATH, worker slot setup, verify-cmd discovery)
- Orchestration loop (assess-and-act): SCAN → REACTION CHECKS → FEATURE EXPANSION → DISPATCH → PROCESS RESULTS → COMPLETION
- Per-bean lifecycle (steps 1-9 with script calls)
- Coupling Detection Protocol (three-layer: dependency → path overlap → clash)
- Swarm restart rules
- Bean tag schema reference
- Red flags

Source all content from the spec's "Swarm Mode" section. The skill is read inline by develop/SKILL.md — it is NOT invoked via Skill().

- [ ] **Step 2: Verify references**

```bash
# Check all script references exist
grep "scripts/" skills/develop-swarm/SKILL.md | while read line; do
  script=$(echo "$line" | grep -o 'scripts/[a-z-]*.sh')
  [ -f "$script" ] && echo "OK: $script" || echo "MISSING: $script"
done

# Check role references
grep "roles/" skills/develop-swarm/SKILL.md | while read line; do
  role=$(echo "$line" | grep -o 'roles/[a-z-]*.md')
  [ -f "skills/develop-swarm/$role" ] && echo "OK: $role" || echo "MISSING: $role"
done
```

- [ ] **Step 3: Commit**

```bash
git add skills/develop-swarm/SKILL.md
git commit -m "feat: create develop-swarm orchestration skill

Previously parallel execution used develop-subs (broken nesting)
or develop-team (team variant) with shared ralph-core.

Now develop-swarm provides a single orchestration loop with flat
subagents, incremental rebase-before-review merge, coupling detection,
and durable restart via bean tags.

Bean: <BEAN_ID>"
```

---

### Task 5: Add superpowers patches to patch-superpowers

**Files:**
- Modify: `skills/patch-superpowers/SKILL.md`

- [ ] **Step 1: Read current patch-superpowers/SKILL.md fully**

Understand the existing patch structure (Steps 1-5, marker-based).

- [ ] **Step 2: Add Patch 6: Beans for subagent-driven-development**

Add a new step after existing Step 5. Find the `subagent-driven-development` cached skill. Replace all TodoWrite references with beans equivalents:
- `TodoWrite` task creation → `beans list --json` (beans already exist)
- `TodoWrite` mark complete → `beans update {id} --status completed`
- `TodoWrite` mark in-progress → `beans update {id} --status in-progress`
- Update the process flow diagram to reference beans instead of TodoWrite
- Add `<!-- [BEANS-PATCHED] -->` marker

- [ ] **Step 3: Add Patch 7: Remove finishing + final review from both skills**

Add another step. For both `subagent-driven-development` and `executing-plans`:
- Remove `finishing-a-development-branch` invocation/reference
- Remove "final code reviewer subagent" dispatch from subagent-driven
- Add: "Return control to the caller. Do not invoke finishing-a-development-branch or dispatch a final code reviewer."
- Update dot diagrams to remove finishing/final-review nodes

- [ ] **Step 4: Add Patch 8: Remove `--tag branch` from writing-plans**

In the existing writing-plans patch (Step 4b), find the section starting with `**Isolation tags:**` through the end of the table and the two paragraphs following it (`**Default to \`worktree\` for every bean.**` and the explanation). Remove the entire block. Replace with: "All beans use worktrees by default when `--workers > 1`. No isolation tags needed."

- [ ] **Step 5: Update the skill description**

Update the frontmatter description and overview to mention the new patches.

- [ ] **Step 6: Commit**

```bash
git add skills/patch-superpowers/SKILL.md
git commit -m "feat: add superpowers patches for develop redesign

Previously patch-superpowers only patched brainstorming, writing-plans,
and executing-plans for beans integration.

Now also patches subagent-driven-development for beans, removes
finishing-a-development-branch from both execution skills, and removes
branch-tag isolation from writing-plans.

Bean: <BEAN_ID>"
```

---

### Task 6: Rewrite develop/SKILL.md

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Read the current develop/SKILL.md fully**

- [ ] **Step 2: Rewrite with the develop protocol**

Replace the entire content. The new skill has:

**Frontmatter:**
```yaml
---
name: fiddle:develop
description: Run the DEVELOP phase — execute beans via superpowers (subagent-driven or sequential) or swarm mode, with holistic review and deferred finishing.
argument-hint: --epic <id> [--execution subagent|sequential|swarm] [--workers 2]
---
```

**Configuration:** Parse `--epic` (required), `--execution`, `--workers`, `--max-review-cycles` from args. Read `develop {}` from `orchestrate.json`, fall back to `ralph {}`.

**Develop protocol:** Steps 1-8 from the spec, with the dot diagram. Include:
- Step 1: VALIDATE — `beans show {epic-id} --json`, check child beans exist
- Step 2: WORKTREE — `Skill("superpowers:using-git-worktrees")`
- Step 3: EXECUTION CHOICE — hard gate, three options with `--execution` flag support
- Step 4: EXECUTE — delegate to superpowers or swarm, handle needs-attention and context exhaustion re-invocation
- Step 5: HOLISTIC REVIEW — dispatch via `skills/develop-swarm/roles/provider-dispatch.md` procedure. If no providers available, spawn reviewer subagent as fallback. Provide full diff + acceptance criteria. Max cycles from config.
- Step 6: Fix loop — create fix beans, back to step 4
- Step 7: FINISH — `Skill("superpowers:finishing-a-development-branch")`
- Step 8: RETURN — terminal states (merge/PR → deliver, keep → deliver, discard → abort, needs-attention → wait)

**Execution choices:** Three options:
- A: `Skill("superpowers:subagent-driven-development")` — recommended
- B: `Skill("superpowers:executing-plans")` — interactive
- C: `Read("skills/develop-swarm/SKILL.md")` → follow inline — parallel

**Stall detection:** Monitor bean state between execution turns. Read `spawned-at` tags, check elapsed vs `stall_timeout_min`.

**Red flags:** The full list from the spec.

- [ ] **Step 3: Verify no references to old names**

```bash
grep -i "ralph\|develop-subs\|develop-team\|tmux" skills/develop/SKILL.md || echo "Clean"
```

- [ ] **Step 4: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "refactor: rewrite develop skill with protocol + three execution modes

Previously develop had four execution modes including broken ralph-subs
and team variants with separate dispatch mechanisms.

Now develop implements a unified protocol (validate → worktree → execute
→ holistic review → finish) with three modes: subagent-driven
(recommended), sequential (interactive), and swarm (parallel).

Bean: <BEAN_ID>"
```

---

### Task 7: Update orchestrate and config

**Files:**
- Modify: `skills/orchestrate/SKILL.md`
- Modify: `orchestrate.json`

- [ ] **Step 1: Update orchestrate/SKILL.md**

1. Remove `--max-total-turns` from CLI flags table (line 30)
2. Update config parsing to read `develop {}` with `ralph {}` fallback
3. Remove `--max-total-turns` from the arg-building block in the DEVELOP section
4. Add `--execution` passthrough if `develop.execution` is set in config
5. Update any references to "Ralph Subs"/"Tmux Team" with new execution mode names

- [ ] **Step 2: Update orchestrate.json**

```json
{
  "providers": { ... },
  "develop": {
    "execution": "subagent",
    "workers": 2,
    "max_review_cycles": 3,
    "max_impl_turns": 50,
    "stall_timeout_min": 15,
    "stall_max_respawns": 2
  },
  "models": {},
  "plans": {}
}
```

Remove the `ralph` key. Move values to `develop`. Remove `max_review_turns`, `max_total_turns`, `ci_max_retries`.

- [ ] **Step 3: Commit**

```bash
git add skills/orchestrate/SKILL.md orchestrate.json
git commit -m "refactor: update orchestrate for develop redesign

Previously orchestrate passed --max-total-turns and read from the ralph
config block.

Now orchestrate reads from develop config (ralph fallback), passes
--execution flag, and no longer references max-total-turns.

Bean: <BEAN_ID>"
```

---

### Task 8: Update docs, create ADR, delete old files

**Files:**
- Modify: `docs/technical/SYSTEM.md`
- Create: `docs/technical/decisions/004-develop-redesign.md`
- Delete: `skills/develop-subs/`
- Delete: `skills/develop-team/`
- Delete: `skills/ralph/`

- [ ] **Step 1: Update SYSTEM.md**

Update the component descriptions:
- **Develop** — rewrite to describe the new protocol + three execution modes
- **Swarm** — new entry describing `develop-swarm/SKILL.md`
- Remove references to `develop-subs`, `develop-team`, `ralph-core.md`, review coordinator

- [ ] **Step 2: Create ADR 004**

```markdown
# 004 — Develop phase redesign: superpowers composition with swarm option

**Date:** 2026-03-28
**Status:** accepted
**Supersedes:** 001, 002

## Context

The develop phase had three problems: subagent nesting (coordinator → reviewer)
broke in practice, merge conflicts deferred to cleanup, and two variants
(develop-subs/develop-team) duplicated logic.

## Decision

Replace with a unified develop protocol that composes superpowers skills
(subagent-driven-development, executing-plans) with beans-based state tracking,
holistic review, and deferred finishing. A separate swarm mode provides parallel
worktree-per-bean execution for large epics.

## Consequences

- One develop entry point instead of three (develop + develop-subs + develop-team)
- No subagent nesting — swarm uses flat subagents with inline review pipeline
- Incremental rebase-before-review merge replaces deferred batch merge
- Superpowers skills patched to skip finishing (develop owns the lifecycle)
- Three execution choices: subagent-driven (recommended), sequential, swarm
```

- [ ] **Step 3: Delete old skill directories**

```bash
rm -rf skills/develop-subs/
rm -rf skills/develop-team/
rm -rf skills/ralph/
```

- [ ] **Step 4: Verify no dangling references**

```bash
grep -r "develop-subs\|develop-team\|skills/ralph/\|review-coordinator" skills/ hooks/ docs/ orchestrate.json | grep -v ".beans/" || echo "Clean"
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: delete old develop variants and update docs

Previously skills/develop-subs/, skills/develop-team/, and skills/ralph/
provided two parallel execution variants with shared ralph-core logic.

Now these are replaced by develop-swarm/ (parallel) and superpowers
composition (sequential). ADR 003 documents the decision.

Bean: <BEAN_ID>"
```

---

### Task 9: Run patch-superpowers and smoke test

**Files:**
- No new files — validation only

- [ ] **Step 1: Run patch-superpowers**

```bash
# Invoke the updated patch skill to apply all patches
# This patches the cached superpowers skills in-place
```

Use `Skill("fiddle:patch-superpowers")` to apply all patches including the new ones (patches 6-8).

- [ ] **Step 2: Verify patches applied**

```bash
# Check subagent-driven-development is beans-patched
grep "BEANS-PATCHED" ~/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/subagent-driven-development/SKILL.md

# Check executing-plans still beans-patched
grep "BEANS-PATCHED" ~/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/executing-plans/SKILL.md

# Check finishing removed
grep -c "finishing-a-development-branch" ~/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/subagent-driven-development/SKILL.md
# Expected: 0 or only in comments
```

- [ ] **Step 3: Verify develop skill loads**

```bash
# Check the skill is discoverable
grep "fiddle:develop" skills/develop/SKILL.md
grep "fiddle:develop-swarm" skills/develop-swarm/SKILL.md
```

- [ ] **Step 4: Verify no broken references across the project**

```bash
# Check for stale ralph references
grep -r "ralph" skills/ hooks/ --include="*.md" --include="*.sh" --include="*.json" | grep -v ".beans/" | grep -v "docs/" || echo "Clean"

# Check for stale develop-subs/develop-team references
grep -r "develop-subs\|develop-team" skills/ hooks/ --include="*.md" --include="*.sh" | grep -v ".beans/" || echo "Clean"
```

- [ ] **Step 5: Commit any fixes**

If the verification steps found issues, fix and commit.
