# Calibrated Evaluator System — Milestone 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove the implement → evaluate → converge loop works end-to-end with a single evaluator, single domain, no runtime verification.

**Architecture:** Replace superpowers' pass/fail review pipeline with scored evaluation. The orchestrator dispatches an implementer subagent, then an evaluator subagent, runs deterministic scripts to check thresholds and convergence, and iterates until converged or budget exceeded. All evaluation state persisted on beans for restart resilience.

**Tech Stack:** Bash scripts (jq for JSON), Markdown skills, beans CLI

**Design doc:** `docs/superpowers/specs/2026-03-29-calibrated-evaluator-system-design.md`

---

### Task 1: Delete swarm infrastructure and move provider template

Remove develop-swarm, patch-superpowers, swarm scripts. Move provider-context.md to its new home. Update dispatch-provider.sh template path.

**Files:**
- Delete: `skills/develop-swarm/` (entire directory)
- Delete: `skills/patch-superpowers/` (entire directory)
- Delete: `scripts/rebase-worker.sh`
- Delete: `scripts/merge-to-integration.sh`
- Delete: `scripts/post-rebase-verify.sh`
- Delete: `scripts/detect-reviewers.sh`
- Delete: `scripts/reset-slot.sh`
- Move: `skills/develop-swarm/roles/provider-context.md` → `skills/develop/provider-context.md`
- Modify: `hooks/dispatch-provider.sh:16`

- [ ] **Step 1: Copy provider-context.md to new location**

```bash
cp skills/develop-swarm/roles/provider-context.md skills/develop/provider-context.md
```

- [ ] **Step 2: Update dispatch-provider.sh template path**

In `hooks/dispatch-provider.sh`, line 16, change:
```bash
TEMPLATE="$PROJECT_DIR/skills/develop-swarm/roles/provider-context.md"
```
to:
```bash
TEMPLATE="$PROJECT_DIR/skills/develop/provider-context.md"
```

- [ ] **Step 3: Delete swarm infrastructure**

```bash
rm -rf skills/develop-swarm/
rm -rf skills/patch-superpowers/
rm -f scripts/rebase-worker.sh scripts/merge-to-integration.sh scripts/post-rebase-verify.sh scripts/detect-reviewers.sh scripts/reset-slot.sh
```

- [ ] **Step 4: Verify dispatch-provider.sh still works**

Run: `hooks/dispatch-provider.sh codex --check`
Expected: `{"provider":"codex","available":true,...}` or `{"provider":"codex","available":false,...}` — either is fine, as long as the script runs without error.

- [ ] **Step 5: Verify provider-context.md exists at new path**

Run: `test -f skills/develop/provider-context.md && echo OK`
Expected: `OK`

- [ ] **Step 6: Commit**

```bash
git add -A skills/develop-swarm/ skills/patch-superpowers/ scripts/ skills/develop/provider-context.md hooks/dispatch-provider.sh
git commit -m "refactor: delete swarm infrastructure, move provider template

Previously: develop-swarm, patch-superpowers, and 5 swarm scripts.
Now: provider-context.md moved to skills/develop/, template path updated.

Bean: <bean-id>"
```

---

### Task 2: Fork discipline primitives from superpowers

Copy TDD, verification, debugging, worktrees, and finish-branch skills into fiddle. These are unchanged copies — no modifications.

**Files:**
- Create: `skills/tdd/SKILL.md`
- Create: `skills/verify/SKILL.md`
- Create: `skills/debug/SKILL.md`
- Create: `skills/worktrees/SKILL.md`
- Create: `skills/finish-branch/SKILL.md`

- [ ] **Step 1: Create skill directories and copy files**

```bash
mkdir -p skills/tdd skills/verify skills/debug skills/worktrees skills/finish-branch

SUPERPOWERS="$HOME/.claude-personal/plugins/cache/claude-plugins-official/superpowers/5.0.6/skills"

cp "$SUPERPOWERS/test-driven-development/SKILL.md" skills/tdd/SKILL.md
cp "$SUPERPOWERS/verification-before-completion/SKILL.md" skills/verify/SKILL.md
cp "$SUPERPOWERS/systematic-debugging/SKILL.md" skills/debug/SKILL.md
cp "$SUPERPOWERS/using-git-worktrees/SKILL.md" skills/worktrees/SKILL.md
cp "$SUPERPOWERS/finishing-a-development-branch/SKILL.md" skills/finish-branch/SKILL.md
```

- [ ] **Step 2: Update frontmatter names to fiddle namespace**

In each copied file, update the `name:` field in the YAML frontmatter to use the fiddle prefix:

- `skills/tdd/SKILL.md`: `name: fiddle:tdd`
- `skills/verify/SKILL.md`: `name: fiddle:verify`
- `skills/debug/SKILL.md`: `name: fiddle:debug`
- `skills/worktrees/SKILL.md`: `name: fiddle:worktrees`
- `skills/finish-branch/SKILL.md`: `name: fiddle:finish-branch`

Also update any internal cross-references from `superpowers:` to `fiddle:`. For example, if TDD references `superpowers:verification-before-completion`, change to `fiddle:verify`.

- [ ] **Step 3: Copy any supporting files referenced by skills**

Check each skill for file references (e.g., `testing-anti-patterns.md` referenced by TDD). Copy those too:

```bash
# TDD references testing-anti-patterns.md
if [ -f "$SUPERPOWERS/test-driven-development/testing-anti-patterns.md" ]; then
  cp "$SUPERPOWERS/test-driven-development/testing-anti-patterns.md" skills/tdd/testing-anti-patterns.md
fi

# finishing-a-development-branch may have supporting files
ls "$SUPERPOWERS/finishing-a-development-branch/"
# Copy any non-SKILL.md files found
```

- [ ] **Step 4: Verify all skills have correct frontmatter**

```bash
for skill in tdd verify debug worktrees finish-branch; do
  echo "=== $skill ==="
  head -5 "skills/$skill/SKILL.md"
  echo
done
```

Expected: Each shows `name: fiddle:<skill-name>` in frontmatter.

- [ ] **Step 5: Commit**

```bash
git add skills/tdd/ skills/verify/ skills/debug/ skills/worktrees/ skills/finish-branch/
git commit -m "feat: fork discipline primitives from superpowers

TDD, verification, debugging, worktrees, and finish-branch forked
as-is from superpowers 5.0.6. Renamed to fiddle: namespace.
No content changes — these are stable discipline primitives.

Bean: <bean-id>"
```

---

### Task 3: Write check-thresholds.sh

The first core script. Takes a scorecard and config, checks each dimension score against its threshold, returns a structured verdict.

For Milestone 1 (single provider, single domain), the input scorecard is the evaluator's direct output — no merging needed.

**Files:**
- Create: `scripts/check-thresholds.sh`

- [ ] **Step 1: Write the test**

Create a test script that exercises check-thresholds.sh:

```bash
cat > scripts/test-check-thresholds.sh << 'TESTEOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0

assert_exit() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS+1)); echo "  PASS: $desc"
  else
    FAIL=$((FAIL+1)); echo "  FAIL: $desc (expected exit $expected, got $actual)"
  fi
}

assert_json() {
  local desc="$1" field="$2" expected="$3" json="$4"
  local actual
  actual=$(echo "$json" | jq -r "$field")
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS+1)); echo "  PASS: $desc"
  else
    FAIL=$((FAIL+1)); echo "  FAIL: $desc (expected '$expected', got '$actual')"
  fi
}

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Minimal orchestrate.json with general domain defaults
cat > "$TMPDIR/orchestrate.json" << 'EOF'
{
  "evaluators": {
    "max_dispatches_per_task": 60,
    "domains": {
      "general": {
        "template": "evaluator-general",
        "thresholds": {
          "correctness": 7,
          "domain_spec_fidelity": 8,
          "code_quality": 6
        }
      }
    }
  }
}
EOF

echo "Test 1: All dimensions pass"
cat > "$TMPDIR/scorecard.json" << 'EOF'
{
  "domains": {
    "general": {
      "dimensions": {
        "correctness": {"score": 8, "threshold": 7},
        "domain_spec_fidelity": {"score": 9, "threshold": 8},
        "code_quality": {"score": 7, "threshold": 6}
      },
      "criteria": [{"id": "test-crit", "pass": true}]
    }
  }
}
EOF
cat > "$TMPDIR/criteria.json" << 'EOF'
[{"id": "test-crit", "pass": true}]
EOF

OUTPUT=$("$SCRIPT_DIR/check-thresholds.sh" --scorecard "$TMPDIR/scorecard.json" --config "$TMPDIR/orchestrate.json" --criteria "$TMPDIR/criteria.json" 2>/dev/null) || true
EXIT_CODE=$?
assert_exit "all pass → exit 0" 0 "$EXIT_CODE"
assert_json "verdict is PASS" ".verdict" "PASS" "$OUTPUT"

echo "Test 2: One dimension below threshold"
cat > "$TMPDIR/scorecard.json" << 'EOF'
{
  "domains": {
    "general": {
      "dimensions": {
        "correctness": {"score": 5, "threshold": 7},
        "domain_spec_fidelity": {"score": 9, "threshold": 8},
        "code_quality": {"score": 7, "threshold": 6}
      },
      "criteria": [{"id": "test-crit", "pass": true}]
    }
  }
}
EOF

OUTPUT=$("$SCRIPT_DIR/check-thresholds.sh" --scorecard "$TMPDIR/scorecard.json" --config "$TMPDIR/orchestrate.json" --criteria "$TMPDIR/criteria.json" 2>/dev/null) || true
EXIT_CODE=$?
assert_exit "one fail → exit 1" 1 "$EXIT_CODE"
assert_json "verdict is FAIL" ".verdict" "FAIL" "$OUTPUT"
assert_json "failing dim is correctness" ".failing_dimensions[0].dimension" "correctness" "$OUTPUT"

echo "Test 3: Criterion fails"
cat > "$TMPDIR/scorecard.json" << 'EOF'
{
  "domains": {
    "general": {
      "dimensions": {
        "correctness": {"score": 8, "threshold": 7},
        "domain_spec_fidelity": {"score": 9, "threshold": 8},
        "code_quality": {"score": 7, "threshold": 6}
      },
      "criteria": [{"id": "test-crit", "pass": false}]
    }
  }
}
EOF
cat > "$TMPDIR/criteria.json" << 'EOF'
[{"id": "test-crit", "pass": false}]
EOF

OUTPUT=$("$SCRIPT_DIR/check-thresholds.sh" --scorecard "$TMPDIR/scorecard.json" --config "$TMPDIR/orchestrate.json" --criteria "$TMPDIR/criteria.json" 2>/dev/null) || true
EXIT_CODE=$?
assert_exit "criterion fail → exit 1" 1 "$EXIT_CODE"
assert_json "verdict is FAIL" ".verdict" "FAIL" "$OUTPUT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
TESTEOF
chmod +x scripts/test-check-thresholds.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/test-check-thresholds.sh`
Expected: FAIL — `scripts/check-thresholds.sh` does not exist yet.

- [ ] **Step 3: Write check-thresholds.sh**

```bash
cat > scripts/check-thresholds.sh << 'SCRIPTEOF'
#!/usr/bin/env bash
# check-thresholds.sh — Compare scorecard against threshold config.
# Exit 0 = all pass, 1 = at least one fail, 2 = invalid input.
set -euo pipefail

SCORECARD=""
CONFIG=""
CRITERIA=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scorecard) SCORECARD="$2"; shift 2;;
    --config) CONFIG="$2"; shift 2;;
    --criteria) CRITERIA="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -f "$SCORECARD" ]] || { echo '{"error":"scorecard file not found"}'; exit 2; }
[[ -f "$CONFIG" ]] || { echo '{"error":"config file not found"}'; exit 2; }
[[ -f "$CRITERIA" ]] || { echo '{"error":"criteria file not found"}'; exit 2; }

# Check dimensions against thresholds
FAILING_DIMS=$(jq -c '
  [.domains | to_entries[] | .key as $domain |
   .value.dimensions | to_entries[] |
   select(.value.score < .value.threshold) |
   {domain: $domain, dimension: .key, score: .value.score, threshold: .value.threshold}]
' "$SCORECARD")

# Check criteria
FAILING_CRITERIA=$(jq -c '[.[] | select(.pass == false) | .id]' "$CRITERIA")

FAIL_DIM_COUNT=$(echo "$FAILING_DIMS" | jq 'length')
FAIL_CRIT_COUNT=$(echo "$FAILING_CRITERIA" | jq 'length')

PASSING_DIMS=$(jq -c '
  [.domains | to_entries[] | .key as $domain |
   .value.dimensions | to_entries[] |
   select(.value.score >= .value.threshold) |
   {domain: $domain, dimension: .key, score: .value.score, threshold: .value.threshold}]
' "$SCORECARD")

if [[ "$FAIL_DIM_COUNT" -eq 0 && "$FAIL_CRIT_COUNT" -eq 0 ]]; then
  jq -n --argjson passing "$PASSING_DIMS" '{
    verdict: "PASS",
    failing_dimensions: [],
    failing_criteria: [],
    passing_dimensions: $passing
  }'
  exit 0
else
  jq -n --argjson failing_dims "$FAILING_DIMS" \
        --argjson failing_crit "$FAILING_CRITERIA" \
        --argjson passing "$PASSING_DIMS" '{
    verdict: "FAIL",
    failing_dimensions: $failing_dims,
    failing_criteria: $failing_crit,
    passing_dimensions: $passing
  }'
  exit 1
fi
SCRIPTEOF
chmod +x scripts/check-thresholds.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash scripts/test-check-thresholds.sh`
Expected: All 3 tests PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/check-thresholds.sh scripts/test-check-thresholds.sh
git commit -m "feat: add check-thresholds.sh for scorecard threshold enforcement

Compares scorecard dimensions against thresholds, returns structured
PASS/FAIL verdict with failing dimensions and criteria listed.
Exit 0 = pass, 1 = fail, 2 = invalid input.

Bean: <bean-id>"
```

---

### Task 4: Write check-convergence.sh

Finding-stability convergence: two consecutive passing evaluations with no new failing dimensions and no score regressions.

**Files:**
- Create: `scripts/check-convergence.sh`

- [ ] **Step 1: Write the test**

```bash
cat > scripts/test-check-convergence.sh << 'TESTEOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0

assert_exit() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS+1)); echo "  PASS: $desc"
  else
    FAIL=$((FAIL+1)); echo "  FAIL: $desc (expected exit $expected, got $actual)"
  fi
}

assert_json() {
  local desc="$1" field="$2" expected="$3" json="$4"
  local actual
  actual=$(echo "$json" | jq -r "$field")
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS+1)); echo "  PASS: $desc"
  else
    FAIL=$((FAIL+1)); echo "  FAIL: $desc (expected '$expected', got '$actual')"
  fi
}

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Test 1: First PASS → PASS_PENDING"
cat > "$TMPDIR/current.json" << 'EOF'
{"verdict":"PASS","failing_dimensions":[],"failing_criteria":[]}
EOF
echo "[]" > "$TMPDIR/history.json"
OUTPUT=$("$SCRIPT_DIR/check-convergence.sh" --current "$TMPDIR/current.json" --history "$TMPDIR/history.json" --max-dispatches 60 --current-dispatches 2) || true
assert_exit "first pass → exit 1" 1 $?
assert_json "status PASS_PENDING" ".status" "PASS_PENDING" "$OUTPUT"

echo "Test 2: Two consecutive PASS → CONVERGED"
cat > "$TMPDIR/history.json" << 'EOF'
[{"verdict":"PASS","failing_dimensions":[],"failing_criteria":[],
  "dimensions":{"general.correctness":8,"general.code_quality":7}}]
EOF
cat > "$TMPDIR/current.json" << 'EOF'
{"verdict":"PASS","failing_dimensions":[],"failing_criteria":[],
 "dimensions":{"general.correctness":8,"general.code_quality":7}}
EOF
OUTPUT=$("$SCRIPT_DIR/check-convergence.sh" --current "$TMPDIR/current.json" --history "$TMPDIR/history.json" --max-dispatches 60 --current-dispatches 4) || true
assert_exit "two passes → exit 0" 0 $?
assert_json "status CONVERGED" ".status" "CONVERGED" "$OUTPUT"

echo "Test 3: PASS but score regressed → PASS_REGRESSED"
cat > "$TMPDIR/history.json" << 'EOF'
[{"verdict":"PASS","failing_dimensions":[],"failing_criteria":[],
  "dimensions":{"general.correctness":9,"general.code_quality":7}}]
EOF
cat > "$TMPDIR/current.json" << 'EOF'
{"verdict":"PASS","failing_dimensions":[],"failing_criteria":[],
 "dimensions":{"general.correctness":7,"general.code_quality":7}}
EOF
OUTPUT=$("$SCRIPT_DIR/check-convergence.sh" --current "$TMPDIR/current.json" --history "$TMPDIR/history.json" --max-dispatches 60 --current-dispatches 4) || true
assert_exit "regression → exit 1" 1 $?
assert_json "status PASS_REGRESSED" ".status" "PASS_REGRESSED" "$OUTPUT"

echo "Test 4: FAIL verdict"
cat > "$TMPDIR/current.json" << 'EOF'
{"verdict":"FAIL","failing_dimensions":[{"dimension":"correctness"}],"failing_criteria":[]}
EOF
echo "[]" > "$TMPDIR/history.json"
OUTPUT=$("$SCRIPT_DIR/check-convergence.sh" --current "$TMPDIR/current.json" --history "$TMPDIR/history.json" --max-dispatches 60 --current-dispatches 2) || true
assert_exit "fail → exit 1" 1 $?
assert_json "status FAIL" ".status" "FAIL" "$OUTPUT"

echo "Test 5: Dispatches exceeded"
echo "[]" > "$TMPDIR/history.json"
cat > "$TMPDIR/current.json" << 'EOF'
{"verdict":"FAIL","failing_dimensions":[],"failing_criteria":[]}
EOF
OUTPUT=$("$SCRIPT_DIR/check-convergence.sh" --current "$TMPDIR/current.json" --history "$TMPDIR/history.json" --max-dispatches 5 --current-dispatches 6) || true
assert_exit "dispatches exceeded → exit 2" 2 $?
assert_json "status DISPATCHES_EXCEEDED" ".status" "DISPATCHES_EXCEEDED" "$OUTPUT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
TESTEOF
chmod +x scripts/test-check-convergence.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/test-check-convergence.sh`
Expected: FAIL — script does not exist.

- [ ] **Step 3: Write check-convergence.sh**

```bash
cat > scripts/check-convergence.sh << 'SCRIPTEOF'
#!/usr/bin/env bash
# check-convergence.sh — Finding-stability convergence check.
# Exit 0 = CONVERGED, 1 = FAIL/PASS_PENDING/PASS_REGRESSED, 2 = DISPATCHES_EXCEEDED
set -euo pipefail

CURRENT="" HISTORY="" MAX_DISPATCHES=60 CURRENT_DISPATCHES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --current) CURRENT="$2"; shift 2;;
    --history) HISTORY="$2"; shift 2;;
    --max-dispatches) MAX_DISPATCHES="$2"; shift 2;;
    --current-dispatches) CURRENT_DISPATCHES="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -f "$CURRENT" ]] || { echo '{"error":"current file not found"}'; exit 2; }
[[ -f "$HISTORY" ]] || { echo '{"error":"history file not found"}'; exit 2; }

# Check dispatch budget first
if [[ "$CURRENT_DISPATCHES" -ge "$MAX_DISPATCHES" ]]; then
  jq -n --argjson dispatches "$CURRENT_DISPATCHES" --argjson budget "$MAX_DISPATCHES" \
    '{"status":"DISPATCHES_EXCEEDED","dispatches":$dispatches,"budget":$budget}'
  exit 2
fi

VERDICT=$(jq -r '.verdict' "$CURRENT")

# If current evaluation failed, return FAIL
if [[ "$VERDICT" != "PASS" ]]; then
  ITERATION=$(jq 'length + 1' "$HISTORY")
  jq -n --argjson iteration "$ITERATION" '{"status":"FAIL","iteration":$iteration}'
  exit 1
fi

# Current passed — check history for prior pass
HISTORY_LEN=$(jq 'length' "$HISTORY")
if [[ "$HISTORY_LEN" -eq 0 ]]; then
  # First pass ever — need confirmation
  echo '{"status":"PASS_PENDING"}'
  exit 1
fi

LAST_VERDICT=$(jq -r '.[-1].verdict' "$HISTORY")
if [[ "$LAST_VERDICT" != "PASS" ]]; then
  # Last was not a pass — this is first pass after failure
  echo '{"status":"PASS_PENDING"}'
  exit 1
fi

# Both current and last passed — check for regressions
# Compare dimension scores: current vs last passing evaluation
REGRESSIONS=$(jq -c --slurpfile hist "$HISTORY" '
  .dimensions as $current |
  ($hist[0] | .[-1].dimensions) as $previous |
  [($current | to_entries[]) |
   . as $entry |
   ($previous[$entry.key] // 0) as $prev_score |
   select($entry.value < $prev_score) |
   $entry.key]
' "$CURRENT")

REG_COUNT=$(echo "$REGRESSIONS" | jq 'length')
if [[ "$REG_COUNT" -gt 0 ]]; then
  jq -n --argjson regressions "$REGRESSIONS" \
    '{"status":"PASS_REGRESSED","regressions":$regressions}'
  exit 1
fi

# Two consecutive passes, no regressions — CONVERGED
echo '{"status":"CONVERGED"}'
exit 0
SCRIPTEOF
chmod +x scripts/check-convergence.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash scripts/test-check-convergence.sh`
Expected: All 5 tests PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/check-convergence.sh scripts/test-check-convergence.sh
git commit -m "feat: add check-convergence.sh for finding-stability convergence

Two consecutive passing evaluations with no score regressions = converged.
Checks dispatch budget. Returns CONVERGED/PASS_PENDING/PASS_REGRESSED/
FAIL/DISPATCHES_EXCEEDED.

Bean: <bean-id>"
```

---

### Task 5: Write append-eval-log.sh and parse-eval-log.sh

These two scripts work as a pair: append writes evaluation iterations to bean bodies, parse reads them back for restart.

**Files:**
- Create: `scripts/append-eval-log.sh`
- Create: `scripts/parse-eval-log.sh`

- [ ] **Step 1: Write the test**

```bash
cat > scripts/test-eval-log.sh << 'TESTEOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS+1)); echo "  PASS: $desc"
  else
    FAIL=$((FAIL+1)); echo "  FAIL: $desc (expected '$expected', got '$actual')"
  fi
}

# Create a test bean
BEAN_ID=$(beans create "Test eval log" -t task -s in-progress --json 2>/dev/null | jq -r '.id')
trap "beans update $BEAN_ID -s scrapped 2>/dev/null || true" EXIT

echo "Test 1: Init eval log on bean"
"$SCRIPT_DIR/append-eval-log.sh" --bean-id "$BEAN_ID" --init --base-sha "abc1234"
BODY=$(beans show "$BEAN_ID" --json 2>/dev/null | jq -r '.body')
echo "$BODY" | grep -q "BASE_SHA: abc1234" && assert_eq "base_sha in body" "yes" "yes" || assert_eq "base_sha in body" "yes" "no"

echo "Test 2: Append iteration"
cat > /tmp/test-scorecard.json << 'EOF'
{"domains":{"general":{"dimensions":{"correctness":{"score":7,"threshold":7}},"criteria":[]}},"verdict":"PASS"}
EOF
"$SCRIPT_DIR/append-eval-log.sh" --bean-id "$BEAN_ID" --iteration 1 --scorecard /tmp/test-scorecard.json --dispatches 1 --guidance "Looks good"
BODY=$(beans show "$BEAN_ID" --json 2>/dev/null | jq -r '.body')
echo "$BODY" | grep -q "### Iteration 1" && assert_eq "iteration 1 in body" "yes" "yes" || assert_eq "iteration 1 in body" "yes" "no"
echo "$BODY" | grep -q "total_dispatches: 1" && assert_eq "total_dispatches updated" "yes" "yes" || assert_eq "total_dispatches updated" "yes" "no"

echo "Test 3: Parse eval log"
OUTPUT=$("$SCRIPT_DIR/parse-eval-log.sh" --bean-id "$BEAN_ID")
assert_eq "base_sha parsed" "abc1234" "$(echo "$OUTPUT" | jq -r '.base_sha')"
assert_eq "iteration_count" "1" "$(echo "$OUTPUT" | jq -r '.iteration_count')"
assert_eq "total_dispatches" "1" "$(echo "$OUTPUT" | jq -r '.total_dispatches')"

echo ""
echo "Results: $PASS passed, $FAIL failed"
rm -f /tmp/test-scorecard.json
[ "$FAIL" -eq 0 ] || exit 1
TESTEOF
chmod +x scripts/test-eval-log.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/test-eval-log.sh`
Expected: FAIL — scripts don't exist.

- [ ] **Step 3: Write append-eval-log.sh**

```bash
cat > scripts/append-eval-log.sh << 'SCRIPTEOF'
#!/usr/bin/env bash
# append-eval-log.sh — Append/init evaluation log on a bean body.
# Exit 0 = success, 1 = bean not found, 2 = invalid input.
set -euo pipefail

BEAN_ID="" INIT=false BASE_SHA="" ITERATION="" SCORECARD="" DISPATCHES="" GUIDANCE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bean-id) BEAN_ID="$2"; shift 2;;
    --init) INIT=true; shift;;
    --base-sha) BASE_SHA="$2"; shift 2;;
    --iteration) ITERATION="$2"; shift 2;;
    --scorecard) SCORECARD="$2"; shift 2;;
    --dispatches) DISPATCHES="$2"; shift 2;;
    --guidance) GUIDANCE="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -n "$BEAN_ID" ]] || { echo "Missing --bean-id" >&2; exit 2; }

if $INIT; then
  [[ -n "$BASE_SHA" ]] || { echo "Missing --base-sha for --init" >&2; exit 2; }
  beans update "$BEAN_ID" --body-append "$(cat <<EOF

## Evaluation Log
BASE_SHA: $BASE_SHA
total_dispatches: 0
EOF
)" 2>/dev/null || { echo "Bean $BEAN_ID not found" >&2; exit 1; }
  exit 0
fi

# Append iteration
[[ -n "$ITERATION" ]] || { echo "Missing --iteration" >&2; exit 2; }
[[ -f "$SCORECARD" ]] || { echo "Missing --scorecard file" >&2; exit 2; }
[[ -n "$DISPATCHES" ]] || { echo "Missing --dispatches" >&2; exit 2; }

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build the iteration entry from scorecard JSON
ENTRY=$(jq -r --arg iter "$ITERATION" --arg ts "$TIMESTAMP" --arg disp "$DISPATCHES" --arg guide "$GUIDANCE" '
  "### Iteration \($iter) (\($ts))\ndispatches: \($disp)" +
  (.domains | to_entries | map(
    "\n**\(.key):**" +
    (.value.dimensions | to_entries | map(
      "\n- \(.key): \(.value.score)/10" +
      (if .value.score < .value.threshold then " (FAIL, threshold \(.value.threshold))" else "" end)
    ) | join(""))
  ) | join("")) +
  (if $guide != "" then "\n**Guidance:** \"\($guide)\"" else "" end)
' "$SCORECARD")

# Update total_dispatches
CURRENT_BODY=$(beans show "$BEAN_ID" --json 2>/dev/null | jq -r '.body') || { echo "Bean $BEAN_ID not found" >&2; exit 1; }
OLD_TOTAL=$(echo "$CURRENT_BODY" | grep -oP 'total_dispatches: \K[0-9]+' || echo "0")
NEW_TOTAL=$((OLD_TOTAL + DISPATCHES))

beans update "$BEAN_ID" \
  --body-replace-old "total_dispatches: $OLD_TOTAL" \
  --body-replace-new "total_dispatches: $NEW_TOTAL" 2>/dev/null || true

beans update "$BEAN_ID" --body-append "$ENTRY" 2>/dev/null || { echo "Bean $BEAN_ID not found" >&2; exit 1; }
exit 0
SCRIPTEOF
chmod +x scripts/append-eval-log.sh
```

- [ ] **Step 4: Write parse-eval-log.sh**

```bash
cat > scripts/parse-eval-log.sh << 'SCRIPTEOF'
#!/usr/bin/env bash
# parse-eval-log.sh — Extract evaluation state from a bean's body.
# Exit 0 = log found and parsed, 1 = no evaluation log on bean.
set -euo pipefail

BEAN_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bean-id) BEAN_ID="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -n "$BEAN_ID" ]] || { echo "Missing --bean-id" >&2; exit 2; }

BODY=$(beans show "$BEAN_ID" --json 2>/dev/null | jq -r '.body') || { echo '{"error":"bean not found"}'; exit 1; }

# Check if evaluation log exists
if ! echo "$BODY" | grep -q "## Evaluation Log"; then
  echo '{"error":"no evaluation log found"}'
  exit 1
fi

# Extract BASE_SHA
BASE_SHA=$(echo "$BODY" | grep -oP 'BASE_SHA: \K\S+' || echo "")
TOTAL_DISPATCHES=$(echo "$BODY" | grep -oP 'total_dispatches: \K[0-9]+' || echo "0")

# Count iterations
ITERATION_COUNT=$(echo "$BODY" | grep -c '### Iteration ' || echo "0")

# Extract last guidance
LAST_GUIDANCE=$(echo "$BODY" | grep -oP '\*\*Guidance:\*\* "\K[^"]*' | tail -1 || echo "")

# Extract last verdict by checking if last iteration had FAIL markers
LAST_VERDICT="UNKNOWN"
if [[ "$ITERATION_COUNT" -gt 0 ]]; then
  LAST_SECTION=$(echo "$BODY" | awk '/### Iteration '"$ITERATION_COUNT"'/{found=1} found{print}')
  if echo "$LAST_SECTION" | grep -q "FAIL"; then
    LAST_VERDICT="FAIL"
  else
    LAST_VERDICT="PASS"
  fi
fi

jq -n \
  --arg base_sha "$BASE_SHA" \
  --argjson iteration_count "$ITERATION_COUNT" \
  --argjson total_dispatches "$TOTAL_DISPATCHES" \
  --arg last_verdict "$LAST_VERDICT" \
  --arg last_guidance "$LAST_GUIDANCE" \
  '{base_sha: $base_sha, iteration_count: $iteration_count, total_dispatches: $total_dispatches, last_verdict: $last_verdict, last_guidance: $last_guidance}'
SCRIPTEOF
chmod +x scripts/parse-eval-log.sh
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash scripts/test-eval-log.sh`
Expected: All tests PASS, exit 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/append-eval-log.sh scripts/parse-eval-log.sh scripts/test-eval-log.sh
git commit -m "feat: add append-eval-log.sh and parse-eval-log.sh

append-eval-log.sh: init evaluation log on bean, append iterations.
parse-eval-log.sh: extract base_sha, iteration count, dispatches for restart.
Both operate on bean bodies via beans CLI.

Bean: <bean-id>"
```

---

### Task 6: Write assess-git-state.sh

Classify git state as CLEAN/DIRTY/CORRUPTED relative to a base commit.

**Files:**
- Create: `scripts/assess-git-state.sh`

- [ ] **Step 1: Write the test**

```bash
cat > scripts/test-assess-git-state.sh << 'TESTEOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0

assert_json() {
  local desc="$1" field="$2" expected="$3" json="$4"
  local actual
  actual=$(echo "$json" | jq -r "$field")
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS+1)); echo "  PASS: $desc"
  else
    FAIL=$((FAIL+1)); echo "  FAIL: $desc (expected '$expected', got '$actual')"
  fi
}

echo "Test 1: Clean state (HEAD is at or ahead of base)"
BASE_SHA=$(git rev-parse HEAD)
OUTPUT=$("$SCRIPT_DIR/assess-git-state.sh" --base-sha "$BASE_SHA")
assert_json "clean state" ".state" "CLEAN" "$OUTPUT"

echo "Test 2: Base SHA from earlier commit"
BASE_SHA=$(git rev-parse HEAD~1 2>/dev/null || git rev-parse HEAD)
OUTPUT=$("$SCRIPT_DIR/assess-git-state.sh" --base-sha "$BASE_SHA")
assert_json "clean ahead state" ".state" "CLEAN" "$OUTPUT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
TESTEOF
chmod +x scripts/test-assess-git-state.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/test-assess-git-state.sh`
Expected: FAIL — script does not exist.

- [ ] **Step 3: Write assess-git-state.sh**

```bash
cat > scripts/assess-git-state.sh << 'SCRIPTEOF'
#!/usr/bin/env bash
# assess-git-state.sh — Classify git state relative to a base commit.
# Exit 0 = CLEAN, 1 = DIRTY, 2 = CORRUPTED
set -euo pipefail

BASE_SHA=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-sha) BASE_SHA="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -n "$BASE_SHA" ]] || { echo '{"error":"missing --base-sha"}'; exit 2; }

# Check for merge conflicts
if git ls-files --unmerged | grep -q .; then
  CONFLICT_FILES=$(git ls-files --unmerged | awk '{print $4}' | sort -u | jq -R -s 'split("\n") | map(select(. != ""))')
  jq -n --argjson files "$CONFLICT_FILES" '{"state":"CORRUPTED","reason":"merge conflict","files":$files}'
  exit 2
fi

# Check for uncommitted changes
DIRTY_FILES=$(git status --porcelain 2>/dev/null | awk '{print $2}')
if [[ -n "$DIRTY_FILES" ]]; then
  FILES_JSON=$(echo "$DIRTY_FILES" | jq -R -s 'split("\n") | map(select(. != ""))')
  jq -n --argjson files "$FILES_JSON" '{"state":"DIRTY","uncommitted_files":$files}'
  exit 1
fi

# Clean — count commits ahead of base
HEAD_SHA=$(git rev-parse HEAD)
COMMITS_AHEAD=$(git rev-list "$BASE_SHA".."$HEAD_SHA" --count 2>/dev/null || echo "0")

jq -n --arg head "$HEAD_SHA" --argjson ahead "$COMMITS_AHEAD" \
  '{"state":"CLEAN","head_sha":$head,"commits_ahead":$ahead}'
exit 0
SCRIPTEOF
chmod +x scripts/assess-git-state.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash scripts/test-assess-git-state.sh`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/assess-git-state.sh scripts/test-assess-git-state.sh
git commit -m "feat: add assess-git-state.sh for restart state classification

Classifies git state as CLEAN/DIRTY/CORRUPTED relative to a base SHA.
Used by the orchestrator to determine restart strategy.

Bean: <bean-id>"
```

---

### Task 7: Write evaluator-general.md domain template

The general-purpose evaluator template with Correctness, Domain Spec Fidelity, and Code Quality dimensions — each with full 1-10 scales.

**Files:**
- Create: `skills/evaluate/evaluator-general.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/evaluate
```

- [ ] **Step 2: Write evaluator-general.md**

Write the complete general domain template with all three dimensions, each with full 1-10 scoring scales. The content comes directly from the design spec (lines 249-282). Include default thresholds.

The file should be ~120-150 lines containing:
- Header identifying it as the general domain template
- Correctness dimension: definition, default threshold 7, full 1-10 scale (from spec lines 175-197)
- Domain Spec Fidelity dimension: definition, default threshold 8, full 1-10 scale (from spec lines 148-169)
- Code Quality dimension: definition, default threshold 6, full 1-10 scale (from spec lines 260-282)

Copy the exact scales from the design spec — do not paraphrase.

- [ ] **Step 3: Verify line count and structure**

Run: `wc -l skills/evaluate/evaluator-general.md && head -5 skills/evaluate/evaluator-general.md`
Expected: ~120-150 lines, starts with header.

- [ ] **Step 4: Commit**

```bash
git add skills/evaluate/evaluator-general.md
git commit -m "feat: add evaluator-general.md domain template

General-purpose evaluator template with Correctness (threshold 7),
Domain Spec Fidelity (threshold 8), and Code Quality (threshold 6).
Full 1-10 scoring scales for every dimension, no gaps.

Bean: <bean-id>"
```

---

### Task 8: Write evaluate/SKILL.md — evaluator protocol

The foundational skill read by evaluator subagents. Covers: how to score, evidence requirements, scorecard JSON format, distrust rules. Must be small (~100-150 lines) so agents actually read it.

**Files:**
- Create: `skills/evaluate/SKILL.md`

- [ ] **Step 1: Write the evaluator protocol skill**

Content must include:
- Frontmatter: `name: fiddle:evaluate`, description
- HARD-GATE: must score every dimension, evidence required, no passing without evidence
- Scorecard JSON output format (canonical schema from spec lines 889-909)
- Distrust rules: "verify independently, don't trust implementer's claims"
- Scoring instructions: use the domain template's 1-10 scales exactly
- Criteria evaluation: check each criterion from the Evaluation block, return pass/fail with evidence
- Antipattern checking: if antipatterns file provided, check each one
- How to handle prior scorecards (iteration 2+): compare with prior, note improvements/regressions
- Report format: return the canonical scorecard JSON to stdout

Keep under 150 lines. This skill is loaded into the evaluator's context — if it's too long, the evaluator will ignore parts.

- [ ] **Step 2: Verify line count**

Run: `wc -l skills/evaluate/SKILL.md`
Expected: 100-150 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/evaluate/SKILL.md
git commit -m "feat: add evaluate/SKILL.md — evaluator protocol

Foundational skill for evaluator agents. Covers scoring protocol,
evidence requirements, scorecard JSON format, distrust rules.
~130 lines — small enough for agents to read completely.

Bean: <bean-id>"
```

---

### Task 9: Write develop/implementer-prompt.md

Template for dispatching implementer subagents. Based on existing superpowers implementer prompt but adapted for the evaluator system.

**Files:**
- Create: `skills/develop/implementer-prompt.md`

- [ ] **Step 1: Write the implementer prompt template**

Based on the existing superpowers `implementer-prompt.md` (from subagent-driven-development), adapted for the evaluator system. Key changes:
- Include Evaluation block in the prompt so implementer knows what it will be graded on
- Include antipattern file content
- On iteration 2+: include prior scorecard and evaluator guidance
- Report format: DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT
- Self-review section before reporting
- Reference `fiddle:tdd` and `fiddle:verify` skills

The template uses placeholders: `{TASK_TEXT}`, `{CONTEXT}`, `{EVAL_BLOCK}`, `{ANTIPATTERNS}`, `{PRIOR_SCORECARD}`, `{PRIOR_GUIDANCE}`, `{ITERATION}`, `{WORK_DIR}`

- [ ] **Step 2: Verify**

Run: `wc -l skills/develop/implementer-prompt.md && grep -c '{' skills/develop/implementer-prompt.md`
Expected: ~80-100 lines, 8+ placeholders.

- [ ] **Step 3: Commit**

```bash
git add skills/develop/implementer-prompt.md
git commit -m "feat: add implementer-prompt.md dispatch template

Template for implementer subagent dispatch. Includes evaluation block,
antipatterns, prior scorecard on iteration 2+. Reports DONE/BLOCKED/
NEEDS_CONTEXT status.

Bean: <bean-id>"
```

---

### Task 10: Rewrite develop/SKILL.md — single execution mode with evaluator loop

The core orchestrating skill. Replaces the current three-mode develop skill with a single evaluator loop. This is the largest task.

**Files:**
- Rewrite: `skills/develop/SKILL.md`

- [ ] **Step 1: Read the current develop/SKILL.md for reference**

Read the full file to understand its structure, then plan the rewrite.

- [ ] **Step 2: Write the new develop/SKILL.md**

The new skill must contain:

**Header:**
- Frontmatter: `name: fiddle:develop`
- Description of the evaluator loop
- Announce message

**Step 0: Validate and Setup**
- Validate epic bean exists with child task beans
- Set up worktree via `fiddle:worktrees`
- Read `orchestrate.json` evaluator config

**Step 1: Per-Task Loop**
For each task bean (sequential):
1. Record BASE_SHA via `append-eval-log.sh --init`
2. Mark bean in-progress
3. Dispatch implementer subagent (using `implementer-prompt.md` template)
4. Handle implementer status (DONE/BLOCKED/NEEDS_CONTEXT)
5. HARD-GATE: Run `check-thresholds.sh` on evaluator scorecard
6. HARD-GATE: Run `check-convergence.sh`
7. HARD-GATE: Run `append-eval-log.sh` after every evaluation
8. On FAIL: dispatch fresh implementer with scorecard feedback → loop
9. On PASS_PENDING: re-evaluate → loop
10. On PASS_REGRESSED: fresh implementer with regression info → loop
11. On CONVERGED: mark bean completed → next task
12. On DISPATCHES_EXCEEDED: escalate to human

**Step 2: Completion**
- After all tasks: invoke `fiddle:finish-branch`

**HARD-GATE blocks** (from spec lines 1336-1376):
- Scripts must be called, not computed manually
- Dispatch budget must be respected
- Eval log must be appended after every cycle
- Restart must use parse-eval-log.sh and assess-git-state.sh

**Restart handling:**
- On session start: check for in-progress bean
- Run parse-eval-log.sh + assess-git-state.sh
- Resume from appropriate point

**Simplifications for M1:**
- Single domain: no resolve-domains.sh needed
- Single provider: evaluator scorecard IS the scorecard (no merging)
- No runtime: evaluator reviews code only
- No attended gate (will be added in M5)
- No antipatterns (will be added in M5)

Target: ~200-250 lines. Larger than foundational skills because it orchestrates the full loop.

- [ ] **Step 3: Verify structure**

Run: `wc -l skills/develop/SKILL.md && grep -c 'HARD-GATE' skills/develop/SKILL.md`
Expected: 200-250 lines, 4+ HARD-GATE blocks.

- [ ] **Step 4: Verify all script references are correct**

Run: `grep -oP 'scripts/\S+\.sh' skills/develop/SKILL.md | sort -u`
Expected: check-thresholds.sh, check-convergence.sh, append-eval-log.sh, parse-eval-log.sh, assess-git-state.sh

- [ ] **Step 5: Commit**

```bash
git add skills/develop/SKILL.md
git commit -m "feat: rewrite develop skill with evaluator loop

Single execution mode: implement → evaluate → converge per task.
HARD-GATE enforcement for scripts. Restart via bean evaluation log.
Circuit breaker via max_dispatches_per_task.

Previously: three execution modes (subagent/sequential/swarm).
Now: single evaluator loop, M1 scope (no runtime, no multi-provider).

Bean: <bean-id>"
```

---

### Task 11: Update orchestrate.json and orchestrate/SKILL.md

Add evaluator config, remove develop.execution key and execution mode references.

**Files:**
- Modify: `orchestrate.json`
- Modify: `skills/orchestrate/SKILL.md`

- [ ] **Step 1: Update orchestrate.json**

Replace the `develop` block with `evaluators` block:

```json
{
  "providers": {
    "codex": { "command": "codex exec", "flags": "--json -s read-only" },
    "gemini": { "command": "gemini", "flags": "-o json --approval-mode auto_edit" },
    "phases": {
      "discover": ["codex"],
      "define": ["codex", "gemini"],
      "develop": [],
      "develop_holistic": ["codex"],
      "deliver": ["codex"]
    },
    "timeout": { "attended": 120, "unattended": 90 }
  },
  "evaluators": {
    "attended": false,
    "max_dispatches_per_task": 60,
    "domains": {
      "general": {
        "template": "evaluator-general",
        "providers": ["claude"]
      }
    }
  },
  "models": {},
  "plans": {}
}
```

- [ ] **Step 2: Update orchestrate/SKILL.md**

Remove references to `--execution` flag, `develop.execution` config, and execution mode selection. The develop phase now has a single mode — no choice needed.

Find the section that passes `--execution` to develop and simplify it.

- [ ] **Step 3: Verify orchestrate.json is valid JSON**

Run: `jq . orchestrate.json > /dev/null && echo "Valid JSON"`
Expected: "Valid JSON"

- [ ] **Step 4: Commit**

```bash
git add orchestrate.json skills/orchestrate/SKILL.md
git commit -m "feat: add evaluator config, remove execution mode selection

orchestrate.json: add evaluators section (general domain, single provider).
Remove develop.execution key.
orchestrate/SKILL.md: remove --execution flag and mode selection.

Bean: <bean-id>"
```

---

### Task 12: Fork and modify brainstorm skill

Fork superpowers brainstorming, add calibration anchor extraction from specs.

**Files:**
- Create: `skills/brainstorm/SKILL.md`

- [ ] **Step 1: Copy and rename**

```bash
mkdir -p skills/brainstorm
SUPERPOWERS="$HOME/.claude-personal/plugins/cache/claude-plugins-official/superpowers/5.0.6/skills"
cp "$SUPERPOWERS/brainstorming/SKILL.md" skills/brainstorm/SKILL.md
```

- [ ] **Step 2: Update frontmatter and cross-references**

- Change `name:` to `fiddle:brainstorm`
- Replace `superpowers:` references with `fiddle:` equivalents
- Update the terminal state: instead of "invoke writing-plans", invoke `fiddle:write-plan`
- Update spec save path to use `orchestrate.json` `plans.path` if configured

- [ ] **Step 3: Add calibration anchor extraction step**

After the "Write design doc" step and before "Spec self-review", add a new checklist item:

```markdown
7. **Extract initial calibration anchors** — If the spec describes visual/behavioral output, extract quality tier descriptions as initial calibration anchors for the evaluator. Save alongside the spec.
```

Add corresponding instructions after the design doc writing section:

```markdown
**Calibration Anchor Extraction:**

If the design spec describes what the output should look like (visual designs, API contracts, behavioral descriptions), extract calibration anchors:

- What would a **poor** (3-4) implementation look like?
- What would an **acceptable** (6-7) implementation look like?
- What would an **excellent** (9-10) implementation look like?

Save to `docs/evaluator-calibration-<domain>.md` alongside the spec. These anchors are loaded by evaluators during implementation to calibrate their scoring.

If the spec is purely structural (scripts, configuration, tooling) with no visible output, skip this step.
```

- [ ] **Step 4: Copy supporting files if any**

```bash
ls "$SUPERPOWERS/brainstorming/"
# Copy any non-SKILL.md files (visual-companion.md, etc.)
for f in "$SUPERPOWERS/brainstorming/"*; do
  [ "$(basename "$f")" = "SKILL.md" ] && continue
  cp "$f" "skills/brainstorm/$(basename "$f")"
done
```

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorm/
git commit -m "feat: fork brainstorm skill from superpowers, add calibration extraction

Forked brainstorming skill with calibration anchor extraction step.
After writing design spec, extracts quality tier descriptions as
initial evaluator calibration anchors.

Bean: <bean-id>"
```

---

### Task 13: Fork and modify write-plan skill

Fork superpowers writing-plans, add Evaluation blocks per task.

**Files:**
- Create: `skills/write-plan/SKILL.md`

- [ ] **Step 1: Copy and rename**

```bash
mkdir -p skills/write-plan
SUPERPOWERS="$HOME/.claude-personal/plugins/cache/claude-plugins-official/superpowers/5.0.6/skills"
cp "$SUPERPOWERS/writing-plans/SKILL.md" skills/write-plan/SKILL.md
```

- [ ] **Step 2: Update frontmatter and cross-references**

- Change `name:` to `fiddle:write-plan`
- Replace `superpowers:` references with `fiddle:` equivalents
- Update plan save path to use `orchestrate.json` `plans.path` if configured
- Update execution handoff to reference `fiddle:develop`

- [ ] **Step 3: Add Evaluation block requirement to task structure**

After the existing Task Structure section, add:

````markdown
## Evaluation Block

**Every task MUST include an Evaluation block** — a fenced YAML block with language tag `eval`:

```eval
domains: [general]
criteria:
  general:
    - id: descriptive-criterion-id
      check: "Human-readable description of what to verify"
thresholds: {}
```

**Schema rules:**
- `domains`: array of domain names (use `general` for non-frontend/backend tasks)
- `criteria`: keyed by domain, each with stable `id` (snake_case) and `check` text
- `thresholds`: optional overrides (empty = use domain defaults)
- Criterion IDs must be unique within the task, stable across edits

**The Evaluation block tells the evaluator what to check.** Without it, the evaluator has no task-specific criteria — only generic dimension scoring. Every plan task needs specific, verifiable criteria.
````

- [ ] **Step 4: Update the plan header template**

Update the header to reference `fiddle:develop`:

```markdown
> **For agentic workers:** REQUIRED SUB-SKILL: Use fiddle:develop to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
```

- [ ] **Step 5: Commit**

```bash
git add skills/write-plan/
git commit -m "feat: fork write-plan skill from superpowers, add Evaluation blocks

Forked writing-plans skill with Evaluation block requirement per task.
Each task must include a fenced YAML eval block with domains, criteria
(stable IDs), and optional threshold overrides.

Bean: <bean-id>"
```

---

### Task 14: Integration test — run the evaluator loop end-to-end

Create a test bean, run the develop skill's evaluate loop manually to verify the full pipeline works.

**Files:**
- No new files — this is a verification task

- [ ] **Step 1: Create a test task bean**

```bash
beans create "Test: evaluator loop integration" -t task -s todo -d "$(cat <<'EOF'
Test task for verifying the evaluator loop.

```eval
domains: [general]
criteria:
  general:
    - id: file-exists
      check: "A file test-output.txt exists with content 'hello world'"
thresholds: {}
```

- [ ] Create test-output.txt with 'hello world'
EOF
)"
```

- [ ] **Step 2: Verify scripts work together**

```bash
# Init eval log
BEAN_ID=<created-bean-id>
scripts/append-eval-log.sh --bean-id "$BEAN_ID" --init --base-sha "$(git rev-parse HEAD)"

# Simulate a failing scorecard
cat > /tmp/test-fail-scorecard.json << 'EOF'
{"domains":{"general":{"dimensions":{"correctness":{"score":5,"threshold":7},"domain_spec_fidelity":{"score":4,"threshold":8},"code_quality":{"score":6,"threshold":6}},"criteria":[{"id":"file-exists","pass":false}]}},"verdict":"FAIL"}
EOF

# Check thresholds
scripts/check-thresholds.sh --scorecard /tmp/test-fail-scorecard.json --config orchestrate.json --criteria <(echo '[{"id":"file-exists","pass":false}]')
echo "Exit: $?"
# Expected: exit 1, FAIL verdict

# Append to log
scripts/append-eval-log.sh --bean-id "$BEAN_ID" --iteration 1 --scorecard /tmp/test-fail-scorecard.json --dispatches 1 --guidance "File not created"

# Check convergence
scripts/check-convergence.sh --current <(scripts/check-thresholds.sh --scorecard /tmp/test-fail-scorecard.json --config orchestrate.json --criteria <(echo '[{"id":"file-exists","pass":false}]') 2>/dev/null || true) --history <(echo '[]') --max-dispatches 60 --current-dispatches 1
echo "Exit: $?"
# Expected: exit 1, FAIL status

# Parse eval log
scripts/parse-eval-log.sh --bean-id "$BEAN_ID"
# Expected: base_sha, iteration_count: 1, total_dispatches: 1

# Simulate a passing scorecard
cat > /tmp/test-pass-scorecard.json << 'EOF'
{"domains":{"general":{"dimensions":{"correctness":{"score":8,"threshold":7},"domain_spec_fidelity":{"score":9,"threshold":8},"code_quality":{"score":7,"threshold":6}},"criteria":[{"id":"file-exists","pass":true}]}},"verdict":"PASS","dimensions":{"general.correctness":8,"general.domain_spec_fidelity":9,"general.code_quality":7}}
EOF

# Two consecutive passes for convergence
# ... (verify PASS_PENDING on first, CONVERGED on second)
```

- [ ] **Step 3: Verify restart recovery**

```bash
# Parse eval log shows correct state
scripts/parse-eval-log.sh --bean-id "$BEAN_ID"

# Assess git state
scripts/assess-git-state.sh --base-sha "$(scripts/parse-eval-log.sh --bean-id "$BEAN_ID" | jq -r '.base_sha')"
# Expected: CLEAN
```

- [ ] **Step 4: Clean up test bean**

```bash
beans update "$BEAN_ID" -s scrapped
rm -f /tmp/test-fail-scorecard.json /tmp/test-pass-scorecard.json
```

- [ ] **Step 5: Commit (no code changes — verification only)**

No commit needed unless fixes were required during testing. If fixes were made, commit them with description of what was fixed.

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| Fork discipline primitives (TDD, verify, debug, worktrees, finish-branch) | Task 2 |
| Fork and modify brainstorm (calibration extraction) | Task 12 |
| Fork and modify write-plan (Evaluation blocks) | Task 13 |
| Evaluator protocol skill | Task 8 |
| Evaluator-general domain template | Task 7 |
| Implementer dispatch template | Task 9 |
| Develop skill rewrite (evaluator loop) | Task 10 |
| check-thresholds.sh | Task 3 |
| check-convergence.sh | Task 4 |
| append-eval-log.sh | Task 5 |
| parse-eval-log.sh | Task 5 |
| assess-git-state.sh | Task 6 |
| Scorecard JSON schema | Task 8 (in evaluator protocol) |
| orchestrate.json evaluator config | Task 11 |
| Session restart/recovery | Task 10 (in develop skill) |
| Circuit breaker (max_dispatches_per_task) | Task 4 + Task 10 |
| Delete patch-superpowers, develop-swarm, swarm scripts | Task 1 |
| Move provider template, update dispatch-provider.sh | Task 1 |
| Update orchestrate/SKILL.md | Task 11 |
| Integration test | Task 14 |

**Not in scope (per M1 spec):** runtime verification, multi-provider, multi-domain, holistic review, calibration files, antipatterns, merge-scorecards.sh, resolve-domains.sh, start/stop-runtimes.sh.
