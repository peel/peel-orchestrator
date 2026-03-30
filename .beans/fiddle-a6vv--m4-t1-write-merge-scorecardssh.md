---
# fiddle-a6vv
title: 'M4-T1: Write merge-scorecards.sh'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:22:58Z
updated_at: 2026-03-30T08:37:40Z
parent: fiddle-63d9
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m4.md Task 1

Merge multiple provider scorecards into one. Minimum score per dimension wins.

Files:
- Create: scripts/merge-scorecards.sh
- Create: scripts/test-merge-scorecards.sh

Steps:
1. Write test: two providers same domain (min scores, disagreements detected), single provider (passthrough), multi-domain (each merged independently), malformed input (exit 2)
2. Run test — verify it fails
3. Write merge-scorecards.sh: accept JSON array on stdin, group by domain, min score per dimension, record provider_scores, detect disagreements (spread >= 3) on stderr, merge criteria (any fail = fail), output merged scorecard
4. Run test — verify it passes
5. Commit

See parent epic Contracts for Merged Scorecard Format and Disagreement Format.


## Evaluation Log
BASE_SHA: d1621e91ea71f78cf35620bf5309b8a2f37578c7
total_dispatches: 3

### Iteration 1 (2026-03-30T08:34:10Z)
dispatches: 1
**general:**
- correctness: 7/10
- domain_spec_fidelity: 8/10
- code_quality: 7/10

### Iteration 2 (2026-03-30T08:37:35Z)
dispatches: 2
**general:**
- correctness: 7/10
- domain_spec_fidelity: 8/10
- code_quality: 7/10
