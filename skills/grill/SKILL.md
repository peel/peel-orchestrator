---
name: fiddle:grill
description: Stress-test shared understanding by systematically walking the decision tree — resolving every branch before proceeding. Use at phase transitions (end of discover, middle of define) or standalone to pressure-test any plan or design.
argument-hint: [--phase discover|define] [--context file1 file2]
---

# Grill

Interview the user relentlessly about every aspect of their plan or design until reaching shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one.

If a question can be answered by exploring the codebase, explore the codebase instead of asking.

ARGUMENTS: {ARGS}

## Configuration

Parse from `{ARGS}`:

| Flag | Default | Description |
|---|---|---|
| `--phase <phase>` | none | Phase context: `discover` or `define`. Omit for standalone use. |
| `--context <files>` | none | Space-separated file paths to read for context |

If `--context` files are provided, read each with the Read tool.

## Phase Behavior

The core behavior is always the same: systematically walk the decision tree, resolve every branch, self-serve from the codebase. What changes per phase is **what you're grilling on** and **what signals completion**.

### `--phase discover`

**Grilling target:** Scope, assumptions, and constraints surfaced during docs-discover.

**Context to gather before starting:**
- Read curated docs in `docs/product/` and `docs/technical/` (whatever exists)
- Read recent beans (`beans list --json -s todo -s in-progress`) for project direction
- Read any context files passed via `--context`

**Lines of questioning:**
- Scope boundaries: "You said X is in scope — what about Y? Where's the line?"
- Assumptions: "This assumes Z exists / works / is stable. Have you verified that?"
- Unstated constraints: "What about time, team size, dependencies, compliance?"
- Codebase reality: explore the code to check whether stated assumptions hold. "You said the auth system is simple, but I see 3 middleware layers and a token refresh flow — does that change anything?"
- Prior art: "The codebase already has [pattern]. Should this follow or diverge?"

**Completion signal:** The user can articulate the scope with no open branches — every "what about X?" has a clear answer (either "in scope because..." or "out of scope because..."). There are no hand-waves left.

### `--phase define`

**Grilling target:** The chosen design approach, post-brainstorming.

**Context to gather before starting:**
- Read the design doc (most recent file in `docs/plans/`)
- If panel enrichment was run, the design doc should contain panel commentary — read it for dissent points and unresolved disagreements
- Read relevant source files that the design touches
- Read any context files passed via `--context`

**Lines of questioning:**
- Edge cases: "What happens when [input] is [unexpected value]? When [service] is down?"
- Integration points: "This touches [component]. How does it interact with [other component]?"
- Panel dissent: if the panel flagged disagreements, grill on those specifically. "The panel didn't reach consensus on X — what's your position and why?"
- Failure modes: "What's the rollback plan? What breaks if this is half-deployed?"
- Sequencing: "Step 3 depends on step 1's output. What if step 1 produces something different than expected?"
- Sizing: "You're estimating this as [N] beans. Walk me through why [specific bean] is one unit of work."

**Completion signal:** The design has no unresolved decision branches. Every integration point, failure mode, and dissent point has been addressed. The user can explain what they're building, why each decision was made, and what they're deliberately not handling.

### Standalone (no `--phase`)

Grill on whatever the user presents. Read relevant context from the codebase and any provided files. Apply the full decision-tree walk without phase-specific framing.

## Process

### 1. Gather context

Read the codebase and docs relevant to the topic. Build your own understanding before asking the user anything. The more you know independently, the sharper your questions.

### 2. Identify the decision tree

Map out the key decisions, assumptions, and dependencies in the plan or design. This is your internal agenda — you don't share it, but it guides the interrogation.

### 3. Walk the tree

For each branch:
1. Ask one question at a time. Be direct and specific — not "have you thought about error handling?" but "what happens to in-flight requests when the connection pool is exhausted?"
2. If the user's answer opens new branches, note them and return to them.
3. If a question can be answered by reading the codebase, do that yourself and present what you found: "I checked — the current rate limiter uses a sliding window with a 60s TTL. Your design assumes fixed windows. Intentional?"
4. When a branch is resolved (clear answer, explicit decision, or deliberate deferral), move to the next one.

### 4. Track resolved and open branches

Maintain a mental model of what's been resolved and what's still open. When you think you're close to done, summarize:

```
"Here's where I think we've landed:
- [Decision 1]: resolved — [summary]
- [Decision 2]: resolved — [summary]
- [Open item]: still needs [what]
```

Ask the user to confirm or correct.

### 5. Handoff

When all branches are resolved and the user confirms shared understanding:

- **`--phase discover`**: State "Scope is solid — ready for DEFINE." Stop. Control returns to the caller.
- **`--phase define`**: State "Design holds up — ready for implementation planning." Stop. Control returns to the caller.
- **Standalone**: Summarize the resolved decision tree and stop.

## Rules

- **One question at a time.** Never stack multiple questions in one message.
- **Self-serve aggressively.** Every question you answer from the codebase is a question the user doesn't have to answer. Explore files, check types, read tests, trace call paths.
- **Be direct, not adversarial.** The goal is shared understanding, not winning. If the user's answer is solid, say so and move on.
- **Track what's resolved.** Don't re-ask decided questions. Don't circle back unless new information invalidates a prior decision.
- **Respect deliberate deferrals.** "We'll handle that later" is a valid answer if the user acknowledges the branch exists. Note it and move on.
- **Don't grill on the obvious.** If the codebase makes something clear, state it as fact and move on. Reserve questions for genuine ambiguity.
- **Know when to stop.** This is not an endurance test. When branches are resolved, wrap up. Over-grilling wastes time and erodes trust.
