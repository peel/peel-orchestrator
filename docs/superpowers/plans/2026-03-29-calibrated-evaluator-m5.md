# Calibrated Evaluator System — Milestone 5: Calibration and Evolve

> **For agentic workers:** REQUIRED SUB-SKILL: Use fiddle:develop to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The compound learning loop — attended mode refines evaluator calibration through human corrections, antipatterns accumulate from real failures, the evolve step encodes improvements for future runs.

**Architecture:** Attended mode shows scorecards to human before acting. Corrections become calibration anchors in project-specific files. Antipattern files loaded by implementer and evaluator. Evolve step (in deliver phase) enriched to update both.

**Tech Stack:** Markdown files (calibration, antipatterns), orchestrate.json config, beans CLI

**Depends on:** Milestone 4 (multi-provider must be working)

---

### Task 1: Implement attended mode gate in develop/SKILL.md

When `evaluators.attended: true`, show scorecards to human before acting on them.

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Add attended gate after merge**

After scorecard merge (step 4 in per-task protocol), before convergence check:

```markdown
<HARD-GATE>
IF evaluators.attended is true in orchestrate.json:
  Show the merged scorecard to the human.
  Highlight:
    - Any dimension below threshold (with score and threshold)
    - Provider disagreements (if multi-provider)
    - Domain-specific failures
  Ask: "Do you agree with these scores? Correct any you disagree with."

  If human corrects a score:
    - Record correction: {dimension, evaluator_score, human_score, reason}
    - Use human score for threshold/convergence check
    - Pass correction to calibration encoding (step below)

  If human confirms: proceed with evaluator scores.
</HARD-GATE>
```

- [ ] **Step 2: Add calibration anchor encoding**

When human corrects a score, append an anchor to the project's calibration file:

```markdown
## [dimension] — Correction (date)
**Evaluator scored:** X/10 — "[evaluator evidence]"
**Human corrected to:** Y/10 — "[human reason]"
**Anchor:** For this project, score Y means: [human's description]
```

Read calibration file path from `evaluators.domains.<domain>.calibration` in orchestrate.json. Create the file if it doesn't exist.

- [ ] **Step 3: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "feat: add attended mode gate with calibration encoding

Shows scorecards to human before acting. Human corrections
encoded as calibration anchors in project calibration file."
```

---

### Task 2: Add antipattern loading and checking

Load antipattern files into implementer and evaluator prompts. Evaluator checks for known antipatterns.

**Files:**
- Modify: `skills/develop/SKILL.md`
- Modify: `skills/develop/implementer-prompt.md`
- Modify: `skills/evaluate/SKILL.md`

- [ ] **Step 1: Update implementer prompt to include antipatterns**

In `implementer-prompt.md`, add a section after the task context:

```markdown
## Known Antipatterns — Avoid These

{ANTIPATTERNS}

These are real failures from prior runs. Check your implementation against each one before reporting DONE.
```

The orchestrator reads `evaluators.domains.<domain>.antipatterns` from orchestrate.json, reads the file content, and injects it into the `{ANTIPATTERNS}` placeholder.

- [ ] **Step 2: Update evaluator protocol to check antipatterns**

In `skills/evaluate/SKILL.md`, add:

```markdown
## Antipattern Check

If an antipatterns file is loaded in your context, check each antipattern:
- Does the current implementation exhibit this known failure?
- Report detected antipatterns in your scorecard under `antipatterns_detected`
- Any detected antipattern is grounds for failing the task

{ANTIPATTERNS}
```

- [ ] **Step 3: Update develop skill to load antipattern files**

Read antipatterns file path from domain config. Pass content to both implementer and evaluator prompts.

- [ ] **Step 4: Commit**

```bash
git add skills/develop/SKILL.md skills/develop/implementer-prompt.md skills/evaluate/SKILL.md
git commit -m "feat: load antipatterns into implementer and evaluator

Implementer: 'avoid these known failures' section.
Evaluator: antipattern check, any detection = task fail.
Files loaded from evaluators.domains.<domain>.antipatterns config."
```

---

### Task 3: Add calibration anchor loading

Load project-specific calibration files into evaluator prompts alongside the domain template.

**Files:**
- Modify: `skills/develop/SKILL.md`

- [ ] **Step 1: Update evaluator dispatch**

When dispatching evaluator, check if `evaluators.domains.<domain>.calibration` is configured. If so, read the file and include it in the evaluator's context after the domain template:

```
Evaluator receives:
1. skills/evaluate/SKILL.md (protocol)
2. skills/evaluate/evaluator-<domain>.md (domain template with generic anchors)
3. docs/evaluator-calibration-<domain>.md (project-specific anchors, if exists)
4. skills/runtime-evidence/SKILL.md (if runtime configured)
5. runtime_agent / stack_agents content (if configured)
6. Task criteria from eval block
7. Prior scorecards (if iteration 2+)
8. Antipatterns file (if configured)
```

- [ ] **Step 2: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "feat: load project calibration files into evaluator context

Project-specific calibration anchors loaded alongside domain template.
Order: protocol → domain template → calibration → runtime → criteria."
```

---

### Task 4: Update brainstorm skill to generate initial calibration

When brainstorming produces a design spec with visual/behavioral descriptions, extract calibration anchors.

**Files:**
- Modify: `skills/brainstorm/SKILL.md`

- [ ] **Step 1: Verify calibration extraction step exists**

Check that Task 12 from M1 (brainstorm fork) already added the calibration extraction step. If so, verify it works by reading the skill and confirming the step is present.

- [ ] **Step 2: Test by running brainstorm on a sample topic**

Run the brainstorm skill on a small topic. Verify it produces a spec AND generates initial calibration anchors file.

- [ ] **Step 3: Fix if needed, commit**

---

### Task 5: Enrich deliver/SKILL.md evolve step

Update the deliver skill's evolve step to cover evaluator artifact updates.

**Files:**
- Modify: `skills/deliver/SKILL.md`

- [ ] **Step 1: Add evaluator evolve section**

After the existing evolve/feedback section, add:

```markdown
## Evaluator Evolve

After delivery, review the evaluation artifacts from this run:

1. **Review scorecards**: Present the evaluator scorecards from the run.
   Ask the human: "Where did the evaluator get it wrong?"

2. **Update calibration**: For each correction:
   - Add to `docs/evaluator-calibration-<domain>.md`
   - Format: score level + concrete example from this project

3. **Add antipatterns**: For each real failure found post-delivery:
   - Append to `docs/antipatterns-<domain>.md`
   - Format: one line per antipattern with date

4. **Adjust thresholds**: If evaluator was consistently too strict or lenient:
   - Update threshold in `orchestrate.json` evaluators.domains.<domain>.thresholds

5. **Review iteration counts**: High iteration counts (>5) suggest calibration gaps.
   Focus calibration updates on the dimensions that caused the most iterations.
```

- [ ] **Step 2: Commit**

```bash
git add skills/deliver/SKILL.md
git commit -m "feat: enrich deliver evolve step for evaluator artifacts

Evolve step now covers: scorecard review, calibration updates,
antipattern additions, threshold adjustments. Feeds forward into
next run's evaluator context."
```

---

### Task 6: Add attended/unattended toggle documentation

Document how to flip between attended and unattended modes.

**Files:**
- Modify: `orchestrate.json` (document the `attended` field)

- [ ] **Step 1: Verify attended field exists in orchestrate.json**

```bash
jq '.evaluators.attended' orchestrate.json
```
Expected: `true` or `false`

- [ ] **Step 2: Add to fiddle docs**

If not already documented, add a note in the relevant docs about the attended/unattended progression:
- Start with `attended: true`
- After several runs, when evaluator judgment aligns with human, set `attended: false`
- Periodic spot-checks at evolve step

No new files needed — this is documentation in existing places.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "docs: document attended/unattended evaluator progression

attended: true for initial calibration runs. Flip to false when
evaluator judgment is trusted. Periodic spot-checks at evolve."
```

---

### Task 7: Integration test — full calibration loop

Test the complete calibration cycle: attended correction → anchor encoding → next evaluation uses anchor.

**Files:**
- No new files

- [ ] **Step 1: Set up attended mode**

Set `evaluators.attended: true` in orchestrate.json.

- [ ] **Step 2: Run evaluation, correct a score**

Run a task through the evaluator loop. When scorecard is presented, correct a dimension score. Verify correction is encoded as calibration anchor in the calibration file.

- [ ] **Step 3: Run second evaluation, verify anchor loaded**

Run another task. Verify the evaluator's context includes the calibration file with the anchor from step 2.

- [ ] **Step 4: Add an antipattern, verify it's loaded**

Manually add an antipattern to the antipatterns file. Run evaluation. Verify both implementer and evaluator received the antipattern in their context.

- [ ] **Step 5: Clean up**

Restore original orchestrate.json settings if changed.
