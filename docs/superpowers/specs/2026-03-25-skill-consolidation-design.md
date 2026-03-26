# Skill Consolidation: 17 → 10 Composable Skills

## Problem

Fiddle has 17 skills. The phase-based organization is clear, but the sheer count creates cognitive load: knowing which skill to use when, and maintaining consistency across a large surface area.

The user values:
- The discover → define → develop → deliver flow (with phase skipping)
- Multiple LLM providers for exploration
- Hands-on and hands-free implementation
- Beans as the fundamental building block
- Standardized docs

The goal: **fewer skills, same capabilities, composable by design.**

## Design: Composable Phases + Primitives

Two-tier architecture:

| Tier | Skills | Purpose |
|------|--------|---------|
| **Phases** (workflows) | `orchestrate`, `discover`, `define`, `develop`, `deliver` | Lifecycle stages that compose primitives |
| **Primitives** (tools) | `panel`, `challenge`, `capture`, `discover-docs` | Small, focused, independently invocable building blocks |
| **Infrastructure** | `patch-superpowers` | Maintenance, orthogonal to workflow |

**Total: 10 skills** (down from 17). No behavior lost.

### Why 10 and not 8

Prior analysis (bean `fiddle-adk6`, scrapped 2026-03-25) established that `discover-docs` has legitimate standalone use for periodic doc reviews outside any epic flow. Inlining 109 lines of Socratic dialogue into `discover` would add bulk without removing redundancy — `discover` currently delegates via a single `Skill()` call. `discover-docs` is reclassified as a **primitive** (a focused tool that phases compose) rather than a phase sub-skill.

### Three usage tiers

```
Tier 1: Just beans
  beans create → fix it → beans update completed
  (no skills needed)

Tier 2: Beans + primitives
  beans create → challenge (interrogate root cause) → fix it → capture --type adr
  (grab individual primitives as needed)

Tier 3: Beans + phases
  orchestrate → discover → define → develop → deliver
  (full lifecycle, phases invoke primitives internally)
```

A bug fix uses tier 1 or 2. A new feature uses tier 3. The primitives are the composability layer — useful standalone AND inside phases.

## Consolidated Skill Specifications

### 1. `orchestrate` (modified — sentinel update)

Phase sequencing, config parsing, epic resumption and phase tags — all unchanged.

**Required fix:** Phase resumption logic currently uses `git log --oneline --grep="deliver-docs"` to detect whether the deliver phase already ran. After consolidation, "deliver-docs" will no longer appear in commit messages. Update the sentinel to grep for `"deliver"` or check the epic's `orchestrate-phase:deliver` tag instead.

### 2. `discover` (unchanged)

Continues to:
1. Invoke `discover-docs` primitive (single `Skill()` call)
2. Dispatch external research via providers
3. Invoke `challenge` primitive for scope validation

No absorption. `discover-docs` stays standalone as a primitive.

### 3. `define` (absorbs `define-beans`)

**Current:** `define` chains brainstorming → panel → challenge → writing-plans. `define-beans` is a separate skill with bean sizing rules referenced by writing-plans.

**New:** Single skill with bean sizing rules as a final section:

```
Step 1: Brainstorm approaches (invokes superpowers:brainstorming)
Step 2: Panel enrichment (invokes panel primitive, optional)
Step 3: Challenge design (invokes challenge primitive)
Step 4: Create implementation plan (invokes superpowers:writing-plans)
Step 5: Bean sizing and creation (was define-beans)
  - Sizing rules:
    - 1-2 TDD cycles → task bean
    - 3+ TDD cycles → feature bean with child task beans
  - Shared contracts pattern for parallel work
  - Dependency management across beans
```

**What moves:** The full content of `define-beans/SKILL.md` — sizing rules, shared contracts pattern, dependency management — becomes the "Bean Sizing" section. Writing-plans references these rules during plan creation; the section serves as the authoritative reference.

### 4. `develop` (absorbs `develop-subs` + `develop-team`)

**Current:** `develop` presents execution choices and delegates to `develop-subs` or `develop-team`. Both variants share `ralph-core.md` but are separate skill files.

**New:** Single skill. The `--execution` flag (already exists in `develop`) routes to the appropriate mode section. The **full behavioral content** of each variant SKILL.md is preserved verbatim as conditional sections — not summarized. The current dispatch mechanism (`Read` of external `develop-subs/SKILL.md` and `develop-team/SKILL.md` files) is replaced by inline mode sections within the single skill file.

```
Step 1: Validate epic and present execution choices (unchanged)
  - Ralph Subs (background agents)
  - Ralph Team (persistent teammates)
  - Hands-on this session
  - Hands-on parallel session

Step 2: Execute based on choice → mode section
```

**Mode: subs** (verbatim from `develop-subs/SKILL.md`):
- Variant identifier: keep `<!-- VARIANT:subs -->` blocks, strip `<!-- VARIANT:team -->`
- No additional setup after core step 4
- Event handling: background task notifications → identify bean from task name → read result via TaskOutput → check role tag → follow ralph-core "Handling Results"
- Tag management on implementer → review transition: `--remove-tag role:implement --remove-tag bg-task:{old_task_id} --remove-tag ci-retries --remove-tag stall-respawns --remove-tag spawned-at --tag role:review`
- Review coordinator spawn: update `bg-task` tag to new task ID
- User interrupt handling: "Assess and Act" immediately, check task status for in-progress beans with `bg-task:*` tag
- `--caller <name>` flag: output machine-readable `RALPH_STATUS` on exit
- Agent spawn config: no `team_name`, all subagents, `run_in_background: true`
- Completion: PARKED (needs-attention beans) or COMPLETE (holistic review + cleanup). If `--caller` set: machine-readable status. If not: remind user: `"Run /fiddle:deliver --epic <id> to update project docs."` (Note: source file says `deliver-docs` — update to `deliver` when inlining.)

**Mode: team** (verbatim from `develop-team/SKILL.md`):
- Variant identifier: keep `<!-- VARIANT:team -->` blocks, strip `<!-- VARIANT:subs -->`
- Variant setup: `TeamCreate`, `TaskCreate` for each non-completed bean with `blocked-by` mirroring
- Event handling: act IMMEDIATELY on each message, never batch, never send shutdown mid-work
- Implementer reports done → follow ralph-core handling, transition tags
- Review coordinator reports verdict → follow ralph-core handling, mark team task completed on APPROVED
- Integration test lock protocol: grant/deny/release with bean tag tracking (`integration-lock:{teammate-name}`)
- Stale implementer handling (idle, no prior message → Abandon Bean)
- Stale review coordinator handling (idle, no prior verdict → increment cycle or Abandon)
- Noise message handling: IGNORE, STOP
- User interrupt handling: "Assess and Act" immediately, respawn for beans with no active agents
- Agent spawn config: `team_name` present, `run_in_background: true`
- Feature expansion extra: `TaskCreate` for new children, mark team task completed on feature completion

**Mode: hands-on** (unchanged):
- Superpowers TDD/executing-plans, no ralph machinery

**Step 3: Handle ralph results** (unchanged)

**What stays untouched:**
- `ralph-core.md` — shared loop logic
- `roles/*.md` — all role templates
- `checklists/*.md` — language-specific review checklists

### 5. `deliver` (absorbs `deliver-docs`)

**Current:** `deliver` runs drift analysis, invokes `deliver-docs`, closes epic.

**New:** Single skill with doc updates inlined as step 3. Flags from `deliver-docs` are promoted to `deliver`:

**Flag table (updated):**
| Flag | Source | Description |
|------|--------|-------------|
| `--epic <id>` | both | Scope to this epic |
| `--diff` | deliver-docs | Also read git diff of recent work (default: infer from beans) |
| `--dry-run` | deliver-docs | Show proposed changes without writing |

```
Step 1: Validate epic (unchanged)

Step 2: Drift analysis (unchanged)
  - Compare design to implementation via external providers
  - Optional, graceful degradation

Step 3: Documentation updates (was deliver-docs, full content preserved)
  - Gather context: read all docs, completed beans, optionally git diff
  - Classify changes: architectural → SYSTEM.md, decisions → ADR,
    issues/ideas → BACKLOG, product implications → flag only
  - Propose ALL changes grouped by doc, wait for user confirmation
  - Write changes respecting doc schema constraints:
    VISION <1 page, SYSTEM 1-2 pages, ADRs ~10-20 lines each
  - ADR creation: `Skill(skill: "fiddle:capture", args: "--type adr <context>")`
  - BACKLOG append: `Skill(skill: "fiddle:capture", args: "--type backlog <item>")`
  - Deliver does NOT duplicate capture logic — it delegates via Skill() calls
  - Verify: read back files, check schema constraints, confirm no
    append-only entries deleted
  - --dry-run skips the write step entirely
  - Rules: never auto-update product docs (VISION, MARKET, PRICING, GTM),
    never edit existing ADRs, never delete append-only entries,
    never bloat docs beyond schema constraints

Step 4: Close epic (unchanged)
```

### 6. `panel` (primitive, mostly unchanged)

Stays as a standalone primitive. No structural changes needed.

One simplification: **remove degraded mode complexity.** Currently, when no external providers are available, panel spawns two Claude subagents as competing advocates.

**New behavior when no providers available:**
- Claude presents both sides inline (pro/con analysis) instead of spawning two subagent advocates
- Cross-review step is skipped (one model can't meaningfully cross-review itself)
- Synthesis proceeds as normal

### 7. `challenge` (primitive, unchanged)

No changes. Already a clean, focused primitive.

### 8. `capture` (new primitive, replaces `adr` + `feedback` + `backlog`)

Single skill with `--type` parameter:

```
/fiddle:capture --type adr "Context and decision..."
/fiddle:capture --type feedback "What the user said..."
/fiddle:capture --type backlog "Idea or debt item..."
```

**Behavior by type:**

| Type | Target file | Format | Tags |
|------|------------|--------|------|
| `adr` | `docs/technical/decisions/NNN-title.md` | Context/Decision/Consequences (~10-20 lines) | None (numbered) |
| `feedback` | `docs/product/FEEDBACK.md` | Append entry with auto-tags | `#feature-request` `#bug` `#confusion` `#praise` `#churn-signal` `#ux` `#performance` |
| `backlog` | `docs/BACKLOG.md` | Append entry with auto-tags | `#idea` `#debt` `#optimization` `#feature` `#experiment` `#infrastructure` `#ux` `#security` |

**Process (per type, preserved from source skills):**

- **adr**: If user provided enough detail, draft directly. Otherwise ask 2-3 brief questions about context, decision, and consequences. Auto-increment number from highest in `docs/technical/decisions/`. Create directory if it doesn't exist.
- **feedback**: If no argument, ask what the user heard/observed. Ask for source/context if not obvious. Auto-assign tags. Create `docs/product/FEEDBACK.md` with header `# User Feedback` if it doesn't exist.
- **backlog**: Determine origin from context (which epic, which conversation). Auto-assign tags. Scan existing entries briefly to avoid duplicates. Create `docs/BACKLOG.md` if it doesn't exist.

**Shared rules:**
- Append-only (feedback, backlog). Never edit existing entries.
- ADR: auto-increment number, write new file. Never edit old ADRs.
- All types: ask user to confirm content before writing.

### 9. `discover-docs` (primitive, reclassified)

No content changes. Reclassified from "discover sub-skill" to "primitive" in the taxonomy. Continues to be invoked by `discover` via `Skill()` call, and can be invoked standalone for periodic doc reviews.

### 10. `patch-superpowers` (infrastructure, updated references)

Content unchanged except for stale references to deleted skills:

| Line | Old reference | New reference |
|------|--------------|---------------|
| ~202 | `"follow the define-beans skill"` | `"follow the Bean Sizing section in define"` |
| ~232, 294, 306 | `"/fiddle:develop-team"` | `"/fiddle:develop --execution team"` |

After updating, re-run `patch-superpowers` to refresh any already-patched superpowers caches.

## Files Changed

### Deleted (7 skill directories + 1 script directory)

```
skills/define-beans/       → absorbed into skills/define/
skills/develop-subs/       → absorbed into skills/develop/
skills/develop-team/       → absorbed into skills/develop/
skills/deliver-docs/       → absorbed into skills/deliver/
skills/adr/                → replaced by skills/capture/
skills/feedback/           → replaced by skills/capture/
skills/backlog/            → replaced by skills/capture/
scripts/                   → removed (orchestrate-status.sh unused TUI dashboard)
```

### Created (1 skill directory)

```
skills/capture/SKILL.md    → new primitive (replaces adr + feedback + backlog)
```

### Modified (5 skill files)

```
skills/define/SKILL.md         → add bean sizing section from define-beans
skills/develop/SKILL.md        → inline subs/team mode sections (verbatim) from develop-subs/develop-team
skills/deliver/SKILL.md        → inline doc update steps from deliver-docs, promote --diff/--dry-run flags
skills/panel/SKILL.md          → simplify degraded mode (inline analysis, remove subagent advocates)
skills/patch-superpowers/SKILL.md → update references to deleted skills
```

### Cross-reference updates

These files reference deleted skill names and must be updated:

| File | References to update |
|------|---------------------|
| `skills/orchestrate/SKILL.md` | Phase detection sentinel: `git log --grep="deliver-docs"` → `git log --grep="deliver"` or tag check. Reminder text at ~line 246: `"/fiddle:deliver-docs --epic <id>"` → `"/fiddle:deliver --epic <id>"` |
| `skills/challenge/SKILL.md` | `discover-docs` in phase behavior description → no change needed (discover-docs still exists) |
| `skills/ralph/ralph-core.md` | `develop-subs and develop-team` in description → update to `develop (subs/team modes)` |
| `docs/technical/SYSTEM.md` | Component list referencing old skill names |
| `README.md` | Skill names in feature list |
| `docs/README.md` | Flow diagram and skill references |

### Unchanged

```
skills/orchestrate/SKILL.md    (except sentinel fix)
skills/discover/SKILL.md
skills/challenge/SKILL.md
skills/discover-docs/SKILL.md  (reclassified only)
skills/ralph/ralph-core.md     (except description update)
skills/ralph/roles/*.md     (progress reporting removed, decision protocol added to implementer,
                                review-coordinator progress body-append removed)
skills/ralph/checklists/*.md
hooks/*                        (note: task-completed-verify.sh matches `develop-team-*` pattern —
                                team name format is intentionally preserved in mode:team section)
orchestrate.json
```

## Behavior Coverage Verification

Before deleting any old skill file, run this mechanical check:

1. For each deleted skill, extract every action verb line (invoke, dispatch, append, create, check, tag, spawn, read, write, update)
2. Verify each action appears in the new consolidated skill
3. Any unmatched action is a gap that must be addressed before deletion

This is the safety net — no behavior lost through oversight.

## Migration Order

Implement in this order to minimize risk (each step is independently shippable):

1. **`capture`** — Create new primitive. Verify it handles all three types correctly. Delete `adr`, `feedback`, `backlog`.
2. **`define`** — Inline bean sizing rules. Delete `define-beans`.
3. **`deliver`** — Inline doc updates, promote `--diff`/`--dry-run` flags. Update to use `capture` for ADR/backlog. Delete `deliver-docs`.
4. **`develop`** — Inline subs/team modes verbatim. Delete `develop-subs`, `develop-team`.
5. **`panel`** — Simplify degraded mode.
6. **Cross-references** — Update all files listed in cross-reference table.
7. **`orchestrate`** — Fix phase detection sentinel.
8. **`patch-superpowers`** — Update stale references, re-patch superpowers cache.
9. **`SYSTEM.md`, `README.md`, `docs/README.md`** — Update documentation to reflect new skill inventory.

Each step: consolidate → verify behavior coverage → delete old skill → commit.

## Acknowledged Tradeoffs

**Larger individual files:** After absorption, projected sizes:
- `define/SKILL.md`: ~165 lines (from 75)
- `develop/SKILL.md`: ~325 lines (from 178)
- `deliver/SKILL.md`: ~200 lines (from 90)

This is the explicit tradeoff: fewer files but larger individual files. The develop skill is the largest concern at ~325 lines, but most of that is two clearly separated mode sections that are only read when the corresponding mode is selected. If a file becomes hard to navigate, the ralph pattern (separate `roles/*.md` files referenced by the main skill) can be applied — extract mode-specific content to `skills/develop/mode-subs.md` and `skills/develop/mode-team.md` referenced via "Read `skills/develop/mode-subs.md`". This is a future option, not part of this migration.

## Final State: Documentation

After migration, the project README and docs/README should reflect the consolidated skill inventory.

### README.md

```markdown
# Fiddle

Claude Code plugin for orchestrating a four-phase development lifecycle with multi-model support.

## Orchestrate

`/fiddle:orchestrate <topic>` chains four phases. Each phase is also a standalone skill.

**DISCOVER** [`/fiddle:discover`](skills/discover/SKILL.md) — Scan project docs, research the ecosystem via external providers, and challenge scope assumptions until every branch is resolved.

**DEFINE** [`/fiddle:define`](skills/define/SKILL.md) — Brainstorm approaches, run a multi-model adversarial panel, challenge the chosen design, then produce an implementation plan with sized beans.

**DEVELOP** [`/fiddle:develop`](skills/develop/SKILL.md) — Execute beans via ralph subs (`--execution subs`, background agents) or ralph team (`--execution team`, persistent teammates), or hands-on. Holistic review via external providers when done.

**DELIVER** [`/fiddle:deliver`](skills/deliver/SKILL.md) — Drift analysis via external providers, update technical docs, close the epic.

> [!NOTE]
> Any CLI that accepts a prompt on stdin works as a provider (Codex, Gemini, Copilot, etc). Configure per phase in [`orchestrate.json`](orchestrate.json).

## Primitives

Focused tools that phases compose internally, but are also useful standalone.

| Primitive | Description |
|-----------|-------------|
| [`fiddle:panel`](skills/panel/SKILL.md) | Multi-model adversarial debate — participants argue positions and cross-review. |
| [`fiddle:challenge`](skills/challenge/SKILL.md) | Walk the decision tree on any plan or design until shared understanding. |
| [`fiddle:capture`](skills/capture/SKILL.md) | Record an ADR, user feedback signal, or backlog item (`--type adr\|feedback\|backlog`). |
| [`fiddle:discover-docs`](skills/discover-docs/SKILL.md) | Socratic dialogue to bootstrap or review project docs. |

## Three Ways to Work

| Tier | When | Example |
|------|------|---------|
| **Just beans** | Simple bug fix, known solution | `beans create "Fix X" -t bug` → fix → done |
| **Beans + primitives** | Investigation, needs a second opinion | `challenge` to interrogate root cause, `capture` to record a decision |
| **Beans + phases** | New feature, full lifecycle | `orchestrate` → discover → define → develop → deliver |

## Language Support

Review checklists in [`skills/ralph/checklists/`](skills/ralph/checklists/) provide language-specific quality rules. The review coordinator auto-detects the language from the diff.

Shipped: `go`, `dart`, `typescript`. To add a language, create `skills/ralph/checklists/<lang>.md`.

## Configuration

Orchestrate reads [`orchestrate.json`](orchestrate.json) from the project root. All keys optional — defaults apply when omitted. See [`fiddle:orchestrate`](skills/orchestrate/SKILL.md) for the full reference.

## Install

Requires [superpowers](https://github.com/obra/superpowers) plugin.

\`\`\`bash
# superpowers (dependency)
/plugin install superpowers

# fiddle — from marketplace
/plugin marketplace add github:peel/peel-marketplace
/plugin install fiddle

# fiddle — from source
claude --plugin-dir /path/to/fiddle
\`\`\`

After install, run `/fiddle:patch-superpowers` to apply beans integration. Providers are auto-detected on session start.

### Optional: Clash (conflict detection)

When running parallel workers in worktrees, fiddle includes a PreToolUse hook that warns agents before writing to files that conflict with another worktree. This requires [clash](https://github.com/clash-sh/clash):

\`\`\`bash
# via cargo
cargo install clash-sh

# via nix
nix profile install github:clash-sh/clash
\`\`\`

The hook is advisory (never blocks) and silently skips if clash is not installed.
```

### docs/README.md

```markdown
# Project Documentation

Living docs for product and technical decisions. Persistent knowledge that informs all work — separate from beans (actionable work) and plans (session-scoped execution).

**Flow:** `/discover-docs` → `/challenge` → brainstorming → `/panel` → `/challenge` → writing-plans → beans → `/develop` → `/deliver`

## Structure

\`\`\`
docs/
├── product/
│   ├── VISION.md        — what, who, why, non-goals
│   ├── MARKET.md         — landscape, competitors, positioning
│   ├── PRICING.md        — business model, costs, revenue
│   ├── GTM.md            — distribution, channels, messaging
│   └── FEEDBACK.md       — user signals (append-only)
├── technical/
│   ├── SYSTEM.md         — how it works now
│   ├── decisions/
│   │   └── NNN-title.md  — ADRs (append-only)
│   └── RUNBOOKS.md       — deploy, rollback, common issues
└── BACKLOG.md            — pre-bean ideas and debt (append-only)
\`\`\`

## Skills

- `/discover-docs [scope]` — Socratic dialogue to bootstrap or review docs
- `/capture --type adr <title>` — new architecture decision record
- `/capture --type feedback <signal>` — append user feedback
- `/capture --type backlog <idea>` — append idea or debt item
- `/deliver [--epic <id>] [--dry-run]` — post-ship update of technical docs, ADRs, backlog

## Conventions

- Product docs: overwrite freely. Technical decisions: append-only, supersede with new records.
- Append-only logs (FEEDBACK, BACKLOG, decisions/) are never edited or deleted.
- Every curated doc has a `Last reviewed:` date.
- Keep it short. A doc you won't read doesn't exist.
```

## What This Does NOT Change

- The four-phase lifecycle (discover → define → develop → deliver)
- Beans as the fundamental building block
- Ralph's execution model (assess-and-act loop, reaction engine, worktrees)
- Multi-model provider support
- Hands-on vs hands-free implementation choice
- Standardized documentation structure
- Any hook behavior
- orchestrate.json configuration
- discover-docs standalone invocation
