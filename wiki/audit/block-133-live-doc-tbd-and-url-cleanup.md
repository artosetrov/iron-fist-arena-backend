---
title: Block 133 — live doc TBD and URL cleanup
category: audit
tags: [audit, docs, progression, deploy, live-doc]
sources:
  - docs/06_game_systems/PROGRESSION.md
  - docs/10_operations/DEPLOY.md
updated: 2026-04-16
status: Fixed
---

# Block 133 — live doc TBD and URL cleanup

## Scope

- `docs/06_game_systems/PROGRESSION.md`
- `docs/10_operations/DEPLOY.md`

## Why this block

After the larger historical-boundary pass, a smaller class of issues was still left in live docs: unresolved `TBD` wording and missing live URLs inside documents that are supposed to be actively used.

These are tiny details, but they matter because they make current docs feel provisional even when the underlying system already exists.

## Related pages

- [[block-109-operations-deploy-docs-reality-sync]]
- [[block-111-operations-database-migration-runbook-parity]]
- [[block-117-source-of-truth-project-overview-parity]]
- [[progression]]

## File notes

### `docs/06_game_systems/PROGRESSION.md`

- **Zone:** live game-systems documentation
- **Purpose:** progression and reward mechanics overview
- **Problem found:** daily-quest reward row still said `(TBD by quest)` even though live quest definitions already drive per-quest reward values
- **Fix:** rewrote the line to describe the real state: configured per quest definition, usually gold/XP, varying by quest type/tuning
- **Status:** Fixed

### `docs/10_operations/DEPLOY.md`

- **Zone:** live deploy runbook
- **Purpose:** current deploy surface map
- **Problem found:** landing-site row still showed `TBD` in the URL column even though the repo-level ops notes already name `hexboundapp.com`
- **Fix:** replaced the placeholder with the real landing-site deploy path and domain
- **Status:** Fixed

## Problems found

1. **Live docs still contained unresolved placeholder language**
   - Risk: current specs feel incomplete even when the implementation and operational reality are already known.
   - Fix: replaced the placeholder wording with concrete repo-backed descriptions.

2. **Deploy matrix understated a known landing-site surface**
   - Risk: readers may assume the marketing site has no documented production URL or no documented deploy trigger.
   - Fix: aligned the row with the existing monorepo/landing-repo split already documented elsewhere.

## Verification

- reviewed the affected lines in both files after editing
- confirmed landing-site domain/path matches the repo-level operations notes
- `git diff --check`

## Follow-up

- Continue scanning live docs for the remaining small `TBD`/placeholder tails so the maintained documentation layer reads as current, not provisional.
