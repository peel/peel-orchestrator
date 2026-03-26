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

`develop-subs/` and `develop-team/` are deleted. `develop/SKILL.md` becomes the single entry point. `<!-- VARIANT:subs/team -->` blocks in role templates are stripped.

## Per-Bean Lifecycle

```
1. Spawn implementer in worktree → TDD, verify, commit → done
2. Rebase worker onto integration HEAD
3. If conflicts → resolve in worker worktree
4. Post-rebase verification (build/test)
5. If fails → fix in worker worktree, back to 2
6. Review the rebased code → verdict
7. If ISSUES → spawn fix implementer, back to 2
8. Fast-forward merge into integration
9. Reset slot to integration HEAD
```

Multiple beans run step 1 in parallel (up to `--workers`). Steps 2-8 are serial — one merge at a time.

**Single-worker fast path:** When `--workers 1`, skip worktree/integration setup. Implementer works in main checkout. Rebase and merge are no-ops.

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

## Review Pipeline

Replaces the review coordinator. Procedure in `lead-procedures.md`, executed by the lead on demand.

```
1. DETECT LANGUAGES
   git diff --name-only HEAD~1
   → Map extensions/paths to checklists:
     *.go → go, *.ts/*.svelte → typescript, *.dart → dart,
     *.sql/migrations/ → database
   → Glob(pattern: "skills/ralph/checklists/*.md") to find available
   → One reviewer per matched checklist
   → No matches → baseline only

2. BUILD PROMPTS (for each reviewer)
   Read("skills/ralph/roles/reviewer.md")
   → Replace: {BEAN_ID}, {BEAN_TITLE}, {BEAN_BODY},
     {WORKTREE_PATH}, {REVIEW_CYCLE}, {PREVIOUS_ISSUES}
   Read("skills/ralph/checklists/{lang}.md")
   → Replace {LANGUAGE_CHECKLIST}
   If domain expert (not baseline):
     Read(".claude/agents/{agent-name}.md")
     → Append under "## Domain Expertise"

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
     → If ISSUES: capture numbered issue list
     → If APPROVED WITH COMMENTS: capture suggestions
     → If empty/error: classify as APPROVED

5. AGGREGATE
   Any ISSUES → verdict is ISSUES + merged issue list
   Any COMMENTS (no ISSUES) → APPROVED_WITH_COMMENTS + suggestions
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
     Read("skills/ralph/roles/implementer.md") → substitute placeholders
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

   Implementer done →
     Execute per-bean lifecycle steps 2-9 (rebase, verify,
     review, merge)
     On APPROVED + merged → beans update {id} --status completed
     On ISSUES → spawn fix implementer, STOP

   Empty/error → Abandon Bean

6. COMPLETION
   No ready, no active, no needs-attention →
     All completed → holistic review → cleanup

   needs-attention beans exist →
     Present to user, wait for guidance
```

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

Removed: `max_review_turns` (no coordinator), `max_total_turns` (no subagent ralph), `ci_max_retries` (handled by flow).

The `ralph` key is renamed to `develop` for clarity.

## Files Changed

### Deleted
```
skills/develop-subs/          → collapsed into develop
skills/develop-team/          → collapsed into develop
skills/ralph/roles/review-coordinator.md → replaced by Review Pipeline procedure
```

### Modified
```
skills/develop/SKILL.md                 → single variant, inline loop
skills/ralph/ralph-core.md              → remove variant references
skills/ralph/roles/implementer.md       → strip VARIANT blocks, update commit format
skills/ralph/roles/reviewer.md          → strip VARIANT blocks, output as final response only
skills/ralph/roles/lead-procedures.md   → add Review Pipeline + Conflict Resolution procedures,
                                          update Cleanup (no batch merge), remove Lead Verification
hooks/clash-check.sh                    → unchanged (advisory)
orchestrate.json                        → rename ralph → develop, drop ci_max_retries
docs/technical/SYSTEM.md                → update component descriptions
docs/technical/decisions/               → new ADR superseding 001 and 002
```

### Unchanged
```
skills/ralph/checklists/*.md
skills/ralph/roles/provider-dispatch.md
skills/ralph/roles/provider-context.md
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
