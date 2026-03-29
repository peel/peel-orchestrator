---
# fiddle-mx0s
title: 'M3-T1: Write resolve-domains.sh'
status: todo
type: task
created_at: 2026-03-29T19:22:17Z
updated_at: 2026-03-29T19:22:17Z
parent: fiddle-3ehs
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m3.md Task 1
Parse task domain list, resolve to full config from orchestrate.json.
Unknown domains fall back to general with resolved_via: fallback.
Exit 0 = resolved, 1 = invalid input.
Files: scripts/resolve-domains.sh, scripts/test-resolve-domains.sh
