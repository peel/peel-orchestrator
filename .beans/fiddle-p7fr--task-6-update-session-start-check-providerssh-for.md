---
# fiddle-p7fr
title: 'Task 6: Update session-start-check-providers.sh for CLI-only'
status: todo
type: task
priority: normal
tags:
    - worktree
created_at: 2026-03-15T13:48:44Z
updated_at: 2026-03-15T13:48:44Z
parent: fiddle-jj30
---

Plan: docs/plans/2026-03-15-async-provider-coordination.md Task 6

Files:
- Modify: hooks/session-start-check-providers.sh

Steps:
1. Remove the MCP config checking logic — the jq checks against .mcp.json and ~/.claude.json for mcpServers.codex. Remove the PROJECT_MCP and GLOBAL_MCP variables and the inner loop that checks MCP config files.

2. Replace with uniform CLI PATH checking for all providers:

```bash
for provider in $PROVIDERS; do
  if ! command -v "$provider" &>/dev/null; then
    needs_setup+=("$provider (not installed)")
  fi
done
```

Both codex and gemini are treated identically — just check if binary is on PATH.

3. Update the nudge message from "Run /fiddle:init to configure." to "Install missing providers to enable multi-model features."

4. Verify: run bash hooks/session-start-check-providers.sh — should report only genuinely missing CLI tools with no MCP config mentions.

5. Commit: git commit -m "refactor: session-start hook checks CLI binaries instead of MCP config"

Acceptance criteria:
- No MCP config checking (no jq, no .mcp.json, no ~/.claude.json references)
- Uniform command -v check for all providers
- Updated user-facing message
- Script exits 0 on success
