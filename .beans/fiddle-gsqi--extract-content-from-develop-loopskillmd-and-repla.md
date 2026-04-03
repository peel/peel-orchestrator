---
# fiddle-gsqi
title: Extract content from develop-loop/SKILL.md and replace with references
status: completed
type: task
priority: normal
created_at: 2026-04-03T19:03:04Z
updated_at: 2026-04-03T19:11:20Z
parent: fiddle-rwyx
---

Replace 4 verbose sections in develop-loop/SKILL.md with one-line references to the new reference files. Target: under 250 lines.

## Files
- Modify: `skills/develop/develop-loop/SKILL.md`

- [x] Replace step 1a with restart-recovery reference
- [ ] Replace context loading order in step 1f with reference
- [ ] Replace steps 1g-1h with scorecard-merge reference
- [ ] Replace step 1i with attended-gate reference
- [ ] Verify line count under 250
- [ ] Commit

```eval
domains: [general]
criteria:
  general:
    - id: loop-line-count
      check: "develop-loop/SKILL.md is under 250 lines"
    - id: loop-flow-intact
      check: "Step sequence 1a→1b→1c→1d→1e→1f→1g-1h→1i→1j→1k→1l→1m is still navigable"
    - id: loop-hard-gates-preserved
      check: "HARD-GATEs for domain resolution (1c), runtime start (1f), threshold checks (1j), convergence (1k), and logging (1l) remain inline"
thresholds: {}
```
