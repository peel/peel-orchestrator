# Holistic Review

Cross-domain evaluation that assesses the full system as an integrated whole. Runs after all domain evaluators have scored their individual dimensions. Produces a holistic scorecard, spec coverage matrix, and remediation beans for any gaps.

## HARD-GATE: Runtime Interaction Required

<HARD-GATE>
You MUST interact with ALL domain runtimes before scoring any holistic dimension.
Do NOT score from source code alone. Do NOT score from individual domain scorecards alone.
Every score must cite evidence gathered from live runtime interaction.
If any runtime is not running, score Runtime Health as 1 and note the failure.
</HARD-GATE>

The runtimes are started by `start-runtimes.sh` before holistic review begins. You receive runtime state for each domain including ports and domain names. Use the appropriate MCP tools (marionette for Flutter, curl for HTTP, go-dev-mcp for Go) to interact with each runtime.

### Evidence Gathering

- Launch each domain's runtime and verify it responds
- Exercise the primary user flows end-to-end across domains
- Take screenshots of frontend states reached via backend data
- Verify API calls from frontend reach backend and return correct data
- Check console output for errors, warnings, or unhandled exceptions
- Record which cross-domain flows were tested and their outcomes

## Cross-Domain Integration Check

Before scoring, verify that domains work together as a system:

- **API contract compliance:** Does the frontend send requests the backend expects? Does the backend respond with shapes the frontend can parse?
- **Data flow end-to-end:** Trace at least one full user action from UI interaction through API call to backend processing and back to UI update.
- **Error propagation:** When the backend returns an error, does the frontend display appropriate feedback?
- **State consistency:** Does the frontend state reflect backend state accurately after mutations?

Note any integration gaps in the scorecard evidence. Integration failures directly affect the Integration and Coherence dimension scores.

## Dimensions

Score each dimension using the scales defined in: `skills/develop/holistic-dimensions.md`

Dimensions and default thresholds:
- **Integration** (7) — Do the pieces work together?
- **Coherence** (7) — Does the whole feel like one system?
- **Holistic Spec Fidelity** (8) — Does the full result match the design vision?
- **Polish** (6) — Would you ship this?
- **Runtime Health** (9) — App launches cleanly, no console errors?

## Output

Produce output following: `skills/develop/holistic-scorecard-schema.md`

This includes the spec coverage matrix, remediation beans, and scorecard JSON.

## Red Flags

- **Never** score without launching and interacting with all runtimes
- **Never** skip the spec coverage matrix — every spec requirement must be classified
- **Never** leave a "Missing" coverage entry without generating a remediation bean
- **Never** generate remediation beans for "Weak" entries — those are flagged for human review
- **Never** score Holistic Spec Fidelity based on individual task specs — use the overall design document
- **Never** copy domain evaluator scores — holistic dimensions evaluate the whole, not individual parts
