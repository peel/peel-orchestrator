---
# fiddle-hl32
title: 'M5-T7: Integration test — full calibration loop'
status: done
type: task
priority: normal
created_at: 2026-03-29T19:23:24Z
updated_at: 2026-03-29T19:23:25Z
parent: fiddle-fq08
blocked_by:
    - fiddle-88ir
    - fiddle-xafx
    - fiddle-16rn
    - fiddle-rksw
---

Plan: docs/superpowers/plans/2026-03-29-calibrated-evaluator-m5.md Task 7
Test: attended correction → anchor encoding → next eval uses anchor.
Test: antipattern added → loaded by implementer + evaluator.
Verify compound learning loop works across runs.

## Integration Test Report — Full Calibration Loop (2026-03-30)

### Trace 1: Attended Correction Flow

**Path:** `orchestrate.json` `evaluators.attended: true` → SKILL.md step 1i → human corrects score → calibration anchor written → SKILL.md step 1f position 3 → evaluator loads calibration file

| Step | Document | Location | Status |
|---|---|---|---|
| Attended gate check | `skills/develop/SKILL.md` | Step 1i, line 284-303 | PASS — HARD-GATE checks `evaluators.attended` from orchestrate.json |
| Show merged scorecard | `skills/develop/SKILL.md` | Step 1i, line 289-291 | PASS — Shows all dimensions, highlights below-threshold and disagreements |
| Record correction | `skills/develop/SKILL.md` | Step 1i, line 295 | PASS — Records {domain, dimension, evaluator_score, human_score, reason} |
| Update scorecard | `skills/develop/SKILL.md` | Step 1i, line 296 | PASS — Corrected score replaces evaluator score in scorecard.json |
| Encode anchor | `skills/develop/SKILL.md` | Step 1i, line 297 + lines 305-320 | PASS — Writes anchor to calibration file with markdown format |
| Locate calibration file | `skills/develop/SKILL.md` | Step 1i, line 309 | PASS — Reads from orchestrate.json key, defaults to `docs/evaluator-calibration-<domain>.md` |
| Load calibration on next eval | `skills/develop/SKILL.md` | Step 1f, line 185 (context position 3) | **FIXED** — Was skipping default path if config key absent; now checks default `docs/evaluator-calibration-<domain>.md` |
| Log corrections | `skills/develop/SKILL.md` | Step 1l, line 385 | **FIXED** — `append-eval-log.sh` was missing `--corrections` parameter |

**Verified field toggle:** Set `evaluators.attended: true` in orchestrate.json, confirmed valid JSON parse, restored to `false`.

### Trace 2: Antipattern Flow

**Path:** `orchestrate.json` `evaluators.domains.<domain>.antipatterns` → SKILL.md step 1d → implementer gets `{ANTIPATTERNS}` AND SKILL.md step 1f position 8 → evaluator gets `{ANTIPATTERNS}`

| Step | Document | Location | Status |
|---|---|---|---|
| Antipattern config source | `orchestrate.json` | `evaluators.domains.<domain>.antipatterns` | PASS — Key is optional, path is relative to project root |
| Implementer loading | `skills/develop/SKILL.md` | Step 1d, lines 129-131 | PASS — Reads from all resolved domains, concatenates, injects into `{ANTIPATTERNS}` |
| Implementer template | `skills/develop/implementer-prompt.md` | Line 19-23 | PASS — "Known Antipatterns" section with `{ANTIPATTERNS}` placeholder |
| Evaluator loading | `skills/develop/SKILL.md` | Step 1f position 8, line 190 | PASS — Reads from orchestrate.json config, injects into evaluator `{ANTIPATTERNS}` |
| Evaluator template | `skills/evaluate/SKILL.md` | Lines 47-56, "Antipattern Checking" | PASS — `{ANTIPATTERNS}` placeholder with detection/scoring instructions |
| Antipattern detection output | `skills/evaluate/SKILL.md` | Line 101, 115 | PASS — `antipatterns_detected` array in scorecard JSON |
| Deliver creates antipatterns | `skills/deliver/SKILL.md` | Step 4c, lines 117-128 | **FIXED** — Was missing orchestrate.json wiring instruction |

### Trace 3: Calibration-Antipattern Compound Loop

**Full cycle:** Deliver step 4b writes calibration anchors → Deliver step 4c writes antipatterns → Next develop run loads both

| Integration Point | Status |
|---|---|
| Deliver 4b → Develop 1f pos 3 (calibration) | **FIXED** — Deliver now instructs wiring orchestrate.json; Develop now also checks default path |
| Deliver 4c → Develop 1d + 1f pos 8 (antipatterns) | **FIXED** — Deliver now instructs wiring orchestrate.json `evaluators.domains.<domain>.antipatterns` |
| Attended 1i → next eval 1f pos 3 (same-session loop) | **FIXED** — Develop now checks default path even without config key |

### Gaps Found and Fixed

1. **`append-eval-log.sh` missing `--corrections` parameter** — SKILL.md step 1l references `--corrections {corrections_json}` but the script did not accept this flag. Added `--corrections` parameter with jq formatting for human correction entries.

2. **Calibration file not loaded from default path** — Step 1i writes anchors to default `docs/evaluator-calibration-<domain>.md` when no config key exists, but step 1f only loaded calibration when the config key was present. Fixed step 1f to also check the default path when the config key is absent.

3. **Deliver SKILL.md does not wire orchestrate.json for antipatterns** — Step 4c creates `docs/antipatterns-<domain>.md` but did not instruct updating `orchestrate.json` with the `antipatterns` path. Added wiring instruction.

4. **Deliver SKILL.md does not wire orchestrate.json for calibration** — Step 4b creates calibration files but did not instruct updating `orchestrate.json` with the `calibration` path. Added wiring instruction.

### Files Changed

- `scripts/append-eval-log.sh` — Added `--corrections` parameter support
- `skills/develop/SKILL.md` — Fixed calibration loading to check default path; updated M5 simplifications note
- `skills/deliver/SKILL.md` — Added orchestrate.json wiring instructions for calibration (4b) and antipatterns (4c)
