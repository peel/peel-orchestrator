# Lead Procedures

On-demand procedures for the lead. Read this file only when a specific procedure is needed.

## Token Optimization Checklist

When building implementer/reviewer prompts:
- Replace `{BEANS_ROOT}` with main checkout path (where `.beans/` lives) — prevents "bean not found" errors
- Replace `{WORKTREE_PATH}` with absolute path or empty string for main checkout
- Check API quota before spawning expensive multi-reviewer coordinators

## Review Pipeline

Replaces the review coordinator. Execute on demand when a bean passes rebase + verification.

1. DETECT REVIEWERS
   Bash("scripts/detect-reviewers.sh {worktree} {integration-branch}")
   → One reviewer per output line. Empty → baseline only
   → All cycles use the same reviewers (no narrowing)

2. BUILD PROMPTS
   Read("skills/develop-swarm/roles/reviewer.md")
   → Replace placeholders: {BEAN_ID}, {BEAN_TITLE}, {BEAN_BODY},
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
     → Parse first line: APPROVED / APPROVED WITH COMMENTS / ISSUES
     → Track reviewer name for flagged-by

5. AGGREGATE
   Any ISSUES → ISSUES + merged list
   Any COMMENTS → APPROVED_WITH_COMMENTS + suggestions
   All clean → APPROVED

## Conflict Resolution

When rebase produces conflicts:

1. Read conflict markers in each file
2. `git log --oneline {integration-branch} -- {file}` to see what landed
3. `git show {sha}` for relevant commits — commit messages explain intent
4. Resolve
5. `git rebase --continue`

The clash hook (clash-check.sh) warns implementers about shared-file edits.
The crops-report-gate.sh hook enforces decision reporting.

## Abandon Bean

When a bean must be abandoned (max review cycles exceeded, implementer hit max_turns):

1. `beans update {id} --status draft --tag abandoned`
2. Revert uncommitted changes: `git checkout -- .` (safe because committed work is in git)
3. Check for beans whose `blocked-by` includes the abandoned bean
4. For each dependent: `beans update {dep-id} --status draft --tag abandoned-upstream:{id}`
5. Cascade: repeat 3-4 for each newly-abandoned dependent (depth-first)
6. Report to user: list the abandoned bean and all cascaded dependents

## Cleanup

When all beans are completed (called from develop protocol):

1. Stop any running background tasks: TaskStop(task_id) for beans with bg-task:* tags
2. Remove worker worktrees: git worktree remove {worktree-dir}/{prefix}-{N} for each slot
3. Delete scratch branches: git branch -d {prefix}-{N}/scratch
4. Report integration branch name — develop protocol handles the rest via finishing-a-development-branch
