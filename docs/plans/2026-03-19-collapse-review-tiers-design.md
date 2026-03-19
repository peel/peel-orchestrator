# Collapse Review Tiers — Design Spec

## Problem

The current develop phase uses a two-tier review pipeline per bean:
- Tier-1: parallel reviewers (baseline + domain experts) at `models.develop.lite` (sonnet)
- Tier-2: single confirmation pass at `models.develop.standard`, only cycle 1 when all tier-1 pass

The `baseline` reviewer runs the same generic checklist as tier-2 with no domain expertise appended. In practice it catches nothing that domain experts don't already flag. Tier-2 is a confirmation pass on code that N reviewers already blessed — redundant by design.

The two-tier structure adds latency (sequential tier-1 → tier-2), token cost (baseline runs on every bean), and complexity (conditional tier-2 logic, two model config keys) without measurable quality improvement.

## Design

### Reviewer Selection

**Current:** Lead always includes `baseline` alongside auto-selected domain experts. Tags bean with `reviewers:baseline+{expert1}+{expert2}`.

**New:** Lead auto-selects domain experts based on bean content. If zero domain experts match, use `baseline` as fallback. Tags bean with `reviewers:{expert1}+{expert2}` or `reviewers:baseline` (fallback case).

Cycle 2+ behavior unchanged: use only reviewers from the bean's `flagged-by:*` tag.

### Review Coordinator

**Current flow:** Build prompts → tier-1 parallel (lite model) → evaluate tier-1 → conditional tier-2 (standard model, cycle 1 only) → return verdict.

**New flow:**
1. **Build Reviewer Prompts** — for each reviewer, read `reviewer.md` as base. If domain expert, append agent definition under `## Domain Expertise`. If `baseline` (fallback), use reviewer.md as-is.
2. **Spawn Reviewers** — all reviewers in parallel, all at `models.develop`.
3. **Collect & Aggregate** — wait for all results. Classify: APPROVED / APPROVED WITH COMMENTS / ISSUES / empty=implicit APPROVED.
4. **Return Verdict** — same format. Replace tier references in verdict text: `"Tier-1 ({N} reviewers) and tier-2 all clean."` → `"{N} reviewer(s) all clean."`

### Reviewer Prompt

Add **Cross-Cutting Concerns** checklist section after Safety in `reviewer.md`:

- Backward compatibility: breaking changes to public APIs, CLI flags, config schema, or file formats?
- Data migrations: schema changes, state format changes, or data loss risks?
- Dependency changes: new dependencies added, versions bumped, or removals?
- Observability: logging, error messages, or monitoring affected?

This compensates for removing the always-on baseline reviewer. Every reviewer — domain expert or fallback — checks these regardless of specialization.

### Config Schema

**Current:**
```hcl
models {
  develop {
    standard = "sonnet"
    lite = "sonnet"
  }
}
```

**New:**
```hcl
models {
  develop = "sonnet"
}
```

Flatten to single key. `models.develop.lite` removed entirely. All develop-phase agents (implementers, reviewers, coordinator) use the same model.

All references to `models.develop.standard` become `models.develop`. All references to `models.develop.lite` are removed.

### SYSTEM.md

Update Ralph description from:
> "Dispatches implementer subagents (sonnet) in worktrees with tiered review (haiku then sonnet)."

To:
> "Dispatches implementer subagents in worktrees with single-pass domain-expert review (baseline fallback when no experts match)."

## Files Changed

Both variants means `develop-subs` + `develop-team`.

| File | Change |
|---|---|
| `skills/develop-subs/roles/review-coordinator.md` | Replace tier-1/tier-2 flow with single spawn-collect-aggregate flow |
| `skills/develop-team/roles/review-coordinator.md` | Same |
| `skills/develop-subs/roles/reviewer.md` | Add cross-cutting concerns checklist |
| `skills/develop-team/roles/reviewer.md` | Same |
| `skills/develop-subs/SKILL.md` | Update reviewer selection (domain experts, baseline fallback), remove `models.develop.lite` references, update model references |
| `skills/develop-team/SKILL.md` | Same |
| `skills/develop/SKILL.md` | Remove `models.develop.lite` from config docs, update model references |
| `skills/orchestrate/SKILL.md` | Update model defaults table (remove lite row, flatten develop) |
| `docs/technical/SYSTEM.md` | Fix stale review description |

No new files. No new mechanisms.
