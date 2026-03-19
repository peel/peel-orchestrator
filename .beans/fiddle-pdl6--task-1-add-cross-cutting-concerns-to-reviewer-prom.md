---
# fiddle-pdl6
title: 'Task 1: Add cross-cutting concerns to reviewer prompt'
status: completed
type: task
priority: normal
tags:
    - reviewers:baseline
    - worktree-slot:fiddle-zi76-worker-1
    - worktree
    - agent:implementer
created_at: 2026-03-19T11:44:13Z
updated_at: 2026-03-19T11:53:21Z
parent: fiddle-zi76
---

Plan: docs/plans/2026-03-19-collapse-review-tiers.md Task 1

Files:
- Modify: skills/develop-subs/roles/reviewer.md (after Safety section)
- Modify: skills/develop-team/roles/reviewer.md (after Safety section)

Steps:
- [ ] Add Cross-Cutting Concerns section to develop-subs reviewer.md after ### Safety
- [ ] Apply same change to develop-team reviewer.md
- [ ] Verify both files: section appears after Safety and before ## Previous Review Issues
- [ ] Commit

Cross-Cutting Concerns checklist to add:
### Cross-Cutting Concerns
- Backward compatibility: any breaking changes to public APIs, CLI flags, config schema, or file formats?
- Data migrations: schema changes, state format changes, or data loss risks?
- Dependency changes: new dependencies added, versions bumped, or removals?
- Observability: logging, error messages, or monitoring affected?

## Progress
- 12:49 edit: added Cross-Cutting Concerns section to develop-subs/roles/reviewer.md
- 12:49 edit: added Cross-Cutting Concerns section to develop-team/roles/reviewer.md
