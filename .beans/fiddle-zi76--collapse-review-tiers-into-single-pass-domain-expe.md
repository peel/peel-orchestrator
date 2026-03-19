---
# fiddle-zi76
title: Collapse review tiers into single-pass domain-expert review
status: todo
type: epic
created_at: 2026-03-19T11:43:58Z
updated_at: 2026-03-19T11:43:58Z
---

Plan: docs/plans/2026-03-19-collapse-review-tiers.md
Spec: docs/plans/2026-03-19-collapse-review-tiers-design.md

Replace the two-tier review pipeline (tier-1 parallel + tier-2 confirmation) with a single-pass domain-expert review, using baseline as fallback when no experts match. Flatten models.develop config to single key. Add cross-cutting concerns checklist to reviewer prompt.
