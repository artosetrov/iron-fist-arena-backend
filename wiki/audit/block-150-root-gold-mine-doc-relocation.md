---
title: Block 150 — root Gold Mine doc relocation
category: audit
tags: [audit, docs, gold-mine, relocation]
sources:
  - docs/features/gold-mine/GOLD_MINE_MINIGAME_BALANCE_AUDIT.md
  - docs/features/gold-mine/GOLD_MINE_MINIGAME_PLAN.md
  - backend/src/lib/game/shaft-catalog.ts
  - wiki/audit/block-001-root-files.md
  - wiki/audit/project-file-inventory.md
updated: 2026-04-17
status: Fixed
---

# Block 150 — root Gold Mine doc relocation

## Scope

- `GOLD_MINE_MINIGAME_BALANCE_AUDIT.md` -> `docs/features/gold-mine/GOLD_MINE_MINIGAME_BALANCE_AUDIT.md`
- `GOLD_MINE_MINIGAME_PLAN.md` -> `docs/features/gold-mine/GOLD_MINE_MINIGAME_PLAN.md`
- `backend/src/lib/game/shaft-catalog.ts`

## Why this block

The Gold Mine implementation plan and balance audit were still sitting in root even though:

- the feature already has its own docs folder
- the minigame prototype is gone
- the runtime now uses these files only as historical rationale/reference

## What changed

### Gold Mine planning docs

- moved both Gold Mine historical docs into `docs/features/gold-mine/`
- kept the plan/audit pair together with the live `GOLD_MINE_OVERVIEW.md`

### Code reference parity

- updated `backend/src/lib/game/shaft-catalog.ts` so its balance-doc comment points at the new canonical location

## Problems resolved

1. **Feature-owned Gold Mine history lived noisily in root**
   - Resolution: both docs now live in the Gold Mine feature folder.

2. **A code comment still relied on the old root path convention**
   - Resolution: the balance comment now names the feature-doc path directly.

## Verification

- confirmed both Gold Mine docs no longer exist in root
- confirmed both moved files exist under `docs/features/gold-mine/`
- confirmed the `shaft-catalog.ts` reference points at the new path
- `git diff --check`

## Follow-up

- any remaining Gold Mine cleanup from here should be about stale content inside the plan, not about where the plan lives.
