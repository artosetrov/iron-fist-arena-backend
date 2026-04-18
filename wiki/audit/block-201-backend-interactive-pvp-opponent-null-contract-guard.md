---
title: Audit Block 201 — Backend Interactive PvP Opponent Null Contract Guard
category: audit
tags: [audit, backend, pvp, interactive-combat, nullability]
sources:
  - backend/src/app/api/pvp/strike/route.ts
  - backend/src/app/api/pvp/match/complete/route.ts
  - wiki/features/pvp-combat.md
  - docs/03_backend_and_api/API_REFERENCE.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 201 — Backend Interactive PvP Opponent Null Contract Guard

## Scope

- `backend/src/app/api/pvp/strike/route.ts`
- `backend/src/app/api/pvp/match/complete/route.ts`
- `wiki/features/pvp-combat.md`
- `docs/03_backend_and_api/API_REFERENCE.md`

## Why this block

The Interactive Combat v1 PvP routes were still implicitly assuming a real second player:

- `strike`
- `match/complete`

But the schema allows `player2Id` to be nullable.

That left a type/runtime seam where the routes were conceptually “PvP only” but still dereferenced `match.player2Id` as if it could never be null.

## Fix applied

### `backend/src/app/api/pvp/strike/route.ts`

- added an explicit guard:
  - if `match.player2Id` is missing → return `409 Player-vs-player opponent missing`
- introduced `defenderId` after the guard so the rest of the route works against a non-null contract

### `backend/src/app/api/pvp/match/complete/route.ts`

- added the same explicit `409 Player-vs-player opponent missing` guard before loading the defender row

### Docs

- `wiki/features/pvp-combat.md` now calls out the new contract explicitly
- `docs/03_backend_and_api/API_REFERENCE.md` now documents the `409` path for both interactive endpoints

## Result

The interactive PvP routes are now honest about their contract:

- they require a real PvP opponent
- they fail explicitly when the row does not satisfy that contract
- they no longer rely on accidental nullability assumptions to “work until TypeScript complains”

## Verification

- `cd backend && npx eslint src/app/api/pvp/strike/route.ts src/app/api/pvp/match/complete/route.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
