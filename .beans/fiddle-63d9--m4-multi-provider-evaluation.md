---
# fiddle-63d9
title: 'M4: Multi-Provider Evaluation'
status: completed
type: epic
priority: normal
created_at: 2026-03-29T19:17:56Z
updated_at: 2026-03-30T10:09:45Z
blocked_by:
    - fiddle-3ehs
---

Multiple LLM providers (Claude, Codex, Gemini) evaluate each task for diversity of judgment. Minimum score per dimension wins. Per-domain provider list in orchestrate.json. Claude dispatched via Agent, external providers via dispatch-provider.sh. merge-scorecards.sh combines results. Disagreements (spread 3+) surfaced.

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m4.md
Design: docs/superpowers/specs/2026-03-29-calibrated-evaluator-system-design.md
Depends on: M3 (fiddle-3ehs)

## Contracts

### merge-scorecards.sh Interface
Input: JSON array of canonical scorecards on stdin
Output: Merged scorecard JSON on stdout (min score per dimension), disagreements on stderr
Exit: 0 = merged, 2 = invalid input

### Merged Scorecard Format
Same as canonical scorecard but with provider_scores per dimension:
```json
{
  "domains": {
    "general": {
      "dimensions": {
        "correctness": {"score": 7, "threshold": 7, "provider_scores": {"claude": 8, "codex": 7}}
      }
    }
  }
}
```

### Disagreement Format (stderr)
```json
[{"domain": "general", "dimension": "correctness", "spread": 3, "scores": {"claude": 9, "codex": 6}}]
```
Disagreement = spread >= 3 between any two providers.

### Merge Rules
- Dimensions: min score across providers wins
- Criteria: any provider says fail → fail
- Coverage matrices (holistic): any provider marks Missing → Missing

### Provider Dispatch
- claude: dispatch via Agent tool (same process)
- External (codex, gemini): dispatch via hooks/dispatch-provider.sh
- All receive same context: evaluation protocol + domain template + calibration + diff + criteria
- External providers must output canonical scorecard JSON

### Dispatch Budget
Each provider dispatch = 1 toward budget. 2 providers × 2 domains = 4 dispatches per iteration.

## Deliverables
- [ ] Script: merge-scorecards
- [ ] Per-provider dispatch in develop skill
- [ ] Provider disagreement surfacing
- [ ] Multi-provider holistic review
- [ ] Integration test


## Summary of Changes

M4 adds multi-provider evaluation to the calibrated evaluator system:

- **merge-scorecards.sh**: Merges provider scorecards using conservative (min) scoring per dimension, records provider_scores, detects disagreements (spread >= 3)
- **Multi-provider dispatch**: SKILL.md updated with per-provider evaluator dispatch (claude via Agent, external via dispatch-provider.sh), merge HARD-GATEs, and dispatch budget tracking
- **Disagreement surfacing**: append-eval-log.sh accepts --disagreements parameter, renders disagreement details in eval log; attended gate documented for M5
- **Multi-provider holistic review**: Per-provider holistic dispatch, scorecard merge, coverage matrix merge (any Missing → Missing), remediation bean dedup
- **Integration test**: 80 assertions covering full multi-provider pipeline (merge, thresholds, convergence, disagreements, budget)

437 total tests passing (136 new from M4).
