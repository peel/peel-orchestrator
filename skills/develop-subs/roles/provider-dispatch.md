# Provider Dispatch

On-demand procedure for calling external providers. Read this file only when you need to dispatch a provider call.

## Read Config

1. Read `orchestrate.conf` → `providers.<name>` block for `command` and `flags`
2. Read `providers.timeout` block for `attended` and `unattended` values
3. If a provider has no config block, skip it silently

## Build Prompt

1. Read `roles/provider-context.md`
2. Substitute placeholders with values from the calling context:
   - `{PROVIDER_ROLE}` — the provider's assigned perspective for this call
   - `{TOPIC}` — what is being analyzed or debated
   - `{APPROACHES}` — candidate approaches (panel debates)
   - `{DESIGN_DOC}` — design document content (reviews, drift analysis)
   - `{DIFF}` — code diff (reviews, drift analysis)
   - `{PREVIOUS_FEEDBACK}` — other participants' positions (cross-review rounds)
   - `{INSTRUCTIONS}` — what the provider should produce
3. Strip sections where the value is empty — do not send empty headers to the provider
4. Write the final prompt to a temp file:
   ```bash
   PROMPT_FILE=$(mktemp /tmp/provider-XXXX.md)
   cat <<'PROMPT_EOF' > "$PROMPT_FILE"
   <substituted template content>
   PROMPT_EOF
   ```

## Dispatch (Background)

Fire the provider CLI as a background Bash task:

```
task = Bash(
  run_in_background: true,
  command: "<command> <flags> < \"$PROMPT_FILE\""
)
```

Record the task ID and provider name.

**Parallelism rule:** When dispatching multiple providers, fire ALL in a single message — one Bash call per provider, all with `run_in_background: true`. This gives true parallelism. Do not fire sequentially.

For Claude positions in panel debates, use `Agent(run_in_background: true)` as before — this procedure covers external CLI providers only.

## Collect Results

The calling skill determines the mode based on the current phase:
- **DISCOVER, DEFINE, DELIVER** → attended mode
- **DEVELOP** → unattended mode

### Attended mode

For each task, call:
```
TaskOutput(task_id: <id>, timeout: <timeout.attended * 1000>)
```

Process results as they arrive — do not wait for all providers before handling the first result.

If timeout fires before a result arrives, present to user:
```
"<provider> has not responded after <timeout>s.
Options: (1) keep waiting, (2) respawn, (3) kill and proceed without it"
```

- **Keep waiting**: re-call TaskOutput with extended timeout (double the original)
- **Respawn**: TaskStop the hung task, re-run Build Prompt and Dispatch for that provider only, collect again with fresh timeout
- **Kill**: TaskStop and proceed with whatever results are available

### Unattended mode

For each task, call:
```
TaskOutput(task_id: <id>, timeout: <timeout.unattended * 1000>)
```

If timeout fires before result:
- `TaskStop(task_id)`
- Log: "`<provider>` timed out after `<timeout>`s, proceeding without"

**First-past-the-post:** When collecting from multiple providers, process results as they arrive. If 2+ providers have returned and a remaining provider times out, proceed with available results. Do not wait for stragglers.

## Parse Output

Read the result from TaskOutput. The output is the provider's raw response. Return it to the calling skill as-is — the caller handles synthesis and aggregation.

## Cleanup

After all results are collected (or timed out):
```bash
rm -f "$PROMPT_FILE"
```
