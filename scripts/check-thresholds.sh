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
