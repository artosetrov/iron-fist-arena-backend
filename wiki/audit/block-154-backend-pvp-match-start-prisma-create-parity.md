---
title: Audit Block 154 — Backend PvP Match Start Prisma Create Parity
category: audit
tags: [audit, backend, pvp, interactive-combat, prisma]
sources:
  - backend/src/app/api/pvp/match/start/route.ts
  - wiki/audit/block-011-backend-passives-interactive-combat-runtime.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 154 — Backend PvP Match Start Prisma Create Parity

## Scope

- `backend/src/app/api/pvp/match/start/route.ts`
- `wiki/audit/block-011-backend-passives-interactive-combat-runtime.md`

## Why this block

`/api/pvp/match/start` was still carrying a stale Prisma-client workaround from the earlier Interactive Combat rollout:

- `tx.pvpMatch.create as any`

At this point the generated backend client is current again, and the route already builds the interactive payload in a stable typed shape. That made the old cast noise rather than protection.

## What changed

### `backend/src/app/api/pvp/match/start/route.ts`

- removed the stale `as any` cast from `tx.pvpMatch.create(...)`
- imported `Prisma` from `@prisma/client`
- typed the two interactive JSON fields explicitly:
  - `interactiveChoices` -> `Prisma.JsonArray`
  - `interactiveActives` -> `Prisma.InputJsonValue`

This keeps the route on the real Prisma create surface while staying explicit about the JSON contract.

### `wiki/audit/block-011-backend-passives-interactive-combat-runtime.md`

- updated the `pvp/match/start` file record from `Needs review` to `Fixed`
- narrowed the remaining follow-up note to the still-open `pvp/strike` / `pvp/match/complete` workaround paths instead of implying that `match/start` still needs the same cleanup

## Problems resolved

1. **Historical Prisma workaround outlived the actual schema/client drift**
   - Resolution: `pvp/match/start` now uses the typed Prisma create API directly.

2. **Interactive JSON fields still needed explicit typing**
   - Resolution: kept the JSON boundary explicit with Prisma JSON types instead of falling back to `any`.

## Verification

- `npx eslint src/app/api/pvp/match/start/route.ts`
- `npm run build`
- `git diff --check`

All three passed after the change.

## Follow-up

- `pvp/match/start` is now clean.
- The remaining interactive-PvP Prisma workaround tail is narrower and now clearly lives in:
  - `backend/src/app/api/pvp/strike/route.ts`
  - `backend/src/app/api/pvp/match/complete/route.ts`
