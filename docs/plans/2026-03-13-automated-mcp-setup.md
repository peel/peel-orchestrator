# Automated MCP Provider Setup — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Automate MCP server configuration for fiddle's external providers via a SessionStart hook and `/fiddle:init` skill.

**Architecture:** A bash hook script checks provider availability vs MCP config on each session start and nudges the user. A skill (`/fiddle:init`) does the actual config writing — detecting installed binaries, asking where to write, and merging into the target file.

**Tech Stack:** Bash (hook script), Markdown (skill), jq (JSON merging)

---

### Task 1: SessionStart hook script

**Files:**
- Create: `hooks/session-start-check-providers.sh`

**Step 1: Write the hook script**

```bash
#!/usr/bin/env bash
# SessionStart hook: detect installed-but-unconfigured providers and suggest /fiddle:init.
set -euo pipefail

# Only act if orchestrate.conf exists in the project
CONF="${CLAUDE_PROJECT_DIR:-.}/orchestrate.conf"
[[ -f "$CONF" ]] || exit 0

# Extract unique provider names from orchestrate.conf
# Matches quoted strings inside brackets: ["codex", "gemini"]
PROVIDERS=$(grep -oE '"[a-z]+"' "$CONF" | tr -d '"' | sort -u)

[[ -z "$PROVIDERS" ]] && exit 0

# MCP config locations to check
PROJECT_MCP="${CLAUDE_PROJECT_DIR:-.}/.mcp.json"
GLOBAL_MCP="$HOME/.claude.json"

needs_setup=()

for provider in $PROVIDERS; do
  case "$provider" in
    codex)
      # Codex needs MCP config — check if binary exists and MCP entry is missing
      if command -v codex &>/dev/null; then
        configured=false
        for f in "$PROJECT_MCP" "$GLOBAL_MCP"; do
          if [[ -f "$f" ]] && jq -e '.mcpServers.codex // empty' "$f" &>/dev/null; then
            configured=true
            break
          fi
        done
        if [[ "$configured" == "false" ]]; then
          needs_setup+=("codex (installed, MCP not configured)")
        fi
      fi
      ;;
    gemini)
      # Gemini uses CLI, not MCP — just check if it's on PATH
      if ! command -v gemini &>/dev/null; then
        needs_setup+=("gemini (not installed)")
      fi
      ;;
  esac
done

if [[ ${#needs_setup[@]} -gt 0 ]]; then
  echo "fiddle: provider setup needed:"
  for item in "${needs_setup[@]}"; do
    echo "  - $item"
  done
  echo "Run /fiddle:init to configure."
fi

exit 0
```

**Step 2: Make the script executable**

Run: `chmod +x hooks/session-start-check-providers.sh`

**Step 3: Verify the script runs without error**

Run: `bash hooks/session-start-check-providers.sh`
Expected: exits 0 with no output (no orchestrate.conf in project root during test) or prints provider setup message

**Step 4: Commit**

```bash
git add hooks/session-start-check-providers.sh
git commit -m "feat: add SessionStart hook to detect unconfigured providers"
```

---

### Task 2: Wire hook into hooks.json

**Files:**
- Modify: `hooks/hooks.json`

**Step 1: Update hooks.json to call the new script from the existing SessionStart entry**

Update the existing `session-start` script to also call `session-start-check-providers.sh`, OR add a second hook entry to the SessionStart array.

The existing `hooks.json` uses `run-hook.cmd` which dispatches to a named script. Add a second hook entry:

Replace the SessionStart hooks array in `hooks/hooks.json` with:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "'${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd' session-start",
            "async": false
          },
          {
            "type": "command",
            "command": "bash '${CLAUDE_PLUGIN_ROOT}/hooks/session-start-check-providers.sh'",
            "async": false
          }
        ]
      }
    ]
  }
}
```

**Step 2: Validate JSON**

Run: `jq . hooks/hooks.json`
Expected: valid JSON output

**Step 3: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: wire provider-check hook into SessionStart"
```

---

### Task 3: Init skill

**Files:**
- Create: `skills/init/SKILL.md`

**Step 1: Create the skill directory**

Run: `mkdir -p skills/init`

**Step 2: Write the skill**

Create `skills/init/SKILL.md`:

````markdown
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
````

**Step 3: Commit**

```bash
git add skills/init/SKILL.md
git commit -m "feat: add /fiddle:init skill for provider setup"
```

---

### Task 4: Update README

**Files:**
- Modify: `README.md`

**Step 1: Add init to the skills table**

In `README.md`, add a row to the "All Skills" table after the existing entries:

```markdown
| `fiddle:init` | Configure MCP servers and CLI providers — detects installed tools and writes config |
```

**Step 2: Add setup section**

After the "External Providers" section, add:

```markdown
## Setup

Run `/fiddle:init` to auto-detect and configure external providers. The SessionStart hook will remind you if providers are installed but unconfigured.
```

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document /fiddle:init skill and auto-setup"
```

---

### Task 5: End-to-end verification

**Step 1: Verify hook runs cleanly**

Run: `CLAUDE_PROJECT_DIR=/Users/peel/wrk/fiddle bash /Users/peel/wrk/fiddle/hooks/session-start-check-providers.sh`

Expected: If codex is installed but not configured, prints setup suggestion. Otherwise silent.

**Step 2: Verify hooks.json is valid**

Run: `jq . /Users/peel/wrk/fiddle/hooks/hooks.json`

Expected: valid JSON

**Step 3: Verify skill file exists and has valid frontmatter**

Run: `head -6 /Users/peel/wrk/fiddle/skills/init/SKILL.md`

Expected: YAML frontmatter with `name: fiddle:init`

**Step 4: Commit all if any stragglers**

```bash
git status
# If any unstaged changes, add and commit
```
