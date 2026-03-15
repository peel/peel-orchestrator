---
# fiddle-q1fz
title: 'Task 2: Create provider-context.md template'
status: todo
type: task
priority: high
tags:
    - worktree
created_at: 2026-03-15T13:47:43Z
updated_at: 2026-03-15T13:47:43Z
parent: fiddle-jj30
---

Plan: docs/plans/2026-03-15-async-provider-coordination.md Task 2

Files:
- Create: skills/ralph-subs-implement/roles/provider-context.md

Steps:
1. Create the template file with these sections and placeholders:

```markdown
# Provider Context

Respond with your analysis only — no preamble, no meta-commentary.

## Role
{PROVIDER_ROLE}

## Topic
{TOPIC}

## Approaches
{APPROACHES}

## Design Document
{DESIGN_DOC}

## Diff
{DIFF}

## Previous Feedback
{PREVIOUS_FEEDBACK}

## Instructions
{INSTRUCTIONS}
```

2. Verify: all placeholders use {UPPER_SNAKE_CASE} format. File is in skills/ralph-subs-implement/roles/ alongside implementer.md and reviewer.md.
3. Commit: git commit -m "feat: add provider context template for standardized handoff"

Acceptance criteria:
- File exists at skills/ralph-subs-implement/roles/provider-context.md
- All 7 placeholders present: PROVIDER_ROLE, TOPIC, APPROACHES, DESIGN_DOC, DIFF, PREVIOUS_FEEDBACK, INSTRUCTIONS
- Sections with no value are meant to be stripped by the caller — template just defines the structure
