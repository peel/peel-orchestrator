#!/usr/bin/env bash
# SubagentStop hook: enforce decision reporting for implementer agents
set -euo pipefail

INPUT=$(cat)

# Only gate implementer agents (name starts with "impl-")
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // .agent_id // ""')
echo "$AGENT_NAME" | grep -qE '^impl-' || exit 0

# Avoid infinite loops: if we already blocked once, allow stop
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

# Extract bean ID from agent name (impl-{bean-slug} or impl-{bean-slug}-fix{N})
BEAN_ID=$(echo "$AGENT_NAME" | sed 's/^impl-//' | sed 's/-fix[0-9]*//')
[ -z "$BEAN_ID" ] && exit 0

# Check if decisions were reported for this bean
BEAN_BODY=$(beans show "$BEAN_ID" --json 2>/dev/null | jq -r '.body // ""' || true)

if echo "$BEAN_BODY" | grep -q "## Decisions"; then
  exit 0
fi

echo "Before finishing, report at least one architectural/design decision:" >&2
echo "  crops report decisions $BEAN_ID \\" >&2
echo "    --decision 'What you chose' \\" >&2
echo "    --reasoning 'Why this over alternatives'" >&2
exit 2
