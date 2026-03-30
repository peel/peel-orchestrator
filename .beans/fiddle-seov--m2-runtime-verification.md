---
# fiddle-seov
title: 'M2: Runtime Verification'
status: completed
type: epic
priority: normal
created_at: 2026-03-29T19:17:55Z
updated_at: 2026-03-30T07:21:14Z
blocked_by:
    - fiddle-yzzk
---

Add runtime evaluation — evaluators launch and interact with the running app using project-configured MCP tools. Orchestrator starts/stops the app via scripts. Evaluator subagent uses available MCP tools (marionette, curl, go-dev-mcp) to interact with the running app and gather evidence. Domain-specific evaluator templates (frontend, backend) replace the general template for typed projects.

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m2.md
Design: docs/superpowers/specs/2026-03-29-calibrated-evaluator-system-design.md

## Contracts

### Runtime State JSON (start-runtimes.sh output, stop-runtimes.sh input)
```json
[{"domain": "backend", "pid": 12345, "port": 8080, "command": "go run ./cmd/server"},
 {"domain": "frontend", "pid": 12346, "port": 8081, "command": "flutter run"}]
```

### Resolved Domains JSON (start-runtimes.sh input)
```json
{
  "domains": {
    "frontend": {
      "template": "evaluator-frontend",
      "runtime": ["flutter run -d chrome --web-port=8080"],
      "ready_check": {"type": "http", "url": "http://localhost:8080", "timeout_ms": 60000, "retry_interval_ms": 2000}
    }
  },
  "runtime_order": ["backend", "frontend"]
}
```

### Exit Codes (start-runtimes.sh)
- 0: runtime started and ready
- 1: app failed to start (implementation bug)
- 2: invalid input (missing config, bad args)
- 3: harness failure (port conflict, missing dep)

### Ready Check Types
- `http`: Poll URL until expected status code. Fields: url, expect_status (default 200), timeout_ms, retry_interval_ms
- `tcp`: Poll port until connection accepted. Fields: port, timeout_ms, retry_interval_ms
- `command`: Run command, wait for exit 0. Fields: command, timeout_ms, retry_interval_ms
- Default: tcp on port 8080

### Frontend Evaluator Dimensions
Visual Quality (threshold 7), Craft (threshold 7), Functionality (threshold 8), Domain Spec Fidelity (threshold 8)

### Backend Evaluator Dimensions
Correctness (threshold 7), API Contract Fidelity (threshold 7), Error Handling (threshold 7), Domain Spec Fidelity (threshold 8)

## Deliverables
- [x] Scripts: start-runtimes, stop-runtimes
- [x] Foundational: evaluator-frontend, evaluator-backend, runtime-evidence skill
- [x] Develop skill runtime lifecycle
- [x] Integration test with running app
