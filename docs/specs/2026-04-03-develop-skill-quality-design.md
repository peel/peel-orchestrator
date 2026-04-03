# Develop Skill Quality Improvements

**Date:** 2026-04-03
**Scope:** Improve fiddle:develop skill ecosystem to follow superpowers best practices

## Problem

The fiddle-native skills (develop, develop-loop, develop-holistic, evaluate, runtime-evidence) violate several superpowers skill authoring best practices:

1. **CSO violations** — descriptions summarize the workflow instead of stating trigger conditions. This causes Claude to shortcut past skill bodies.
2. **No rationalization tables** — the ported skills (tdd, debug, verify) have them; fiddle-native skills don't. Empirical testing shows these boost compliance from ~33% to ~72%.
3. **Duplicated Iron Laws** — same 5 laws appear verbatim in develop and develop-loop.
4. **Oversized skills** — develop-loop (371 lines) and holistic-review (349 lines) inline verbose examples, schemas, and recovery procedures that should be progressive-disclosure reference files.

## Design

### 1. CSO Description Fixes

Change 5 descriptions from "what it does" to "when to use":

| Skill | New Description |
|---|---|
| `fiddle:develop` | "Use when implementing an epic's task beans through the evaluator loop — after plan and beans exist" |
| `fiddle:develop-loop` | "Use when a single task bean needs implementation and evaluation — called by fiddle:develop, not directly" |
| `fiddle:develop-holistic` | "Use after all per-task evaluations complete — assesses cross-domain integration and creates remediation beans" |
| `fiddle:evaluate` | "Use when scoring an implementation against its task spec — dispatched by develop-loop, not directly" |
| `fiddle:runtime-evidence` | "Use when an evaluator needs to interact with a running application before scoring dimensions" |

### 2. Shared Iron Laws

Extract duplicated Iron Laws to `skills/develop/iron-laws.md` (reference file, no frontmatter). Both `develop/SKILL.md` and `develop-loop/SKILL.md` replace inline block with:

```
Read and internalize: skills/develop/iron-laws.md
```

### 3. Rationalization Tables

Add tables to `develop/SKILL.md`, `develop-loop/SKILL.md`, and `evaluate/SKILL.md`.

**develop/SKILL.md:**

| Rationalization | Reality |
|---|---|
| "Only one task, skip holistic" | Holistic catches integration issues invisible to per-task eval |
| "All beans passed, holistic will too" | Per-task scores say nothing about cross-domain coherence |
| "Worktree setup is overhead" | Worktree protects main branch. Non-negotiable. |
| "Bean bodies look fine, skip validation" | Thin bodies produce thin implementations. Validate. |

**develop-loop/SKILL.md:**

| Rationalization | Reality |
|---|---|
| "Implementer said DONE, skip evaluation" | DONE is a claim. Evaluation is evidence. |
| "General domain only, lightweight eval" | General domain gets the full chain. No shortcuts. |
| "Simple task, one iteration enough" | Convergence requires two consecutive passes. Run the scripts. |
| "Runtime not configured, skip runtime start" | No runtime ≠ no evaluation. General domain still applies. |
| "Scorecard looks good, skip merge scripts" | You cannot eyeball conservative min scoring. Run merge-scorecards.sh. |
| "Budget is high, no need to track dispatches" | Budget exists to prevent infinite loops. Track every dispatch. |

**evaluate/SKILL.md:**

| Rationalization | Reality |
|---|---|
| "Code looks clean, score high" | Clean structure ≠ correct behavior. Trace the logic. |
| "Tests pass so correctness is fine" | Tests may not cover the criterion. Check coverage. |
| "Implementer already explained this" | Implementer claims are marketing. Verify independently. |
| "Prior scorecard was high, maintain it" | Each iteration scored fresh. Regressions happen. |
| "No antipatterns configured, skip check" | Check the code anyway. Antipattern file is supplementary, not exhaustive. |

### 4. Progressive Disclosure — develop-loop

Extract from `develop-loop/SKILL.md` into reference files:

| Reference File | Content Extracted | ~Lines Saved |
|---|---|---|
| `develop-loop/restart-recovery.md` | Step 1a: HARD-GATE, restart state interpretation (CLEAN/DIRTY/CORRUPTED) | 20 |
| `develop-loop/scorecard-merge.md` | Steps 1g-1h: provider merge JSON, cross-domain merge jq, disagreements | 65 |
| `develop-loop/attended-gate.md` | Step 1i: attended review procedure, calibration anchor encoding | 40 |
| `develop-loop/context-loading-order.md` | Step 1f: 8-item context loading order with details | 20 |

SKILL.md replaces each extracted section with a one-line reference. Estimated result: ~371 → ~200 lines.

### 5. Progressive Disclosure — holistic-review.md

Extract from `holistic-review.md` into reference files:

| Reference File | Content Extracted | ~Lines Saved |
|---|---|---|
| `skills/develop/holistic-dimensions.md` | Full 1-10 scale blocks for 5 dimensions | 150 |
| `skills/develop/holistic-scorecard-schema.md` | Spec coverage matrix protocol + remediation bean generation + scorecard JSON example | 100 |

holistic-review.md replaces with one-line references. Estimated result: ~349 → ~100 lines.

## Out of Scope

- Splitting develop-loop into sub-skills (deferred — trim first, reassess later)
- Pressure-testing skills with adversarial scenarios (P3 follow-up)
- Changes to ported superpowers skills (tdd, debug, verify, finish-branch, worktrees — already CSO-compliant)

## File Changes Summary

**New files:**
- `skills/develop/iron-laws.md`
- `skills/develop/develop-loop/restart-recovery.md`
- `skills/develop/develop-loop/scorecard-merge.md`
- `skills/develop/develop-loop/attended-gate.md`
- `skills/develop/develop-loop/context-loading-order.md`
- `skills/develop/holistic-dimensions.md`
- `skills/develop/holistic-scorecard-schema.md`

**Modified files:**
- `skills/develop/SKILL.md` — CSO fix, Iron Laws reference, rationalization table
- `skills/develop/develop-loop/SKILL.md` — CSO fix, Iron Laws reference, rationalization table, extract 4 sections
- `skills/develop/develop-holistic/SKILL.md` — CSO fix
- `skills/develop/holistic-review.md` — extract dimensions and scorecard schema
- `skills/evaluate/SKILL.md` — CSO fix, rationalization table
- `skills/runtime-evidence/SKILL.md` — CSO fix
