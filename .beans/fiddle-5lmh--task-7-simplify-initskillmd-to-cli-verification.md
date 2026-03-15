---
# fiddle-5lmh
title: 'Task 7: Simplify init/SKILL.md to CLI verification'
status: completed
type: task
priority: low
tags:
    - worktree
created_at: 2026-03-15T13:48:57Z
updated_at: 2026-03-15T14:33:18Z
parent: fiddle-jj30
---

Plan: docs/plans/2026-03-15-async-provider-coordination.md Task 7

Files:
- Modify: skills/init/SKILL.md

Steps:
1. Update skill description from "Configure MCP servers and CLI providers" to "Verify CLI providers for fiddle multi-model orchestration."

2. Remove Steps 2-4 (Check existing configuration, Choose target, Write configuration) which write MCP entries to .mcp.json or ~/.claude.json.

3. Replace with simplified flow:
   - Step 1: Detect providers — read orchestrate.conf for declared providers, check each with which/command -v. Report status.
   - Step 2: Verify config — check that orchestrate.conf has command and flags for each installed provider. If missing, add default entries.
   - Step 3: Auth reminders — codex: codex --login, gemini: gemini auth.

4. Remove all MCP references (mcpServers, .mcp.json, ~/.claude.json, jq merge logic).

5. Verify: read full file — no MCP references remain, flow is detect → verify config → auth.

6. Commit: git commit -m "refactor: simplify init to CLI verification, remove MCP config flow"

Acceptance criteria:
- No MCP references in file
- No .mcp.json or ~/.claude.json references
- No jq merge logic
- Simplified 3-step flow: detect, verify config, auth reminders
- Updated skill description
