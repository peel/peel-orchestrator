# Calibrated Evaluator System — Milestone 2: Runtime Verification

> **For agentic workers:** REQUIRED SUB-SKILL: Use fiddle:develop to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add runtime evaluation — evaluators launch and interact with the running app using project-configured MCP tools.

**Architecture:** Orchestrator starts/stops the app via scripts. Evaluator subagent uses available MCP tools (marionette, curl, go-dev-mcp) to interact with the running app and gather evidence. Domain-specific evaluator templates (frontend, backend) replace the general template for typed projects.

**Tech Stack:** Bash scripts (jq), Markdown skills, project MCP tools

**Depends on:** Milestone 1 (core evaluator loop must be working)

---

### Task 1: Write start-runtimes.sh

Starts runtime processes for evaluation with ready-check polling.

**Files:**
- Create: `scripts/start-runtimes.sh`

- [ ] **Step 1: Write the test**

Test script that:
- Starts a simple HTTP server (`python3 -m http.server`)
- Verifies start-runtimes.sh detects readiness via TCP check
- Verifies exit codes (0 = started, 1 = app fail, 2 = invalid input, 3 = harness fail)
- Verifies runtime state JSON output (pid, port, command)

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/test-start-runtimes.sh`
Expected: FAIL — script does not exist.

- [ ] **Step 3: Write start-runtimes.sh**

The script must:
- Accept `--domains <resolved-domains.json>` and `--slot-index <N>`
- For each domain with runtime configured, start the runtime command in background
- Poll the ready_check (http/tcp/command) with timeout and retry
- Respect `runtime_order` if present (start backends before frontends)
- Output runtime state JSON: `[{"domain":"...", "pid":12345, "port":8080, "command":"..."}]`
- Exit 0 on success, 1 if app fails to start, 2 for invalid input, 3 for harness failure (port conflict, missing dep)

- [ ] **Step 4: Run test to verify it passes**

Run: `bash scripts/test-start-runtimes.sh`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/start-runtimes.sh scripts/test-start-runtimes.sh
git commit -m "feat: add start-runtimes.sh with ready-check polling

Starts runtime processes, polls readiness (http/tcp/command),
respects runtime_order for multi-domain. Exit codes distinguish
app failure (1) from harness failure (3)."
```

---

### Task 2: Write stop-runtimes.sh

Stops runtime processes started by start-runtimes.sh.

**Files:**
- Create: `scripts/stop-runtimes.sh`

- [ ] **Step 1: Write the test**

Test that:
- Starts a background process, records its PID
- Calls stop-runtimes.sh with the runtime state JSON
- Verifies process is stopped

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write stop-runtimes.sh**

Accept `--state <runtime-state.json>`. SIGTERM each PID. Wait for shutdown. SIGKILL after 10s fallback. Exit 0.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add scripts/stop-runtimes.sh scripts/test-stop-runtimes.sh
git commit -m "feat: add stop-runtimes.sh for runtime teardown

SIGTERM with 10s SIGKILL fallback. Accepts runtime state JSON
from start-runtimes.sh."
```

---

### Task 3: Write evaluator-frontend.md domain template

Flutter-focused frontend evaluator template with Visual Quality, Craft, Functionality, Domain Spec Fidelity — full 1-10 scales.

**Files:**
- Create: `skills/evaluate/evaluator-frontend.md`

- [ ] **Step 1: Write evaluator-frontend.md**

Copy the full 1-10 scales from the design spec (lines 75-169) for all four frontend dimensions:
- Visual Quality (threshold 7)
- Craft (threshold 7)
- Functionality (threshold 8)
- Domain Spec Fidelity (threshold 8)

Add a **Runtime Interaction** section specific to frontend:
- Launch the app and visually inspect it
- Use available MCP tools (marionette for Flutter, curl for web, etc.)
- Take screenshots at relevant states
- Exercise key interactions (navigation, input, responsive behavior)
- Check for visual consistency with design references

- [ ] **Step 2: Verify line count**

Run: `wc -l skills/evaluate/evaluator-frontend.md`
Expected: ~150-180 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/evaluate/evaluator-frontend.md
git commit -m "feat: add evaluator-frontend.md with full 1-10 scales

Visual Quality, Craft, Functionality, Domain Spec Fidelity.
Runtime interaction guidance for frontend evaluation."
```

---

### Task 4: Write evaluator-backend.md domain template

Go API-focused backend evaluator template with Correctness, API Contract Fidelity, Error Handling, Domain Spec Fidelity.

**Files:**
- Create: `skills/evaluate/evaluator-backend.md`

- [ ] **Step 1: Write evaluator-backend.md**

Copy full 1-10 scales from design spec (lines 175-247) for all four backend dimensions:
- Correctness (threshold 7)
- API Contract Fidelity (threshold 7)
- Error Handling (threshold 7)
- Domain Spec Fidelity (threshold 8)

Add a **Runtime Interaction** section specific to backend:
- Start the server and hit API endpoints
- Use curl/httpie for HTTP verification
- Check response shapes, status codes, headers
- Test error paths (invalid input, missing resources)
- Verify database state if applicable

- [ ] **Step 2: Verify line count**

Run: `wc -l skills/evaluate/evaluator-backend.md`
Expected: ~150-180 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/evaluate/evaluator-backend.md
git commit -m "feat: add evaluator-backend.md with full 1-10 scales

Correctness, API Contract Fidelity, Error Handling, Domain Spec Fidelity.
Runtime interaction guidance for API evaluation."
```

---

### Task 5: Write runtime-evidence/SKILL.md

Foundational skill providing runtime evidence gathering guidance. Loaded alongside the domain template into the evaluator's context.

**Files:**
- Create: `skills/runtime-evidence/SKILL.md`

- [ ] **Step 1: Write the skill**

Content:
- Frontmatter: `name: fiddle:runtime-evidence`
- What runtime evidence means: interacting with the RUNNING app, not just reading code
- HARD-GATE: if runtime is configured, you MUST interact with the app before scoring
- How to gather evidence: screenshots, HTTP responses, console output, interaction results
- Evidence format: structured description of what was observed
- Common patterns per stack (guidance, not requirements):
  - Flutter: marionette MCP for widget interaction
  - Go API: curl for endpoint verification, go-dev-mcp for tooling
  - Web frontend: browser tools, curl for dev server
- Distinguishing app failure from harness failure: if the app won't start, that's evaluation-relevant (score Functionality 1-2); if the evaluator's tools won't work, that's harness failure (escalate, don't score)

Target: ~80-100 lines.

- [ ] **Step 2: Verify**

Run: `wc -l skills/runtime-evidence/SKILL.md`
Expected: 80-100 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/runtime-evidence/
git commit -m "feat: add runtime-evidence skill for evaluator runtime guidance

Foundational skill: how to gather runtime evidence, evidence format,
stack-specific interaction patterns, failure classification."
```

---

### Task 6: Add runtime support to develop/SKILL.md

Update the develop skill to start/stop runtimes around evaluator dispatch when runtime is configured.

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Add runtime lifecycle HARD-GATE**

Add to the develop skill, in the per-task evaluation section:

```markdown
<HARD-GATE>
If the task's domain has runtime configured in orchestrate.json, you MUST run:
  scripts/start-runtimes.sh --domains resolved.json --slot-index 0
before dispatching the evaluator.
After evaluation completes:
  scripts/stop-runtimes.sh --state runtime-state.json
Handle exit code 3 (harness failure): retry once, then escalate without counting against dispatch budget.
Do NOT skip runtime. Do NOT let evaluators assess without runtime evidence.
</HARD-GATE>
```

- [ ] **Step 2: Update evaluator dispatch to include runtime-evidence skill**

When dispatching the evaluator, include `skills/runtime-evidence/SKILL.md` in the evaluator's context alongside the domain template.

- [ ] **Step 3: Update evaluator dispatch to include runtime_agent and stack_agents**

If `runtime_agent` or `stack_agents` are configured for the domain, read the referenced agent files and include their content in the evaluator's prompt context.

- [ ] **Step 4: Verify HARD-GATE count increased**

Run: `grep -c 'HARD-GATE' skills/develop/SKILL.md`
Expected: Previous count + 1 (runtime gate added).

- [ ] **Step 5: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "feat: add runtime lifecycle to develop evaluator loop

Start/stop runtimes around evaluator dispatch. Harness failure
handling (exit 3: retry once, then escalate). Runtime-evidence
skill and runtime_agent/stack_agents loaded into evaluator context."
```

---

### Task 7: Integration test — runtime evaluation end-to-end

Test the full loop with a running app. Use a simple HTTP server as the "app."

**Files:**
- No new files

- [ ] **Step 1: Create test config with runtime**

Create a temporary `orchestrate.json` with runtime configured for a simple Python HTTP server.

- [ ] **Step 2: Verify start-runtimes.sh + stop-runtimes.sh lifecycle**

Start a Python HTTP server, verify ready check passes, verify evaluator can curl it, stop it.

- [ ] **Step 3: Verify evaluator can interact with running server**

Dispatch an evaluator subagent with the runtime-evidence skill loaded. Verify it actually makes HTTP requests to the running server and includes the results in its scorecard evidence.

- [ ] **Step 4: Clean up**

Stop any running processes, restore original config.
