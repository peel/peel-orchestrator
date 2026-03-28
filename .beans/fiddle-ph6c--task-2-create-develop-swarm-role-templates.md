---
# fiddle-ph6c
title: 'Task 2: Create develop-swarm role templates'
status: todo
type: task
tags:
    - worktree
created_at: 2026-03-28T11:12:19Z
updated_at: 2026-03-28T11:12:19Z
parent: fiddle-p0do
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
