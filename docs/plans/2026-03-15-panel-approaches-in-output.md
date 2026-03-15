# Panel Approaches in Output Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an `### Approaches` section to the panel output format so users see what was debated.

**Architecture:** Single file edit to `skills/panel/SKILL.md` — update the Output Format template and the anti-rationalization check that enumerates required sections.

**Tech Stack:** Markdown skill files

---

### Task 1: Add Approaches section to panel Output Format

**Files:**
- Modify: `skills/panel/SKILL.md:149-170` (Output Format section)
- Modify: `skills/panel/SKILL.md:188` (Anti-Rationalization Check #4)

**Step 1: Update the Output Format template**

In `skills/panel/SKILL.md`, replace the Output Format code block (lines 151-168) to insert `### Approaches` between `## Debate: <topic>` and `### Consensus`:

```markdown
## Output Format

Produce exactly this structure:

```markdown
## Debate: <topic>

### Approaches

**Approach 1: <name>**
<full approach text as provided by caller or generated in standalone mode>

**Approach 2: <name>**
<full approach text>

[...for each approach]

### Consensus
- [Points where all participants agree]

### Majority (2/3)
- [Points where 2 of 3 agree, with noted dissent]
- "Claude and Codex prefer X. Gemini argues Y because..."

### No consensus
- [Points of unresolved disagreement]
- Include tradeoffs for each position

### Recommendation
Based on the above, I recommend [approach] because [reasoning].
[Note key dissents and why they don't apply / do apply here.]
```

In degraded mode (2 participants), use "Both agree" / "Disagreement" instead of Majority.
```

**Step 2: Update Anti-Rationalization Check #4**

Replace line 188:
- Old: `4. **Does the output have all four sections?** Consensus, Majority, No consensus, Recommendation — all four MUST be present. Use "None" for empty sections.`
- New: `4. **Does the output have all five sections?** Approaches, Consensus, Majority, No consensus, Recommendation — all five MUST be present. Use "None" for empty sections.`

**Step 3: Verify the edit**

Read the file to confirm the Output Format section and check #4 are correct.

**Step 4: Commit**

```bash
git add skills/panel/SKILL.md
git commit -m "feat: include approaches in panel output format"
```

Acceptance criteria:
- Output Format template includes `### Approaches` section between `## Debate:` and `### Consensus`
- Anti-rationalization check #4 references five sections including Approaches
- No other sections or behavior changed
