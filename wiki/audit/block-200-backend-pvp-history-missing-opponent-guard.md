---
title: Audit Block 200 — Backend PvP History Missing Opponent Guard
category: audit
tags: [audit, backend, pvp, history, nullability]
sources:
  - backend/src/app/api/pvp/history/route.ts
  - backend/tests/api/pvp-history.test.ts
  - wiki/features/pvp-combat.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 200 — Backend PvP History Missing Opponent Guard

## Scope

- `backend/src/app/api/pvp/history/route.ts`
- `backend/tests/api/pvp-history.test.ts`
- `wiki/features/pvp-combat.md`

## Why this block

`GET /api/pvp/history` assumed every returned row had a resolved opponent relation.

That was not always true:

- older non-PvP residue
- bot-style rows with `player2Id = null`
- incomplete/opponent-less rows

Any such row could crash the whole history response instead of being treated as an incomplete record.

## Fix applied

### `backend/src/app/api/pvp/history/route.ts`

- changed the response shaping from `map(...)` to `flatMap(...)`
- if a row has no resolved opponent relation, it is skipped instead of dereferenced blindly

### `backend/tests/api/pvp-history.test.ts`

- added regression coverage proving:
  - a null-opponent row no longer crashes the response
  - valid PvP history rows still come through normally

### `wiki/features/pvp-combat.md`

- documented that `/pvp/history` now skips snapshot-less rows without a resolved opponent relation

## Result

PvP history is now robust against incomplete legacy/non-PvP rows:

- one bad row no longer poisons the whole response
- valid player-vs-player history still renders normally

## Verification

- `cd backend && npx vitest run tests/api/pvp-history.test.ts`
- `cd backend && npx eslint src/app/api/pvp/history/route.ts tests/api/pvp-history.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
