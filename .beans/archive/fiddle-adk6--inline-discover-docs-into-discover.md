---
# fiddle-adk6
title: Inline discover-docs into discover
status: scrapped
type: task
priority: low
created_at: 2026-03-25T21:22:16Z
updated_at: 2026-03-25T21:56:09Z
---

Inline discover-docs logic (assess docs, Socratic dialogue, write) directly into discover as Step 1 instead of Skill invocation hop. Keep discover-docs as standalone skill for periodic doc review. Removes indirection, discover reads as one cohesive flow.

## Reasons for Scrapping

On closer inspection, the overlap between discover and discover-docs does not exist. Discover Step 1 is a single `Skill()` call — it delegates entirely to discover-docs without reading docs itself. Inlining 109 lines of doc schema + Socratic dialogue into discover would make it bigger without removing any actual redundancy. The one-line Skill invocation is not meaningful overhead, and discover-docs has legitimate standalone use for periodic doc reviews.
