---
# fiddle-2cgr
title: Create holistic progressive disclosure reference files
status: completed
type: task
priority: normal
created_at: 2026-04-03T19:03:04Z
updated_at: 2026-04-03T19:12:56Z
parent: fiddle-rwyx
---

Create 2 reference files extracted from holistic-review.md: dimension scales and scorecard schema.

## Files
- Create: `skills/develop/holistic-dimensions.md`
- Create: `skills/develop/holistic-scorecard-schema.md`

- [x] Create holistic-dimensions.md with all 5 scales
- [ ] Create holistic-scorecard-schema.md with coverage matrix, remediation, and scorecard JSON
- [ ] Commit

```eval
domains: [general]
criteria:
  general:
    - id: holistic-dimensions-exists
      check: "holistic-dimensions.md exists with all 5 dimension scales"
    - id: holistic-schema-exists
      check: "holistic-scorecard-schema.md exists with spec coverage matrix, remediation beans, and scorecard JSON"
thresholds: {}
```
