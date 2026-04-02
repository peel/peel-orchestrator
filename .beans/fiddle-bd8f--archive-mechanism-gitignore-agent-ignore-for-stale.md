---
# fiddle-bd8f
title: Archive mechanism — gitignore + agent-ignore for stale beans and plans
status: completed
type: feature
priority: normal
created_at: 2026-04-02T07:40:20Z
updated_at: 2026-04-02T07:59:41Z
---

Archive completed/scrapped beans and delivered plans. Gitignore archive directories, git rm --cached archived files, enforce agent never-read via PreToolUse hook. Add fiddle:archive skill and prompt in deliver phase.

## Summary of Changes

Created archive mechanism with multi-agent enforcement:
- scripts/archive.sh — runs beans archive, moves plans to .archive/plans/, git rm --cached
- skills/archive/SKILL.md — thin skill wrapper, invocable by deliver phase or on-demand
- hooks/archive-guard.sh — PreToolUse hook rejecting reads from archive paths
- hooks/hooks.json — wired archive-guard for Claude Code (Read|Glob|Grep|Bash)
- .codex/hooks.json — wired archive-guard for Codex
- .geminiignore — Gemini CLI ignore for archive dirs
- .gitignore — excludes .beans/archive/ and .archive/ from repo
- skills/deliver/SKILL.md — added Step 7 (archive) after epic closure
