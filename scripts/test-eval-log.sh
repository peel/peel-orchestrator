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
BEAN_ID=$(beans create "Test eval log" -t task -s in-progress --json 2>/dev/null | jq -r '.bean.id // .id')
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

echo "Test 4: Append second iteration with FAIL"
cat > /tmp/test-scorecard2.json << 'EOF'
{"domains":{"general":{"dimensions":{"correctness":{"score":5,"threshold":7}},"criteria":[]}},"verdict":"FAIL"}
EOF
"$SCRIPT_DIR/append-eval-log.sh" --bean-id "$BEAN_ID" --iteration 2 --scorecard /tmp/test-scorecard2.json --dispatches 2 --guidance "Needs improvement"
OUTPUT=$("$SCRIPT_DIR/parse-eval-log.sh" --bean-id "$BEAN_ID")
assert_eq "iteration_count after 2nd" "2" "$(echo "$OUTPUT" | jq -r '.iteration_count')"
assert_eq "total_dispatches cumulative" "3" "$(echo "$OUTPUT" | jq -r '.total_dispatches')"
assert_eq "last_verdict is FAIL" "FAIL" "$(echo "$OUTPUT" | jq -r '.last_verdict')"
assert_eq "last_guidance" "Needs improvement" "$(echo "$OUTPUT" | jq -r '.last_guidance')"

echo "Test 5: Missing --bean-id errors"
EXIT_CODE=0
"$SCRIPT_DIR/append-eval-log.sh" --init --base-sha "x" 2>/dev/null || EXIT_CODE=$?
assert_eq "append missing bean-id → exit 2" "2" "$EXIT_CODE"

EXIT_CODE=0
"$SCRIPT_DIR/parse-eval-log.sh" 2>/dev/null || EXIT_CODE=$?
assert_eq "parse missing bean-id → exit 2" "2" "$EXIT_CODE"

echo ""
echo "Results: $PASS passed, $FAIL failed"
rm -f /tmp/test-scorecard.json /tmp/test-scorecard2.json
[ "$FAIL" -eq 0 ] || exit 1
