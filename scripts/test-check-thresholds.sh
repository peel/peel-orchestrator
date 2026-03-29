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

OUTFILE="$TMPDIR/out.json"
EXIT_CODE=0
"$SCRIPT_DIR/check-thresholds.sh" --scorecard "$TMPDIR/scorecard.json" --config "$TMPDIR/orchestrate.json" --criteria "$TMPDIR/criteria.json" > "$OUTFILE" 2>/dev/null || EXIT_CODE=$?
OUTPUT=$(cat "$OUTFILE")
assert_exit "all pass → exit 0" 0 "$EXIT_CODE"
assert_json "verdict is PASS" ".verdict" "PASS" "$OUTPUT"
assert_json "dimensions has correctness" '.dimensions["general.correctness"]' "8" "$OUTPUT"
assert_json "dimensions has domain_spec_fidelity" '.dimensions["general.domain_spec_fidelity"]' "9" "$OUTPUT"
assert_json "dimensions has code_quality" '.dimensions["general.code_quality"]' "7" "$OUTPUT"

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

EXIT_CODE=0
"$SCRIPT_DIR/check-thresholds.sh" --scorecard "$TMPDIR/scorecard.json" --config "$TMPDIR/orchestrate.json" --criteria "$TMPDIR/criteria.json" > "$OUTFILE" 2>/dev/null || EXIT_CODE=$?
OUTPUT=$(cat "$OUTFILE")
assert_exit "one fail → exit 1" 1 "$EXIT_CODE"
assert_json "verdict is FAIL" ".verdict" "FAIL" "$OUTPUT"
assert_json "failing dim is correctness" ".failing_dimensions[0].dimension" "correctness" "$OUTPUT"
assert_json "dimensions has correctness score" '.dimensions["general.correctness"]' "5" "$OUTPUT"
assert_json "dimensions has domain_spec_fidelity score" '.dimensions["general.domain_spec_fidelity"]' "9" "$OUTPUT"
assert_json "dimensions has code_quality score" '.dimensions["general.code_quality"]' "7" "$OUTPUT"

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

EXIT_CODE=0
"$SCRIPT_DIR/check-thresholds.sh" --scorecard "$TMPDIR/scorecard.json" --config "$TMPDIR/orchestrate.json" --criteria "$TMPDIR/criteria.json" > "$OUTFILE" 2>/dev/null || EXIT_CODE=$?
OUTPUT=$(cat "$OUTFILE")
assert_exit "criterion fail → exit 1" 1 "$EXIT_CODE"
assert_json "verdict is FAIL" ".verdict" "FAIL" "$OUTPUT"
assert_json "dimensions present on crit fail" '.dimensions["general.correctness"]' "8" "$OUTPUT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
