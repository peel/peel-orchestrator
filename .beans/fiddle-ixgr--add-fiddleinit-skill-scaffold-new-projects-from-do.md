---
# fiddle-ixgr
title: Add fiddle:init skill — scaffold new projects from .docs/ template
status: completed
type: feature
priority: normal
created_at: 2026-04-01T21:17:36Z
updated_at: 2026-04-01T21:49:30Z
---

New skill that initializes a project for use with fiddle. Copies .docs/ template to target docs/ directory, creates starter orchestrate.json, scaffolds all directories (personas/, insights/, templates/, releases/, decisions/). One-time action, then points user to discover-docs. Keeps .docs/ as the canonical template source.

## Checklist

- [x] RED: Baseline — no init mechanism existed
- [x] GREEN: Write fiddle:init skill + scripts/init.sh
- [x] GREEN: Update .docs/ template with personas/insights/templates/releases dirs
- [x] GREEN: Iterated with user on skill design
- [x] REFACTOR: Simplified — script does mechanical work, skill is thin wrapper
- [x] Removed redundant .docs/README.md
- [x] Commit (pending)

## Summary of Changes

Created fiddle:init skill and scripts/init.sh. The script scaffolds docs/ from .docs/ templates, copies orchestrate.json from plugin root, and runs beans init with prefix derived from directory name. All idempotent — skips existing files. Updated .docs/ template to include personas/, insights/, templates/, releases/ directories. Removed redundant .docs/README.md (each template file is self-documenting).
