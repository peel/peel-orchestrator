---
# fiddle-f6o0
title: 'Task 3: Update lead SKILL.md files — reviewer selection and model references'
status: completed
type: task
priority: normal
tags:
    - reviewers:baseline
    - worktree-slot:fiddle-zi76-worker-1
    - worktree
    - agent:implementer
created_at: 2026-03-19T11:44:33Z
updated_at: 2026-03-19T11:58:22Z
parent: fiddle-zi76
---

Plan: docs/plans/2026-03-19-collapse-review-tiers.md Task 3

Files:
- Modify: skills/develop-subs/SKILL.md
- Modify: skills/develop-team/SKILL.md

Steps:
- [ ] Update develop-subs/SKILL.md: frontmatter description (remove "tier-1/tier-2"), "Every Turn" section (remove tier refs), Review Coordinator Spawn (baseline fallback instead of always-include), model refs (models.develop.standard → models.develop), Rules section (flatten model description)
- [ ] Update develop-team/SKILL.md: same changes as subs variant
- [ ] Verify both files: no tier-1/tier-2 refs, no "Always include baseline", all models.develop.standard → models.develop, all models.develop.lite gone
- [ ] Commit

## Progress
- 12:55 Updated develop-subs/SKILL.md: frontmatter, every-turn, reviewer selection, model refs, rules
- 12:55 Updated develop-team/SKILL.md: frontmatter, every-turn, reviewer selection, model refs, rules
- 12:55 Verified: no tier-1/tier-2 refs, no models.develop.lite, no models.develop.standard, no Always include
