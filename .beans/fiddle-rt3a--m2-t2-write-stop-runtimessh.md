---
# fiddle-rt3a
title: 'M2-T2: Write stop-runtimes.sh'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:21:53Z
updated_at: 2026-03-30T06:54:27Z
parent: fiddle-seov
blocked_by:
    - fiddle-zr8a
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m2.md Task 2

Stops runtime processes started by start-runtimes.sh.

Files:
- Create: scripts/stop-runtimes.sh
- Create: scripts/test-stop-runtimes.sh

Steps:
1. Write test: start background process, record PID, call stop-runtimes.sh with runtime state JSON, verify process is stopped
2. Run test — verify it fails (script doesn't exist)
3. Write stop-runtimes.sh: accept --state <runtime-state.json>, SIGTERM each PID, wait for shutdown, SIGKILL after 10s fallback, exit 0
4. Run test — verify it passes
5. Commit

See parent epic Contracts for Runtime State JSON format (input to this script).


## Evaluation Log
BASE_SHA: c5d5f2d16171e7f90383bccfb5f83c5de43d0367
total_dispatches: 6

### Iteration 1 (2026-03-30T06:47:43Z)
dispatches: 1
**general:**
- correctness: 6/10 (FAIL, threshold 7)
- domain_spec_fidelity: 7/10 (FAIL, threshold 8)
- code_quality: 7/10
**Guidance:** "Two criteria fail. (1) stop-sigkill-fallback: add a test that spawns a process trapping SIGTERM and verify the script still kills it via SIGKILL. (2) stop-input-validation: validate PIDs are positive integers before passing to kill. Guard against --state with no value."

### Iteration 2 (2026-03-30T06:52:16Z)
dispatches: 2
**general:**
- correctness: 8/10
- domain_spec_fidelity: 8/10
- code_quality: 7/10
**Guidance:** "All prior iteration failures addressed. PASS_PENDING — need consecutive pass."

### Iteration 3 (2026-03-30T06:54:21Z)
dispatches: 3
**general:**
- correctness: 8/10
- domain_spec_fidelity: 8/10
- code_quality: 7/10
**Guidance:** "CONVERGED — two consecutive passes, no regressions."


## Summary of Changes

Implemented `scripts/stop-runtimes.sh` — stops runtime processes from a runtime-state JSON file.

**Features:**
- Accepts `--state <runtime-state.json>` with full input validation (missing args, bad file, bad JSON, bad PIDs → exit 2)
- SIGTERM each PID with per-PID 10s grace period, then SIGKILL fallback
- Graceful handling of already-dead processes (exit 0)
- PID validation rejects zero, negative, and non-numeric values
- Structured JSON error messages to stderr

**Tests:** 12 test scenarios, 21 assertions — covers input validation, single/multi process stop, dead process, SIGKILL fallback with timing verification.

**Evaluator convergence:** 3 iterations (correctness 8/7, domain spec fidelity 8/8, code quality 7/6).
