# Calibrated Evaluator System — Milestone 4: Multi-Provider Evaluation

> **For agentic workers:** REQUIRED SUB-SKILL: Use fiddle:develop to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Multiple LLM providers (Claude, Codex, Gemini) evaluate each task for diversity of judgment. Minimum score per dimension wins.

**Architecture:** Per-domain provider list in orchestrate.json. Evaluators dispatched per provider (Claude via Agent, external via dispatch-provider.sh). merge-scorecards.sh combines results. Disagreements (3+ spread) surfaced.

**Tech Stack:** Bash scripts (jq), hooks/dispatch-provider.sh, Markdown skills

**Depends on:** Milestone 3 (multi-domain + holistic review must be working)

---

### Task 1: Write merge-scorecards.sh

Merge multiple provider scorecards into one. Minimum score per dimension wins.

**Files:**
- Create: `scripts/merge-scorecards.sh`

- [ ] **Step 1: Write the test**

Test with:
- Two providers, same domain: min scores used, disagreements detected (spread 3+)
- Single provider: passthrough (no merging needed)
- Multi-domain: each domain merged independently
- Malformed input: exit 2

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write merge-scorecards.sh**

Accept JSON array of canonical scorecards on stdin. For each domain:
- Group scorecards by domain
- For each dimension: take minimum score across providers
- Record provider_scores per dimension
- Detect disagreements (spread >= 3) → emit to stderr
- Merge criteria: if any provider says fail, it's fail
- Output merged scorecard JSON (canonical merged format from spec)

Exit 0 = merged, 2 = invalid input.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add scripts/merge-scorecards.sh scripts/test-merge-scorecards.sh
git commit -m "feat: add merge-scorecards.sh — minimum score per dimension

Merges multi-provider scorecards. Min score wins per dimension.
Disagreements (3+ spread) emitted to stderr. Criteria: any fail = fail."
```

---

### Task 2: Update develop/SKILL.md for multi-provider dispatch

Dispatch evaluators per provider for each domain. Merge before threshold check.

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Add per-provider dispatch logic**

For each resolved domain, read `providers` array from domain config (default: `["claude"]`). For each provider:
- `claude`: dispatch via Agent tool
- External providers (codex, gemini): dispatch via `hooks/dispatch-provider.sh`

All providers receive the same context: evaluation protocol + domain template + calibration + diff + task criteria.

External providers must output canonical scorecard JSON. The provider context template (`skills/develop/provider-context.md`) must be updated to demand JSON scorecard output format.

- [ ] **Step 2: Add merge HARD-GATE**

After all provider scorecards collected for all domains:
```markdown
<HARD-GATE>
After receiving evaluator scorecards, you MUST run:
  merge-scorecards.sh < scorecards.json
Act on the merged scorecard. Do NOT merge scores yourself.
</HARD-GATE>
```

- [ ] **Step 3: Update dispatch budget tracking**

Each provider dispatch = 1 dispatch toward the budget. Multi-provider evaluation of 2 domains with 2 providers each = 4 dispatches per iteration. `append-eval-log.sh --dispatches` must reflect actual count.

- [ ] **Step 4: Update provider-context.md for scorecard output**

Add to `skills/develop/provider-context.md`:
- Scorecard JSON schema requirements
- "You MUST output a valid JSON scorecard as the last content block"
- Schema validation will reject malformed output

- [ ] **Step 5: Commit**

```bash
git add skills/develop/SKILL.md skills/develop/provider-context.md
git commit -m "feat: add multi-provider evaluation to develop loop

Per-provider dispatch (Claude via Agent, external via dispatch-provider.sh).
Merge via merge-scorecards.sh. Dispatch budget tracks actual provider calls.
Provider context template updated for JSON scorecard output."
```

---

### Task 3: Add disagreement surfacing

When providers disagree (spread 3+), surface in the evaluation log and to the human (in attended mode).

**Files:**
- Modify: `skills/develop/SKILL.md`
- Modify: `scripts/append-eval-log.sh`

- [ ] **Step 1: Update append-eval-log.sh to include disagreements**

Add `--disagreements <file>` parameter. If provided, append disagreement details to the iteration entry in the bean body.

- [ ] **Step 2: Update develop skill attended gate**

In attended mode, when disagreements exist:
- Show each disagreement with provider scores
- Ask human to confirm which score to use
- Encode correction as calibration anchor (preparation for M5)

- [ ] **Step 3: Commit**

```bash
git add scripts/append-eval-log.sh skills/develop/SKILL.md
git commit -m "feat: surface provider disagreements in eval log and attended gate

Disagreements (3+ spread) shown to human in attended mode.
Logged in bean evaluation log for audit trail."
```

---

### Task 4: Update holistic review for multi-provider

Holistic reviewer also dispatches per configured provider.

**Files:**
- Modify: `skills/develop/SKILL.md` (holistic review section)

- [ ] **Step 1: Add provider dispatch to holistic review**

Read `evaluators.holistic.providers` from orchestrate.json. Dispatch holistic reviewer per provider. Merge holistic scorecards via merge-scorecards.sh. Merge coverage matrices (any provider marks Missing → it's Missing).

- [ ] **Step 2: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "feat: add multi-provider to holistic review

Holistic reviewer dispatched per configured provider.
Scorecards merged (min per dimension). Coverage matrices merged
(any Missing → Missing)."
```

---

### Task 5: Integration test — multi-provider evaluation

Test with Claude + a mock external provider.

**Files:**
- No new files

- [ ] **Step 1: Configure multi-provider in orchestrate.json**

Add `"providers": ["claude", "codex"]` to a domain config.

- [ ] **Step 2: Verify dual dispatch and merge**

Run evaluation. Verify both providers dispatched, scorecards merged with minimum, disagreements surfaced if spread >= 3.

- [ ] **Step 3: Verify dispatch budget accounting**

Check that dispatch count reflects actual number of provider calls (2 per domain per iteration).

- [ ] **Step 4: Clean up**
