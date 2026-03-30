---
# fiddle-3ehs
title: 'M3: Multi-Domain + Holistic Review'
status: completed
type: epic
priority: normal
created_at: 2026-03-29T19:17:55Z
updated_at: 2026-03-30T08:09:48Z
blocked_by:
    - fiddle-seov
---

Tasks spanning multiple domains (frontend + backend) get evaluated per-domain. Holistic review catches cross-task integration issues after all tasks complete. resolve-domains.sh parses Evaluation blocks and looks up per-domain config. Evaluators run per-domain, scorecards merged (union, each domain independent). Holistic reviewer runs after all tasks with full app + spec coverage matrix.

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m3.md
Design: docs/superpowers/specs/2026-03-29-calibrated-evaluator-system-design.md
Depends on: M2 (fiddle-seov)

## Contracts

### Resolved Domains Output (resolve-domains.sh)
```json
[
  {"domain": "frontend", "template": "evaluator-frontend", "runtime": ["flutter run ..."], "ready_check": {...}, "resolved_via": "config"},
  {"domain": "general", "template": "evaluator-general", "resolved_via": "fallback"}
]
```

### resolve-domains.sh Interface
Input: --domains "frontend,backend" --config <orchestrate.json>
Output: JSON array of resolved domain configs on stdout
Exit: 0 = all resolved (including fallbacks), 1 = invalid input

### Cross-Domain Merge Rule
Union across domains — each domain scored independently. domain_spec_fidelity in frontend ≠ domain_spec_fidelity in backend. Each domain must independently meet its own thresholds.

### Holistic Dimensions
Integration (threshold 7), Coherence (threshold 7), Holistic Spec Fidelity (threshold 8), Polish (threshold 6), Runtime Health (threshold 9)

### Spec Coverage Matrix Format
Every spec requirement → Full/Weak/Missing + evidence. Remediation beans generated for Missing entries.

## Deliverables
- [x] Script: resolve-domains
- [x] Multi-domain evaluation in develop skill
- [x] Domain spec fidelity separation
- [x] Holistic review skill with full 1-10 scales
- [x] Spec coverage matrix + remediation beans
- [x] Integration test

## Summary of Changes

All 6 task beans completed:
- T1: resolve-domains.sh (64 tests) — parses domain list, resolves from orchestrate.json, fallback to general
- T2: Multi-domain evaluation in develop/SKILL.md — domain resolution HARD-GATE, per-domain dispatch, cross-domain merge
- T3: Verified domain_spec_fidelity naming consistency across all evaluator templates
- T4: holistic-review.md (349 lines) — 5 holistic dimensions with 1-10 scales, spec coverage matrix, remediation beans
- T5: Wired holistic review into develop/SKILL.md — Step 2 with remediation loop, manual trigger, convergence
- T6: Integration test (117 assertions) — resolve-domains, scorecard merge, holistic review, SKILL.md structure

Total: 301 tests passing across 9 test scripts.
Merged to main via fast-forward.
