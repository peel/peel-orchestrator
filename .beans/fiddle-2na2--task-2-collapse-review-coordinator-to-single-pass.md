---
# fiddle-2na2
title: 'Task 2: Collapse review coordinator to single pass'
status: completed
type: task
priority: normal
tags:
    - agent:implementer
    - reviewers:baseline
    - worktree-slot:fiddle-zi76-worker-2
    - worktree
created_at: 2026-03-19T11:44:24Z
updated_at: 2026-03-19T11:54:25Z
parent: fiddle-zi76
---

Plan: docs/plans/2026-03-19-collapse-review-tiers.md Task 2

Files:
- Modify: skills/develop-subs/roles/review-coordinator.md (rewrite Steps 1-5)
- Modify: skills/develop-team/roles/review-coordinator.md (rewrite Steps 1-5)

Steps:
- [ ] Rewrite develop-subs review-coordinator.md: replace ## Process section with single-pass flow (Build Prompts → Spawn Reviewers → Aggregate Results → Return Verdict). Delete Tier-1, Tier-2 steps. Use models.develop (not lite/standard). Update verdict text to "{N} reviewer(s) all clean." Update line 1 description to "manage the review pipeline".
- [ ] Rewrite develop-team review-coordinator.md: same structural rewrite, but use SendMessage pattern for verdicts instead of direct output. Update verdict content strings. Keep ## Shutdown section unchanged.
- [ ] Verify both files: no tier-1/tier-2 references, model refs use models.develop, verdict text updated
- [ ] Commit
