---
title: Audit Block 155 — Backend PvP Strike and Complete Prisma JSON Parity
category: audit
tags: [audit, backend, pvp, interactive-combat, prisma, json]
sources:
  - backend/src/app/api/pvp/strike/route.ts
  - backend/src/app/api/pvp/match/complete/route.ts
  - wiki/audit/block-011-backend-passives-interactive-combat-runtime.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 155 — Backend PvP Strike and Complete Prisma JSON Parity

## Scope

- `backend/src/app/api/pvp/strike/route.ts`
- `backend/src/app/api/pvp/match/complete/route.ts`
- `wiki/audit/block-011-backend-passives-interactive-combat-runtime.md`

## Why this block

After [[block-154-backend-pvp-match-start-prisma-create-parity]], the remaining stale Prisma-client workaround tail in interactive PvP had narrowed to two routes:

- `pvp/strike`
- `pvp/match/complete`

Both were still doing some combination of:

- `findUnique as any`
- `updateMany as any`

The real requirement turned out to be smaller than that: Prisma now understands the columns, but the interactive payload still crosses a JSON boundary, so TypeScript just needs explicit `unknown -> Prisma.InputJsonValue` bridges.

## What changed

### `backend/src/app/api/pvp/match/complete/route.ts`

- imported `Prisma`
- removed the stale `prisma.pvpMatch.findUnique as any`
- removed the stale `tx.pvpMatch.updateMany as any`
- kept `combatLog` explicit as a Prisma JSON write:
  - `JSON.parse(JSON.stringify(combat_log)) as Prisma.InputJsonValue`

### `backend/src/app/api/pvp/strike/route.ts`

- imported `Prisma`
- removed the stale `prisma.pvpMatch.findUnique as any`
- removed both `updateMany as any` calls
- made the JSON bridges explicit instead of implicit:
  - `interactiveChoices` read: `JsonArray -> unknown -> StoredRound[]`
  - `interactiveActives` read: `JsonValue -> unknown -> InteractiveActivesState | null`
  - `interactiveChoices` write: `StoredRound[] -> unknown -> Prisma.InputJsonValue`
  - `interactiveActives` write: `InteractiveActivesState -> unknown -> Prisma.InputJsonValue`

## Problems resolved

1. **Interactive PvP still looked dependent on stale Prisma generation**
   - Resolution: `start`, `strike`, and `complete` now all use the typed Prisma client directly.

2. **JSON boundary was hidden inside `any`**
   - Resolution: the JSON boundary is now explicit and narrow, which is easier to reason about and much safer to revisit later.

## Verification

- `npx eslint src/app/api/pvp/match/complete/route.ts src/app/api/pvp/strike/route.ts`
- `npm run build`
- `git diff --check -- backend/src/app/api/pvp/match/complete/route.ts backend/src/app/api/pvp/strike/route.ts wiki/audit/block-155-backend-pvp-strike-complete-prisma-json-parity.md wiki/audit/block-011-backend-passives-interactive-combat-runtime.md wiki/audit/audit-index.md wiki/index.md wiki/log.md wiki/audit/project-file-inventory.md`

All passed after the change.

## Follow-up

- The broad "stale Prisma client" concern is now no longer true for the interactive PvP runtime core.
- The remaining review surface in this area is product/runtime behavior, not schema-client workaround debt.
