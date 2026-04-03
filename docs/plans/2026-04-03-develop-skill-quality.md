# Develop Skill Quality Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use fiddle:develop to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve fiddle:develop skill ecosystem to follow superpowers best practices — CSO-compliant descriptions, shared iron laws, rationalization tables, and progressive disclosure.

**Architecture:** In-place improvements to existing skill files. New reference files for extracted content. No structural splits or new skills.

**Tech Stack:** Markdown skill files, YAML frontmatter

**Design spec:** `docs/specs/2026-04-03-develop-skill-quality-design.md`

---

### Task 1: Create shared Iron Laws reference file

**Files:**
- Create: `skills/develop/iron-laws.md`

- [ ] **Step 1: Create the iron-laws.md reference file**

Create `skills/develop/iron-laws.md` with the following content (no YAML frontmatter — this is a reference file, not a skill):

```markdown
# Iron Laws

These apply to EVERY task. There are no exceptions.

1. Every task gets evaluated through the full loop. No exceptions for domain, complexity, or task type.
2. Every evaluation uses the full chain: domain resolution → implementer → evaluator → scorecard merge → convergence scripts.
3. "General" domain is not "optional" domain. No configured runtime does not mean no evaluation.
4. Implementer success is not evaluation. Self-reported passing is not convergence.
5. If you are thinking "this is straightforward enough to skip," that thought is the signal to not skip.
```

- [ ] **Step 2: Commit**

```bash
rtk git add skills/develop/iron-laws.md && rtk git commit -m "chore: extract shared iron laws to reference file"
```

```eval
domains: [general]
criteria:
  general:
    - id: iron-laws-file-exists
      check: "skills/develop/iron-laws.md exists with all 5 iron laws, no frontmatter"
    - id: iron-laws-content-matches
      check: "Content matches the 5 laws verbatim from the original develop/SKILL.md"
thresholds: {}
```

---

### Task 2: Fix CSO descriptions on all 5 fiddle-native skills

**Files:**
- Modify: `skills/develop/SKILL.md:1-4` (frontmatter)
- Modify: `skills/develop/develop-loop/SKILL.md:1-4` (frontmatter)
- Modify: `skills/develop/develop-holistic/SKILL.md:1-4` (frontmatter)
- Modify: `skills/evaluate/SKILL.md:1-4` (frontmatter)
- Modify: `skills/runtime-evidence/SKILL.md:1-3` (frontmatter)

- [ ] **Step 1: Fix develop/SKILL.md description**

In `skills/develop/SKILL.md`, change the `description` field in the YAML frontmatter from:
```
description: Execute an epic via the evaluator loop — validate beans, implement per-task, holistic review, finish.
```
to:
```
description: Use when implementing an epic's task beans through the evaluator loop — after plan and beans exist
```

- [ ] **Step 2: Fix develop-loop/SKILL.md description**

In `skills/develop/develop-loop/SKILL.md`, change:
```
description: Per-task evaluation loop — implement, evaluate, converge for a single bean. Called by fiddle:develop orchestrator.
```
to:
```
description: Use when a single task bean needs implementation and evaluation — called by fiddle:develop, not directly
```

- [ ] **Step 3: Fix develop-holistic/SKILL.md description**

In `skills/develop/develop-holistic/SKILL.md`, change:
```
description: Holistic cross-domain review — assess the full system as an integrated whole after per-task evaluation completes. Creates remediation beans if needed.
```
to:
```
description: Use after all per-task evaluations complete — assesses cross-domain integration and creates remediation beans
```

- [ ] **Step 4: Fix evaluate/SKILL.md description**

In `skills/evaluate/SKILL.md`, change:
```
description: Evaluator protocol — score an implementation against its task spec, domain template, and criteria. Returns a scorecard JSON to stdout.
```
to:
```
description: Use when scoring an implementation against its task spec — dispatched by develop-loop, not directly
```

- [ ] **Step 5: Fix runtime-evidence/SKILL.md description**

In `skills/runtime-evidence/SKILL.md`, change:
```
description: Runtime evidence gathering guidance for evaluators — interact with the running app before scoring
```
to:
```
description: Use when an evaluator needs to interact with a running application before scoring dimensions
```

- [ ] **Step 6: Commit**

```bash
rtk git add skills/develop/SKILL.md skills/develop/develop-loop/SKILL.md skills/develop/develop-holistic/SKILL.md skills/evaluate/SKILL.md skills/runtime-evidence/SKILL.md && rtk git commit -m "fix: CSO-compliant descriptions for fiddle-native skills"
```

```eval
domains: [general]
criteria:
  general:
    - id: cso-develop
      check: "develop/SKILL.md description starts with 'Use when'"
    - id: cso-develop-loop
      check: "develop-loop/SKILL.md description starts with 'Use when'"
    - id: cso-develop-holistic
      check: "develop-holistic/SKILL.md description starts with 'Use after'"
    - id: cso-evaluate
      check: "evaluate/SKILL.md description starts with 'Use when'"
    - id: cso-runtime-evidence
      check: "runtime-evidence/SKILL.md description starts with 'Use when'"
    - id: no-workflow-summaries
      check: "No description contains workflow steps like 'validate, implement, review, finish'"
thresholds: {}
```

---

### Task 3: Add rationalization table and Iron Laws reference to develop/SKILL.md

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Replace inline Iron Laws with reference**

In `skills/develop/SKILL.md`, replace the full Iron Laws section (lines 15-24):

```markdown
## Iron Laws

These apply to EVERY task. There are no exceptions.

1. Every task gets evaluated through the full loop. No exceptions for domain, complexity, or task type.
2. Every evaluation uses the full chain: domain resolution → implementer → evaluator → scorecard merge → convergence scripts.
3. "General" domain is not "optional" domain. No configured runtime does not mean no evaluation.
4. Implementer success is not evaluation. Self-reported passing is not convergence.
5. If you are thinking "this is straightforward enough to skip," that thought is the signal to not skip.
```

with:

```markdown
## Iron Laws

Read and internalize: `skills/develop/iron-laws.md`
```

- [ ] **Step 2: Add rationalization table after Iron Laws reference**

In `skills/develop/SKILL.md`, immediately after the Iron Laws section, add:

```markdown
## Rationalization Prevention

| Rationalization | Reality |
|---|---|
| "Only one task, skip holistic" | Holistic catches integration issues invisible to per-task eval |
| "All beans passed, holistic will too" | Per-task scores say nothing about cross-domain coherence |
| "Worktree setup is overhead" | Worktree protects main branch. Non-negotiable. |
| "Bean bodies look fine, skip validation" | Thin bodies produce thin implementations. Validate. |
```

- [ ] **Step 3: Commit**

```bash
rtk git add skills/develop/SKILL.md && rtk git commit -m "chore: iron laws reference + rationalization table in develop"
```

```eval
domains: [general]
criteria:
  general:
    - id: iron-laws-reference-develop
      check: "develop/SKILL.md references skills/develop/iron-laws.md instead of inlining laws"
    - id: rationalization-table-develop
      check: "develop/SKILL.md has a Rationalization Prevention section with 4 entries"
    - id: no-duplicate-laws
      check: "The 5 iron laws do NOT appear inline in develop/SKILL.md body"
thresholds: {}
```

---

### Task 4: Add rationalization table and Iron Laws reference to develop-loop/SKILL.md

**Files:**
- Modify: `skills/develop/develop-loop/SKILL.md`

- [ ] **Step 1: Replace inline Iron Laws with reference**

In `skills/develop/develop-loop/SKILL.md`, replace the full Iron Laws section (lines 38-46):

```markdown
## Iron Laws

These apply to EVERY task. There are no exceptions.

1. Every task gets evaluated through the full loop. No exceptions for domain, complexity, or task type.
2. Every evaluation uses the full chain: domain resolution → implementer → evaluator → scorecard merge → convergence scripts.
3. "General" domain is not "optional" domain. No configured runtime does not mean no evaluation.
4. Implementer success is not evaluation. Self-reported passing is not convergence.
5. If you are thinking "this is straightforward enough to skip," that thought is the signal to not skip.
```

with:

```markdown
## Iron Laws

Read and internalize: `skills/develop/iron-laws.md`
```

- [ ] **Step 2: Add rationalization table after Iron Laws reference**

In `skills/develop/develop-loop/SKILL.md`, immediately after the Iron Laws section, add:

```markdown
## Rationalization Prevention

| Rationalization | Reality |
|---|---|
| "Implementer said DONE, skip evaluation" | DONE is a claim. Evaluation is evidence. |
| "General domain only, lightweight eval" | General domain gets the full chain. No shortcuts. |
| "Simple task, one iteration enough" | Convergence requires two consecutive passes. Run the scripts. |
| "Runtime not configured, skip runtime start" | No runtime ≠ no evaluation. General domain still applies. |
| "Scorecard looks good, skip merge scripts" | You cannot eyeball conservative min scoring. Run merge-scorecards.sh. |
| "Budget is high, no need to track dispatches" | Budget exists to prevent infinite loops. Track every dispatch. |
```

- [ ] **Step 3: Commit**

```bash
rtk git add skills/develop/develop-loop/SKILL.md && rtk git commit -m "chore: iron laws reference + rationalization table in develop-loop"
```

```eval
domains: [general]
criteria:
  general:
    - id: iron-laws-reference-loop
      check: "develop-loop/SKILL.md references skills/develop/iron-laws.md instead of inlining laws"
    - id: rationalization-table-loop
      check: "develop-loop/SKILL.md has a Rationalization Prevention section with 6 entries"
    - id: no-duplicate-laws-loop
      check: "The 5 iron laws do NOT appear inline in develop-loop/SKILL.md body"
thresholds: {}
```

---

### Task 5: Add rationalization table to evaluate/SKILL.md

**Files:**
- Modify: `skills/evaluate/SKILL.md`

- [ ] **Step 1: Add rationalization table after Red Flags section**

In `skills/evaluate/SKILL.md`, after the existing "Red Flags — STOP and Re-examine" section (ends around line 141), add:

```markdown
## Rationalization Prevention

| Rationalization | Reality |
|---|---|
| "Code looks clean, score high" | Clean structure ≠ correct behavior. Trace the logic. |
| "Tests pass so correctness is fine" | Tests may not cover the criterion. Check coverage. |
| "Implementer already explained this" | Implementer claims are marketing. Verify independently. |
| "Prior scorecard was high, maintain it" | Each iteration scored fresh. Regressions happen. |
| "No antipatterns configured, skip check" | Check the code anyway. Antipattern file is supplementary, not exhaustive. |
```

- [ ] **Step 2: Commit**

```bash
rtk git add skills/evaluate/SKILL.md && rtk git commit -m "chore: add rationalization table to evaluate skill"
```

```eval
domains: [general]
criteria:
  general:
    - id: rationalization-table-evaluate
      check: "evaluate/SKILL.md has a Rationalization Prevention section with 5 entries after Red Flags"
    - id: evaluate-output-contract-intact
      check: "The Output Contract section at the end of evaluate/SKILL.md is unchanged"
thresholds: {}
```

---

### Task 6: Create develop-loop progressive disclosure reference files

**Files:**
- Create: `skills/develop/develop-loop/restart-recovery.md`
- Create: `skills/develop/develop-loop/context-loading-order.md`
- Create: `skills/develop/develop-loop/scorecard-merge.md`
- Create: `skills/develop/develop-loop/attended-gate.md`

- [ ] **Step 1: Create restart-recovery.md**

Create `skills/develop/develop-loop/restart-recovery.md` with the content extracted from develop-loop step 1a:

```markdown
# Restart Recovery

If a bean is already `in-progress` (session restart or crash recovery):

<HARD-GATE>
On session restart or when encountering an in-progress bean, you MUST run:
  scripts/parse-eval-log.sh --bean-id {id}
  scripts/assess-git-state.sh --base-sha {sha}
Resume based on script output. Do NOT guess state from memory or context.
</HARD-GATE>

**Interpreting restart state:**
- `parse-eval-log.sh` returns `{base_sha, total_dispatches, iteration_count, last_verdict, last_guidance}`.
- `assess-git-state.sh` returns `{state: CLEAN|DIRTY|CORRUPTED}`.
  - **CLEAN:** Code is committed. Resume from domain resolution and evaluation (step 1c) if last verdict was not CONVERGED, or skip to next task if CONVERGED.
  - **DIRTY:** Uncommitted changes exist. Commit or stash them, then resume from evaluation.
  - **CORRUPTED:** Merge conflict or broken state. Escalate to human — mark bean `needs-attention`.
```

- [ ] **Step 2: Create context-loading-order.md**

Create `skills/develop/develop-loop/context-loading-order.md` with the content extracted from develop-loop step 1f:

```markdown
# Evaluator Context Loading Order

Provide to all evaluators (claude and external) in the following order:

1. **Evaluation protocol** — `skills/evaluate/SKILL.md`
2. **Domain template** — `skills/evaluate/evaluator-<domain>.md` (as specified in the resolved domain's `template` field, e.g., `evaluator-general.md`, `evaluator-frontend.md`)
3. **Project calibration** (if exists) — read `evaluators.domains.<domain>.calibration` from `orchestrate.json`. If the key is present, read the file at that path (relative to project root) and include its content immediately after the domain template. If the key is absent, check whether the default path `docs/evaluator-calibration-<domain>.md` exists (this file is created when the attended gate writes anchors in step 1i). If the default file exists, load it. If neither the config key nor the default file exists, skip.
4. **Runtime evidence** (if runtime configured) — `skills/runtime-evidence/SKILL.md` content, plus runtime state (port, domain) so the evaluator can interact with the running app
5. **Runtime/stack agents** (if configured) — if `runtime_agent` or `stack_agents` are configured for the domain in orchestrate.json, read those agent files and include their content
6. **Task criteria** — the bean's acceptance criteria and the domain template's scoring dimensions
7. **Prior scorecards** (if iteration 2+) — the full diff since BASE_SHA (`git diff {BASE_SHA}...HEAD`) and the previous iteration's scorecard with evaluator guidance
8. **Antipatterns** (if configured) — if `evaluators.domains.<domain>.antipatterns` is configured in orchestrate.json, read the antipatterns file and inject its content into the evaluator's `{ANTIPATTERNS}` placeholder. This is loaded last in the evaluator context.
```

- [ ] **Step 3: Create scorecard-merge.md**

Create `skills/develop/develop-loop/scorecard-merge.md` with the content extracted from develop-loop steps 1g-1h:

```markdown
# Scorecard Merge Protocol

## Per-Domain Provider Merge (Step 1g)

After all provider scorecards are collected for each domain, merge them before threshold checks.

<HARD-GATE>
After receiving ALL provider scorecards for a domain, you MUST run:
  scripts/merge-scorecards.sh < scorecards-array.json > scorecard-{domain}.json 2> disagreements-{domain}.json
Use the merged scorecard for threshold checks. Do NOT merge scores yourself.
</HARD-GATE>

For each domain, build a JSON array of all provider scorecards for that domain, then pipe to `merge-scorecards.sh`:

```bash
# Collect all provider scorecards for a domain into a JSON array
jq -s '.' scorecard-{domain}-*.json | \
  scripts/merge-scorecards.sh > scorecard-{domain}.json 2> disagreements-{domain}.json
```

The merged scorecard uses conservative (min) scoring: for each dimension, the final score is the minimum across providers. Each dimension includes `provider_scores` showing per-provider breakdown:

```json
{
  "domains": {
    "general": {
      "dimensions": {
        "correctness": {"score": 7, "threshold": 7, "provider_scores": {"claude": 8, "codex": 7}}
      }
    }
  }
}
```

Disagreements (spread >= 3 between providers on any dimension) are written to `disagreements-{domain}.json`. Include disagreement data in evaluator feedback when re-dispatching implementers.

After merging all domains, combine disagreement files for the eval log:

```bash
# Merge per-domain disagreement files into a single array
jq -s 'add // []' disagreements-*.json > disagreements.json
```

Pass the combined `disagreements.json` to `append-eval-log.sh` in the logging step.

If a domain has only one provider, `merge-scorecards.sh` still runs (single-element array) to ensure consistent scorecard format.

## Cross-Domain Merge (Step 1h)

After all domain evaluators return, merge their scorecards:

- **Union** scorecards across domains — each domain is scored independently
- The merged scorecard has all domains under `.domains`: `{"frontend": {...}, "backend": {...}}`
- **No shared dimensions** — `domain_spec_fidelity` in frontend is completely independent from `domain_spec_fidelity` in backend
- Each domain must independently meet its own thresholds

```bash
# Merge per-domain (already provider-merged) scorecards into a single cross-domain scorecard.
# Use only scorecard-{domain}.json files (not scorecard-{domain}-{provider}.json raw files).
jq -s '
  { domains: (reduce .[] as $s ({}; . + ($s.domains // {}))) ,
    criteria: [.[] | .criteria[]?] }
' scorecard-general.json scorecard-frontend.json ... > scorecard.json

# Extract merged criteria
jq '.criteria' scorecard.json > criteria.json
```

List only the per-domain merged scorecards (one per resolved domain). Do NOT include raw per-provider scorecards (`scorecard-{domain}-{provider}.json`) in this merge.

On failure, the merged scorecard identifies which domain(s) failed. Pass the merged scorecard to `check-thresholds.sh` — it already handles multi-domain scorecards.

Both files (`scorecard.json` and `criteria.json`) are then passed to the attended gate and subsequently to `check-thresholds.sh`.
```

- [ ] **Step 4: Create attended-gate.md**

Create `skills/develop/develop-loop/attended-gate.md` with the content extracted from develop-loop step 1i:

```markdown
# Attended Scorecard Gate

<HARD-GATE>
IF evaluators.attended is true in orchestrate.json:
  After merging cross-domain scorecards, before threshold checks, you MUST present the merged scorecard to the human for review.

  1. Show the full merged scorecard with ALL dimension scores across ALL domains.
  2. Highlight any dimension scoring BELOW its threshold (show score and threshold).
  3. Highlight any provider disagreements from disagreements.json (show dimension, provider scores, spread).
  4. Ask: "Do you agree with these scores? Correct any you disagree with, or confirm to proceed."

  If the human corrects a score:
    a. Record the correction: {domain, dimension, evaluator_score, human_score, reason}
    b. Update the merged scorecard (scorecard.json) with the human's corrected score for that dimension.
    c. Encode the correction as a calibration anchor in the project's calibration file (see below).
    d. Use the corrected scorecard for ALL subsequent threshold and convergence checks.

  If the human confirms: proceed with evaluator scores unchanged.

Do NOT skip the attended gate when evaluators.attended is true.
Do NOT proceed to threshold checks without human confirmation when attended mode is active.
</HARD-GATE>

## Calibration Anchor Encoding

When the human corrects a score during attended review, append a calibration anchor to the project's calibration file for that domain.

**Locate the calibration file:** Read `evaluators.domains.<domain>.calibration` from `orchestrate.json`. If the key is present, use that path. If absent, default to `docs/evaluator-calibration-<domain>.md`. Create the file if it does not exist.

**Append the anchor in this format:**

```markdown
## [dimension] — Correction (YYYY-MM-DD)
**Evaluator scored:** X/10 — "[evaluator evidence from scorecard]"
**Human corrected to:** Y/10 — "[human's stated reason]"
**Anchor:** For this project, score Y means: [human's description of what that score level looks like]
```

Ask the human for their reason and description when they correct a score. The anchor becomes part of the evaluator's context on future dispatches (loaded at position 3 in the context loading order — see `skills/develop/develop-loop/context-loading-order.md`).

When `evaluators.attended` is false, skip the attended gate entirely — proceed directly to threshold checks.
```

- [ ] **Step 5: Commit**

```bash
rtk git add skills/develop/develop-loop/restart-recovery.md skills/develop/develop-loop/context-loading-order.md skills/develop/develop-loop/scorecard-merge.md skills/develop/develop-loop/attended-gate.md && rtk git commit -m "chore: create develop-loop progressive disclosure reference files"
```

```eval
domains: [general]
criteria:
  general:
    - id: restart-recovery-exists
      check: "skills/develop/develop-loop/restart-recovery.md exists with HARD-GATE and CLEAN/DIRTY/CORRUPTED states"
    - id: context-loading-order-exists
      check: "skills/develop/develop-loop/context-loading-order.md exists with all 8 ordered items"
    - id: scorecard-merge-exists
      check: "skills/develop/develop-loop/scorecard-merge.md exists with provider merge and cross-domain merge sections"
    - id: attended-gate-exists
      check: "skills/develop/develop-loop/attended-gate.md exists with HARD-GATE and calibration anchor encoding"
thresholds: {}
```

---

### Task 7: Extract content from develop-loop/SKILL.md and replace with references

**Files:**
- Modify: `skills/develop/develop-loop/SKILL.md`

- [ ] **Step 1: Replace step 1a restart check with reference**

In `skills/develop/develop-loop/SKILL.md`, replace the full content of section "## 1a. Restart Check" (from `If a bean is already...` through `...mark bean needs-attention.`) with:

```markdown
## 1a. Restart Check

If bean is `in-progress`, follow: `skills/develop/develop-loop/restart-recovery.md`
```

- [ ] **Step 2: Replace context loading order in step 1f with reference**

In `skills/develop/develop-loop/SKILL.md`, in section "## 1f. Dispatch Per-Domain, Per-Provider Evaluators", replace the 8-item numbered context loading order list (starting with `Provide to all evaluators (claude and external) in the following **context loading order**:` through item 8 ending with `...loaded last in the evaluator context.`) with:

```markdown
Load evaluator context in order specified by: `skills/develop/develop-loop/context-loading-order.md`
```

- [ ] **Step 3: Replace steps 1g-1h with reference**

In `skills/develop/develop-loop/SKILL.md`, replace the full content of sections "## 1g. Merge Provider Scorecards" and "## 1h. Merge Cross-Domain Scorecards" (from the 1g heading through `...subsequently to check-thresholds.sh (step 1j).`) with:

```markdown
## 1g–1h. Merge Scorecards

Merge provider and cross-domain scorecards following: `skills/develop/develop-loop/scorecard-merge.md`

<GATE>Proceed to threshold checks (1j). Do not skip to next task.</GATE>
```

- [ ] **Step 4: Replace step 1i with reference**

In `skills/develop/develop-loop/SKILL.md`, replace the full content of section "## 1i. Attended Scorecard Gate" (from the heading through `...skip this step entirely — proceed directly to threshold checks (step 1j).`) with:

```markdown
## 1i. Attended Scorecard Gate

If `evaluators.attended` is true in orchestrate.json, follow: `skills/develop/develop-loop/attended-gate.md`

When `evaluators.attended` is false, skip directly to threshold checks (step 1j).
```

- [ ] **Step 5: Verify line count reduction**

Run: `wc -l skills/develop/develop-loop/SKILL.md`
Expected: approximately 200-230 lines (down from 371)

- [ ] **Step 6: Commit**

```bash
rtk git add skills/develop/develop-loop/SKILL.md && rtk git commit -m "refactor: extract develop-loop verbose content to reference files"
```

```eval
domains: [general]
criteria:
  general:
    - id: loop-references-restart
      check: "develop-loop/SKILL.md references restart-recovery.md instead of inlining restart procedure"
    - id: loop-references-context-order
      check: "develop-loop/SKILL.md references context-loading-order.md instead of inlining 8-item list"
    - id: loop-references-merge
      check: "develop-loop/SKILL.md references scorecard-merge.md instead of inlining merge procedures"
    - id: loop-references-attended
      check: "develop-loop/SKILL.md references attended-gate.md instead of inlining attended procedure"
    - id: loop-line-count
      check: "develop-loop/SKILL.md is under 250 lines"
    - id: loop-flow-intact
      check: "The step sequence 1a→1b→1c→1d→1e→1f→1g-1h→1i→1j→1k→1l→1m is still navigable in SKILL.md"
    - id: loop-hard-gates-preserved
      check: "HARD-GATEs for domain resolution (1c), runtime start (1f), threshold checks (1j), convergence (1k), and logging (1l) remain inline in SKILL.md"
thresholds: {}
```

---

### Task 8: Create holistic progressive disclosure reference files

**Files:**
- Create: `skills/develop/holistic-dimensions.md`
- Create: `skills/develop/holistic-scorecard-schema.md`

- [ ] **Step 1: Create holistic-dimensions.md**

Create `skills/develop/holistic-dimensions.md` with the 5 dimension scale definitions extracted from `holistic-review.md`. Include each dimension's name, description, default threshold, and the full 1-10 scale block. Content starts from "### Integration" through the end of "### Runtime Health" scale (lines 38-195 of the current holistic-review.md).

The file should contain:

```markdown
# Holistic Dimensions — Scoring Scales

## Integration

Do the pieces work together? Are there visible seams between domains?

**Default threshold: 7**

```
 1  Disconnected: Domains don't communicate at all. Frontend and backend
    are completely independent applications with no integration.
 2  Broken bridge: Integration attempted but fundamentally broken. API
    calls fail, data formats incompatible, endpoints missing.
 3  Partial wiring: Some connections work. Core data flow exists but
    secondary flows (error handling, edge cases) are not wired up.
 4  Fragile link: Happy path works end-to-end but any deviation breaks
    the integration. Hardcoded URLs, missing error handling across boundaries.
 5  Functional seams: Domains communicate and data flows, but the seams
    are visible. Inconsistent loading states, mismatched terminology,
    different interaction patterns across domain boundaries.
 6  Joined: Integration works reliably. Error states propagate across
    domains. Seams visible only to careful inspection (e.g., slight
    timing differences, inconsistent empty states).
 7  Smooth: Domains feel connected. Data flows correctly, errors handled
    at boundaries, terminology consistent. Minor rough edges at transitions.
 8  Seamless: No visible seams. Cross-domain flows feel like a single
    application. State synchronized, transitions smooth, errors coherent.
 9  Unified: Integration is invisible. Cross-domain operations feel
    atomic. Optimistic updates, graceful degradation when a domain is slow.
10  Organic: System feels like it was built as one piece. Cross-domain
    features work better together than they would separately.
```

## Coherence

Does the whole feel like one system or a patchwork of separate pieces?

**Default threshold: 7**

```
 1  Patchwork: Each domain looks and feels completely different. No shared
    design language, terminology, or interaction patterns.
 2  Conflicting: Domains actively contradict each other. Different names
    for the same concepts, conflicting navigation patterns, clashing styles.
 3  Disjointed: Some shared elements but applied inconsistently. Same
    data displayed differently across domains. User must learn separate
    mental models for each part.
 4  Loosely themed: A common theme exists but execution varies widely.
    Color palette shared but typography, spacing, and component styles diverge.
 5  Partially unified: Core concepts named consistently. Primary
    navigation coherent. Secondary interactions and edge cases diverge
    between domains.
 6  Mostly coherent: Shared design language applied across domains.
    Terminology consistent. Interaction patterns similar. A few areas
    feel like they were built by a different team.
 7  Coherent: System feels unified. Consistent naming, patterns, and
    visual language. User can predict behavior in one domain based on
    experience in another.
 8  Harmonious: Beyond consistency — domains complement each other.
    Information architecture flows logically. Transitions between
    domains feel intentional and guided.
 9  Holistic: System tells a single coherent story. Every part reinforces
    the whole. Navigation, terminology, and visual rhythm all aligned.
10  Inevitable: The system feels like it could only have been designed
    this way. Every piece in its right place. Removing any part would
    diminish the whole.
```

## Holistic Spec Fidelity

Does the full result match the design document's overall vision? This is distinct from per-task domain_spec_fidelity — it evaluates whether the assembled whole achieves what the spec intended.

**Default threshold: 8**

```
 1  Wrong product: What was built bears no resemblance to the design
    document's vision. Completely different application.
 2  Wrong direction: Recognizably related to the spec but the fundamental
    approach contradicts the design intent.
 3  Major gaps: Some spec elements present but the overall vision is
    unrealized. Key features or interactions missing entirely.
 4  Partial vision: ~50% of the spec's vision realized. The shape is
    visible but large pieces missing. A reviewer would say "it's a start."
 5  Incomplete: ~70% realized. Most features present but the overall
    experience doesn't yet match the spec's intended feel or flow.
 6  Functional match: All primary spec requirements met. The app does
    what the spec says but doesn't capture the spirit — feels mechanical.
 7  Good match: Spec requirements met with reasonable interpretation of
    ambiguous areas. The app matches the spec's letter and partially
    its spirit.
 8  Faithful: Implementation matches the design document in both letter
    and spirit. The intended user experience is achieved. Design intent
    preserved throughout.
 9  Complete vision: Every aspect of the spec fully realized. Ambiguities
    resolved in ways that enhance the design intent. No drift from vision.
10  Transcends spec: All spec requirements met and the implementation
    improves on the vision where the spec was underspecified. The result
    is better than what was described.
```

## Polish

Would you ship this? Or does it feel AI-generated and unfinished?

**Default threshold: 6**

```
 1  Prototype: Clearly a rough draft. Placeholder text, missing assets,
    broken layouts, debug output visible.
 2  Scaffold: Structure exists but no finishing. Default styles, Lorem
    ipsum, TODO comments visible in output, unstyled error messages.
 3  Draft: Some intentional styling but obviously incomplete. Mix of
    polished and rough areas. Console warnings visible.
 4  Rough: Works and has styling but feels unfinished. Inconsistent
    spacing, orphaned elements, generic error messages, no loading states.
 5  Adequate: Functional and styled but not refined. A developer would
    say "it works." A designer would say "needs a polish pass."
 6  Presentable: Could show to stakeholders. Minor rough edges but
    nothing embarrassing. Loading states present, errors handled,
    spacing consistent.
 7  Polished: Feels finished. Attention to detail visible — proper
    empty states, transitions, consistent iconography, no console errors.
 8  Refined: Details that most people wouldn't notice are right. Micro-
    interactions, hover states, focus management, accessible labels.
 9  Crafted: Every pixel intentional. Animations enhance understanding.
    Error states are helpful. Performance is snappy. Feels hand-made.
10  Delightful: Exceeds expectations. Surprise-and-delight moments.
    The kind of quality that makes people ask "how did they do this?"
```

## Runtime Health

App launches cleanly, no console errors, responsive under interaction.

**Default threshold: 9**

```
 1  Won't start: Application fails to launch. Build errors, missing
    dependencies, crash on startup.
 2  Crashes immediately: Launches but crashes within seconds. Fatal
    errors on first interaction.
 3  Unstable: Launches but crashes frequently during normal use.
    Multiple console errors on startup.
 4  Limping: Runs but with persistent issues. Significant console
    errors, slow startup, memory warnings.
 5  Shaky: Core functionality works but secondary features cause
    errors. Console warnings present. Occasional hangs.
 6  Functional: Runs without crashes. Some console warnings but no
    errors. Startup takes reasonable time. Responds to interactions.
 7  Stable: No crashes, no console errors. Startup clean. All
    interactions responsive. Minor performance hiccups under load.
 8  Healthy: Clean startup, no warnings, responsive interactions.
    Memory stable over time. No network errors.
 9  Solid: Fast startup, zero console output (no errors, no warnings).
    All interactions instant. Smooth scrolling, no jank. Handles rapid
    interaction without degradation.
10  Exemplary: Sub-second startup. Zero console noise. Handles stress
    testing (rapid clicks, large data, resize). Performance metrics
    all green. Could run in production.
```
```

- [ ] **Step 2: Create holistic-scorecard-schema.md**

Create `skills/develop/holistic-scorecard-schema.md` with the spec coverage matrix protocol, remediation bean generation, and scorecard output sections extracted from `holistic-review.md` (lines 197-349 of current file):

```markdown
# Holistic Scorecard Schema

## Spec Coverage Matrix Protocol

After scoring all dimensions, produce a spec coverage matrix. Extract every
requirement from the design document and classify each:

| Coverage | Meaning |
|---|---|
| **Full** | Requirement implemented and verified via runtime evidence |
| **Weak** | Requirement partially implemented or implemented but not fully verified |
| **Missing** | Requirement not implemented or no evidence of implementation |

### Format

Produce the matrix as a JSON array in the scorecard output:

```json
{
  "spec_coverage_matrix": [
    {
      "requirement": "Radial spoke layout",
      "coverage": "Full",
      "evidence": "Screenshot shows 6 spokes radiating from center"
    },
    {
      "requirement": "Camera zoom 0.3x-2.0x",
      "coverage": "Weak",
      "evidence": "Zoom works but bounds not tested at extremes"
    },
    {
      "requirement": "Seed elements in empty districts",
      "coverage": "Missing",
      "evidence": "Not visible in any screenshot or interaction"
    }
  ]
}
```

### Rules

- Every requirement in the design document must appear in the matrix — do not skip requirements
- "Full" requires runtime evidence (screenshot, curl response, interaction log)
- "Weak" means evidence exists but is incomplete — flag for human judgment
- "Missing" means no evidence found — these become remediation tasks automatically

## Remediation Bean Generation

For each **Missing** entry in the spec coverage matrix and each holistic dimension that scores **below its threshold**, generate a remediation bean.

### Format

Produce remediation beans as a JSON array in the scorecard output:

```json
{
  "remediation_beans": [
    {
      "title": "Fix: Seed elements not visible in empty districts",
      "description": "The design spec requires seed elements to appear in empty districts to guide the user. No evidence of this feature was found during holistic review.",
      "source": "spec_coverage:Missing",
      "eval": {
        "criteria": [
          {
            "id": "seed_elements_visible",
            "description": "Empty districts display seed elements as specified in design doc",
            "threshold": 8
          }
        ]
      }
    },
    {
      "title": "Fix: Runtime Health below threshold (scored 6, needs 9)",
      "description": "Console errors present during runtime interaction. Multiple warnings on startup. Holistic reviewer observed degraded responsiveness during cross-domain flows.",
      "source": "dimension:runtime_health",
      "eval": {
        "criteria": [
          {
            "id": "runtime_clean_startup",
            "description": "Application starts with zero console errors or warnings",
            "threshold": 9
          },
          {
            "id": "runtime_responsive",
            "description": "All interactions respond without jank or delay",
            "threshold": 9
          }
        ]
      }
    }
  ]
}
```

### Rules

- Every "Missing" spec coverage entry produces exactly one remediation bean
- Every dimension below threshold produces one remediation bean (combine related issues)
- "Weak" entries do NOT automatically produce remediation beans — flag them for human review
- Each remediation bean must have an `eval` block with criteria specific to the gap
- The `source` field traces back to the coverage matrix entry or dimension that triggered it
- Bean titles start with "Fix:" to distinguish remediation from original tasks

## Scorecard Output

The holistic reviewer outputs a single JSON scorecard. The domain key is `holistic` and dimension keys are snake_case.

```json
{
  "domain": "holistic",
  "dimensions": {
    "integration": {
      "score": 7,
      "threshold": 7,
      "evidence": "Frontend correctly calls backend API endpoints. Data flows end-to-end for primary user flow. Error propagation works — backend 422 shows validation message in frontend. Minor: loading state inconsistent between create and update flows."
    },
    "coherence": {
      "score": 8,
      "threshold": 7,
      "evidence": "Consistent naming throughout. Navigation patterns match across domains. Visual language unified. Interaction patterns predictable."
    },
    "holistic_spec_fidelity": {
      "score": 7,
      "threshold": 8,
      "evidence": "Primary spec requirements met. Camera zoom and radial layout working. Missing: seed elements in empty districts. Weak: district zone gradients not as soft as spec describes."
    },
    "polish": {
      "score": 6,
      "threshold": 6,
      "evidence": "Loading states present. Error handling adequate. No console errors in normal flow. Empty states handled. Minor: hover states inconsistent on secondary buttons."
    },
    "runtime_health": {
      "score": 9,
      "threshold": 9,
      "evidence": "All runtimes start cleanly. Zero console errors or warnings. Frontend renders in under 2 seconds. Backend responds to all endpoints within 100ms. No memory growth observed during 5-minute interaction session."
    }
  },
  "cross_domain_integration": {
    "api_contract_compliance": "Frontend sends expected request shapes. Backend responds with parseable JSON. All status codes handled.",
    "data_flow_verified": true,
    "integration_gaps": []
  },
  "spec_coverage_matrix": [],
  "remediation_beans": []
}
```
```

- [ ] **Step 3: Commit**

```bash
rtk git add skills/develop/holistic-dimensions.md skills/develop/holistic-scorecard-schema.md && rtk git commit -m "chore: create holistic progressive disclosure reference files"
```

```eval
domains: [general]
criteria:
  general:
    - id: holistic-dimensions-exists
      check: "skills/develop/holistic-dimensions.md exists with all 5 dimension scales (Integration, Coherence, Holistic Spec Fidelity, Polish, Runtime Health)"
    - id: holistic-dimensions-complete
      check: "Each dimension has its description, default threshold, and full 1-10 scale block"
    - id: holistic-schema-exists
      check: "skills/develop/holistic-scorecard-schema.md exists with spec coverage matrix, remediation beans, and scorecard JSON sections"
thresholds: {}
```

---

### Task 9: Extract content from holistic-review.md and replace with references

**Files:**
- Modify: `skills/develop/holistic-review.md`

- [ ] **Step 1: Replace dimension scales with reference**

In `skills/develop/holistic-review.md`, replace the full "## Dimensions" section (from the `## Dimensions` heading through the end of the Runtime Health scale block, lines 37-195) with:

```markdown
## Dimensions

Score each dimension using the scales defined in: `skills/develop/holistic-dimensions.md`

Dimensions and default thresholds:
- **Integration** (7) — Do the pieces work together?
- **Coherence** (7) — Does the whole feel like one system?
- **Holistic Spec Fidelity** (8) — Does the full result match the design vision?
- **Polish** (6) — Would you ship this?
- **Runtime Health** (9) — App launches cleanly, no console errors?
```

- [ ] **Step 2: Replace output sections with reference**

In `skills/develop/holistic-review.md`, replace the sections from "## Spec Coverage Matrix Protocol" through the end of "## Scorecard Output" (lines 197-340) with:

```markdown
## Output

Produce output following: `skills/develop/holistic-scorecard-schema.md`

This includes the spec coverage matrix, remediation beans, and scorecard JSON.
```

- [ ] **Step 3: Verify line count reduction**

Run: `wc -l skills/develop/holistic-review.md`
Expected: approximately 80-110 lines (down from 349)

- [ ] **Step 4: Commit**

```bash
rtk git add skills/develop/holistic-review.md && rtk git commit -m "refactor: extract holistic-review verbose content to reference files"
```

```eval
domains: [general]
criteria:
  general:
    - id: holistic-references-dimensions
      check: "holistic-review.md references holistic-dimensions.md instead of inlining scale definitions"
    - id: holistic-references-schema
      check: "holistic-review.md references holistic-scorecard-schema.md instead of inlining output format"
    - id: holistic-line-count
      check: "holistic-review.md is under 120 lines"
    - id: holistic-hard-gate-preserved
      check: "The HARD-GATE for runtime interaction remains inline at the top of holistic-review.md"
    - id: holistic-red-flags-preserved
      check: "The Red Flags section remains inline at the end of holistic-review.md"
    - id: holistic-cross-domain-preserved
      check: "The Cross-Domain Integration Check section remains inline"
thresholds: {}
```
