---
# fiddle-3gqb
title: 'Task 4: Update config docs and SYSTEM.md'
status: completed
type: task
priority: normal
tags:
    - worktree-slot:fiddle-zi76-worker-2
    - worktree
    - agent:implementer
    - reviewers:baseline
created_at: 2026-03-19T11:44:45Z
updated_at: 2026-03-19T11:58:37Z
parent: fiddle-zi76
---

Plan: docs/plans/2026-03-19-collapse-review-tiers.md Task 4

Files:
- Modify: skills/develop/SKILL.md (config section lines 29-30, line 91)
- Modify: skills/orchestrate/SKILL.md (model defaults table lines 103-104, config example lines 86-87, provider defaults line 115, SETUP config parsing line 137)
- Modify: docs/technical/SYSTEM.md (Ralph description line 13)

Steps:
- [ ] Update develop/SKILL.md: merge two model config lines into single models.develop line, update ralph spawn model comment
- [ ] Update orchestrate/SKILL.md: collapse model defaults table (2 develop rows → 1), flatten config example (nested develop block → single key), update provider defaults rationale ("tiered review" → "single-pass domain-expert review"), update SETUP config parsing ("Nested develop block contains standard and lite keys" → "develop is a string key")
- [ ] Update SYSTEM.md: fix Ralph description ("tiered review (haiku then sonnet)" → "single-pass domain-expert review (baseline fallback when no experts match)"), update Last reviewed date to 2026-03-19
- [ ] Verify all three files: no models.develop.standard/lite, no tier-1/tier-2/haiku/sonnet refs, one develop row in model defaults
- [ ] Commit

Updated all three files: develop/SKILL.md (merged model config lines, updated ralph spawn comment), orchestrate/SKILL.md (collapsed model defaults table, flattened config example, updated provider rationale, updated config parsing), SYSTEM.md (updated Ralph description). Verified no stale references remain.
