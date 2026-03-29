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
- Convergence-based stopping (finding-stability: two consecutive evaluations with no new failing dimensions and no score regressions = converged. Inspired by correctless multi-round convergence auditing.)
- Safety cap at `max_dispatches_per_task` (default 60 dispatches, where dispatches = providers × domains × iterations)
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

All dimensions are fiddle defaults. Projects can override, add, or remove dimensions via `orchestrate.json`. Each dimension includes:
- Definition (what it measures)
- Default threshold
- Full 1-10 scoring scale (every level defined — no gaps, no interpolation)

Generic anchors describe quality levels in terms of **patterns and signals**, not project-specific content. Below is a representative example for one frontend dimension. The actual domain templates contain the full scale for EVERY dimension.

#### Frontend Dimensions

**Visual Quality** — Does the rendered output look intentional and polished?
Default threshold: 7

```
 1  Broken: App doesn't render. Blank screen, crash, or error state.
 2  Non-functional: Something renders but is unusable. Layout completely
    broken, elements overlapping or off-screen.
 3  Placeholder: Default framework output. Colored rectangles, system
    fonts, no evidence of design system.
 4  Minimal: Some custom styling attempted but inconsistent. Mix of
    placeholder and styled elements. Looks unfinished.
 5  Mediocre: Design system partially applied. Some components styled,
    others default. An engineer's "it works" not a designer's "it's ready."
 6  Acceptable: Design system applied consistently. Custom components
    throughout. Rough edges visible but overall looks intentional.
 7  Good: Matches design reference in structure and feel. Minor polish
    issues. A designer would say "needs a pass" not "start over."
 8  Strong: Close to design reference. Consistent visual language.
    Details mostly right. Minor nitpicks only.
 9  Polished: Matches design reference closely. Smooth transitions,
    proper spacing, color harmony. Ready to ship.
10  Exceptional: Exceeds design reference. Delightful details,
    micro-interactions, visual surprise. Better than specified.
```

**Craft** — Typography, spacing, color harmony, contrast, alignment.
Default threshold: 7

```
 1  Broken: No text visible, or text unreadable (white on white, 0px font).
 2  Illegible: Text renders but wrong size, overlapping, or truncated.
    Colors clash. No spacing system.
 3  System defaults: Framework default fonts, spacing, colors.
    No intentional typographic choices.
 4  Inconsistent: Some intentional choices but applied unevenly.
    Multiple font sizes with no hierarchy. Spacing varies randomly.
 5  Basic: One font applied. Some spacing consistency. Colors from a
    palette but without harmony. Alignment mostly correct.
 6  Competent: Type hierarchy clear (headings, body, labels). Spacing
    system visible. Colors harmonious. Minor alignment issues.
 7  Good: Type hierarchy, spacing, and color all feel designed together.
    Contrast ratios adequate. Alignment consistent.
 8  Strong: Typography reinforces hierarchy and mood. Spacing creates
    rhythm. Color usage purposeful. No orphaned elements.
 9  Refined: Typographic details polished (line height, letter spacing,
    font weight variation). White space used intentionally.
10  Masterful: Typography, color, and spacing create a distinctive
    visual identity. Every detail considered.
```

**Functionality** — Does it work when you use it? Interactive behavior correct?
Default threshold: 8

```
 1  Broken: Core interaction doesn't work. Buttons don't respond, pages don't load.
 2  Crashes: Some interactions work, others crash the app.
 3  Partial: Main flow works. Secondary interactions broken or missing.
 4  Fragile: Works for expected interactions. Unexpected actions (back button,
    rapid taps, resize) cause breakage.
 5  Basic: All specified interactions work. No feedback for loading states,
    errors, or edge cases.
 6  Functional: Interactions work with appropriate feedback. Loading states
    shown. Some edge cases unhandled.
 7  Solid: All interactions work correctly with feedback. Error states
    handled. Responsive to different viewport sizes.
 8  Robust: Handles rapid interaction, concurrent state changes, connectivity
    issues. Animations smooth. No jank.
 9  Polished: Transitions between states feel natural. Undo/recovery
    available. Accessibility basics met.
10  Delightful: Interactions feel instant. Animations guide attention.
    Keyboard navigation works. Screen reader compatible.
```

**Domain Spec Fidelity** — Does this task's implementation match the task-level spec?
Default threshold: 8

```
 1  Wrong feature: Built something entirely different from task spec.
 2  Wrong approach: Right feature, fundamentally wrong implementation strategy.
 3  Major gaps: Core task requirements missing. What exists may be correct
    but the task is incomplete.
 4  Partial: ~50% of task requirements implemented. Missing pieces noticeable.
 5  Most there: ~70% of task requirements. Missing pieces are secondary
    but a careful reviewer would catch them.
 6  Functional coverage: All primary task requirements met. Secondary requirements
    (edge cases, error states, responsive behavior) partially covered.
 7  Good coverage: All task requirements met. Some implemented minimally
    (letter of the spec, not spirit).
 8  Faithful: Implementation matches task spec in both letter and spirit.
    Design intent preserved.
 9  Complete: Every task requirement fully implemented. No drift.
    Implementation captures nuances of the task description.
10  Exceeds spec: All requirements met and implementation improves on
    spec where the task description was ambiguous or underspecified.
```

Note: This is the domain-local version scored by task evaluators. The holistic reviewer scores a separate **Holistic Spec Fidelity** dimension that evaluates the entire implementation against the full design doc (see Holistic Dimensions).

#### Backend Dimensions

**Correctness** — Does the code produce right results for all inputs?
Default threshold: 7

```
 1  Broken: Doesn't compile or start. Panics on launch.
 2  Crashes: Starts but crashes on basic operations. Core paths broken.
 3  Happy path only: Main flow works, all error paths crash or
    return wrong data.
 4  Fragile: Works for expected inputs. Unexpected inputs cause
    silent corruption, panics, or wrong results.
 5  Partial: Most paths handled. Some edge cases produce wrong
    results. Error messages misleading.
 6  Functional: All specified paths work correctly. Edge cases
    handled but some return generic errors.
 7  Solid: All paths correct with appropriate errors. Input
    validation present. No silent failures.
 8  Robust: Handles unexpected inputs gracefully. Errors are
    specific and actionable. Concurrent access safe.
 9  Thorough: All edge cases handled correctly. Error recovery
    works. Observability (logging, metrics) in place.
10  Bulletproof: Handles adversarial input. Graceful degradation
    under load. Comprehensive observability.
```

**API Contract Fidelity** — Does the implementation match the API spec/contract?
Default threshold: 7

```
 1  No contract: No spec, endpoints return arbitrary shapes.
 2  Wrong contract: Spec exists but implementation contradicts it.
 3  Partial match: Some endpoints match spec, others diverge
    in structure or status codes.
 4  Structure matches, semantics don't: JSON shapes correct but
    values wrong (wrong units, missing nullability).
 5  Happy path matches: Success responses match spec. Error
    responses are ad-hoc.
 6  Mostly compliant: All responses structurally correct. Some
    status codes wrong (200 instead of 201, 400 instead of 422).
 7  Compliant: All status codes, response shapes, and headers
    match spec. Pagination/filtering works as documented.
 8  Strict compliance: Content types, validation errors, and
    edge case responses all match spec. Undocumented fields absent.
 9  Verified compliance: Contract tests exist and pass.
    Spec and implementation provably in sync.
10  Self-documenting: Generated docs from implementation match
    spec exactly. Breaking changes detected automatically.
```

**Error Handling** — How gracefully does the system handle failures?
Default threshold: 7

```
 1  No handling: Panics and stack traces leak to client.
 2  Catch-all: Generic 500 for all errors. No differentiation.
 3  Basic: Some errors caught, some leak. Inconsistent format.
 4  Structured but wrong: Error format consistent but status
    codes inappropriate or messages misleading.
 5  Adequate: Errors categorized (4xx vs 5xx). Messages exist
    but are generic ("something went wrong").
 6  Informative: Specific error messages. Correct status codes.
    Client can distinguish error types.
 7  Actionable: Messages tell client what to fix. Validation
    errors reference specific fields.
 8  Complete: All error paths return structured, documented
    errors. Retry-after headers where appropriate.
 9  Graceful: Partial failures handled (some items succeed,
    some fail). Transactional consistency maintained.
10  Resilient: Circuit breakers, fallbacks, degraded modes.
    Errors don't cascade across services.
```

**Domain Spec Fidelity** — Same scale as frontend domain spec fidelity.
Default threshold: 8

#### General Dimensions

For tasks that don't fit a specific domain (scripts, configuration, tooling).

**Correctness** — Same scale as backend correctness.
Default threshold: 7

**Domain Spec Fidelity** — Same scale as frontend/backend domain spec fidelity.
Default threshold: 8

**Code Quality** — Is the code clean, maintainable, and idiomatic?
Default threshold: 6

```
 1  Broken: Syntax errors, doesn't parse.
 2  Garbage: Runs but incomprehensible. No structure, no naming,
    no separation of concerns.
 3  Spaghetti: Works but tangled. Functions do too many things.
    Copy-paste duplication. Global state.
 4  Rough: Some structure but inconsistent. Mix of patterns.
    Long functions with unclear responsibilities.
 5  Adequate: Reasonable structure. Functions mostly do one thing.
    Some duplication. Naming is okay but not great.
 6  Clean: Clear structure, good naming, minimal duplication.
    Follows existing codebase patterns.
 7  Good: Well-organized with clear interfaces. Easy to read.
    Follows language idioms. Tests are clear.
 8  Strong: Clean abstractions, good separation of concerns.
    Code reads like documentation. Easy to modify.
 9  Excellent: Elegant and simple. Minimal surface area.
    Another developer could maintain this easily.
10  Exemplary: Could be used as a teaching example. Every
    abstraction earns its complexity.
```

**Layer 3: Project-Specific Configuration (per project — optional overrides)**

Projects customize via `orchestrate.json`:

- Which domain evaluator to use
- Runtime commands for evaluation
- References to project-specific agents (flutter-expert, rest-expert, go-expert, etc.)
- Extra dimensions beyond the base set
- Custom thresholds
- Project-specific calibration file with concrete anchors for this app
- Antipattern file reference

**Domain resolution:** Each task's Evaluation block specifies a `Domain` field (e.g., `frontend`). The orchestrator resolves this to the matching key in `evaluators.domains` in `orchestrate.json`. If no match, falls back to `evaluator-general.md` with no runtime.

**No evaluator config at all:** If a project has no `evaluators` section in `orchestrate.json`, the develop phase uses `evaluator-general.md` with no runtime, no multi-provider, and default thresholds (6 on all dimensions). There is no superpowers fallback — fiddle is self-contained.

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
| Holistic spec fidelity | Does the full result match the design doc's vision? (Distinct from domain-local spec fidelity scored by task evaluators.) |
| Polish | Would you ship this? Or does it feel AI-generated? |
| Runtime health | App launches cleanly, no console errors, responsive |

Note: Holistic spec fidelity is a separate dimension from domain spec fidelity. Task evaluators score domain spec fidelity (task requirements vs task implementation). The holistic reviewer scores holistic spec fidelity (full design doc vs full implementation). These are never merged — they are different dimensions scored at different levels.

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

### Multi-Domain Tasks

A task that touches both frontend and backend (e.g., "add an endpoint and wire it into the UI") needs evaluation from multiple domains.

**The Evaluation block supports multiple domains:**

```markdown
### Task 5: Wire district data API to city visualization

**Evaluation:**
- Domains: [frontend, backend]
- Task criteria:
    backend:
      - GET /api/districts returns all 6 districts with unlock counts
      - Response matches DistrictResponse schema
    frontend:
      - City visualization fetches from API, not hardcoded data
      - Loading state shown while fetching
      - Error state if API unavailable
- Threshold: 7/10 per dimension across both domains
```

**How the orchestrator handles multi-domain evaluation:**

1. One implementer builds both sides (single subagent, single commit)
2. Domain evaluators run independently, each on the relevant parts:
   - Backend evaluator(s): start server, hit API, score backend dimensions
   - Frontend evaluator(s): start app, interact with UI, score frontend dimensions
   - Can run in parallel if runtime slots allow, or sequentially with flock
3. Merge ALL scorecards across all domains (minimum per dimension)
4. Each domain must independently meet its own thresholds — backend passing doesn't compensate for frontend failing
5. On failure, feedback to the fresh implementer identifies which domain(s) failed and why

**Runtime for multi-domain:** Each domain uses its own runtime command from `orchestrate.json`. The backend evaluator starts the server; the frontend evaluator starts the app. If the frontend depends on the backend (API calls), the frontend runtime command should also start the backend, or the orchestrator starts it first.

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

Use `flock` (or equivalent locking mechanism, e.g., `shlock` on BSD) when:
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

The strict implement → evaluate → iterate loop that replaces the current subagent-driven-development per-task flow.

#### Step 0: Record baseline

```
- Record BASE_SHA: git rev-parse HEAD
- Mark task bean as in-progress
- Append to bean body:
    ## Evaluation Log
    BASE_SHA: {BASE_SHA}
```

#### Step 1: Dispatch implementer

```
DISPATCH implementer (subagent, fresh per iteration)
  - Full task text + context
  - Evaluation block (so implementer knows what it will be graded on)
  - Antipattern file ("avoid these known failures")
  - Prior scorecard + evaluator guidance (if iteration 2+)

Implementer returns: DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT
  - DONE → proceed to step 2
  - DONE_WITH_CONCERNS → read concerns, address if needed, proceed to step 2
  - BLOCKED → assess blocker, provide context or escalate
  - NEEDS_CONTEXT → provide missing context, re-dispatch step 1
```

#### Step 2: Resolve domains

```
Read task's Evaluation block → extract Domains list

Single domain (e.g., Domains: [frontend]):
  → Look up evaluators.domains.frontend in orchestrate.json
  → One set of evaluators, one runtime config

Multiple domains (e.g., Domains: [frontend, backend]):
  → Look up EACH domain in orchestrate.json
  → Each domain gets its own evaluator(s) with its own runtime
  → If frontend runtime depends on backend (API calls):
      start backend runtime first, then frontend
```

#### Step 3: Dispatch evaluator(s)

```
FOR EACH domain in task's Domains list:

  DISPATCH evaluator(s) (fresh team member(s))
    - Evaluation protocol + domain template + project config
    - Calibration anchors (generic + project-specific for this domain)
    - Antipattern file for this domain
    - Git diff (BASE_SHA..HEAD_SHA)
    - Runtime command for this domain (from orchestrate.json)
    - Task criteria for this domain (from plan's Evaluation block)
    - Iteration number and prior scorecards (if iteration 2+)

  Multi-provider: all configured providers evaluate this domain
    (parallel or coordinated via runtime command)
  Each provider returns a scorecard for this domain's dimensions.

Domains can evaluate in parallel if runtime slots allow,
or sequentially with flock coordination.
```

#### Step 4: Merge scorecards

```
MERGE across providers: minimum score per dimension wins
MERGE across domains: union of all dimension scores
  - Frontend dimensions scored by frontend evaluators only
  - Backend dimensions scored by backend evaluators only
  - Shared dimensions (Spec Fidelity) scored by all, minimum wins
  - Each domain must independently meet its own thresholds

Append to bean's Evaluation Log:
  ### Iteration N (timestamp)
  **frontend:**
  - Visual quality: 7/10
  - Craft: 6/10 (FAIL, threshold 7)
  - Functionality: 8/10
  - Spec fidelity: 8/10
  **backend:**
  - Correctness: 8/10
  - API contract: 7/10
  - Error handling: 7/10
  - Spec fidelity: 8/10
  **Task criteria:** 5/6 pass (FAIL: "Loading state not shown while fetching")
  **Guidance:** "Craft: spacing between district labels inconsistent..."
```

#### Step 5: Attended gate

```
IF evaluators.attended: true
  Show merged scorecard to human
  Highlight:
    - Any dimension below threshold
    - Provider disagreements (score differs by 3+ between providers)
    - Domain-specific failures
  Human confirms or corrects
  Corrections encoded as calibration anchors for the relevant domain
```

#### Step 6: Convergence check

```
ALL dimensions >= threshold across ALL domains?
ALL task criteria pass across ALL domains?
No known antipatterns detected?

CONVERGED (finding-stability convergence, inspired by correctless):
  Convergence requires TWO consecutive passing evaluations where:
  - All dimensions >= threshold across all domains
  - No new failing dimensions compared to prior evaluation
  - No score regressions (no dimension scored lower than prior pass)
  - All task criteria pass
  This prevents lucky single passes. If the second evaluation
  introduces new failures or regressions, convergence resets.
  → Mark task bean as completed → next task

PASS (first time, all thresholds met):
  → Re-evaluate to confirm stability → step 3
  → This confirmation pass is NOT optional

FAIL + dispatches < max_dispatches_per_task:
  → Dispatch FRESH implementer with:
      - Merged scorecard (all domains)
      - Per-domain guidance (which domain failed and why)
      - "Backend passed. Frontend failed on Craft (6/10, need 7).
         Fix: spacing between district labels."
  → Go to step 1

DISPATCHES EXCEEDED (dispatches >= max_dispatches_per_task):
  → ESCALATE to human
    "Task X used N dispatches (budget: M).
     Iterations: K. Latest scores: [full scorecard across all domains].
     Failing domains: [list].
     Recommend: [action]"
```

#### Critical protocol rules

1. **Evaluator is NEVER the implementer.** Always separate. Self-review is pre-screening only, not the gate.
2. **Fresh implementer on each iteration.** Not the same agent asked to "fix things." Fresh context with the evaluator's feedback injected.
3. **Merged evaluator scores are final.** The orchestrator checks thresholds mechanically — no judgment call on whether a 6 is "close enough to 7."
4. **No skipping runtime** for tasks that have a runtime command. If the Evaluation block specifies a domain with runtime configured, the evaluator MUST launch it and inspect.
5. **Escalate, don't force.** If max iterations reached without passing, stop and ask the human. Never silently lower thresholds.
6. **Evaluator gets previous scores.** On iteration 2+, the evaluator sees all prior scorecards to track improvement/regression. If scores regress, flag it.
7. **Each domain evaluated independently.** Frontend evaluators only score frontend dimensions. Backend evaluators only score backend dimensions. A frontend pass does not compensate for a backend fail.
8. **Multi-domain runtime ordering.** If one domain depends on another at runtime (frontend calls backend API), start the dependency first. The Evaluation block should document this: `Runtime dependency: backend must be running before frontend evaluation.`

---

### Holistic Review Protocol

```
1. DISPATCH holistic reviewer(s) (fresh team member(s))
   - Evaluation protocol + holistic dimensions + project config
   - Full spec/design doc
   - Entire diff from plan start (BASE_SHA..HEAD_SHA)
   - Runtime commands for ALL domains configured in the project
     (holistic reviewer evaluates the whole system)
   - Calibration anchors + antipattern files (all domains)

   Multi-provider: same coordination as task evaluators.
   Runtime ordering: start backends before frontends.

2. Reviewer produces:
   - Holistic dimension scores
   - Spec coverage matrix (every requirement → Full/Weak/Missing + evidence)
   - Antipattern check at system level (across all domains)
   - Cross-domain integration assessment
     (does frontend correctly consume backend API? Data formats match?)
   - Remediation recommendations (if failing)

3. MERGE scorecards (minimum per dimension)
   MERGE coverage matrices (if any provider marks requirement as Missing,
   it's Missing)

4. ATTENDED GATE (if evaluators.attended: true)

5. CHECK thresholds
   PASS → continue to next batch or finish
   FAIL → create remediation tasks:
          - Each remediation task gets its own Evaluation block with domains
          - Remediation tasks go through the full per-task protocol
          - Holistic review runs again after all remediation tasks complete
          - Up to max_holistic_iterations (default 3)
          - If still failing → escalate to human
```

---

### Session Restart and Recovery

If a session dies mid-execution (crash, timeout, user interrupt), the orchestrator must resume cleanly on restart.

#### State persistence

| Data | Where | Survives restart? |
|---|---|---|
| Task completion status | Bean status field | Yes |
| Current task | Bean marked `in-progress` | Yes |
| Evaluation history + iteration count | Bean body `## Evaluation Log` | Yes |
| Baseline commit for current task | Bean body `BASE_SHA` | Yes |
| Calibration corrections | Calibration file on disk | Yes |
| Antipattern additions | Antipattern file on disk | Yes |

All evaluation state is persisted on the bean. No ephemeral session state needed.

#### Restart protocol

```
1. READ plan and all task beans

2. SKIP tasks with status = completed (trust git history)

3. FIND task with status = in-progress
   - Read its Evaluation Log from bean body
   - Extract BASE_SHA and iteration count

4. ASSESS git state:
   a. Clean (HEAD has commits beyond BASE_SHA, no conflicts):
      → Resume evaluation from iteration N+1
      → Evaluator receives all prior scorecards from bean's Evaluation Log

   b. Dirty (uncommitted changes, partial work):
      → git stash (preserve partial work for reference)
      → Reset to last committed state
      → Resume from last completed iteration

   c. Corrupted (merge conflicts, broken state):
      → git reset --hard {BASE_SHA}
      → Clear Evaluation Log for this task
      → Restart task from iteration 1

5. RESUME per-task protocol from appropriate step
```

#### Bean evaluation log format

```markdown
## Evaluation Log
BASE_SHA: a7981ec

### Iteration 1 (2026-03-29T14:23:00Z)
**frontend:**
- Visual quality: 5/10 (FAIL)
- Craft: 6/10 (FAIL)
- Functionality: 7/10
- Spec fidelity: 4/10 (FAIL)
**Guidance:** "Sprites not loading, fallback rectangles visible..."

### Iteration 2 (2026-03-29T14:31:00Z)
**frontend:**
- Visual quality: 7/10
- Craft: 7/10
- Functionality: 7/10
- Spec fidelity: 6/10 (FAIL)
**Guidance:** "Sprites load but zone radius doesn't grow..."
```

On restart, the orchestrator reads this log and resumes at iteration 3 with full history. The fresh implementer gets all prior scorecards as context.

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

### Scorecard JSON Schema

All scripts operate on a standard scorecard format. Evaluator team members MUST output this format. Scripts validate against it.

```json
{
  "task_id": "bean-id",
  "iteration": 3,
  "timestamp": "2026-03-29T14:31:00Z",
  "provider": "claude",
  "domain": "frontend",
  "dimensions": {
    "visual_quality": { "score": 7, "evidence": "Districts render with soft-edged zones...", "threshold": 7 },
    "craft": { "score": 6, "evidence": "Spacing between labels inconsistent...", "threshold": 7 },
    "functionality": { "score": 8, "evidence": "All interactions work, zoom smooth...", "threshold": 8 },
    "domain_spec_fidelity": { "score": 8, "evidence": "All task criteria met except...", "threshold": 8 }
  },
  "criteria": [
    { "name": "Districts render as soft-edged circles", "pass": true, "evidence": "Screenshot shows gradient edges" },
    { "name": "Zone radius grows with unlock count", "pass": false, "evidence": "Radius static across different unlock levels" }
  ],
  "antipatterns_detected": [],
  "guidance": "Fix craft: spacing between district labels needs consistent 16dp gap. Fix zone radius: must recalculate on data change.",
  "dispatch_count": 1
}
```

**Schema rules:**
- `dimensions` keys must be snake_case and match the domain template's dimension names exactly
- `score` must be integer 1-10
- `evidence` is required for every dimension — empty string is a schema violation
- `criteria` entries must match the task's Evaluation block criteria verbatim
- `estimated_cost_usd` tracks per-evaluation cost for circuit breaker

**Merged scorecard** (output of `merge-scorecards.sh`):

```json
{
  "task_id": "bean-id",
  "iteration": 3,
  "domains": {
    "frontend": {
      "dimensions": {
        "visual_quality": { "score": 6, "threshold": 7, "provider_scores": {"claude": 7, "codex": 6} },
        "craft": { "score": 5, "threshold": 7, "provider_scores": {"claude": 6, "codex": 5} }
      },
      "criteria": [
        { "name": "Districts render as soft-edged circles", "pass": true },
        { "name": "Zone radius grows with unlock count", "pass": false }
      ]
    },
    "backend": { ... }
  },
  "verdict": "FAIL",
  "failing_dimensions": ["frontend.craft", "frontend.visual_quality"],
  "failing_criteria": ["Zone radius grows with unlock count"],
  "disagreements": [
    { "dimension": "frontend.visual_quality", "spread": 1, "scores": {"claude": 7, "codex": 6} }
  ],
  "total_dispatches": 2
}
```

---

### Runtime Interaction Protocol

Runtime verification requires evaluators to interact with the running application. This section defines the protocol — the mechanism is per-project, but the interface is standard.

#### Protocol Elements

**Runtime evaluation is tool-agnostic.** The evaluator uses whatever tools the project has available — project MCP servers, Bash commands, curl, project-specific agents. Fiddle does not prescribe or depend on any specific runtime tool (no Playwright dependency, no browser automation requirement).

**How the evaluator interacts with the running app:**

The orchestrator starts the app via `start-runtimes.sh`. The evaluator (a team member with full session access) then uses the project's available tools to verify the running app:

- **Frontend (Flutter web):** `marionette` MCP for widget interaction and screenshots, `flutter test integration_test/` for integration tests
- **API (Go):** `curl` / `httpie` for HTTP requests, `go-dev-mcp` for Go-specific tooling, direct database queries if needed
- **Desktop (Wails/Svelte):** `curl` for the dev server, Playwright MCP if richer browser interaction needed

The domain template (`evaluator-frontend.md`, `evaluator-backend.md`) describes WHAT to verify. The evaluator figures out HOW using available tools. This is judgment work — exactly what the evaluator is for.

**`runtime_agent`** (optional) — A project-specific agent definition (`.claude/agents/<name>.md`) that provides stack-specific runtime interaction expertise. If configured, the evaluator's prompt includes this agent's knowledge for guidance on how to interact with the specific stack. This is reference material loaded into the evaluator's context, not a separate dispatched agent.

If `runtime_agent` is not configured, the evaluator uses its own judgment about how to interact with the running app using available tools.

**`stack_agents`** (optional) — Additional project-specific agent definitions that provide domain expertise. Loaded into the evaluator's context as reference material. The evaluator may consult their guidance when scoring.

Both `runtime_agent` and `stack_agents` are **context enrichment for the evaluator prompt**, not separate actors in the system.

#### Ready Check Contract

`start-runtimes.sh` verifies readiness via a configurable check. Each domain's runtime config can specify a readiness check:

```json
{
  "runtime": ["flutter run -d chrome --web-port=8080"],
  "ready_check": {
    "type": "http",
    "url": "http://localhost:8080",
    "expect_status": 200,
    "timeout_ms": 60000,
    "retry_interval_ms": 2000
  }
}
```

Supported check types:
- `http` — Poll URL until expected status code
- `tcp` — Poll port until connection accepted
- `command` — Run a command, wait for exit 0

If no `ready_check` specified, falls back to `tcp` on the port parsed from the runtime command.

#### Default and Project-Specific Configurations

Fiddle ships a minimal default evaluator config that works with no project-specific setup (evaluator-general, no runtime, `curl`-based verification). Projects configure their own evaluators in their `orchestrate.json` using whatever tools they have available.

Below are examples of project-specific configs (these live in the target project repos, not in fiddle):

**Flutter Web** (for `~/wrk/next`):

```json
{
  "template": "evaluator-frontend",
  "runtime": ["cd app && flutter run -d chrome --web-port=8080"],
  "runtime_agent": "flutter-expert",
  "stack_agents": ["dart-expert"],
  "ready_check": { "type": "http", "url": "http://localhost:8080", "timeout_ms": 60000 }
}
```

Evaluator uses `marionette` MCP (already configured in project's `.mcp.json`) to interact with the running Flutter app — navigate widgets, take screenshots, inspect state. The `flutter-expert` agent provides stack-specific guidance in the evaluator's context.

**Wails/Svelte** (for `~/wrk/crops`):

```json
{
  "template": "evaluator-frontend",
  "runtime": ["cd frontend && npm run dev -- --port 5173"],
  "stack_agents": ["svelte-expert"],
  "ready_check": { "type": "http", "url": "http://localhost:5173", "timeout_ms": 30000 }
}
```

Svelte dev server can be verified via `curl` and standard HTTP tools. Could also configure Playwright MCP if richer browser interaction is needed for frontend evaluation.

**Go API** (for `~/wrk/next`, `~/wrk/crops`, `~/wrk/sp-shared/identity/icecube`):

```json
{
  "template": "evaluator-backend",
  "runtime": ["PORT=8080 go run ./cmd/server"],
  "runtime_agent": "rest-expert",
  "stack_agents": ["go-expert", "postgres-expert"],
  "ready_check": { "type": "http", "url": "http://localhost:8080/healthz", "timeout_ms": 15000 }
}
```

Evaluator uses `curl`/`httpie` for HTTP verification, `go-dev-mcp` where available. The `rest-expert` and `go-expert` agent definitions provide context.

#### Distinguishing App Failure from Harness Failure

`start-runtimes.sh` exit codes distinguish these:
- Exit 0: runtime started and ready
- Exit 1: app failed to start (implementation bug — counts as evaluation failure)
- Exit 3: harness failure (port conflict, missing dependency, environment issue — does NOT count against iteration cap)

On exit 3, the orchestrator retries startup once. If still failing, escalates to human with the harness error, not an evaluation failure.

---

### Cost Circuit Breaker

Cost is measured in **evaluator dispatches per task** — the total number of evaluator invocations for a single bean/task.

One dispatch = one evaluator invocation (one provider scoring one domain). One iteration with 2 providers × 2 domains = 4 dispatches. A task that runs 5 iterations at that rate = 20 dispatches.

```json
{
  "evaluators": {
    "max_dispatches_per_task": 60
  }
}
```

This is the single circuit breaker. It naturally accounts for iterations, providers, and domains — all the cost multipliers compound into one number. `check-convergence.sh` receives `--max-dispatches` and `--current-dispatches` and returns `COST_EXCEEDED` when hit.

The default (60) allows: 15 iterations × 2 providers × 2 domains, or 10 iterations × 3 providers × 2 domains, or any other combination that stays under 60. Projects tune this one number based on their provider count and domain count.

**Controlling provider count per domain:** Each domain config specifies which providers evaluate it:

```json
{
  "evaluators": {
    "domains": {
      "frontend": {
        "providers": ["claude"],
        ...
      },
      "backend": {
        "providers": ["claude", "codex"],
        ...
      }
    },
    "holistic": {
      "providers": ["claude", "codex", "gemini"],
      ...
    }
  }
}
```

If `providers` is omitted, defaults to `["claude"]` (single provider). This gives direct control over burn rate per domain:
- Frontend: 1 provider → 1 dispatch per domain per iteration
- Backend: 2 providers → 2 dispatches per domain per iteration
- Holistic: 3 providers → 3 dispatches per review

A task touching both frontend and backend = 3 dispatches per iteration (1 + 2). At 60 max dispatches, that's 20 iterations before the circuit breaker fires. Projects decide the tradeoff: more providers = better quality per iteration but fewer iterations before the cap.

---

### Runtime Command and Locking

The `runtime` field in `orchestrate.json` is an opaque command array. Fiddle passes these commands through to `start-runtimes.sh` without interpretation. Locking, port selection, and resource coordination are the **user's responsibility** — they encode their coordination strategy directly in the command.

Fiddle documents common patterns as guidance:

```bash
# Serialized access via flock (Linux, or macOS with util-linux installed)
"runtime": ["flock /tmp/eval-flutter.lock flutter run -d chrome --web-port=8080"]

# Parallel slots via separate ports
"runtime": ["flutter run -d chrome --web-port=8080", "flutter run -d chrome --web-port=8081"]

# No locking (single provider, no contention)
"runtime": ["flutter run -d chrome --web-port=8080"]
```

Fiddle does NOT depend on `flock` or any specific locking mechanism. The runtime command is whatever the user puts in their config.

---

## Enforcement Model

Two enforcement mechanisms, chosen by the nature of the operation:

**Deterministic operations → bash scripts.** Agents MUST call the script. They MUST NOT attempt the logic themselves. The script's exit code and stdout are the source of truth — agents act on the output, not on their own reasoning about what the output should be.

**Process flow → HARD-GATE blocks in skill definitions.** Skills use the same enforcement patterns that superpowers established: `<HARD-GATE>` blocks that halt progress until a condition is met, Red Flags sections listing rationalizations to watch for, and explicit "violating the letter is violating the spirit" language.

### Scripts (deterministic, no LLM interpretation)

All scripts live in `scripts/`. They accept JSON/structured input and produce JSON/structured output. Exit codes: 0 = success, 1 = failure, 2 = invalid input.

#### `merge-scorecards.sh`

Merge multiple scorecards into one. Minimum score per dimension wins.

```
Input:  JSON array of scorecards on stdin
        [{"domain":"frontend","provider":"claude","scores":{"visual_quality":7,"craft":5}},
         {"domain":"frontend","provider":"codex","scores":{"visual_quality":6,"craft":7}}]

Output: Merged scorecard JSON on stdout
        {"frontend":{"visual_quality":6,"craft":5},"backend":{...}}

Also:   Disagreements (score differs by 3+ between providers) on stderr
        DISAGREEMENT frontend.visual_quality: claude=7 codex=4
```

#### `check-thresholds.sh`

Compare merged scorecard against threshold config. Returns verdict.

```
Input:  --scorecard <merged-scorecard.json>
        --config <orchestrate.json>
        --criteria <task-criteria-results.json>  (binary pass/fail per criterion)

Output: Verdict JSON on stdout
        {"verdict":"FAIL",
         "failing_dimensions":[{"domain":"frontend","dimension":"craft","score":5,"threshold":7}],
         "failing_criteria":["Loading state not shown while fetching"],
         "passing_dimensions":[...]}

Exit:   0 = all pass, 1 = at least one fail
```

#### `check-convergence.sh`

Determine if evaluation has converged based on finding-stability (inspired by correctless convergence auditing). Convergence requires two consecutive passing evaluations with no new failing dimensions and no score regressions.

```
Input:  --current <current-verdict.json>
        --history <eval-history.json>      (all prior verdicts)
        --max-iterations 15
        --max-dispatches 60                  (from orchestrate.json)
        --current-dispatches 12              (accumulated dispatches for this task)

Output: Convergence verdict on stdout
        {"status":"CONVERGED"}              two consecutive stable passes
        {"status":"PASS_PENDING"}           first pass, need confirmation
        {"status":"PASS_REGRESSED",         pass but new failures or
         "regressions":["craft"]}            score drops vs prior pass
        {"status":"FAIL","iteration":3}     below threshold
        {"status":"ESCALATE","iteration":15,
         "reason":"max iterations reached"}
        {"status":"COST_EXCEEDED",
         "dispatches":62,"budget":60}

Exit:   0 = CONVERGED, 1 = FAIL/PASS_PENDING/PASS_REGRESSED, 2 = ESCALATE/COST_EXCEEDED
```

#### `parse-eval-log.sh`

Extract evaluation state from a bean's body for restart.

```
Input:  --bean-id <id>
        (reads bean via `beans show`)

Output: Evaluation state JSON on stdout
        {"base_sha":"a7981ec",
         "iteration_count":2,
         "scorecards":[...],
         "last_verdict":"FAIL",
         "last_guidance":"Sprites load but zone radius doesn't grow..."}

Exit:   0 = log found and parsed, 1 = no evaluation log on bean
```

#### `append-eval-log.sh`

Append an iteration entry to a bean's Evaluation Log.

```
Input:  --bean-id <id>
        --iteration <N>
        --scorecard <scorecard.json>
        --verdict <verdict.json>
        --guidance "free text guidance from evaluator"

Effect: Appends formatted markdown entry to bean body via `beans update`
        ### Iteration N (timestamp)
        **frontend:**
        - Visual quality: 7/10
        ...

Exit:   0 = appended, 1 = bean not found
```

#### `resolve-domains.sh`

Resolve a task's domain list to full evaluator config.

```
Input:  --domains "frontend,backend"
        --config <orchestrate.json>

Output: Full config per domain JSON on stdout
        [{"domain":"frontend",
          "template":"evaluator-frontend",
          "runtime":["flock ..."],
          "runtime_agent":"flutter-expert",
          "calibration":"docs/evaluator-calibration-frontend.md",
          "antipatterns":"docs/antipatterns-frontend.md",
          "thresholds":{"visual_quality":7,"craft":7,...},
          "stack_agents":["flutter-expert"]},
         {"domain":"backend",...}]

Exit:   0 = all domains resolved, 1 = unknown domain (falls back to general)
```

#### `start-runtimes.sh`

Start runtime processes for evaluation. Handles dependency ordering (backends before frontends).

```
Input:  --domains <resolved-domains.json>
        --slot-index <N>  (which runtime slot to use, for parallel)

Output: Runtime state JSON on stdout
        [{"domain":"backend","pid":12345,"port":8080,"command":"..."},
         {"domain":"frontend","pid":12346,"port":8081,"command":"..."}]

Effect: Starts processes in background.
        Waits for each to be ready (polls health endpoint or port).
        Backend started and ready before frontend starts.

Exit:   0 = all runtimes started, 1 = startup failed (includes stderr details)
```

#### `stop-runtimes.sh`

Stop runtime processes started by start-runtimes.sh.

```
Input:  --state <runtime-state.json>  (output from start-runtimes.sh)

Effect: Sends SIGTERM to each PID. Waits for clean shutdown.
        Falls back to SIGKILL after 10s.

Exit:   0 = all stopped
```

#### `assess-git-state.sh`

Determine git state relative to a base commit for restart.

```
Input:  --base-sha <sha>

Output: State assessment on stdout
        {"state":"CLEAN","head_sha":"b1234ef","commits_ahead":3}
        {"state":"DIRTY","uncommitted_files":["app/lib/city.dart"]}
        {"state":"CORRUPTED","reason":"merge conflict in app/lib/city.dart"}

Exit:   0 = CLEAN, 1 = DIRTY, 2 = CORRUPTED
```

### HARD-GATE Enforcement Points (in skill definitions)

These are the points where skill definitions MUST use `<HARD-GATE>` blocks to force compliance. The agent cannot proceed past a HARD-GATE until its condition is met.

#### In `skills/develop/SKILL.md`:

```markdown
<HARD-GATE>
Before dispatching any evaluator, you MUST run:
  resolve-domains.sh --domains "{task domains}" --config orchestrate.json
Use the script's output to configure evaluators. Do NOT resolve domains manually.
</HARD-GATE>

<HARD-GATE>
After receiving evaluator scorecards, you MUST run:
  merge-scorecards.sh < scorecards.json
  check-thresholds.sh --scorecard merged.json --config orchestrate.json --criteria criteria.json
  check-convergence.sh --current verdict.json --history history.json --max-dispatches 60 --current-dispatches N
Act on the scripts' verdicts. Do NOT compute merges, thresholds, or convergence yourself.
</HARD-GATE>

<HARD-GATE>
After every evaluation cycle, you MUST run:
  append-eval-log.sh --bean-id {id} --iteration {N} --scorecard ... --verdict ...
Do NOT skip logging. Do NOT write the log entry manually.
</HARD-GATE>

<HARD-GATE>
If check-convergence.sh returns ESCALATE (exit 2), you MUST stop and ask the human.
Do NOT continue iterating. Do NOT lower thresholds. Do NOT rationalize.
</HARD-GATE>

<HARD-GATE>
If a domain has runtime configured, you MUST run:
  start-runtimes.sh --domains resolved.json --slot-index {N}
before dispatching evaluators for that domain.
After evaluation completes:
  stop-runtimes.sh --state runtime-state.json
Do NOT skip runtime. Do NOT let evaluators assess without runtime evidence.
</HARD-GATE>

<HARD-GATE>
On session restart, you MUST run:
  parse-eval-log.sh --bean-id {id}
  assess-git-state.sh --base-sha {sha}
Resume based on script output. Do NOT guess state from memory or context.
</HARD-GATE>
```

#### In `skills/evaluate/SKILL.md` (evaluator protocol):

```markdown
<HARD-GATE>
You are an evaluator. You MUST score every dimension on the 1-10 scale.
You MUST NOT skip any dimension. You MUST NOT give a dimension a passing
score without evidence. "Looks fine" is not evidence.
</HARD-GATE>

<HARD-GATE>
If runtime is configured for your domain, you MUST launch the application
and interact with it before scoring. Screenshots, clicks, API calls —
actual runtime evidence. Code review alone is NOT sufficient for any
dimension when runtime is available.
</HARD-GATE>
```

### What agents do vs what scripts do

| Operation | Who | Why |
|---|---|---|
| Score dimensions 1-10 | Agent (evaluator) | Requires judgment |
| Write improvement guidance | Agent (evaluator) | Requires judgment |
| Merge scorecards | Script | Arithmetic — `min()` |
| Check thresholds | Script | Comparison — `score >= threshold` |
| Check convergence | Script | State machine — consecutive passes |
| Parse evaluation log | Script | Structured text parsing |
| Append evaluation log | Script | Consistent formatting |
| Resolve domain config | Script | JSON lookup |
| Start/stop runtimes | Script | Process management |
| Assess git state | Script | Git commands + state classification |
| Decide what to implement | Agent (implementer) | Requires judgment |
| Decide what feedback to give | Agent (orchestrator) | Requires judgment |
| Format feedback for implementer | Agent (orchestrator) | Requires judgment |
| Interact with running app | Agent (evaluator) | Requires judgment |
| Write calibration anchors | Human + agent | Requires taste |
| Write antipatterns | Human + agent | Requires experience |

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
| `test-driven-development` | **Fork as-is.** Implementers follow TDD. |
| `verification-before-completion` | **Fork as-is.** Evidence before claims. |
| `systematic-debugging` | **Fork as-is.** Used when implementer is stuck. |
| `using-git-worktrees` | **Fork as-is.** Feature branch isolation. |
| `finishing-a-development-branch` | **Fork as-is.** Branch completion after develop. |
| `receiving-code-review` | **Drop.** Not part of the evaluator loop. |
| `writing-skills` | **Drop.** Not essential for fiddle's runtime. |
| `using-superpowers` | **Drop.** Fiddle has its own skill discovery via orchestrate. |

**Post-migration:** Delete `skills/patch-superpowers/` — no longer needed. Periodically review superpowers upstream for ideas to import (as we did with this design), but no runtime dependency.

---

## Changes Required

### New Files in Fiddle

**Scripts** (`scripts/`):

| File | Purpose |
|---|---|
| `scripts/merge-scorecards.sh` | Merge multiple scorecards — minimum per dimension |
| `scripts/check-thresholds.sh` | Compare merged scorecard against threshold config |
| `scripts/check-convergence.sh` | Determine if evaluation has converged |
| `scripts/parse-eval-log.sh` | Extract evaluation state from bean body for restart |
| `scripts/append-eval-log.sh` | Append iteration entry to bean's Evaluation Log |
| `scripts/resolve-domains.sh` | Resolve task's domain list to full evaluator config |
| `scripts/start-runtimes.sh` | Start runtime processes in dependency order |
| `scripts/stop-runtimes.sh` | Stop runtime processes |
| `scripts/assess-git-state.sh` | Classify git state as CLEAN/DIRTY/CORRUPTED |

**Skills** (`skills/`):

Skills are split into **foundational** (small, self-contained, read by agents playing a specific role) and **orchestrating** (tie foundational skills together, control the flow). This follows the superpowers pattern: foundational skills like TDD are standalone discipline primitives; orchestrating skills like subagent-driven-development reference them but don't inline them.

Agents ignore large skills. Keeping foundational skills small (~100-200 lines) ensures the agent playing that role reads and follows the whole thing. Orchestrating skills are larger but focus on flow control, not role-specific details — they dispatch to agents that load the foundational skills.

**Foundational — evaluator role** (read by evaluator team members):

| File | Purpose | Loaded by |
|---|---|---|
| `skills/evaluate/SKILL.md` | Evaluator protocol: how to score dimensions 1-10, evidence requirements, scorecard JSON format, distrust rules, antipattern checking. Small and focused — the evaluator's "how to do your job" doc. | Evaluator team member |
| `skills/evaluate/evaluator-frontend.md` | Frontend dimensions with full 1-10 scales + generic calibration anchors | Evaluator for frontend domain |
| `skills/evaluate/evaluator-backend.md` | Backend dimensions with full 1-10 scales + generic calibration anchors | Evaluator for backend domain |
| `skills/evaluate/evaluator-general.md` | General dimensions with full 1-10 scales | Evaluator fallback |

**Foundational — runtime evidence role** (read by runtime agents):

| File | Purpose | Loaded by |
|---|---|---|
| `skills/runtime-evidence/SKILL.md` | Runtime evidence protocol: how to interact with a running app, what evidence to capture, evidence format. Guidance for evaluators doing runtime verification. | Evaluator team member (loaded as context alongside domain template) |

**Foundational — implementer role** (read by implementer subagents):

| File | Purpose | Loaded by |
|---|---|---|
| `skills/develop/implementer-prompt.md` | Implementer dispatch template: task context, evaluation block, antipatterns, prior scorecard, self-review, report format. | Implementer subagent |

**Foundational — holistic reviewer role** (read by holistic reviewer team members):

| File | Purpose | Loaded by |
|---|---|---|
| `skills/develop/holistic-review.md` | Holistic review protocol: holistic dimensions, spec coverage matrix, remediation task generation, cross-domain integration checks. | Holistic reviewer team member |

**Orchestrating** (read by the orchestrator / develop lead):

| File | Purpose | References |
|---|---|---|
| `skills/develop/SKILL.md` | The implement → evaluate → converge loop. Dispatches implementers, evaluators, holistic reviewers. Runs scripts. Handles attended mode, restart, dispatch budget. Does NOT contain role-specific instructions — references foundational skills. | evaluate, runtime-evidence, implementer-prompt, holistic-review, all scripts |

**Foundational — forked from superpowers** (unchanged discipline primitives):

| File | Purpose |
|---|---|
| `skills/tdd/SKILL.md` | Test-driven development — implementers follow TDD |
| `skills/verify/SKILL.md` | Verification before completion — evidence before claims |
| `skills/debug/SKILL.md` | Systematic debugging — used when implementer is stuck |
| `skills/worktrees/SKILL.md` | Git worktree management — feature branch isolation |
| `skills/finish-branch/SKILL.md` | Branch completion options — after develop finishes |

Not forked (not essential for fiddle): `write-skill`, `receive-review`, `using-superpowers`, `dispatching-parallel-agents`.

**Orchestrating — forked and modified from superpowers:**

| File | Purpose | Changes from superpowers |
|---|---|---|
| `skills/brainstorm/SKILL.md` | Design exploration + spec writing | Add calibration anchor extraction from specs |
| `skills/write-plan/SKILL.md` | Implementation plan writing | Add Evaluation blocks per task (domains, criteria, thresholds) |

### Modified Files in Fiddle

| File | Change |
|---|---|
| `skills/develop/SKILL.md` | Rewrite: single execution mode with evaluator loop. Drop swarm/sequential/subagent mode split. Add attended mode gate. Convergence-based iteration. |
| `skills/deliver/SKILL.md` | Evolve step enriched to update calibration files + antipatterns. |
| `orchestrate.json` | New `evaluators` section. |

### Deleted Files

| File | Reason |
|---|---|
| `skills/patch-superpowers/` | No longer needed — no superpowers dependency to patch. |
| `skills/develop-swarm/` | Dropped. The new evaluator loop makes parallel worktree-per-bean execution impractical — evaluation with runtime verification dominates execution time, and parallelizing it requires duplicate runtime resources per worktree. Sequential execution with deep evaluation per task is the right tradeoff. |
| `scripts/rebase-worker.sh` | No longer needed — swarm infrastructure. |
| `scripts/merge-to-integration.sh` | No longer needed — swarm infrastructure. |
| `scripts/post-rebase-verify.sh` | No longer needed — swarm infrastructure. |
| `scripts/detect-reviewers.sh` | No longer needed — replaced by domain evaluator selection. |
| `scripts/reset-slot.sh` | No longer needed — swarm infrastructure. |

### Unchanged

- Implementer prompt template (receives scorecard on re-dispatch, otherwise same)
- Beans integration
- Hooks infrastructure
- Provider dispatch mechanism
- discover/define/deliver phase skills (except deliver evolve enrichment)

### Execution Model Simplification

The current develop phase has three execution modes (subagent-driven, sequential, swarm). This design collapses to **one mode**: sequential task execution with the evaluator loop. The orchestrator processes tasks one at a time — each task goes through the full implement → evaluate → converge cycle before the next task starts.

**Rationale:** The evaluator loop with runtime verification and convergence-based iteration is the expensive part of each task. Parallelizing implementation (the cheap part) while evaluation remains sequential yields negligible speedup. One well-executed mode is simpler, more reliable, and easier to reason about than three modes with varying quality levels.

**Worktree isolation is preserved** — the entire feature branch still runs in an isolated worktree (via `using-git-worktrees`). What's dropped is worktree-per-bean parallelism within a single feature.

---

## orchestrate.json — Evaluator Configuration

```json
{
  "evaluators": {
    "attended": true,
    "max_dispatches_per_task": 60,
    "domains": {
      "frontend": {
        "template": "evaluator-frontend",
        "providers": ["claude"],
        "runtime": ["flock /tmp/eval-flutter.lock flutter run -d chrome --web-port=8080"],
        "runtime_agent": "flutter-expert",
        "stack_agents": ["flutter-expert", "dart-expert"],
        "ready_check": { "type": "http", "url": "http://localhost:8080", "timeout_ms": 60000 },
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
          "domain_spec_fidelity": 8
        }
      },
      "backend": {
        "template": "evaluator-backend",
        "providers": ["claude", "codex"],
        "runtime": [
          "PORT=8080 go run ./cmd/server",
          "PORT=8081 go run ./cmd/server"
        ],
        "runtime_agent": "rest-expert",
        "stack_agents": ["go-expert", "postgres-expert"],
        "ready_check": { "type": "http", "url": "http://localhost:8080/healthz", "timeout_ms": 15000 },
        "calibration": "docs/evaluator-calibration-backend.md",
        "antipatterns": "docs/antipatterns-backend.md"
      }
    },
    "holistic": {
      "frequency": "every_3_tasks",
      "providers": ["claude", "codex"],
      "max_iterations": 3,
      "runtime": ["flock /tmp/eval-flutter.lock flutter run -d chrome --web-port=8080"],
      "runtime_agent": "flutter-expert",
      "design_reference": "docs/DESIGN_SYSTEM.md",
      "dimensions": {
        "integration": { "threshold": 7 },
        "coherence": { "threshold": 7 },
        "holistic_spec_fidelity": { "threshold": 8 },
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
  → Initial calibration anchors (extracted from spec, per domain)

PLAN (write-plan)
  → Tasks with Evaluation blocks:
      Domains: [frontend, backend]    ← single or multiple
      Task criteria:
        frontend:
          - Districts render as soft-edged circles
          - Zone radius grows with unlock count
        backend:
          - GET /api/districts returns correct schema
      Threshold: 7/10 per dimension, all criteria must pass
  → Spec requirements list (feeds holistic coverage matrix)

DEVELOP (per task, sequential)
  ┌──────────────────────────────────────────────────────────────┐
  │ 0. Record BASE_SHA, mark bean in-progress                    │
  │                                                              │
  │ 1. Dispatch implementer (subagent, fresh per iteration)      │
  │    - Task text + evaluation block + antipatterns              │
  │    - Prior scorecard (all domains) if iteration 2+           │
  │                                                              │
  │ 2. Resolve domains from Evaluation block                     │
  │    - Look up each domain's config in orchestrate.json        │
  │    - Determine runtime ordering (backends before frontends)  │
  │                                                              │
  │ 3. Dispatch evaluator(s) per domain (fresh team member(s))   │
  │    - Each domain: protocol + template + config + runtime     │
  │    - Multi-provider per domain: parallel or coordinated      │
  │                                                              │
  │ 4. Merge scorecards                                          │
  │    - Across providers: minimum per dimension                 │
  │    - Across domains: union (each domain scored independently)│
  │    - Append scorecard to bean's Evaluation Log               │
  │                                                              │
  │ 5. Attended gate (if attended: show scorecard per domain,    │
  │    highlight cross-domain and cross-provider disagreements,  │
  │    allow corrections → calibration anchors)                  │
  │                                                              │
  │ 6. Convergence check (all domains must pass independently)   │
  │    CONVERGED → mark bean completed → next task               │
  │    FAIL → fresh implementer with per-domain guidance → step 1│
  │    MAX REACHED → escalate to human                           │
  └──────────────────────────────────────────────────────────────┘

HOLISTIC REVIEW (every N tasks + after all tasks)
  ┌──────────────────────────────────────────────────────────────┐
  │ Fresh team member(s), multi-provider                         │
  │ - Start ALL domain runtimes (backends first, then frontends) │
  │ - Full system walkthrough: end-to-end across domains         │
  │ - Cross-domain integration check (frontend ↔ backend)        │
  │ - Spec coverage matrix (all requirements, all domains)       │
  │ - Holistic dimensions scored                                 │
  │ - PASS → continue                                            │
  │ - FAIL → remediation tasks (with domain-specific Evaluation  │
  │          blocks) → per-task loop → re-review                 │
  │ - Max 3 holistic iterations → escalate                       │
  └──────────────────────────────────────────────────────────────┘

FINISH BRANCH
  → finish-branch skill (forked from superpowers)

DELIVER
  → Drift analysis, doc updates (existing)

EVOLVE (post-delivery, human)
  → Review scorecards per domain, coverage matrix, iteration counts
  → Update calibration anchors per domain (where evaluator was wrong)
  → Append new antipatterns per domain (real failures found)
  → Adjust thresholds per domain (if consistently too strict/lenient)
  → These feed forward into the next run

SESSION RESTART
  → Read beans, find in-progress task
  → Read Evaluation Log from bean (BASE_SHA, iteration history)
  → Assess git state (clean/dirty/corrupted)
  → Resume from appropriate iteration with full scorecard history
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

---

## Implementation Milestones

The full system is implemented in milestones. Each milestone produces a working, testable system. Later milestones layer on top of earlier ones.

### Milestone 1: Core Loop — Single Evaluator, Single Domain

Prove the implement → evaluate → converge loop works end-to-end with the simplest configuration.

**Delivers:**
- Fork discipline primitives from superpowers (TDD, verification, debugging, worktrees, finish-branch)
- Fork and modify brainstorm skill (add calibration anchor extraction)
- Fork and modify write-plan skill (add Evaluation blocks)
- Foundational: `skills/evaluate/SKILL.md` — evaluator protocol (how to score, evidence, scorecard format)
- Foundational: `skills/evaluate/evaluator-general.md` — general domain template with full 1-10 scales
- Foundational: `skills/develop/implementer-prompt.md` — implementer dispatch template
- Orchestrating: `skills/develop/SKILL.md` — implement → evaluate → converge loop (single domain, single provider)
- Core scripts: `check-thresholds.sh`, `check-convergence.sh`, `merge-scorecards.sh`, `append-eval-log.sh`, `parse-eval-log.sh`, `resolve-domains.sh`, `assess-git-state.sh`
- Scorecard JSON schema enforced
- `orchestrate.json` evaluator config (single domain, single provider)
- Session restart/recovery
- Circuit breaker (`max_dispatches_per_task`)
- Delete `patch-superpowers/`, `develop-swarm/`, swarm scripts

**Does NOT include:** runtime verification, multi-provider, multi-domain, holistic review, calibration files, antipatterns.

**Test:** Run an attended evaluation cycle on a real task in `~/wrk/next` or `~/wrk/crops`. Verify: evaluator scores dimensions, thresholds are enforced by script, convergence works, restart recovers state, circuit breaker fires.

### Milestone 2: Runtime Verification

Add runtime evaluation — evaluators launch and interact with the running app.

**Delivers:**
- Foundational: `skills/runtime-evidence/SKILL.md` — runtime evidence protocol
- Foundational: `skills/evaluate/evaluator-frontend.md` — Flutter frontend domain template with full 1-10 scales
- Foundational: `skills/evaluate/evaluator-backend.md` — Go API backend domain template with full 1-10 scales
- `start-runtimes.sh`, `stop-runtimes.sh` with ready check contract
- Harness failure vs app failure distinction (exit codes)
- Example project-specific evaluator configs documented (Flutter/marionette, Go/go-dev-mcp, Wails/Svelte) — applied to target project repos, not committed to fiddle
- runtime_agent and stack_agents defined as protocol elements in evaluate skill

**Test:** Run an attended evaluation on a Flutter frontend task in `~/wrk/next`. Verify: evaluator launches app, takes screenshots via Playwright MCP, scores visual quality based on actual rendered output, catches the kind of failures the City Visualization Redesign exhibited.

### Milestone 3: Multi-Domain Evaluation

Tasks that span frontend + backend get evaluated by both domain evaluators.

**Delivers:**
- Multi-domain task handling in develop skill (domain resolution, runtime ordering)
- Domain-local spec fidelity (separate from holistic)
- `resolve-domains.sh` updated for multi-domain
- Cross-domain merge semantics
- Plan Evaluation blocks with multiple domains

**Test:** Run a full-stack task (API endpoint + UI integration) through the evaluator loop. Verify: both domains evaluated independently, both must pass, feedback identifies which domain failed.

### Milestone 4: Holistic Review

Cross-task quality check at configurable checkpoints.

**Delivers:**
- Foundational: `skills/develop/holistic-review.md` — holistic review protocol
- Holistic dimensions with full 1-10 scales (integration, coherence, holistic spec fidelity, polish, runtime health)
- Spec coverage matrix (every requirement → Full/Weak/Missing + evidence)
- Remediation task generation from coverage gaps
- Holistic review frequency configuration

**Test:** Run a 5+ task plan. Verify: holistic reviewer launches app, produces coverage matrix, catches cross-task integration issues, generates remediation tasks for gaps.

### Milestone 5: Multi-Provider Evaluation

Multiple LLM providers evaluate each task for diversity of judgment.

**Delivers:**
- Per-domain provider selection in `orchestrate.json`
- Multi-provider dispatch (parallel or flock-coordinated)
- Scorecard merging across providers (minimum per dimension)
- Provider disagreement surfacing
- Updated circuit breaker accounting for dispatch multiplier

**Test:** Run evaluation with Claude + Codex on a backend task. Verify: both produce scorecards, merge uses minimum, disagreements highlighted in attended mode.

### Milestone 6: Calibration and Evolve

The compound learning loop.

**Delivers:**
- Project-specific calibration files
- Calibration anchor extraction from specs (in brainstorm skill)
- Attended mode with human correction → calibration encoding
- Evolve step enriched for calibration + antipattern updates
- Antipattern accumulation files loaded by implementer and evaluator
- `attended: true/false` toggle in orchestrate.json

**Test:** Run 3 attended cycles. Verify: human corrections are encoded as calibration anchors, antipatterns accumulate, evaluator judgment improves measurably across runs.
