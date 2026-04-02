---
# fiddle-jai0
title: Pluggable product artifact generation in deliver phase
status: completed
type: feature
priority: normal
created_at: 2026-04-01T20:41:04Z
updated_at: 2026-04-01T21:14:48Z
---

Add a configurable deliver-phase step that generates product artifacts (release notes, social copy, screenshots) from plan + diff. Fiddle provides the hook point and dispatch mechanism. Projects supply templates, voice docs, and output instructions via orchestrate.json. Reuses existing runtime infrastructure for screenshots.

## Checklist

- [x] RED: Baseline test — run deliver scenario, confirm no product artifacts step
- [x] GREEN: Add product artifact generation step to deliver skill
- [x] GREEN: Verify agent follows the new step
- [x] REFACTOR: Close loopholes, edge cases
- [x] Update orchestrate.json schema docs (in deliver skill)
- [x] Commit (pending)

## Summary of Changes

Added Step 4 (Product Artifact Generation) to the deliver skill between Documentation Update and Evaluator Evolve. Conditional on `deliver.product_artifacts` in orchestrate.json. Projects supply templates (instructions for voice, format, audience), Fiddle provides the dispatch mechanism. Handles missing templates, missing product docs, directory creation, and overwrite behavior.
