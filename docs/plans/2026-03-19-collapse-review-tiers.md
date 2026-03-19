# Collapse Review Tiers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two-tier review pipeline (tier-1 parallel + tier-2 confirmation) with a single-pass domain-expert review, using baseline as fallback when no experts match.

**Architecture:** Remove tier-1/tier-2 distinction from review coordinators (both variants), update reviewer selection in lead SKILL.md files (domain experts only, baseline fallback), flatten `models.develop` config to single key, add cross-cutting concerns checklist to reviewer prompt.

**Tech Stack:** Markdown skill files, HCL config references

---

### Task 1: Add cross-cutting concerns to reviewer prompt

**Files:**
- Modify: `skills/develop-subs/roles/reviewer.md:73-77` (after Safety section)
- Modify: `skills/develop-team/roles/reviewer.md:73-77` (after Safety section)

- [ ] **Step 1: Add Cross-Cutting Concerns section to develop-subs reviewer.md**

After the `### Safety` section (which ends at line 77), add:

```markdown
### Cross-Cutting Concerns
- Backward compatibility: any breaking changes to public APIs, CLI flags, config schema, or file formats?
- Data migrations: schema changes, state format changes, or data loss risks?
- Dependency changes: new dependencies added, versions bumped, or removals?
- Observability: logging, error messages, or monitoring affected?
```

- [ ] **Step 2: Apply the same change to develop-team reviewer.md**

Add the identical `### Cross-Cutting Concerns` section after `### Safety` in `skills/develop-team/roles/reviewer.md`.

- [ ] **Step 3: Verify both files**

Read both files and confirm the Cross-Cutting Concerns section appears after Safety and before `## Previous Review Issues`.

- [ ] **Step 4: Commit**

```bash
git add skills/develop-subs/roles/reviewer.md skills/develop-team/roles/reviewer.md
git commit -m "feat: add cross-cutting concerns checklist to reviewer prompt"
```

---

### Task 2: Collapse review coordinator to single pass

**Files:**
- Modify: `skills/develop-subs/roles/review-coordinator.md` (rewrite Steps 1-5)
- Modify: `skills/develop-team/roles/review-coordinator.md` (rewrite Steps 1-5)

- [ ] **Step 1: Rewrite develop-subs review-coordinator.md process steps**

Replace the entire `## Process` section (Steps 1-5) with:

The new `## Process` section content for develop-subs/review-coordinator.md (read the current file for the sections before and after `## Process` to preserve them):

**Step 1: Build Reviewer Prompts** — same as current Step 1, but rule 4 changes from "The `baseline` reviewer uses the reviewer.md prompt as-is (no domain expertise appended)" to "If the agent is `baseline` (fallback when no domain experts matched), use the reviewer.md prompt as-is (no domain expertise appended)".

**Step 2: Spawn Reviewers** — spawn ALL reviewers in parallel in ONE message. Use `models.develop` (not lite/standard). Task name pattern: `"review-{agent-name}-{BEAN_ID}-c{REVIEW_CYCLE}"`. Same collecting-results-CRITICAL block as current Step 2 but referencing "Step 3" instead of "Step 3" (no change needed). Remove the "Do NOT proceed to Step 3 until..." line's step number references to tier steps.

**Step 3: Aggregate Results** — merge current Step 3's classification logic. Remove all tier-2 conditional logic. The only outcomes are: ANY non-APPROVED → go to Step 4 with merged feedback; ALL APPROVED → go to Step 4 (APPROVED). No cycle-based tier-2 branching.

**Step 4: Return Verdict** — same as current Step 5, but update the APPROVED verdict text from `"Tier-1 ({N} reviewers) and tier-2 all clean."` to `"{N} reviewer(s) all clean."`. Keep APPROVED_WITH_COMMENTS and ISSUES verdict formats unchanged. Keep the bean progress-append logic. Keep the "CRITICAL: always return a verdict" rule.

Delete current Step 4 (Tier-2 Review) entirely.

Update line 1 description from "manage the full review pipeline (tier-1 + tier-2)" to "manage the review pipeline".

Also update line 1 description from "manage the full review pipeline (tier-1 + tier-2)" to "manage the review pipeline".

Also update the `## Command Execution Rules` section — keep it unchanged (it has no tier references).

- [ ] **Step 2: Rewrite develop-team review-coordinator.md process steps**

Apply the same structural rewrite to `skills/develop-team/roles/review-coordinator.md`. Key differences from the subs variant:
- Step 1: reference path is `.claude/skills/develop-team/roles/reviewer.md`
- Step 4: uses `SendMessage` instead of direct output. Replace verdict outputs with the team-variant SendMessage pattern:

Update verdict SendMessage content strings: replace `"Tier-1 ({N} reviewers) and tier-2 all clean."` with `"{N} reviewer(s) all clean."` in the APPROVED case. Keep APPROVED_WITH_COMMENTS and ISSUES SendMessage patterns unchanged except removing any tier references from content strings. Keep the `## Shutdown` section unchanged.

Also update line 1 from "manage the full review pipeline (tier-1 + tier-2)" to "manage the review pipeline".

Keep the `## Shutdown` section unchanged.

- [ ] **Step 3: Verify both files**

Read both files. Confirm:
- No references to "tier-1", "tier-2", "Tier-1", "Tier-2" remain
- Model references use `models.develop` (not `models.develop.lite` or `models.develop.standard`)
- Verdict text uses `"{N} reviewer(s) all clean"` not the old tier text

- [ ] **Step 4: Commit**

```bash
git add skills/develop-subs/roles/review-coordinator.md skills/develop-team/roles/review-coordinator.md
git commit -m "refactor: collapse review coordinator to single-pass review"
```

---

### Task 3: Update lead SKILL.md files — reviewer selection and model references

**Files:**
- Modify: `skills/develop-subs/SKILL.md`
- Modify: `skills/develop-team/SKILL.md`

- [ ] **Step 1: Update develop-subs/SKILL.md**

**Frontmatter description (line 3):** Change from:
```
description: Execute beans tasks using subagents with ralph loop pattern. Implementers and review coordinators are background subagents; coordinators encapsulate the full tier-1/tier-2 review pipeline and return a verdict. Supports configurable parallelism.
```
To:
```
description: Execute beans tasks using subagents with ralph loop pattern. Implementers and review coordinators are background subagents; coordinators manage the review pipeline and return a verdict. Supports configurable parallelism.
```

**"Every Turn" section (line 43):** Change from:
```
Every bean goes through: **implement** → **review** (coordinator handles tier-1 + tier-2 internally).
```
To:
```
Every bean goes through: **implement** → **review** (coordinator handles review internally).
```

**Review Coordinator Spawn section (lines 174-175):** Change from:
```
**Cycle 1:** Auto-select ALL domain agents relevant to the bean. Always include `baseline`.
**Cycle 2+:** Use only the reviewers from the bean's `flagged-by:*` tag (set by previous verdict).
```
To:
```
**Cycle 1:** Auto-select domain agents relevant to the bean. If no domain agents match, use `baseline` as fallback.
**Cycle 2+:** Use only the reviewers from the bean's `flagged-by:*` tag (set by previous verdict).
```

**Coordinator spawn model (line 183):** Change `models.develop.standard` to `models.develop` in the comment.

**Implementer spawn model (line 161):** Change `models.develop.standard` to `models.develop` in the comment.

**Rules section (line 196):** Change from:
```
- Models: implementers=models.develop.standard, coordinators=models.develop.standard (tier-1 reviewers=models.develop.lite, tier-2=models.develop.standard internally), epic holistic review=opus. Read model config from orchestrate.conf; "default" means omit model parameter to inherit session model.
```
To:
```
- Models: implementers=models.develop, coordinators=models.develop (reviewers=models.develop internally), epic holistic review=opus. Read model config from orchestrate.conf; "default" means omit model parameter to inherit session model.
```

- [ ] **Step 2: Update develop-team/SKILL.md**

Apply the same changes to the team variant:

**Frontmatter description (line 3):** Change "encapsulate the full tier-1/tier-2 review pipeline" to "manage the review pipeline".

**"Every Turn" section (line 41):** Change "coordinator handles tier-1 + tier-2 internally" to "coordinator handles review internally".

**Review Coordinator Spawn (line 131):** Change from "Always include `baseline`" to "If no domain agents match, use `baseline` as fallback."

**Coordinator spawn model (line 140):** Change `models.develop.standard` to `models.develop`.

**Implementer spawn model (line 120):** Change `models.develop.standard` to `models.develop`.

**Rules section (line 153):** Same model reference update as develop-subs.

- [ ] **Step 3: Verify both files**

Read both files. Confirm:
- No "tier-1/tier-2" references remain
- No "Always include `baseline`" remains
- All `models.develop.standard` → `models.develop`
- All `models.develop.lite` references gone
- Baseline is described as fallback only

- [ ] **Step 4: Commit**

```bash
git add skills/develop-subs/SKILL.md skills/develop-team/SKILL.md
git commit -m "refactor: update reviewer selection and model references in lead SKILL.md"
```

---

### Task 4: Update config docs and SYSTEM.md

**Files:**
- Modify: `skills/develop/SKILL.md:29-30` (config section)
- Modify: `skills/orchestrate/SKILL.md:97-107` (model defaults table)
- Modify: `docs/technical/SYSTEM.md:13` (Ralph description)

- [ ] **Step 1: Update develop/SKILL.md config section**

Change lines 29-30 from:
```
- `models.develop.standard` — model for implementers, tier-2 review, ralph orchestrator
- `models.develop.lite` — model for tier-1 review (default: "sonnet")
```
To:
```
- `models.develop` — model for implementers, reviewers, ralph orchestrator
```

Also update line 91: change `models.develop.standard` to `models.develop` in the ralph spawn model comment.

- [ ] **Step 2: Update orchestrate/SKILL.md model defaults table**

Change lines 103-104 from:
```
| models.develop.standard | Implementers, tier-2 review, ralph orchestrator | "default" |
| models.develop.lite | Tier-1 review (quick pass) | "sonnet" |
```
To:
```
| models.develop | Implementers, reviewers, ralph orchestrator | "default" |
```

Also update the config file example. In the `models {}` block comment (around line 86-87), change from:
```hcl
  develop {
    # standard = "sonnet"
    lite = "sonnet"
  }
```
To:
```hcl
  # develop = "sonnet"
```

- [ ] **Step 3: Update SYSTEM.md**

Change the Ralph description (line 13) from:
```
Dispatches implementer subagents (sonnet) in worktrees with tiered review (haiku then sonnet).
```
To:
```
Dispatches implementer subagents in worktrees with single-pass domain-expert review (baseline fallback when no experts match).
```

Update the `Last reviewed` date to `2026-03-19`.

- [ ] **Step 4: Verify all three files**

Read all three files. Confirm:
- No `models.develop.standard` or `models.develop.lite` references remain
- No "tier-1", "tier-2", "haiku then sonnet" references remain
- Orchestrate model defaults table has one develop row, not two

- [ ] **Step 5: Commit**

```bash
git add skills/develop/SKILL.md skills/orchestrate/SKILL.md docs/technical/SYSTEM.md
git commit -m "docs: update config schema and SYSTEM.md for single-pass review"
```
