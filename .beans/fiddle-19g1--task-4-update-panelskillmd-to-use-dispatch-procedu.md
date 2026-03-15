---
# fiddle-19g1
title: 'Task 4: Update panel/SKILL.md to use dispatch procedure'
status: todo
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-15T13:48:15Z
updated_at: 2026-03-15T13:49:27Z
parent: fiddle-jj30
blocked_by:
    - fiddle-j7a1
    - fiddle-q1fz
    - fiddle-f2ib
---

Plan: docs/plans/2026-03-15-async-provider-coordination.md Task 4

Files:
- Modify: skills/panel/SKILL.md

Steps:
1. Replace Mode Detection section. Remove mcp__codex__codex tool check and inline gemini PATH check. Replace with: read orchestrate.conf providers block, check CLI binaries on PATH for each provider in the define phase list. At least one external provider available → full mode, none → degraded mode.

2. Replace Phase 1 — Independent Positions (full mode). Remove the inline mcp__codex__codex() call and the inline gemini -o json ... Bash call. Replace with: read roles/provider-dispatch.md, follow Read Config and Build Prompt for each provider. Spawn Claude position via Agent(run_in_background: true) as before. Spawn external providers via provider-dispatch Dispatch (Background). Fire ALL in one message. Collect via provider-dispatch Collect Results with attended mode.

Template placeholders for Phase 1:
- PROVIDER_ROLE: Codex → "Implementation depth: code patterns, technical feasibility, performance", Gemini → "Ecosystem breadth: alternatives, prior art, industry patterns"
- TOPIC: the debate topic
- APPROACHES: the candidate approaches
- INSTRUCTIONS: "Produce a position paper: what you recommend, why, key tradeoffs, risks."

3. Replace Phase 2+ — Cross-Review (full mode). Same transformation. PREVIOUS_FEEDBACK gets all positions from previous round. INSTRUCTIONS: "Critique the other positions: agreements, disagreements, new concerns."

4. Remove ALL mentions of mcp__codex__codex from the file. Remove all inline gemini -o json --approval-mode auto_edit command strings.

5. Verify: read full file end-to-end. Mode Detection → Phase 1 → Phase 2 → Synthesis flow intact. All provider calls reference dispatch procedure. No orphaned MCP references.

6. Commit: git commit -m "refactor: panel uses async provider dispatch instead of blocking MCP/CLI calls"

Acceptance criteria:
- No mcp__codex__codex references in file
- No inline gemini CLI command strings
- Mode Detection reads orchestrate.conf
- Phase 1 and Phase 2+ use provider-dispatch procedure
- Claude subagent still uses Agent(run_in_background: true) directly
- Degraded mode (Claude subagents only) unchanged
