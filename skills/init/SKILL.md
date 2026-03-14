---
name: fiddle:init
description: Configure MCP servers and CLI providers for fiddle's multi-model orchestration. Detects installed tools and writes config.
disable-model-invocation: true
argument-hint: [--target project|global]
---

# Init

Set up external providers for fiddle. Detects installed tools, checks existing config, and writes MCP entries.

ARGUMENTS: {ARGS}

## Process

### Step 1: Detect providers

Read `orchestrate.conf` (in project root or `.claude/orchestrate.conf`) to find declared providers. If not found, use defaults: codex, gemini.

For each provider, check availability:

**Codex:**
```bash
which codex
```

**Gemini:**
```bash
which gemini
```

Report findings to the user:
```
Provider status:
  codex: installed ✓ / not found ✗
  gemini: installed ✓ / not found ✗
```

If no providers are installed, inform the user and stop:
```
No external providers found on PATH. Install codex or gemini to enable multi-model features.
Fiddle works without them — skills fall back to Claude-only subagents.
```

### Step 2: Check existing configuration

For each installed provider that needs MCP (currently just codex), check if already configured:

```bash
# Check project-level
jq -e '.mcpServers.codex' .mcp.json 2>/dev/null

# Check global
jq -e '.mcpServers.codex' ~/.claude.json 2>/dev/null
```

If already configured, report and skip:
```
codex MCP: already configured in .mcp.json ✓
```

If all installed providers are configured, report "All providers configured" and stop.

### Step 3: Choose target

Parse `--target` from `{ARGS}` if provided. Otherwise, ask the user:

```
Where should the MCP config be written?
1. Project .mcp.json (scoped to this project, can be checked into git)
2. Global ~/.claude.json (available across all projects)
```

Use AskUserQuestion with these two options.

### Step 4: Write configuration

Read the target file if it exists. If it doesn't exist, start with `{}`.

For codex, merge this entry into `mcpServers`:

```json
{
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp"]
    }
  }
}
```

Use jq to merge without clobbering existing entries:

```bash
# If target file exists, merge. Otherwise create.
TARGET="<chosen file>"
if [[ -f "$TARGET" ]]; then
  jq '.mcpServers.codex = {"command": "codex", "args": ["mcp"]}' "$TARGET" > "$TARGET.tmp" && mv "$TARGET.tmp" "$TARGET"
else
  echo '{"mcpServers":{"codex":{"command":"codex","args":["mcp"]}}}' | jq . > "$TARGET"
fi
```

Report what was written.

### Step 5: Auth reminders

For each configured provider, remind about authentication:

```
Setup complete. Auth reminders:
  codex: run `codex --login` to authenticate
  gemini: run `gemini auth` to authenticate (if installed)
```

## Rules

- Never overwrite existing MCP server entries — merge only.
- Gemini uses CLI, not MCP. Init only checks it's on PATH and reminds about auth.
- Idempotent — re-running when configured is a no-op.
- If jq is not available, write the JSON directly with the Write tool instead of shell commands.
