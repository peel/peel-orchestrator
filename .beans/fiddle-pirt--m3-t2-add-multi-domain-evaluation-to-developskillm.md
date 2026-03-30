---
# fiddle-pirt
title: 'M3-T2: Add multi-domain evaluation to develop/SKILL.md'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:22:17Z
updated_at: 2026-03-30T07:54:09Z
parent: fiddle-3ehs
blocked_by:
    - fiddle-mx0s
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m3.md Task 2

Add domain resolution step, per-domain evaluator dispatch, cross-domain merge to develop skill.

Files:
- Modify: skills/develop/SKILL.md

Steps:
1. Add domain resolution HARD-GATE: must run resolve-domains.sh before evaluator dispatch
2. Update evaluator dispatch: for each resolved domain, start runtime (if configured, respecting runtime_order), dispatch evaluator with domain template + config, collect scorecard per domain
3. Update merge step: union scorecards across domains, each domain independent, no shared dimensions, on failure identify which domain(s) failed
4. Add runtime_order handling: parse from task eval block, start runtimes in specified order, default to listed order
5. Commit

See parent epic Contracts for Cross-Domain Merge Rule.


## Evaluation Log
BASE_SHA: 233b73951b1ac0bccd8e58429c9eccffe6d7ebdd
total_dispatches: 3

### Iteration 1 (2026-03-30T07:52:34Z)
dispatches: 1
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "All features implemented correctly."

### Iteration 2 (2026-03-30T07:54:04Z)
dispatches: 2
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "Converged."

## Summary of Changes

Updated skills/develop/SKILL.md with multi-domain evaluation:
- Added step 1c: Resolve Domains HARD-GATE (resolve-domains.sh before any evaluator dispatch)
- Added step 1f: Per-Domain Evaluator Dispatch (iterate resolved domains, domain-specific templates)
- Added step 1g: Merge Cross-Domain Scorecards (union, independent thresholds per domain)
- Added runtime_order handling (parsed from eval block, used for runtime start sequencing)
- Renumbered steps 1a-1k with consistent cross-references
- Updated M1 Simplifications (struck through Single domain)
- Added Red Flag for resolve-domains.sh

Converged after 2 evaluator iterations (1 implementer dispatch).
