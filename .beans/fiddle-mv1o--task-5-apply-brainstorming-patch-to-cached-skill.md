---
# fiddle-mv1o
title: 'Task 5: Apply brainstorming patch to cached skill'
status: todo
type: task
priority: normal
tags:
    - branch
created_at: 2026-03-14T18:37:24Z
updated_at: 2026-03-14T19:03:11Z
parent: fiddle-9qn1
blocked_by:
    - fiddle-fabu
---

Plan: docs/plans/2026-03-14-orchestrate-panel-integration.md Task 5

Files:
- Modify: $CLAUDE_CONFIG_DIR/plugins/cache/superpowers-marketplace/superpowers/*/skills/brainstorming/SKILL.md

Steps:
1. Find cached brainstorming SKILL.md
2. Check for [BEANS-PATCHED] marker — skip if present
3. Apply all patches from patch-superpowers Step 3 (3a-3f):
   - 3a: Add ARGS line with --skip-panel and --from-orchestrate flags
   - 3b: Add panel enrichment to checklist, renumber items
   - 3c: Add panel node to process flow graph
   - 3d: Add --from-orchestrate check to graph terminal state
   - 3e: Replace terminal state text with flag-dependent version
   - 3f: Replace Implementation subsection with flag-dependent version
   - Append [BEANS-PATCHED] marker
4. Read patched file and verify all changes

Acceptance criteria:
- ARGS line with --skip-panel and --from-orchestrate flags present
- Checklist has panel enrichment item (7 items total)
- Process flow has panel and --from-orchestrate nodes
- Terminal state is flag-dependent
- [BEANS-PATCHED] marker at end
