---
# fiddle-u2yi
title: 'Fix develop skill: ralph must run inline, not as nested subagent'
status: in-progress
type: bug
created_at: 2026-03-26T13:58:20Z
updated_at: 2026-03-26T13:58:20Z
---

develop/SKILL.md spawns ralph-subs as a background subagent, but ralph needs to spawn its own subagents (implementers, review coordinators). Subagents can't nest. Fix: both variants run inline in the main session.
