---
# fiddle-oexq
title: 'Task 5: Add superpowers patches'
status: completed
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-28T11:12:19Z
updated_at: 2026-03-28T12:56:57Z
parent: fiddle-p0do
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
