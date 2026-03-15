---
# fiddle-j7a1
title: 'Task 1: Update orchestrate.conf with provider CLI definitions'
status: todo
type: task
priority: high
tags:
    - worktree
created_at: 2026-03-15T13:47:22Z
updated_at: 2026-03-15T13:47:22Z
parent: fiddle-jj30
---

Plan: docs/plans/2026-03-15-async-provider-coordination.md Task 1

Files:
- Modify: orchestrate.conf

Steps:
1. Replace the providers block with explicit CLI definitions. Add nested blocks for codex and gemini with command and flags. Add timeout block with attended (120s) and unattended (90s) values. Keep phase assignments. Keep ralph block unchanged.

```hcl
providers {
  codex {
    command = "codex exec"
    flags   = "--json -s read-only"
  }
  gemini {
    command = "gemini"
    flags   = "-o json --approval-mode auto_edit"
  }

  discover         = ["codex"]
  define           = ["codex", "gemini"]
  develop          = []
  develop_holistic = ["codex"]
  deliver          = ["codex"]

  timeout {
    attended   = 120
    unattended = 90
  }
}
```

2. Verify: cat orchestrate.conf — both providers {} (with nested codex {}, gemini {}, timeout {}) and ralph {} blocks present.
3. Commit: git commit -m "feat: add explicit provider CLI definitions to orchestrate.conf"

Acceptance criteria:
- orchestrate.conf has codex and gemini blocks with command + flags
- timeout block with attended and unattended values
- ralph block unchanged
- File is well-formed HCL
