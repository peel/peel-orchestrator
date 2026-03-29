---
# fiddle-mz3o
title: 'M1-T1: Delete swarm infrastructure, move provider template'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:19:32Z
updated_at: 2026-03-29T19:31:54Z
parent: fiddle-yzzk
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m1.md Task 1

Delete develop-swarm/, patch-superpowers/, swarm scripts.
Copy provider-context.md to skills/develop/.
Update hooks/dispatch-provider.sh template path (line 16).

Files:
- Delete: skills/develop-swarm/, skills/patch-superpowers/
- Delete: scripts/rebase-worker.sh, merge-to-integration.sh, post-rebase-verify.sh, detect-reviewers.sh, reset-slot.sh
- Move: skills/develop-swarm/roles/provider-context.md → skills/develop/provider-context.md
- Modify: hooks/dispatch-provider.sh:16

Steps:
1. Copy provider-context.md to new location
2. Update dispatch-provider.sh template path
3. Delete swarm dirs and scripts
4. Verify dispatch-provider.sh runs without error
5. Commit

## Summary of Changes
Deleted swarm infrastructure (develop-swarm/, patch-superpowers/, 5 scripts). Moved provider-context.md to skills/develop/. Updated dispatch-provider.sh template path. Commit: bcd9928.
