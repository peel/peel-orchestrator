---
name: fiddle:init
description: Verify CLI providers for fiddle's multi-model orchestration. Detects installed tools and checks config.
disable-model-invocation: true
---

# Init

Verify external providers for fiddle. Detects installed tools and checks orchestrate.conf.

## Process

### Step 1: Detect providers

Read `orchestrate.conf` (in project root or `.claude/orchestrate.conf`) to find declared providers. Extract unique provider names from provider definition blocks (e.g. `codex { command = ... }` entries inside the top-level `providers` block). If the file is not found, use defaults: codex, gemini.

For each provider, check availability:

```bash
command -v codex
command -v gemini
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

### Step 2: Verify config

For each installed provider, check that `orchestrate.conf` has a `command` and `flags` block inside the `providers` section. Example of a valid block:

```
codex {
  command = "codex exec"
  flags   = "--json -s read-only"
}
```

If a provider binary is installed but has no config block, warn and suggest adding it:
```
⚠ codex is installed but has no config block in orchestrate.conf.
  Add a block like:
    codex {
      command = "codex exec"
      flags   = "--json"
    }
```

If all installed providers have valid config blocks, report success:
```
All providers configured ✓
```

### Step 3: Auth reminders

For each installed provider, remind about authentication:

```
Auth reminders:
  codex: run `codex --login` to authenticate
  gemini: run `gemini auth` to authenticate
```

## Rules

- Only checks CLI availability and config — does not write config files.
- Idempotent — re-running when configured is a no-op.
