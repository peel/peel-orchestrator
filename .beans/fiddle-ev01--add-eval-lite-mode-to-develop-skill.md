---
# fiddle-ev01
title: 'Add --eval-lite mode to fiddle:develop for lightweight evaluation'
status: todo
type: task
priority: normal
created_at: 2026-03-31T00:00:00Z
updated_at: 2026-03-31T00:00:00Z
---

## Problem

The full evaluator loop (domain resolution → runtime start → multi-provider dispatch → scorecard merge → convergence → runtime stop) is designed for code implementation tasks where runtime verification and multi-pass convergence add real value. But many tasks don't need this:

- **Configuration files** (orchestrate.json, CI configs, Nix flakes)
- **Documentation** (calibration anchors, antipattern files, design specs)
- **Infrastructure-as-code** (Dockerfiles, deployment manifests)
- **Bootstrapping** (setting up the evaluator system itself — circular dependency)

For these tasks, the full loop is pure overhead: no runtime to start, no app to interact with, no convergence needed. But skipping evaluation entirely (`--no-eval`) loses the value of a second pair of eyes checking the eval criteria.

## Solution: `--eval-lite` flag

A simplified evaluation mode for `fiddle:develop` that keeps the evaluator's judgment without the heavyweight machinery.

### What it does

1. Dispatch implementer (same as full mode)
2. Dispatch a **single evaluator pass** — one provider (claude), code-only review (no runtime), checks eval block criteria
3. **No convergence** — one pass: all criteria pass and all dimensions >= threshold → done. Any failure → one retry with guidance. Still fails → escalate to human
4. **No runtime lifecycle** — skip `start-runtimes.sh` / `stop-runtimes.sh` entirely
5. **No multi-provider** — skip `merge-scorecards.sh`, single claude evaluator only
6. **No domain resolution** — always use `evaluator-general` template regardless of eval block domains
7. **Calibration and antipatterns still loaded** — if configured in orchestrate.json, they're included in evaluator context. Quality standards still apply
8. **Attended gate still applies** — if `evaluators.attended: true`, scorecard shown to human before acting. Human corrections still encode calibration anchors

### What it skips

| Full mode | Eval-lite |
|-----------|-----------|
| `resolve-domains.sh` | Skip — always general domain |
| `start-runtimes.sh` / `stop-runtimes.sh` | Skip — no runtime |
| Multi-provider dispatch | Skip — claude only |
| `merge-scorecards.sh` | Skip — single scorecard |
| `check-convergence.sh` (two-pass) | Skip — single pass with one retry |
| Holistic review (Step 2) | Skip — no cross-domain integration check |
| Domain-specific templates | Skip — always evaluator-general |

### What it keeps

- Implementer dispatch with full context (task text, eval block, antipatterns, prior guidance)
- Single evaluator pass checking all eval block criteria
- Dimension scoring against evaluator-general thresholds (correctness: 7, domain_spec_fidelity: 8, code_quality: 6)
- Calibration anchor loading (if file exists)
- Antipattern loading (from general domain config or union of all configured domains)
- Attended gate with human correction → calibration encoding
- `append-eval-log.sh` logging (iteration history preserved)
- Budget enforcement: max 2 dispatches per task (1 implementer + 1 evaluator, or 2 if retry needed)
- Bean status tracking (in-progress → completed / needs-attention)

### Dispatch budget

Eval-lite uses a fixed budget of **4 dispatches per task**: implementer + evaluator + optional retry (implementer + evaluator). No configuration needed. If the retry fails, escalate — the task needs human attention, not more iterations.

### CLI usage

```bash
# Full evaluator loop (default)
fiddle:develop --epic <id>

# Lightweight evaluation
fiddle:develop --eval-lite --plan docs/plans/2026-03-31-foo.md

# No evaluation at all (just run implementers sequentially)
fiddle:develop --no-eval --plan docs/plans/2026-03-31-foo.md
```

`--eval-lite` and `--no-eval` are mutually exclusive. Both can work with `--epic` (beans) or `--plan` (plan file).

### When to use which

| Mode | Use when |
|------|----------|
| Full (`--epic`) | Code implementation with runtime — frontend, backend, multi-domain |
| `--eval-lite` | Config, docs, infra, bootstrapping — no runtime but still want quality check |
| `--no-eval` | Trivial mechanical tasks where evaluation adds no value (e.g., bulk rename) |

## Acceptance Criteria

- [ ] `fiddle:develop` accepts `--eval-lite` flag
- [ ] In eval-lite mode: implementer dispatched, single evaluator dispatched with evaluator-general template
- [ ] In eval-lite mode: criteria pass → bean completed. Criteria fail → one retry with guidance. Retry fails → escalate
- [ ] In eval-lite mode: no runtime start/stop, no domain resolution, no multi-provider, no convergence, no holistic review
- [ ] In eval-lite mode: calibration and antipatterns loaded if configured
- [ ] In eval-lite mode: attended gate works (human sees scorecard, can correct)
- [ ] In eval-lite mode: eval log entries written via `append-eval-log.sh`
- [ ] `--eval-lite` and `--no-eval` are mutually exclusive (error if both passed)
- [ ] `--no-eval` mode: implementer dispatched, no evaluator, bean completed on DONE status
