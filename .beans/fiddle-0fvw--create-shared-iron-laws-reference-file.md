---
# fiddle-0fvw
title: Create shared Iron Laws reference file
status: completed
type: task
priority: normal
created_at: 2026-04-03T19:02:28Z
updated_at: 2026-04-03T19:03:52Z
parent: fiddle-rwyx
---

Create `skills/develop/iron-laws.md` with the 5 iron laws extracted from develop/SKILL.md. No YAML frontmatter — reference file only.

## Files
- Create: `skills/develop/iron-laws.md`

- [x] Create iron-laws.md reference file
- [ ] Commit

```eval
domains: [general]
criteria:
  general:
    - id: iron-laws-file-exists
      check: "skills/develop/iron-laws.md exists with all 5 iron laws, no frontmatter"
    - id: iron-laws-content-matches
      check: "Content matches the 5 laws verbatim from the original develop/SKILL.md"
thresholds: {}
```
