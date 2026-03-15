---
# fiddle-svp1
title: 'Task 8: Update SYSTEM.md for CLI-only providers'
status: todo
type: task
priority: low
tags:
    - worktree
created_at: 2026-03-15T13:49:13Z
updated_at: 2026-03-15T13:49:27Z
parent: fiddle-jj30
blocked_by:
    - fiddle-19g1
    - fiddle-f00m
    - fiddle-p7fr
    - fiddle-5lmh
---

Plan: docs/plans/2026-03-15-async-provider-coordination.md Task 8

Files:
- Modify: docs/technical/SYSTEM.md

Steps:
1. In Overview: replace "Codex via MCP" with "Codex via CLI".

2. In Components:
   - Orchestrate: mention provider-dispatch procedure for external calls
   - Panel: mention async parallel provider calls via dispatch procedure
   - Init: change to "Verifies CLI providers are on PATH and authenticated"
   - Hooks: update session-start description to mention CLI binary checks instead of MCP

3. In Data section: remove .mcp.json entry. Add note about provider-dispatch temp files being ephemeral.

4. Add to Invariants:
   - "Provider calls use the dispatch procedure (roles/provider-dispatch.md) — never inline CLI commands in skill files."
   - "All external provider calls fire as background Bash tasks — never synchronous blocking calls."

5. Add to Infrastructure or a Setup note: "Shared agent context: symlink CLAUDE.md to AGENTS.md so provider CLIs share project baseline."

6. Update Last reviewed date to 2026-03-15.

7. Verify: search for stale MCP/mcp__codex__codex references. Only legitimate references should remain.

8. Commit: git commit -m "docs: update SYSTEM.md for CLI-only provider coordination"

Acceptance criteria:
- No stale MCP references for codex
- Provider dispatch documented in Components and Invariants
- .mcp.json removed from Data section
- AGENTS.md setup documented
- Last reviewed date updated
