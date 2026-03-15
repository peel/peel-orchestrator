---
# fiddle-f2ib
title: 'Task 3: Create provider-dispatch.md procedure'
status: todo
type: task
priority: high
tags:
    - worktree
created_at: 2026-03-15T13:47:57Z
updated_at: 2026-03-15T13:47:57Z
parent: fiddle-jj30
---

Plan: docs/plans/2026-03-15-async-provider-coordination.md Task 3

Files:
- Create: skills/ralph-subs-implement/roles/provider-dispatch.md

Steps:
1. Create the dispatch procedure file with sections: Read Config, Build Prompt, Dispatch (Background), Collect Results (Attended mode + Unattended mode), Parse Output, Cleanup.

Key content:
- Read Config: read orchestrate.conf providers.<name> block for command and flags, read providers.timeout for attended/unattended values
- Build Prompt: read roles/provider-context.md, substitute placeholders, strip empty sections, write to temp file
- Dispatch: Bash(run_in_background: true, command: "<command> <flags> < \"$PROMPT_FILE\""). Fire ALL providers in single message.
- Collect (Attended — DISCOVER/DEFINE): TaskOutput with attended timeout. On timeout: present user with options (1) keep waiting, (2) respawn, (3) kill and proceed
- Collect (Unattended — DEVELOP): TaskOutput with unattended timeout. On timeout: TaskStop and proceed. First-past-the-post when 2+ providers returned.
- Cleanup: rm temp file

2. Verify: procedure references roles/provider-context.md and orchestrate.conf correctly. Both attended and unattended modes documented. Respawn option present in attended mode.
3. Commit: git commit -m "feat: add provider dispatch procedure for async CLI coordination"

Acceptance criteria:
- File exists at skills/ralph-subs-implement/roles/provider-dispatch.md
- Read Config, Build Prompt, Dispatch, Collect Results (both modes), Parse Output, Cleanup sections present
- Attended mode has 3 options: keep waiting, respawn, kill
- Unattended mode has first-past-the-post behavior
- References provider-context.md for template
