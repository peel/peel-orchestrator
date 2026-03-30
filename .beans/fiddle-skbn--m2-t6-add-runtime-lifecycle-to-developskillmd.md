---
# fiddle-skbn
title: 'M2-T6: Add runtime lifecycle to develop/SKILL.md'
status: completed
type: task
priority: normal
created_at: 2026-03-29T19:21:53Z
updated_at: 2026-03-30T07:14:43Z
parent: fiddle-seov
blocked_by:
    - fiddle-zr8a
    - fiddle-rt3a
    - fiddle-b3x4
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m2.md Task 6

Update develop skill to start/stop runtimes around evaluator dispatch when runtime is configured.

Files:
- Modify: skills/develop/SKILL.md

Steps:
1. Add runtime lifecycle HARD-GATE to per-task evaluation section:
   - If domain has runtime configured: run scripts/start-runtimes.sh before evaluator dispatch
   - After evaluation: run scripts/stop-runtimes.sh
   - Handle exit 3 (harness failure): retry once, then escalate without counting against dispatch budget
2. Update evaluator dispatch to include skills/runtime-evidence/SKILL.md in evaluator context alongside domain template
3. Update evaluator dispatch to include runtime_agent and stack_agents: if configured for the domain, read agent files and include content in evaluator prompt context
4. Verify HARD-GATE count increased: grep -c 'HARD-GATE' skills/develop/SKILL.md — expect previous count + 1
5. Commit


## Evaluation Log
BASE_SHA: 8068edfeb4c047a5ea880b4dcf07570cf5f44caa
total_dispatches: 3

### Iteration 1 (2026-03-30T07:13:34Z)
dispatches: 1
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "PASS_PENDING."

### Iteration 2 (2026-03-30T07:14:35Z)
dispatches: 2
**general:**
- correctness: 9/10
- domain_spec_fidelity: 9/10
- code_quality: 8/10
**Guidance:** "CONVERGED."


## Summary of Changes

Updated `skills/develop/SKILL.md` to add runtime lifecycle management.

**Changes:**
- Added HARD-GATE at step 1e: start-runtimes.sh before evaluator dispatch, stop-runtimes.sh after, with exit code handling (0=proceed, 3=retry once, 1/2=include error)
- Evaluator dispatch now includes runtime-evidence/SKILL.md and runtime state in context
- Evaluator dispatch includes runtime_agent/stack_agents if configured
- M1 Simplifications "No runtime" line struck through with M2 note

**Evaluator convergence:** 2 iterations (correctness 9/7, domain spec fidelity 9/8, code quality 8/6).
