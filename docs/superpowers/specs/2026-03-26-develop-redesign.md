# Design: Develop phase redesign — flat subagents with incremental merge

**Date:** 2026-03-26
**Status:** Proposed

## Motivation

The current develop phase has three structural problems:

1. **Subagent nesting doesn't work.** The review coordinator is a subagent that spawns reviewer sub-subagents. In the subs variant, this creates two levels of nesting that empirically gets stuck.
2. **Merge conflicts are deferred to Cleanup.** The lead merges all worktrees at the end, burning context on conflict resolution it has no accumulated knowledge about. Conflicts pile up undetected.
3. **Two variants duplicate logic.** `develop-subs` and `develop-team` share ~90% of their code via `ralph-core.md` but maintain separate event handling, spawn config, and lifecycle management.

## Architecture

One variant. One agent type. The lead runs inline, spawns all agents as background subagents.

| Role | Type | Lifecycle |
|---|---|---|
| Lead | Inline (main session) | Persistent — IS the session |
| Implementer | Background subagent | Stateless, per-bean |
| Reviewer | Background subagent | Stateless, per-bean |

No teams. No coordinator. No integrator. No hybrid dispatch.

The review coordinator is eliminated. Its logic (prompt construction, reviewer spawn, result collection, verdict aggregation) moves to a "Review Pipeline" procedure in `lead-procedures.md`, executed on demand.

`develop-subs/` and `develop-team/` are deleted. `develop/SKILL.md` becomes the entry point that presents execution choices and delegates. The swarm implementation moves to `develop-swarm/SKILL.md` (replaces `ralph-core.md` + variant files). `<!-- VARIANT:subs/team -->` blocks in role templates are stripped.

### Execution Choices

`develop/SKILL.md` presents three options:

1. **Swarm** — `develop-swarm/SKILL.md`. Parallel subagent implementers/reviewers in worktrees with incremental merge. For large epics with independent beans.
2. **Subagent-driven** — `superpowers:subagent-driven-development`. Same session, fresh subagent per task, two-stage review. For moderate work with independent tasks.
3. **Sequential** — `superpowers:executing-plans`. Same session, lead executes each task directly. For small changes where the user wants to interact.

## Per-Bean Lifecycle

```
1. Spawn implementer in worktree → TDD, verify
   (writes .verification-output.txt), commit → done
2. Bash("scripts/rebase-worker.sh {worktree} {integration-branch}")
3. If exit 1 (conflicts) → resolve in worker worktree, git rebase --continue
4. Bash("scripts/post-rebase-verify.sh {worktree} '{verify-cmd}'")
   → overwrites .verification-output.txt
5. If exit 1 → commit fix in worker worktree, back to 4 (re-verify).
   If the fix changes the rebase base, back to 2.
6. Review Pipeline procedure → verdict
   (reviewer reads .verification-output.txt as evidence)
7. If ISSUES → spawn fix implementer, back to 2
8. Bash("scripts/merge-to-integration.sh {worktree} {integration-branch}")
9. Bash("scripts/reset-slot.sh {worktree} {integration-branch}")
```

Multiple beans run step 1 in parallel (up to `--workers`). Steps 2-8 are serial — one merge at a time. The lead processes one completed implementer per turn (STOP after processing each result), same as the current assess-and-act pattern. If multiple implementers complete while the lead is processing steps 2-8 for one bean, their results queue and are processed in subsequent turns.

**Single-worker fast path:** When `--workers 1`, skip worktree/integration setup. Implementer works in main checkout on the current branch. Steps 2-3 (rebase), 8 (merge), and 9 (reset slot) are no-ops. Verification and review still run. Cleanup has no worktrees to remove.

Script arguments in single-worker mode:
- `post-rebase-verify.sh` → `{worktree}` = `.` (main checkout)
- `detect-reviewers.sh` → `{worktree}` = `.`, `{integration-branch}` = `HEAD~{N}` where N is the implementer's commit count (diff against pre-implementation state)

## Implementer Status Protocol

The implementer's final output MUST start with a status keyword on its own line. The lead parses the first line to determine the next action.

The implementer role template (`develop-swarm/roles/implementer.md`) must instruct the agent:

> Your final output MUST begin with exactly one of these status keywords
> on its own line: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED.
> Follow with the content described below. The lead parses the first line
> to decide the next action — if you omit the keyword, the lead cannot
> proceed.

```
DONE
<diff + summary>
  → Lead proceeds to rebase + review

DONE_WITH_CONCERNS
<diff + summary>
<concerns section>
  → Lead reads concerns. If correctness/scope: address before review.
    If observational: note and proceed to review.

NEEDS_CONTEXT
<what's missing — be specific about what information you need>
  → Lead provides missing context, re-dispatches implementer with
    additional information in the prompt.

BLOCKED
<why — specific blocker, not a vague complaint>
  → Lead follows escalation ladder:
    1. If context problem → provide context, re-dispatch
    2. If task too complex → break into smaller beans
    3. If plan is wrong → tag needs-attention, present to user
```

## Conflict Resolution

Everything needed is in git. No separate clash notes file, no broadcast mechanism, no activity store lookups.

When rebase produces conflicts (step 3):

1. Read conflict markers in each file
2. `git log --oneline {integration-branch} -- {file}` to see what landed
3. `git show {sha}` for relevant commits — commit messages explain intent
4. Resolve
5. `git rebase --continue`

Good commit messages are the critical dependency. The clash hook (`clash-check.sh`) warns the implementer when it edits a file modified in another worktree. The existing `crops-report-gate.sh` SubagentStop hook enforces decision reporting for architectural choices.

## Commit Message Format

Conventional commits title + Previously/Now body + Bean trailer.

```
feat: add cancellation support to Store.Append

Previously Append took only beanID and event params, with no way to
cancel long-running writes from the fsnotify watcher.

Now Append takes context.Context as first param, allowing callers to
cancel via context. All Store consumers must update their call sites.

Bean: board-tm7m
```

- **Title:** Conventional commit prefix, imperative, max 70 chars
- **Body:** Previously/Now describing behavioral state change. When the clash hook fired for any file in this commit, the body MUST explain the interface change and impact on consumers.
- **Trailer:** `Bean: {BEAN_ID}`

## Helper Scripts

Deterministic shell scripts for git operations the lead calls during the per-bean lifecycle. Testable independently, eliminate agent interpretation of multi-step git commands.

```
scripts/rebase-worker.sh {worktree} {integration-branch}
  → cd to worktree, rebase onto integration HEAD
  → Exit 0 if clean, exit 1 if conflicts (prints conflicting files)

scripts/merge-to-integration.sh {worktree} {integration-branch}
  → Fast-forward merge worker branch into integration
  → Exit 0 on success, exit 1 if not fast-forwardable

scripts/detect-reviewers.sh {worktree} {integration-branch}
  → Diff worker against integration, match file extensions
    against available checklists in skills/develop-swarm/checklists/
  → Outputs one checklist name per line (e.g., "go", "typescript")
  → Empty output → baseline only

scripts/reset-slot.sh {worktree} {integration-branch}
  → git reset --hard, git clean -fd in the worktree

scripts/post-rebase-verify.sh {worktree} {verify-cmd}
  → cd to worktree, run {verify-cmd}
  → Write results to {worktree}/.verification-output.txt
  → Exit 0 if all pass, exit 1 if any fail
  → The lead reads {verify-cmd} from CLAUDE.md once at setup and
    passes it to all script invocations as a quoted argument
```

## Review Pipeline

Replaces the review coordinator. Procedure in `lead-procedures.md`, executed by the lead on demand.

```
1. DETECT REVIEWERS
   Bash("scripts/detect-reviewers.sh {worktree} {integration-branch}")
   → One reviewer per output line
   → Empty output → baseline only
   → Cycle 2+: narrow to only reviewers from bean's flagged-by tag

2. BUILD PROMPTS (for each reviewer)
   Read("skills/develop-swarm/roles/reviewer.md")
   → Replace: {BEAN_ID}, {BEAN_TITLE}, {BEAN_BODY},
     {WORKTREE_PATH}, {REVIEW_CYCLE}, {PREVIOUS_ISSUES}
   → Inject matched language checklist into {LANGUAGE_CHECKLIST}
   → If a domain expert agent matches the bean content, append
     its definition under "## Domain Expertise"

3. SPAWN ALL REVIEWERS (single message)
   Agent(
     name: "review-{lang}-{BEAN_ID}-c{cycle}",
     subagent_type: "general-purpose",
     mode: "bypassPermissions",
     run_in_background: true,
     max_turns: 30,
     prompt: <built prompt>
   )
   → Record each task_id

4. COLLECT RESULTS
   For each task_id:
     TaskOutput(task_id: <id>, block: true, timeout: 600000)
     → Parse FIRST LINE only: APPROVED / APPROVED WITH COMMENTS / ISSUES
     → If ISSUES: capture numbered issue list + reviewer name
       (from agent spawn name: "review-{lang}-{BEAN_ID}-c{cycle}")
     → If APPROVED WITH COMMENTS: capture suggestions + reviewer name
     → If empty/error: classify as APPROVED
     → If timeout (600s): classify as APPROVED, log warning

5. AGGREGATE
   Any ISSUES → verdict is ISSUES + merged issue list
     Tag bean: --tag flagged-by:{reviewer-names-that-flagged}
   Any COMMENTS (no ISSUES) → APPROVED_WITH_COMMENTS + suggestions
     Tag bean: --tag flagged-by:{reviewer-names-that-commented}
   All clean → APPROVED
```

## Orchestration Loop

Single loop, runs every turn. No variant-specific sections.

```
1. SCAN
   beans list --parent {epic-id} --json
   → Categorize: in-progress, todo (unblocked), completed,
     needs-attention

2. REACTION CHECKS (for each in-progress leaf bean)
   beans show {id} --json → read tags

   - Stall: elapsed since spawned-at > timeout →
     respawn or tag needs-attention
   - Review overflow: cycle >= max_review_cycles → Abandon Bean

3. FEATURE EXPANSION (for each feature bean)
   - todo + unblocked → set in-progress
   - in-progress → list children, add to work queue
   - all children completed → complete the feature

4. DISPATCH (leaf beans only)
   active = count in-progress
   ready = count todo + unblocked
   slots = workers - active

   For each ready bean (up to slots):
     beans update {id} --status in-progress
     Assign worktree slot: --tag worktree-slot:{prefix}-{N}
     Reset slot: cd .worktrees/{prefix}-{N} && git reset --hard
       epic/{epic-id} && git clean -fd
     Read("skills/develop-swarm/roles/implementer.md") → substitute placeholders
     Agent(
       name: "impl-{bean-slug}",
       subagent_type: "general-purpose",
       mode: "bypassPermissions",
       run_in_background: true,
       max_turns: {max_impl_turns},
       prompt: <substituted template>
     )
     beans update {id} --tag role:implement
       --tag spawned-at:$(date +%s) --tag bg-task:{task_id}

   Launch ALL spawns in one message. STOP.

5. PROCESS RESULTS (on background task completion)
   TaskOutput(task_id, block: false, timeout: 5000)

   Parse first word of result (status protocol):

   DONE / DONE_WITH_CONCERNS →
     Execute per-bean lifecycle steps 2-9 (rebase, verify,
     review, merge)
     On APPROVED + merged → beans update {id} --status completed
     On ISSUES → spawn fix implementer, STOP

   NEEDS_CONTEXT → provide context, re-dispatch. STOP.

   BLOCKED → follow escalation ladder. STOP.

   Empty/error → Abandon Bean

6. COMPLETION
   No ready, no active, no needs-attention →
     All completed → holistic review → cleanup

   needs-attention beans exist →
     Present to user, wait for guidance
```

## Bean Tag Schema

Tags on beans track operational state through the lifecycle.

| Tag | Set by | Cleared by | Purpose |
|---|---|---|---|
| `role:implement` | Lead on dispatch | Lead on review start | Current phase |
| `role:review` | Lead on review start | Lead on verdict | Current phase |
| `role:review-fix-{cycle}` | Lead on ISSUES verdict | Lead on next review | Fix cycle tracking |
| `bg-task:{task_id}` | Lead on spawn | Lead on result | Links bean to background task |
| `spawned-at:{epoch}` | Lead on spawn | Lead on result | Stall detection baseline |
| `worktree-slot:{prefix}-{N}` | Lead on dispatch | Lead on completion | Worktree assignment |
| `flagged-by:{names}` | Review Pipeline | Lead on next cycle | Reviewer narrowing for cycle 2+ |
| `needs-attention` | Lead on escalation | User manually | Blocks further automation |
| `stall-respawns:{N}` | Lead on stall | — | Escalation counter |

Terminal states: `completed` (status), `needs-attention` (tag → user intervention), abandoned (status set to `draft` + `abandoned` tag).

## Worktree Management

**Setup** (first turn):
- Integration worktree: `git worktree add .worktrees/{epic-id}-integration -b epic/{epic-id} HEAD`
- Worker slots: `git worktree add .worktrees/{prefix}-{N} -b {prefix}-{N}/scratch epic/{epic-id}`
- `direnv allow` each worktree

**Between beans on the same slot:**
```bash
cd .worktrees/{prefix}-{N}
git reset --hard epic/{epic-id}
git clean -fd
```

**Cleanup** (all beans completed):
1. Remove worker worktrees: `git worktree remove .worktrees/{prefix}-{N}`
2. Delete scratch branches: `git branch -d {prefix}-{N}/scratch`
3. Report integration branch name to user
4. Ask: checkout in main? rebase onto main? leave as-is?

## Configuration

`orchestrate.json` changes:

```json
{
  "develop": {
    "workers": 2,
    "max_review_cycles": 3,
    "max_impl_turns": 50,
    "stall_timeout_min": 15,
    "stall_max_respawns": 2
  }
}
```

Removed: `max_review_turns` (no coordinator), `max_total_turns` (no subagent lead), `ci_max_retries` (handled by flow). Existing configs with removed keys are silently ignored.

The `ralph` key is renamed to `develop` for clarity. `models.develop` is preserved as-is for implementer/reviewer model selection.

The `branch`-tagged bean concept (skip worktree, work in main checkout serially) is dropped. All beans use worktrees when `--workers > 1`.

## Files Changed

### Deleted
```
skills/develop-subs/                    → replaced by develop-swarm
skills/develop-team/                    → replaced by develop-swarm
skills/ralph/                           → renamed to develop-swarm, restructured
```

### Created
```
skills/develop-swarm/SKILL.md           → orchestration loop + per-bean lifecycle
skills/develop-swarm/roles/implementer.md
skills/develop-swarm/roles/reviewer.md
skills/develop-swarm/roles/lead-procedures.md  → Review Pipeline, Conflict Resolution, Cleanup
skills/develop-swarm/checklists/*.md    → moved from ralph/checklists/
scripts/rebase-worker.sh
scripts/merge-to-integration.sh
scripts/detect-reviewers.sh
scripts/reset-slot.sh
scripts/post-rebase-verify.sh
```

### Modified
```
skills/develop/SKILL.md                 → three execution choices (swarm, subagent-driven, sequential)
orchestrate.json                        → rename ralph → develop, drop ci_max_retries/max_review_turns/max_total_turns
docs/technical/SYSTEM.md                → update component descriptions
docs/technical/decisions/               → new ADR superseding 001 and 002
```

### Unchanged
```
hooks/clash-check.sh
hooks/crops-report-gate.sh
```

## What This Does NOT Change

- The four-phase lifecycle (discover → define → develop → deliver)
- Beans as the unit of work
- The assess-and-act loop pattern
- TDD enforcement via superpowers skills
- Decision reporting via crops report
- Holistic review via external providers
- Worktree isolation for parallel work
- Domain-expert reviewer selection (baseline fallback)
