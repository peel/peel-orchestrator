# Calibrated Evaluator System — Milestone 3: Multi-Domain + Holistic Review

> **For agentic workers:** REQUIRED SUB-SKILL: Use fiddle:develop to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tasks spanning multiple domains (frontend + backend) get evaluated per-domain. Holistic review catches cross-task integration issues after all tasks complete.

**Architecture:** resolve-domains.sh parses Evaluation blocks and looks up per-domain config. Evaluators run per-domain, scorecards merged (union, each domain independent). Holistic reviewer runs after all tasks with full app + spec coverage matrix. Remediation beans generated for coverage gaps.

**Tech Stack:** Bash scripts (jq), Markdown skills, beans CLI

**Depends on:** Milestone 2 (runtime verification must be working)

---

### Task 1: Write resolve-domains.sh

Parse a task's domain list and resolve each to full evaluator config from orchestrate.json.

**Files:**
- Create: `scripts/resolve-domains.sh`

- [ ] **Step 1: Write the test**

Test with:
- Single domain: `--domains "general"` → resolves to general config
- Multiple domains: `--domains "frontend,backend"` → both resolved
- Unknown domain: → fallback to general with `resolved_via: "fallback"`
- Invalid input: → exit 1

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write resolve-domains.sh**

Accept `--domains "frontend,backend"` and `--config <orchestrate.json>`. For each domain:
- Look up in `evaluators.domains.<name>`
- If found: return full config with `resolved_via: "config"`
- If not found: return evaluator-general defaults with `resolved_via: "fallback"`

Output JSON array of resolved domain configs.
Exit 0 = all resolved (including fallbacks), 1 = invalid input.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add scripts/resolve-domains.sh scripts/test-resolve-domains.sh
git commit -m "feat: add resolve-domains.sh for multi-domain evaluation

Resolves task domain list to full evaluator config from orchestrate.json.
Unknown domains fall back to evaluator-general with fallback marker."
```

---

### Task 2: Update develop/SKILL.md for multi-domain evaluation

Add domain resolution step, per-domain evaluator dispatch, cross-domain merge.

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Add domain resolution HARD-GATE**

Before evaluator dispatch:
```markdown
<HARD-GATE>
Before dispatching any evaluator, you MUST run:
  scripts/resolve-domains.sh --domains "{task domains}" --config orchestrate.json
Use the script's output to configure evaluators. Do NOT resolve domains manually.
</HARD-GATE>
```

- [ ] **Step 2: Update evaluator dispatch for multi-domain**

For each resolved domain:
- Start runtime for that domain (if configured, respecting runtime_order from eval block)
- Dispatch evaluator with that domain's template + config
- Collect scorecard per domain

- [ ] **Step 3: Update merge step**

After all domain evaluators return:
- Union scorecards across domains (each domain scored independently)
- No shared dimensions — domain_spec_fidelity in frontend ≠ domain_spec_fidelity in backend
- Each domain must independently meet its own thresholds
- On failure, feedback identifies which domain(s) failed

- [ ] **Step 4: Add runtime_order handling**

Parse `runtime_order` from the task's eval block. Start runtimes in specified order. Default: order listed in `domains`.

- [ ] **Step 5: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "feat: add multi-domain evaluation to develop loop

Domain resolution via resolve-domains.sh. Per-domain evaluator dispatch.
Cross-domain merge (union, each domain independent). Runtime ordering
via runtime_order field in eval block."
```

---

### Task 3: Separate domain spec fidelity from holistic spec fidelity

Ensure task evaluators score `domain_spec_fidelity` (task-local) and the holistic reviewer scores `holistic_spec_fidelity` (system-level). These are never merged.

**Files:**
- Modify: `skills/evaluate/evaluator-frontend.md` (verify dimension name is `domain_spec_fidelity`)
- Modify: `skills/evaluate/evaluator-backend.md` (verify dimension name is `domain_spec_fidelity`)
- Modify: `skills/evaluate/evaluator-general.md` (verify dimension name is `domain_spec_fidelity`)

- [ ] **Step 1: Verify all domain templates use `domain_spec_fidelity`**

```bash
grep -r "spec_fidelity" skills/evaluate/
```

Ensure no template uses plain `spec_fidelity` — all must use `domain_spec_fidelity`.

- [ ] **Step 2: Fix if needed, commit**

---

### Task 4: Write holistic-review.md

Foundational skill for the holistic reviewer team member. Full 1-10 scales for holistic dimensions, spec coverage matrix protocol, remediation bean generation.

**Files:**
- Create: `skills/develop/holistic-review.md`

- [ ] **Step 1: Write the skill**

Content:
- Holistic dimensions with full 1-10 scales:
  - Integration (threshold 7)
  - Coherence (threshold 7)
  - Holistic Spec Fidelity (threshold 8)
  - Polish (threshold 6)
  - Runtime Health (threshold 9)
- Spec coverage matrix: how to produce it (every spec requirement → Full/Weak/Missing + evidence)
- Remediation bean generation: for each "Missing" or failing dimension, generate a remediation bean with its own eval block
- Cross-domain integration check: does frontend correctly consume backend API?
- HARD-GATE: must launch ALL domain runtimes and interact before scoring

Target: ~150-200 lines.

- [ ] **Step 2: Commit**

```bash
git add skills/develop/holistic-review.md
git commit -m "feat: add holistic-review.md with full 1-10 scales

Integration, Coherence, Holistic Spec Fidelity, Polish, Runtime Health.
Spec coverage matrix protocol. Remediation bean generation for gaps."
```

---

### Task 5: Wire holistic review into develop/SKILL.md

After all tasks complete, dispatch holistic reviewer. Handle remediation loop.

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Add holistic review step after all tasks**

After the per-task loop completes:
1. Dispatch holistic reviewer team member with holistic-review.md loaded
2. Pass: full diff (BASE_SHA of first task..HEAD), full spec/design doc, all domain runtimes
3. Reviewer returns: holistic scorecards + spec coverage matrix
4. Check holistic thresholds (from orchestrate.json evaluators.holistic.dimensions)
5. PASS → proceed to finish-branch
6. FAIL → generate remediation beans, run them through per-task loop, re-run holistic review
7. Up to evaluators.holistic.max_iterations (default 3), then escalate

- [ ] **Step 2: Add manual holistic review trigger**

Add note that user can manually trigger holistic review mid-stream by asking.

- [ ] **Step 3: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "feat: wire holistic review after all tasks

Holistic reviewer: full app walkthrough, spec coverage matrix,
cross-domain integration check. Remediation loop up to max_iterations.
Manual mid-stream trigger supported."
```

---

### Task 6: Integration test — multi-domain + holistic review

Test with a task that touches both "frontend" and "backend" domains.

**Files:**
- No new files

- [ ] **Step 1: Configure two domains in orchestrate.json**

Add frontend and backend domain configs (with simple HTTP servers as runtimes).

- [ ] **Step 2: Create a multi-domain test task**

Bean with eval block: `domains: [frontend, backend]` with criteria for each.

- [ ] **Step 3: Verify per-domain evaluation**

Run the evaluator loop. Verify both domains evaluated independently, merge is union.

- [ ] **Step 4: Verify holistic review runs after all tasks**

Run holistic reviewer. Verify it produces coverage matrix and scores holistic dimensions.

- [ ] **Step 5: Clean up**
