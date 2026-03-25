# Provider Dispatch

On-demand procedure for calling external providers.

## Dispatch

Run `hooks/dispatch-provider.sh` as a background Bash task. The script handles config lookup, template substitution, and provider execution.

```
Bash(
  run_in_background: true,
  command: "hooks/dispatch-provider.sh <provider-name> --role '<role>' --topic '<topic>' --instructions '<instructions>' [--approaches '<text>'] [--design-doc-file <path>] [--diff-file <path>] [--previous-feedback-file <path>]"
)
```

For large content (design docs, diffs, feedback), write to a temp file first and pass the path:
```bash
DIFF_FILE=$(mktemp /tmp/diff-XXXX.txt)
git diff main...HEAD > "$DIFF_FILE"
hooks/dispatch-provider.sh codex --role "Drift analyst" --topic "..." --instructions "..." --diff-file "$DIFF_FILE"
rm -f "$DIFF_FILE"
```

**Parallelism rule:** When dispatching multiple providers, fire ALL in a single message — one Bash call per provider, all with `run_in_background: true`. This gives true parallelism.

For Claude positions in panel debates, use `Agent(run_in_background: true)` — this procedure covers external CLI providers only.

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
- **Respawn**: TaskStop the hung task, re-dispatch, collect again with fresh timeout
- **Kill**: TaskStop and proceed with whatever results are available

### Unattended mode

For each task, call:
```
TaskOutput(task_id: <id>, timeout: <timeout.unattended * 1000>)
```

If timeout fires before result:
- `TaskStop(task_id)`
- Log: "`<provider>` timed out after `<timeout>`s, proceeding without"

**First-past-the-post:** When collecting from multiple providers, process results as they arrive. If 2+ providers have returned and a remaining provider times out, proceed with available results.

## Parse Output

The output is the provider's raw response. Return it to the calling skill as-is — the caller handles synthesis and aggregation.
