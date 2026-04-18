---
title: Audit Block 179 — Instant Retro Local State De-Tracking
category: audit
tags: [audit, claude, skills, cleanup, local-state]
sources:
  - .claude/skills/instant-retro/SKILL.md
  - .claude/skills/instant-retro/last-retro.json
  - .gitignore
  - wiki/audit/block-004-claude-product-governance-skills.md
updated: 2026-04-17
---

# Audit Block 179 — Instant Retro Local State De-Tracking

## Scope

This block closes the old `block-004` follow-up about mutable retro session state living inside tracked project files.

- **Files audited in this block:** 4
- **Primary file type:** Claude skill protocol plus tracked JSON state and audit/wiki sync
- **Status:** Fixed
- **Related pages:** [[block-004-claude-product-governance-skills]], [[audit-index]], [[project-file-inventory]]

## Summary

- `instant-retro` used a tracked JSON file inside `.claude/skills/`, which made local runtime state look like project source.
- `.gitignore` already ignored `.claude/tmp/`, so the cleanest fix was to move retro state there.
- The skill now reads and writes `.claude/tmp/instant-retro-last.json`.
- The tracked `.claude/skills/instant-retro/last-retro.json` was deleted from the working tree and is now documented as removed local-state residue.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P2 | `instant-retro` stored mutable runtime state inside tracked `.claude/skills/instant-retro/last-retro.json`. | Repo noise, stale session state in source control, and misleading audit inventory. | Moved the state path to ignored `.claude/tmp/instant-retro-last.json`, seeded the new local file, and deleted the tracked JSON from the working tree. |

## File Records

| Path | Name / Zone | Purpose / What It Does | Depends On | Used By | Main Functions / Components | Business Rules | Problems Found | Fixed | Separate Decision | Status |
|------|-------------|------------------------|------------|---------|-----------------------------|----------------|----------------|-------|-------------------|--------|
| `.claude/skills/instant-retro/SKILL.md` | Instant retro skill | Generates a session retrospective from git history, diff stat, status, and optional transcripts. | Git history, optional transcript APIs, ignored local state file. | Retro/progress workflows. | Reads prior timestamp, gathers changes, writes next checkpoint. | Runtime state should live in ignored local storage, not tracked repo content. | Old instructions still pointed at a tracked JSON file. | Switched the state path to `.claude/tmp/instant-retro-last.json`. | None. | Fixed |
| `.claude/skills/instant-retro/last-retro.json` _(deleted in working tree)_ | Former retro state file | Former tracked JSON checkpoint for instant retro. | `instant-retro/SKILL.md`. | Historical workflow only. | `timestamp`, `commit`, `summary`, `retro_count`. | Tracked repo files should not hold mutable per-user runtime state. | Tracked mutable local state. | Removed from the working tree and replaced by ignored local state. | None. | Fixed |
| `.gitignore` | Ignore rules | Defines ignored local/build/runtime paths. | Repo root. | Git, local tools, Claude runtime helpers. | Ignore matching. | Local Claude temp state belongs under ignored `.claude/tmp/`. | No defect in this block; existing ignore rule enabled the cleanup. | Reused existing `.claude/tmp/` ignore path; no new ignore rule needed. | None. | OK |
| `wiki/audit/block-004-claude-product-governance-skills.md` | Prior audit record | Records the original `.claude` governance-skill audit and open decisions. | Wiki audit chain. | Audit readers and future cleanup passes. | File record table, candidates, decisions, verification. | Old open decisions should be closed once later blocks resolve them. | `last-retro.json` was still recorded as an unresolved candidate. | Updated the record to mark the relocation as fixed. | None. | Fixed |

## Verification

- Re-read `.claude/skills/instant-retro/SKILL.md` to confirm the new state path is `.claude/tmp/instant-retro-last.json`.
- Confirmed `.gitignore` already ignores `.claude/tmp/`.
- Confirmed the old tracked `last-retro.json` file was removed from the working tree.
- Seeded `.claude/tmp/instant-retro-last.json` with the prior retro checkpoint so the skill keeps continuity without writing tracked state.

