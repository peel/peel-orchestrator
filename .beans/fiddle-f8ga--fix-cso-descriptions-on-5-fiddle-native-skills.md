---
# fiddle-f8ga
title: Fix CSO descriptions on 5 fiddle-native skills
status: completed
type: task
priority: normal
created_at: 2026-04-03T19:02:33Z
updated_at: 2026-04-03T19:04:30Z
parent: fiddle-rwyx
---

Change descriptions from 'what it does' to 'when to use' on develop, develop-loop, develop-holistic, evaluate, runtime-evidence.

## Files
- Modify: `skills/develop/SKILL.md` (frontmatter)
- Modify: `skills/develop/develop-loop/SKILL.md` (frontmatter)
- Modify: `skills/develop/develop-holistic/SKILL.md` (frontmatter)
- Modify: `skills/evaluate/SKILL.md` (frontmatter)
- Modify: `skills/runtime-evidence/SKILL.md` (frontmatter)

- [x] Fix all 5 descriptions
- [ ] Commit

```eval
domains: [general]
criteria:
  general:
    - id: cso-all-descriptions
      check: "All 5 fiddle-native skill descriptions start with 'Use when' or 'Use after'"
    - id: no-workflow-summaries
      check: "No description contains workflow steps like 'validate, implement, review, finish'"
thresholds: {}
```
