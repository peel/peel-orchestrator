---
# fiddle-ecms
title: Extract orchestrate phases into independent skills
status: completed
type: feature
priority: normal
created_at: 2026-03-18T20:28:50Z
updated_at: 2026-03-18T20:34:59Z
---

Refactor orchestrate so each phase (discover, define, develop, deliver) is its own invocable skill. Orchestrate becomes a thin sequencer. Enables standalone phase invocation like /fiddle:discover or /fiddle:develop --epic <id>.

## Tasks

- [x] Create `skills/discover/SKILL.md`
- [x] Create `skills/define/SKILL.md`
- [x] Create `skills/develop/SKILL.md`
- [x] Create `skills/deliver/SKILL.md`
- [x] Refactor `skills/orchestrate/SKILL.md` to thin sequencer
- [x] Verify cross-references and step numbering

## Summary of Changes

Extracted all four orchestrate phases into independent, standalone-invocable skills:

- `fiddle:discover` (79 lines) — docs-discover + external research + socratic dialogue + grill scope
- `fiddle:define` (76 lines) — brainstorming + grill design + writing-plans + epic capture
- `fiddle:develop` (156 lines) — execution choice + ralph spawn/loop + holistic review
- `fiddle:deliver` (89 lines) — drift analysis + docs-evolve + epic closure

Orchestrate (296 lines, down from 487) is now a thin sequencer: parse config, determine phase, invoke phase skills with passthrough args, manage transitions and cleanup.

Each phase reads `orchestrate.conf` for standalone defaults. When called from orchestrate, CLI arg overrides take precedence.

New flags added to orchestrate: `--skip-grill`, `--skip-panel`.
