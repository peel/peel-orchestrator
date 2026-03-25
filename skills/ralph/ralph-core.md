# Ralph Core Loop

Shared orchestration loop for both ralph variants (develop-subs and develop-team). Each variant's SKILL.md handles setup extras, event delivery, and spawn configuration — this file covers the common loop logic.

## Configuration

Flags (all optional, order-independent):
- `--epic <id>` — scope to beans under this epic (uses `beans list --parent <id>`)
- `--workers N` (default: 10) — parallel beans in-flight
- `--max-review-cycles N` (default: 10) — max cycles before abandoning
- `--max-impl-turns N` (default: 100) — max agent turns per implementer spawn
- `--max-review-turns N` (default: 100) — max agent turns per review coordinator
- `--ci-max-retries N` (default: 3) — CI failures before tagging `needs-attention`
- `--stall-timeout-min N` (default: 15) — minutes of inactivity before respawn/escalation
- `--stall-max-respawns N` (default: 2) — stall respawns before tagging `needs-attention`

**`BEANS_LIST` command:** When `--epic <id>` is set, every `beans list` invocation MUST include `--parent <id>`.
- With `--epic cv0e`: `beans list --parent cv0e --json`
- Without `--epic`: `beans list --json`

**Reading bean data:** Use `beans show <id> --json` via Bash. Do NOT pipe through `python3` or suppress stderr.

**STOP rule:** After processing any event, STOP — end your turn. Do not narrate or summarize. Exceptions noted inline.

## Setup (first turn only)

1. `BEANS_LIST` — if no incomplete beans, stop
2. Compute `MAIN_BEANS_PATH`: the absolute path to `.beans/` in the main checkout. Store this value — it will be substituted into all agent prompts as `{MAIN_BEANS_PATH}`. Example: if main checkout is `/Users/peel/wrk/board`, then `MAIN_BEANS_PATH=/Users/peel/wrk/board/.beans`.
3. Discover available agents: list `.claude/agents/*.md`, `~/.claude/agents/*.md`, and `skills/ralph/roles/*.md`. Read each file's opening lines to understand capabilities.
4. **Worktree setup** (when `--workers > 1`): Read `skills/ralph/roles/lead-procedures.md` → follow "Worktree Setup".
5. **Variant-specific setup** — see your variant's SKILL.md for additional steps.
6. Fall through to "Assess and Act"

## Every Turn: Assess and Act

Every bean goes through: **implement** → **review** (coordinator handles review internally).

Run `BEANS_LIST`. Then:

### Reaction Checks

For each `in-progress` leaf bean, run `beans show {id} --json` and check:

1. **CI failure escalation:** If the bean has a `ci-retries:N` tag and `N >= ci_max_retries`:
   ```bash
   beans update {id} --tag needs-attention
   echo "$(date +%H:%M) impl-{id} failed ${N}x → needs attention" >> .claude/orchestrate-events.log
   ```

2. **Stall detection:** Parse the last timestamp from `## Progress` entries (format: `- HH:MM ...`). If the last entry is older than `stall_timeout_min` minutes:
   - Check the `stall-respawns:N` tag:
     - If `N < stall_max_respawns` (or tag doesn't exist):
       ```bash
       beans update {id} --tag stall-respawns:$((N+1))
       echo "$(date +%H:%M) impl-{id} stalled → respawned ($((N+1))/${stall_max_respawns})" >> .claude/orchestrate-events.log
       ```
       Next cycle will spawn a fresh implementer that reads `## Progress` and continues.
     - If `N >= stall_max_respawns`:
       ```bash
       beans update {id} --tag needs-attention
       echo "$(date +%H:%M) impl-{id} stalled ${N}x → needs attention" >> .claude/orchestrate-events.log
       ```

3. **Review overflow:** If a bean's review cycle count (from tags) reaches `max_review_cycles`:
   ```bash
   beans update {id} --tag needs-attention
   echo "$(date +%H:%M) review-{id} overflow → needs attention" >> .claude/orchestrate-events.log
   ```

### Feature Expansion

For each **feature** bean in the list:
- If `todo` with no blockers → `beans update {id} --status in-progress`
- If `in-progress` → list children: `beans list --parent {id} --json`. Add children to work queue.
- If `in-progress` AND all children `completed` → `beans update {id} --status completed`

### Dispatch Ready Beans

After expansion, work only with **leaf beans** (task, bug):

1. Count `in-progress` leaf beans = active_count
2. Count `todo` leaf beans with no blockers = ready_beans
3. available_slots = workers - active_count

**If ready_beans > 0 AND available_slots > 0:**
For each ready leaf bean (up to available_slots):
- `beans update {id} --status in-progress`
- Select agents for this bean (auto-select based on bean content)
- Tag the bean: `--tag agent:{impl-name} --tag reviewers:{r1}+{r2}`
- **Worktree assignment:** Check bean tags:
  - `worktree` tag (or no tag when `--workers > 1`): assign available worktree slot. Tag bean: `--tag worktree-slot:{prefix}-{N}`
  - `branch` tag: skip worktree, main checkout. Only ONE `branch`-tagged bean in-progress at a time.
- Spawn implementer (see "Spawning Agents"). Launch all spawns in ONE message. STOP.

**If active_count > 0 AND ready_beans == 0:** STOP.

**If active_count == 0 AND ready_beans == 0:**

Check for `needs-attention` beans: `beans list --parent <epic-id> --json` and filter for `needs-attention` tag.

- **If needs-attention beans exist:** Report per variant SKILL.md format and STOP.
- **If all beans completed:** Read `skills/ralph/roles/lead-procedures.md` → run "Epic Holistic Review". If none → follow "Cleanup".

## Handling Results

When an implementer or review coordinator delivers its result (delivery mechanism varies by variant — see your SKILL.md):

### Implementer Result (non-empty)

- Present the diff to the user.
- Read `skills/ralph/roles/lead-procedures.md` → run "Lead Verification". If fails → spawn fix implementer, skip review. STOP.
- `beans update {id} --remove-tag role:implement --tag role:review` (variant may add/remove additional tags — see variant SKILL.md)
- Spawn review coordinator (see "Spawning Agents"). STOP.

### Implementer Result (empty/error)

Stale — read `skills/ralph/roles/lead-procedures.md` → "Abandon Bean". STOP.

### Review Verdict

The result starts with `VERDICT {bean-id} {TYPE}`. Parse the bean ID and verdict type from the first line.

- **`VERDICT {id} APPROVED`** → `beans update {id} --status completed`. Check parent feature: if parent exists and all siblings completed → complete feature. "Assess and Act". STOP.
- **`VERDICT {id} APPROVED_WITH_COMMENTS`** → present comments to user. Parse `FLAGGED_BY:` line (second line). `beans update {id} --remove-tag role:review --tag role:review-fix-{cycle} --tag flagged-by:{reviewers}`. Spawn NEW implementer with suggestions (using `superpowers:receiving-code-review`). STOP.
- **`VERDICT {id} ISSUES`** → present issues to user. Parse `FLAGGED_BY:` line (second line). If cycle >= max_review_cycles → read `skills/ralph/roles/lead-procedures.md` → "Abandon Bean". STOP. Otherwise: `beans update {id} --remove-tag role:review --tag role:review-fix-{cycle} --tag flagged-by:{reviewers}`, spawn fix implementer. STOP.
- **Unparseable result** → log warning, find bean via task name. If cycle >= max_review_cycles → "Abandon Bean". Otherwise: increment cycle, respawn review coordinator. STOP.

**User interrupts (esc) or says to proceed:** "Assess and Act" immediately. Re-read tags. For beans with active agents, check status per variant mechanism. If completed, process result. If no active agent, respawn.

## Spawning Agents

**NEVER inline or simplify role templates.** Always Read the actual file and substitute placeholders. Do not paraphrase, abbreviate, or rewrite templates to save tokens — agents follow instructions literally and skip steps when prompts are simplified.

### Implementer Spawn

1. Read `skills/ralph/roles/implementer.md`, replace placeholders (`{BEAN_ID}`, `{BEAN_TITLE}`, `{BEAN_BODY}`, `{WORKTREE_PATH}`, `{MAIN_BEANS_PATH}`)
2. Strip `<!-- VARIANT:... -->` sections that don't match your variant (keep your variant's sections, remove the other's)
3. If worktree assigned: omit the `## Git Coordination` section (between `<!-- CONDITIONAL -->` markers)
4. For fix cycles, append issues under `## Review Issues to Address`
5. Spawn per your variant's agent config (see variant SKILL.md for `Agent(...)` parameters)

### Review Coordinator Spawn

**Cycle 1:** Auto-select domain agents relevant to the bean. If no domain agents match, use `baseline` as fallback.
**Cycle 2+:** Use only the reviewers from the bean's `flagged-by:*` tag (set by previous verdict).

1. Read `skills/ralph/roles/review-coordinator.md`, replace placeholders (`{BEAN_ID}`, `{BEAN_TITLE}`, `{BEAN_BODY}`, `{WORKTREE_PATH}`, `{MAIN_BEANS_PATH}`, `{REVIEW_CYCLE}`, `{PREVIOUS_ISSUES}`, `{REVIEWER_LIST}`)
2. Strip `<!-- VARIANT:... -->` sections that don't match your variant
3. Spawn per your variant's agent config

## Rules

- Always `run_in_background: true` — never block on agent calls
- Models: from orchestrate.json `models.develop`; "default" means omit model parameter to inherit session model. Epic holistic review always uses opus.
- Fresh context per cycle — never resume agents
- Never implement beans yourself — delegate only
- Safe to kill and restart — beans CLI holds all state
- **Bean commands from worktree context:** After any `cd {worktree_path}`, use `beans --beans-path $MAIN_BEANS_PATH` for all subsequent `beans` commands until you return to the main checkout. Alternatively, always use `--beans-path $MAIN_BEANS_PATH` for safety — it is harmless when already in main.
