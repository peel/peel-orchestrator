# Calibrated Evaluator System — Design Spec

> **Date:** 2026-03-29
> **Status:** Draft
> **References:** [Anthropic harness design post](https://www.anthropic.com/engineering/harness-design-long-running-apps), [Compound Engineering](https://every.to/guides/compound-engineering), [Correctless](https://github.com/joshft/correctless)

---

## Problem

The current superpowers review pipeline (spec-reviewer → code-quality-reviewer) fails in three ways:

1. **Blind reviews.** Reviewers read code diffs. Nobody launches the app, takes screenshots, or interacts with the running output. Visual/UI work passes review while looking terrible.
2. **Lenient reviews.** Generic reviewer checklists let mediocre work through. Reviewers "talk themselves into deciding issues aren't a big deal and approve the work anyway" (Anthropic's finding).
3. **Spec drift.** A single spec-review pass is insufficient. Features are claimed as implemented but aren't — there's massive drift between spec and actual output.

**Evidence:** The City Visualization Redesign in `~/wrk/next/` went through the full superpowers pipeline (brainstorm → plan → subagent-driven development with TDD, spec review, and code quality review) and produced output that needs to be reverted. The frontend output was terrible despite all reviews passing.

## Solution

Replace the two-stage pass/fail review with a **calibrated evaluator system** that scores, thresholds, iterates, and verifies at runtime.

### Core Changes

| Current | New |
|---|---|
| Two-stage review: spec-reviewer → code-quality-reviewer | Single evaluator per task, scored dimensions with hard thresholds |
| Pass/fail review | Scored 1-10 per dimension, minimum threshold per dimension |
| 1-2 review cycles | Convergence-based iteration, up to 15 cycles |
| Code diff review only | Runtime verification — evaluator launches and interacts with the running app |
| Single model reviews | Multi-provider evaluation (Claude + Codex + Gemini), minimum score wins |
| Generic reviewer prompts | Domain-specific calibrated evaluators with few-shot scoring anchors |
| No cross-task quality check | Holistic reviewer at checkpoints with spec coverage matrix |
| Post-delivery feedback docs | Antipattern accumulation fed back into evaluator and implementer |

---

## Architecture

### Evaluator Framework — Three Layers

Each evaluator prompt is assembled from three layers, each more specific:

**Layer 1: Evaluation Protocol (fiddle — universal)**

The scoring/threshold/iteration machinery. Never changes per project.

- How to score (1-10 per dimension)
- How thresholds work (all dimensions must meet minimum)
- Convergence-based stopping (two consecutive passes with no new issues = converged)
- Safety cap at `max_eval_iterations` (default 15)
- Distrust instructions ("verify independently, don't trust implementer's claims")
- Scorecard format and reporting rules
- Escalation protocol (max iterations reached → stop, report to human)

**Layer 2: Domain Evaluator Templates (fiddle — ships defaults, project can override)**

Base dimensions and generic calibration anchors per domain:

| Template | Base Dimensions |
|---|---|
| `evaluator-frontend.md` | Visual quality, Craft (typography/spacing/color), Functionality, Spec fidelity |
| `evaluator-backend.md` | Correctness, API contract fidelity, Error handling, Spec fidelity |
| `evaluator-general.md` | Correctness, Spec fidelity, Code quality |

Each dimension includes:
- Definition (what it measures)
- Default threshold (e.g., 7/10)
- Generic calibration anchors (what a 4/7/9 looks like in stack-agnostic terms)

Generic anchors describe quality levels in terms of **patterns and signals**, not project-specific content:

```markdown
## Visual Quality — Generic Anchors

**Score 3-4 (FAIL):**
- Default/unstyled framework output
- Placeholder shapes where finished UI elements should be
- No evidence the design system was consulted
- Layout functional but visually unintentional

**Score 6-7 (Threshold):**
- Design system colors/typography/spacing applied consistently
- Custom components, not framework defaults
- Rough edges exist but overall looks designed
- A designer would say "needs polish" not "start over"

**Score 9-10 (Excellent):**
- Matches design reference closely
- Consistent visual language across all elements
- Polished details (transitions, alignment, whitespace)
- A designer would say "ship it"
```

**Layer 3: Project-Specific Configuration (per project — optional overrides)**

Projects customize via `orchestrate.json`:

- Which domain evaluator to use
- Runtime commands for evaluation
- References to project-specific agents (playwright-expert, flutter-expert, etc.)
- Extra dimensions beyond the base set
- Custom thresholds
- Project-specific calibration file with concrete anchors for this app
- Antipattern file reference

**Domain resolution:** Each task's Evaluation block specifies a `Domain` field (e.g., `frontend`). The orchestrator resolves this to the matching key in `evaluators.domains` in `orchestrate.json`. If no match, falls back to `evaluator-general.md` with no runtime.

**No evaluator config at all:** If a project has no `evaluators` section in `orchestrate.json`, the develop phase falls back to the current superpowers behavior (spec-reviewer → code-quality-reviewer). The evaluator system is opt-in — projects adopt it by adding the config.

**Team member lifecycle:** Evaluator team members are created fresh per task and torn down after the task's evaluation loop completes (converged or escalated). They do not persist between tasks.

---

### Two-Tier Evaluation

#### Tier 1: Task Evaluator

Runs after each task implementation. Fresh team member per task.

**Sees:** One task's diff, one task's runtime output, one task's criteria.

**Scores:** Base dimensions from domain template + task-specific criteria (binary pass/fail checklist from plan's Evaluation block).

**Catches:** Implementation quality, spec drift, visual slop, broken functionality, known antipatterns — all scoped to a single task.

#### Tier 2: Holistic Reviewer

Runs at configured checkpoints — every N tasks and after all tasks complete. Fresh team member per review point.

**Sees:** Entire codebase diff from plan start, the running application in its current state, the full spec/design doc.

**Scores holistic dimensions:**

| Dimension | What it evaluates |
|---|---|
| Integration | Do the pieces work together? Visible seams? |
| Coherence | Does the whole feel like one system or a patchwork? |
| Spec fidelity (holistic) | Does the full result match the design doc's vision? |
| Polish | Would you ship this? Or does it feel AI-generated? |
| Runtime health | App launches cleanly, no console errors, responsive |

**Produces a spec coverage matrix:**

```
Spec requirement              | Coverage | Evidence
Radial spoke layout           | Full     | Screenshot shows 6 spokes
Soft-edged district zones     | Full     | Screenshot + gradient check
Camera zoom 0.3x-2.0x        | Weak     | Zoom works but bounds untested
Seed elements in empty dists  | Missing  | Not visible in screenshots
```

- "Missing" items become remediation tasks automatically
- "Weak" items flagged for human judgment
- Matrix is available at evolve step for human audit

When holistic review fails, it produces a remediation plan. Remediation tasks go through the standard implement → evaluate loop. Holistic reviewer runs again after remediation. Up to `max_holistic_iterations` (configurable, default 3). If still failing, escalate to human.

---

### Multi-Provider Evaluation

All configured providers (Claude, Codex, Gemini) can participate in evaluation. Each provider can do full runtime evaluation via MCP tools — the constraint is shared resource access, not capability.

**Scorecard merging: minimum score per dimension wins.** If any provider scores below threshold, the task fails. One skeptic blocks. This prevents the lenient-evaluator problem — all providers must agree it's good enough.

**Provider disagreements are a feature.** When Claude scores Visual Quality 7 but Codex scores it 5, the disagreement is surfaced. In attended mode, the human sees the disagreement and decides. In unattended mode, the stricter score wins.

---

### Runtime Resource Coordination

Multiple evaluators may need access to shared resources (dev servers, emulators, ports). The runtime command in `orchestrate.json` controls coordination strategy:

#### Runtime Configuration

The `runtime` field is always an array of commands:

```json
"runtime": ["command1", "command2", ...]
```

**Single element — coordinated access:**

```json
"runtime": ["flock /tmp/eval-flutter.lock flutter run -d chrome --web-port=8080"]
```

All evaluators receive the same command. They share one resource instance. Coordination is handled by the command itself — `flock` ensures evaluators wait their turn. One port, one emulator, simple.

Use `flock` (or equivalent locking mechanism) when:
- Resources are scarce (single emulator, single GPU)
- The app has side effects that conflict across instances (shared database, shared state)
- You want simpler configuration

**Multiple elements — parallel slots:**

```json
"runtime": [
  "flutter run -d chrome --web-port=8080",
  "flutter run -d chrome --web-port=8081",
  "flutter run -d chrome --web-port=8082"
]
```

Orchestrator assigns one slot per evaluator by index. Evaluators run simultaneously on separate instances. Use when:
- Speed matters and resources allow
- Each instance is isolated (separate ports, separate databases)
- The app is stateless or each instance has its own state

**When there are more providers than slots:** Orchestrator assigns slots round-robin. Remaining providers wait for a slot to free up.

#### Examples for Common Stacks

**Flutter web:**
```json
"runtime": ["flock /tmp/eval-flutter.lock flutter run -d chrome --web-port=8080"]
```

**React/Next.js dev server:**
```json
"runtime": ["flock /tmp/eval-react.lock npm run dev -- --port 3000"]
```

**Go API server (parallel, stateless):**
```json
"runtime": [
  "PORT=8080 go run ./cmd/server",
  "PORT=8081 go run ./cmd/server"
]
```

**Mobile (iOS simulator — single device, must coordinate):**
```json
"runtime": ["flock /tmp/eval-ios.lock flutter run -d 'iPhone 16'"]
```

---

### Per-Task Protocol

The strict implement → evaluate → iterate loop that replaces the current subagent-driven-development per-task flow:

```
1. DISPATCH implementer (subagent, fresh per iteration)
   - Full task text + context
   - Evaluation block (so implementer knows what it will be graded on)
   - Antipattern file ("avoid these known failures")
   - Prior scorecard + evaluator guidance (if iteration 2+)

   Implementer returns: DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT
   - Handle BLOCKED/NEEDS_CONTEXT as today (provide context, re-dispatch, escalate)

2. DISPATCH evaluator(s) (fresh team member(s) per task)
   - Evaluation protocol + domain template + project config
   - Calibration anchors + antipattern file
   - Git diff (BASE_SHA..HEAD_SHA)
   - Runtime command (from orchestrate.json)
   - Task criteria (from plan's Evaluation block)
   - Iteration number and prior scorecards (if iteration 2+)

   Multi-provider: all configured providers evaluate (parallel or coordinated)
   Each returns a scorecard.

3. MERGE scorecards (minimum score per dimension)

4. ATTENDED GATE (if evaluators.attended: true)
   - Show merged scorecard to human
   - Highlight provider disagreements
   - Human confirms or corrects
   - Corrections encoded as calibration anchors

5. CONVERGENCE CHECK (on merged scores)
   - All dimensions >= threshold? All task criteria pass? No antipatterns?

   PASS + second consecutive pass (or all scores >= threshold+2):
     → CONVERGED → mark task complete → next task

   PASS (first time):
     → Re-evaluate once more to confirm convergence

   FAIL + iteration < max_eval_iterations:
     → Dispatch FRESH implementer with merged scorecard + guidance → step 1

   FAIL + iteration >= max_eval_iterations:
     → ESCALATE to human
       "Task X failed after N evaluations. Latest scores: [scorecard]. Recommend: [action]"
```

**Critical protocol rules:**

1. Evaluator is NEVER the implementer. Always separate. Self-review is pre-screening only, not the gate.
2. Fresh implementer on each iteration. Not the same agent asked to "fix things." Fresh context with the evaluator's feedback injected.
3. Merged evaluator scores are final. The orchestrator checks thresholds mechanically — no judgment call on whether a 6 is "close enough to 7."
4. No skipping runtime for tasks that have a runtime command. If the Evaluation block says `Runtime: flutter run`, the evaluator MUST launch it and inspect.
5. Escalate, don't force. If max iterations reached without passing, stop and ask the human. Never silently lower thresholds.
6. Evaluator gets previous scores. On iteration 2+, the evaluator sees all prior scorecards to track improvement/regression. If scores regress, flag it.

---

### Holistic Review Protocol

```
1. DISPATCH holistic reviewer(s) (fresh team member(s))
   - Evaluation protocol + holistic dimensions + project config
   - Full spec/design doc
   - Entire diff from plan start (BASE_SHA..HEAD_SHA)
   - Runtime command
   - Calibration anchors + antipattern file

   Multi-provider: same coordination as task evaluators.

2. Reviewer produces:
   - Holistic dimension scores
   - Spec coverage matrix (every requirement → Full/Weak/Missing + evidence)
   - Antipattern check at system level
   - Remediation recommendations (if failing)

3. MERGE scorecards (minimum per dimension)
   MERGE coverage matrices (if any provider marks requirement as Missing, it's Missing)

4. ATTENDED GATE (if evaluators.attended: true)

5. CHECK thresholds
   PASS → continue to next batch or finish
   FAIL → create remediation tasks (from coverage gaps + failed dimensions)
          → remediation tasks go through per-task loop
          → holistic review runs again after remediation
          → up to max_holistic_iterations (default 3)
          → if still failing → escalate to human
```

---

### Calibration

#### Generic Calibration (ships with fiddle)

Each domain evaluator template includes generic scoring anchors that describe quality levels in terms of patterns and signals, not project-specific content. These work for any project because they reference the project's own design system as the standard.

#### Project-Specific Calibration (per project, optional)

Projects provide a calibration file with concrete examples of what quality levels mean for their specific app:

```markdown
# Frontend Evaluation Calibration — whatnext

**Design reference:** docs/DESIGN_SYSTEM.md, docs/style-guide.md

## Visual Quality — Project Anchors

**Score 3-4 for this project looks like:**
- City renders as colored rectangles on blank canvas
- Districts indistinguishable except by color
- No sprite assets loaded, fallback rendering everywhere

**Score 7 for this project looks like:**
- Radial spoke layout visible with central park
- District zones have soft-edged tinted ground
- Building sprites render at correct tier sizes
- Roads connect park to districts with texture

**Score 9 for this project looks like:**
- City matches brand bible illustrations
- Smooth camera zoom, pan constrained to world bounds
- Decorations and foliage fill gaps between districts
```

Location: referenced from `orchestrate.json`, typically `docs/evaluator-calibration-<domain>.md`.

#### Calibration From Specs

When brainstorming produces a design spec, initial calibration anchors are extracted from the spec. The spec already describes what the output should look like — calibration anchors are that description bucketed into quality tiers. This means every brainstorming session that produces a spec also produces initial calibration anchors.

#### Attended Runs Refine Calibration

In attended mode, human corrections to evaluator scorecards are encoded as new calibration anchors. Over multiple attended runs, the calibration file accumulates project-specific examples of what good and bad look like, tuned to the human's taste.

The human flips `evaluators.attended` to `false` when they trust the evaluator's judgment. No ceremony — just confidence built through observed alignment.

---

### Antipattern Accumulation

A growing file of real failures that the system has encountered. Loaded by both implementer ("avoid these") and evaluator ("check for these").

```markdown
# Antipatterns — whatnext frontend

- Flame sprite assets referenced in code but not registered in pubspec.yaml (2026-03-06)
- Soft-edged gradients render as hard circles on web target — test on web, not just simulator (2026-03-06)
- District positions calculated at init but not recalculated on window resize (2026-03-08)
```

**Flows through the entire pipeline:**
- Implementer loads it: "avoid these known failures"
- Task evaluator checks for them: "is this repeating a known antipattern?"
- Holistic reviewer checks at system level
- Evolve step appends new antipatterns from post-delivery findings

**Location:** per project, typically `docs/antipatterns-<domain>.md`. Referenced from `orchestrate.json`.

---

### Attended/Unattended Progression

The flow is always the same. What changes is whether the human confirms evaluator scorecards.

**`evaluators.attended: true`** — Evaluator scores are shown to human before the orchestrator acts on them. Human can confirm or correct. Corrections become calibration anchors. Use this for the first several runs while calibrating the evaluator.

**`evaluators.attended: false`** — Evaluator scores are trusted. The orchestrator acts on them without asking. Human reviews at the evolve step post-delivery.

### Evolve Step

Post-delivery, the human reviews the run. This is fiddle's existing evolve step, enriched to also update evaluator artifacts.

**Human reviews:**
- Final output (the actual running app)
- Evaluator scorecards from the run
- Holistic coverage matrix
- Iteration counts per task (high counts suggest calibration gaps)

**Human produces (with system encoding assistance):**
- Calibration updates (where evaluator judgment was off)
- New antipatterns (real failures found in the output)
- Threshold adjustments (if consistently too strict or lenient)

These feed forward into the next run — evaluator loads updated calibration + antipatterns, implementer loads antipatterns.

---

### Model Selection

| Role | Model | Rationale |
|---|---|---|
| Implementer (simple task) | Sonnet / Haiku | 1-2 files, clear spec, mechanical |
| Implementer (complex task) | Opus | Multi-file, integration, judgment |
| Task evaluator | Opus | Judgment, taste, quality assessment |
| Holistic reviewer | Opus | Broad understanding, cross-cutting |
| External provider evaluators | Codex / Gemini | Diversity of perspective |

Implementer model selection follows existing superpowers guidance (least powerful model that handles the task). Evaluators always use the most capable available model — evaluation is where judgment matters most.

---

## Dependency Change: Drop Superpowers

This design drops the superpowers plugin dependency. Fiddle becomes self-contained.

**Rationale:** The new evaluator system replaces superpowers' entire execution and review pipeline. The remaining superpowers skills are discipline primitives (TDD, verification, debugging) and planning primitives (brainstorming, writing-plans). Patching superpowers on every install is fragile and grows with each design change. The execution models are fundamentally incompatible — superpowers assumes subagent-driven orchestration with pass/fail reviews; fiddle now uses team-based orchestration with scored evaluators.

**Migration strategy:**

| Superpowers skill | Action |
|---|---|
| `subagent-driven-development` | **Drop.** Replaced by fiddle's evaluator loop in develop/develop-swarm. |
| `executing-plans` | **Drop.** Replaced by fiddle's develop orchestration. |
| `requesting-code-review` | **Drop.** Replaced by calibrated evaluators. |
| `dispatching-parallel-agents` | **Drop.** Replaced by fiddle's team-based orchestration. |
| `brainstorming` | **Fork and modify.** Add calibration anchor extraction from specs. Own directly — no more patching. |
| `writing-plans` | **Fork and modify.** Add Evaluation blocks per task. Own directly — no more patching. |
| `test-driven-development` | **Fork as-is.** Stable discipline primitive. Implementers still follow TDD. |
| `verification-before-completion` | **Fork as-is.** Stable discipline primitive. Still applies to implementers. |
| `systematic-debugging` | **Fork as-is.** Stable discipline primitive. |
| `using-git-worktrees` | **Fork as-is.** Still used for isolation. |
| `finishing-a-development-branch` | **Fork as-is.** Still used at end of develop. |
| `receiving-code-review` | **Fork as-is.** Still useful for human reviews. |
| `writing-skills` | **Fork as-is.** Meta skill for creating new skills. |
| `using-superpowers` | **Replace.** Becomes fiddle's own skill discovery mechanism. |

**Post-migration:** Delete `skills/patch-superpowers/` — no longer needed. Periodically review superpowers upstream for ideas to import (as we did with this design), but no runtime dependency.

---

## Changes Required

### New Files in Fiddle

| File | Purpose |
|---|---|
| `skills/evaluate/SKILL.md` | Evaluation protocol — scoring, thresholds, iteration, convergence rules |
| `skills/evaluate/evaluator-frontend.md` | Frontend domain template — dimensions, generic calibration anchors |
| `skills/evaluate/evaluator-backend.md` | Backend domain template |
| `skills/evaluate/evaluator-general.md` | Fallback domain template |
| `skills/evaluate/runtime-evidence.md` | Instructions for runtime verification (launching app, screenshots, interaction) |
| `skills/brainstorm/SKILL.md` | Forked from superpowers + calibration anchor extraction |
| `skills/write-plan/SKILL.md` | Forked from superpowers + Evaluation blocks per task |
| `skills/tdd/SKILL.md` | Forked as-is from superpowers |
| `skills/verify/SKILL.md` | Forked as-is from superpowers |
| `skills/debug/SKILL.md` | Forked as-is from superpowers |
| `skills/worktrees/SKILL.md` | Forked as-is from superpowers |
| `skills/finish-branch/SKILL.md` | Forked as-is from superpowers |
| `skills/receive-review/SKILL.md` | Forked as-is from superpowers |
| `skills/write-skill/SKILL.md` | Forked as-is from superpowers |

### Modified Files in Fiddle

| File | Change |
|---|---|
| `skills/develop/SKILL.md` | Replace two-stage review with evaluator dispatch. Add attended mode gate. Convergence-based iteration. |
| `skills/develop-swarm/SKILL.md` | Same review pipeline change for swarm mode. |
| `skills/deliver/SKILL.md` | Evolve step enriched to update calibration files + antipatterns. |
| `orchestrate.json` | New `evaluators` section. |

### Deleted Files

| File | Reason |
|---|---|
| `skills/patch-superpowers/` | No longer needed — no superpowers dependency to patch. |

### Unchanged

- Implementer prompt template (receives scorecard on re-dispatch, otherwise same)
- Beans integration
- Hooks infrastructure
- Provider dispatch mechanism
- discover/define/deliver phase skills (except deliver evolve enrichment)

---

## orchestrate.json — Evaluator Configuration

```json
{
  "evaluators": {
    "attended": true,
    "max_eval_iterations": 15,
    "domains": {
      "frontend": {
        "template": "evaluator-frontend",
        "runtime": ["flock /tmp/eval-flutter.lock flutter run -d chrome --web-port=8080"],
        "runtime_agent": "playwright-expert",
        "stack_agents": ["flutter-expert", "dart-expert"],
        "calibration": "docs/evaluator-calibration-frontend.md",
        "antipatterns": "docs/antipatterns-frontend.md",
        "extra_dimensions": {
          "brand_consistency": {
            "description": "Matches style guide and brand bible",
            "threshold": 7,
            "reference": "docs/DESIGN_SYSTEM.md"
          }
        },
        "thresholds": {
          "visual_quality": 7,
          "craft": 7,
          "functionality": 8,
          "spec_fidelity": 8
        }
      },
      "backend": {
        "template": "evaluator-backend",
        "runtime": [
          "PORT=8080 go run ./cmd/server",
          "PORT=8081 go run ./cmd/server"
        ],
        "runtime_agent": "rest-expert",
        "stack_agents": ["go-expert", "postgres-expert"],
        "calibration": "docs/evaluator-calibration-backend.md",
        "antipatterns": "docs/antipatterns-backend.md"
      }
    },
    "holistic": {
      "frequency": "every_3_tasks",
      "max_iterations": 3,
      "runtime": ["flock /tmp/eval-flutter.lock flutter run -d chrome --web-port=8080"],
      "runtime_agent": "playwright-expert",
      "design_reference": "docs/DESIGN_SYSTEM.md",
      "dimensions": {
        "integration": { "threshold": 7 },
        "coherence": { "threshold": 7 },
        "spec_fidelity": { "threshold": 8 },
        "polish": { "threshold": 6 },
        "runtime_health": { "threshold": 9 }
      }
    }
  }
}
```

---

## Complete Flow

```
BRAINSTORM
  → Design spec
  → Initial calibration anchors (extracted from spec)

PLAN (writing-plans)
  → Tasks with Evaluation blocks:
      Domain: frontend
      Runtime: (from orchestrate.json)
      Task criteria:
        - Districts render as soft-edged circles
        - Zone radius grows with unlock count
        - Tint colors match design doc palette
      Threshold: 7/10 per dimension, all criteria must pass
  → Spec requirements list (feeds holistic coverage matrix)

DEVELOP (per task)
  ┌──────────────────────────────────────────────────────────────┐
  │ 1. Dispatch implementer (subagent, fresh per iteration)      │
  │    - Task text + evaluation block + antipatterns              │
  │    - Prior scorecard if iteration 2+                         │
  │                                                              │
  │ 2. Dispatch evaluator(s) (fresh team member(s))              │
  │    - Protocol + domain template + project config             │
  │    - Calibration + antipatterns + runtime + diff             │
  │    - Multi-provider: parallel or coordinated via runtime cmd │
  │                                                              │
  │ 3. Merge scorecards (minimum per dimension)                  │
  │                                                              │
  │ 4. Attended gate (if attended: show scorecard, allow         │
  │    corrections → calibration anchors)                        │
  │                                                              │
  │ 5. Convergence check                                         │
  │    CONVERGED → next task                                     │
  │    FAIL + iterations remain → fresh implementer → step 1     │
  │    FAIL + max reached → escalate to human                    │
  └──────────────────────────────────────────────────────────────┘

HOLISTIC REVIEW (every N tasks + after all tasks)
  ┌──────────────────────────────────────────────────────────────┐
  │ Fresh team member(s), multi-provider                         │
  │ - Full app walkthrough + spec coverage matrix                │
  │ - Holistic dimensions scored                                 │
  │ - PASS → continue                                            │
  │ - FAIL → remediation tasks → per-task loop → re-review       │
  │ - Max 3 holistic iterations → escalate                       │
  └──────────────────────────────────────────────────────────────┘

FINISH BRANCH
  → finishing-a-development-branch (unchanged)

DELIVER
  → Drift analysis, doc updates (existing)

EVOLVE (post-delivery, human)
  → Review scorecards, coverage matrix, iteration counts
  → Update calibration anchors (where evaluator was wrong)
  → Append new antipatterns (real failures found)
  → Adjust thresholds (if consistently too strict/lenient)
  → These feed forward into the next run
```

### Compound Loop Across Runs

```
Run 1:  Generic calibration, empty antipatterns, attended
        → Human corrects evaluator, system encodes corrections
        → Evolve adds first antipatterns + calibration anchors

Run 2:  Better calibration, some antipatterns, attended
        → Fewer corrections needed
        → Evaluator catches more, implementer avoids known failures

Run 3+: Good calibration, growing antipatterns
        → Human flips attended: false
        → System runs unattended with calibrated evaluator
        → Evolve only adds genuinely new failure modes

Run N:  Stable calibration, comprehensive antipatterns
        → Periodic human spot-checks at evolve
        → System self-sustaining with accumulated project knowledge
```
