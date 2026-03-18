---
# fiddle-ndb3
title: Add grill skill to discover and define phases
status: completed
type: feature
priority: normal
created_at: 2026-03-18T20:18:25Z
updated_at: 2026-03-18T20:20:31Z
---

Create a fiddle:grill skill that systematically stress-tests shared understanding by walking the decision tree. Integrated at two points: end of DISCOVER (grill scope/assumptions before DEFINE) and within DEFINE (grill chosen design before writing-plans). Inspired by mattpocock/grill-me but adapted with phase context, codebase self-serve, and clear handoff signals. Skippable via --skip-grill flag.

## Tasks

- [x] Create `skills/grill/SKILL.md` — the skill itself
- [x] Wire into orchestrate DISCOVER phase (after docs-discover, before transition to DEFINE)
- [x] Wire into orchestrate DEFINE phase (after brainstorming, before writing-plans)
- [x] Add `--skip-grill` flag to orchestrate
- [x] Update brainstorming skill to support `--skip-grill` passthrough (if needed) — not needed, grill is a separate step in orchestrate, not inside brainstorming

## Summary of Changes

Created `skills/grill/SKILL.md` — a decision-tree stress-testing skill adapted from mattpocock/grill-me. Key adaptations for fiddle:

- **Phase-aware**: `--phase discover` grills on scope/assumptions/constraints; `--phase define` grills on design decisions, edge cases, panel dissent, failure modes. Also works standalone.
- **Codebase self-serve**: aggressively explores the codebase to answer its own questions rather than asking the user things it could figure out.
- **Clear handoff signals**: each phase has explicit completion criteria (no open branches in scope for discover, no unresolved decision branches for define).
- **One question at a time**: prevents overwhelming the user with stacked questions.

Wired into orchestrate at two points:
- DISCOVER Step 4 (after Socratic Dialogue, before transition to DEFINE)
- DEFINE Step 2 (after Brainstorming, before Implementation Planning)

Both skippable via `--skip-grill` flag on orchestrate.
