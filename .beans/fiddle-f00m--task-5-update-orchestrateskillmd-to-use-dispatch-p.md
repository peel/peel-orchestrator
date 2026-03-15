---
# fiddle-f00m
title: 'Task 5: Update orchestrate/SKILL.md to use dispatch procedure'
status: completed
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-15T13:48:28Z
updated_at: 2026-03-15T14:43:40Z
parent: fiddle-jj30
blocked_by:
    - fiddle-j7a1
    - fiddle-q1fz
    - fiddle-f2ib
---

Plan: docs/plans/2026-03-15-async-provider-coordination.md Task 5

Files:
- Modify: skills/orchestrate/SKILL.md

Steps:
1. Replace DISCOVER Step 2 (External Research). Remove inline mcp__codex__codex() and gemini CLI calls. Replace with: read roles/provider-dispatch.md, follow dispatch for each provider in discover phase list. Template: PROVIDER_ROLE="Research analyst", TOPIC=<topic>, INSTRUCTIONS="Research: ecosystem patterns, prior art, implementation approaches, potential pitfalls." Dispatch parallel, collect attended mode.

2. Replace DEVELOP Step 3 (Holistic Review). Remove inline provider calls. Replace with: dispatch for each provider in develop_holistic phase list. Template: PROVIDER_ROLE="Holistic reviewer", TOPIC="Epic holistic review for <epic-id>", DESIGN_DOC=<content>, DIFF=<git diff>, INSTRUCTIONS="Did the implementation match the design? Flag: inconsistencies, missed requirements, naming conflicts, dead code." Dispatch parallel, collect unattended mode (first-past-the-post).

3. Replace DELIVER Step 1 (Drift Analysis). Remove inline provider calls. Replace with: dispatch for each provider in deliver phase list. Template: PROVIDER_ROLE="Drift analyst", TOPIC="Design vs implementation drift", DESIGN_DOC=<content>, DIFF=<git diff>, INSTRUCTIONS="Flag drift, missing features, scope creep, unintended changes." Dispatch parallel, collect attended mode.

4. Remove ALL mcp__codex__codex references and inline gemini commands from the file.

5. Verify: read full file. DISCOVER → DEFINE → DEVELOP → DELIVER flow intact. All provider calls reference dispatch procedure. No orphaned MCP references.

6. Commit: git commit -m "refactor: orchestrate uses async provider dispatch for all external calls"

Acceptance criteria:
- No mcp__codex__codex references in file
- No inline gemini CLI command strings
- DISCOVER Step 2 uses dispatch with attended mode
- DEVELOP Step 3 uses dispatch with unattended mode
- DELIVER Step 1 uses dispatch with attended mode
- All three call sites reference provider-dispatch.md and provider-context.md
