---
# fiddle-mx0s
title: 'M3-T1: Write resolve-domains.sh'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:22:17Z
updated_at: 2026-03-30T07:36:10Z
parent: fiddle-3ehs
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m3.md Task 1

Parse a task's domain list and resolve each to full evaluator config from orchestrate.json.

Files:
- Create: scripts/resolve-domains.sh
- Create: scripts/test-resolve-domains.sh

Steps:
1. Write test: single domain resolves to config, multiple domains both resolved, unknown domain falls back to general with resolved_via: "fallback", invalid input exits 1
2. Run test — verify it fails
3. Write resolve-domains.sh: accept --domains "frontend,backend" --config <orchestrate.json>, look up each in evaluators.domains, fallback to general defaults, output JSON array
4. Run test — verify it passes
5. Commit

See parent epic Contracts for Resolved Domains Output format.


## Evaluation Log
BASE_SHA: adb29d8611a94d2c8e275b11988f3aaa5d9f7597
total_dispatches: 10

### Iteration 1 (2026-03-30T07:28:45Z)
dispatches: 1
**general:**
- correctness: 8/10
- domain_spec_fidelity: 8/10
- code_quality: 8/10
**Guidance:** "Implementation is solid and passes all criteria. Minor improvements: trim whitespace around domain names, consider deduplicating domain input, add --help flag."

### Iteration 2 (2026-03-30T07:30:43Z)
dispatches: 2
**general:**
- correctness: 7/10
- domain_spec_fidelity: 7/10 (FAIL, threshold 8)
- code_quality: 8/10
**Guidance:** "Domain spec fidelity below threshold (7 vs 8). Fix: (1) trim whitespace around domain names, (2) deduplicate domain list, (3) add --help flag."

### Iteration 3 (2026-03-30T07:34:35Z)
dispatches: 3
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "All issues resolved. Implementation is solid."

### Iteration 4 (2026-03-30T07:36:04Z)
dispatches: 4
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "Converged. Implementation solid and stable."

## Summary of Changes

Implemented resolve-domains.sh with:
- Comma-separated domain parsing with whitespace trimming and deduplication
- Config lookup in orchestrate.json evaluators.domains
- Fallback to evaluator-general for unknown domains (resolved_via: fallback)
- --help/-h flag, exit 2 for invalid input
- 64-assertion test suite covering all paths

Converged after 4 evaluator iterations (2 implementer dispatches).
