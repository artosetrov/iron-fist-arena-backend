---
title: Block 051 — admin active config editors consistency
category: audit
tags: [audit, admin, config, balance, loot, daily-login]
sources:
  - admin/src/actions/balance.ts
  - admin/src/app/(dashboard)/balance/balance-client.tsx
  - admin/src/app/(dashboard)/balance/page.tsx
  - admin/src/app/(dashboard)/loot/loot-client.tsx
  - admin/src/app/(dashboard)/loot/page.tsx
  - admin/src/app/(dashboard)/config/config-client.tsx
  - admin/src/app/(dashboard)/config/page.tsx
  - admin/src/app/(dashboard)/daily-login/daily-login-client.tsx
  - admin/src/app/(dashboard)/daily-login/page.tsx
updated: 2026-04-15
status: Fixed
---

# Block 051 — admin active config editors consistency

## Scope

- `admin/src/actions/balance.ts`
- `admin/src/app/(dashboard)/balance/balance-client.tsx`
- `admin/src/app/(dashboard)/balance/page.tsx`
- `admin/src/app/(dashboard)/loot/loot-client.tsx`
- `admin/src/app/(dashboard)/loot/page.tsx`
- `admin/src/app/(dashboard)/config/config-client.tsx`
- `admin/src/app/(dashboard)/config/page.tsx`
- `admin/src/app/(dashboard)/daily-login/daily-login-client.tsx`
- `admin/src/app/(dashboard)/daily-login/page.tsx`

## Why this block

After the canonical backend admin-config route landed, a few high-traffic admin editors were still half on the old mental model:

1. `balance` resets and batch writes still carried admin-side plumbing that made the write path look local even though cache ownership had moved to backend;
2. `loot` still saved config keys one by one, so a partial failure could leave drop tables split-brained;
3. several page/client pairs still carried stale `adminId` prop wiring after mutations no longer needed it;
4. `daily-login` had small but real local UI debt: repeated inline defaults, weak `any` catches, and a loose reward-type selector.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[economy]]
- [[design-principles]]
- [[bug-patterns]]

## File notes

### `admin/src/actions/balance.ts`

- **Zone:** admin / balance actions
- **Purpose:** batch save and reset flows for the curated balance editor
- **Problems found:** batch save/reset still looked like admin-owned mutations even though runtime cache invalidation had moved to backend
- **What was fixed:** both flows now route the actual config mutation through canonical backend admin endpoints while keeping local snapshot/audit-log behavior intact
- **Status:** Fixed

### `admin/src/app/(dashboard)/balance/balance-client.tsx`

- **Zone:** admin / balance editor UI
- **Purpose:** main curated tuning surface for live combat/economy knobs
- **Problems found:** stale `adminId` prop plumbing and outdated banner copy implied the backend still read mostly hardcoded constants
- **What was fixed:** removed obsolete prop usage and rewrote the banner so it matches the current mixed live-config/runtime-fallback reality
- **Status:** Fixed

### `admin/src/app/(dashboard)/balance/page.tsx`

- **Zone:** admin / balance page shell
- **Purpose:** server-side hydration for the balance editor
- **Problems found:** stale `adminId` prop pass-through
- **What was fixed:** removed dead prop wiring
- **Status:** Fixed

### `admin/src/app/(dashboard)/loot/loot-client.tsx`

- **Zone:** admin / loot editor UI
- **Purpose:** edits drop chances and rarity weights
- **Problems found:** sequential per-key writes could partially apply if one request failed midway
- **What was fixed:** switched both save flows to atomic batch config writes through the canonical admin-config contract
- **Status:** Fixed

### `admin/src/app/(dashboard)/loot/page.tsx`

- **Zone:** admin / loot page shell
- **Purpose:** loads grouped config rows for the loot editor
- **Problems found:** stale `adminId` prop pass-through
- **What was fixed:** removed dead prop wiring
- **Status:** Fixed

### `admin/src/app/(dashboard)/config/config-client.tsx`

- **Zone:** admin / raw config editor UI
- **Purpose:** direct generic `GameConfig` editing
- **Problems found:** stale `adminId` mutation prop after writes were rerouted to backend
- **What was fixed:** removed obsolete prop dependency
- **Status:** Fixed

### `admin/src/app/(dashboard)/config/page.tsx`

- **Zone:** admin / raw config page shell
- **Purpose:** loads all config rows for the generic editor
- **Problems found:** stale `adminId` prop pass-through
- **What was fixed:** removed dead prop wiring
- **Status:** Fixed

### `admin/src/app/(dashboard)/daily-login/daily-login-client.tsx`

- **Zone:** admin / daily login editor UI
- **Purpose:** edits the 7-day login reward sequence
- **Problems found:**
  - repeated inline default reward array risked local drift
  - `catch (error: any)` weakened editor typing
  - reward-type selector accepted an untyped value
- **What was fixed:** extracted stable defaults, replaced `any` with `unknown` + explicit message narrowing, and typed the select callback to `DailyLoginReward['type']`
- **Status:** Fixed

### `admin/src/app/(dashboard)/daily-login/page.tsx`

- **Zone:** admin / daily login page shell
- **Purpose:** loads or falls back to default 7-day rewards
- **Problems found:** duplicated inline default reward array
- **What was fixed:** page and client now share the same default contract shape
- **Status:** Fixed

## Problems found

1. **Loot saves could partially apply**
   - Risk: one failed request could leave drop chances and rarity weights out of sync.
   - Fix: moved loot save flows to `updateConfigsBatch(...)`.

2. **Several admin editors still carried dead `adminId` plumbing**
   - Risk: stale props make future auth/integration work look more coupled than it is.
   - Fix: removed the obsolete page→client mutation prop chain.

3. **Daily login editor had small but real local contract drift risk**
   - Risk: duplicated defaults and loose typing make live reward editing easier to break quietly.
   - Fix: centralized defaults and narrowed the client-side error/select contracts.

4. **Balance banner was factually stale**
   - Risk: teammates would distrust a working config surface because the copy still described an older backend shape.
   - Fix: rewrote the banner around the current live-config + fallback reality.

## Verification

- targeted admin `eslint`:
  - `src/actions/balance.ts`
  - `src/app/(dashboard)/balance/balance-client.tsx`
  - `src/app/(dashboard)/balance/page.tsx`
  - `src/app/(dashboard)/loot/loot-client.tsx`
  - `src/app/(dashboard)/loot/page.tsx`
  - `src/app/(dashboard)/config/config-client.tsx`
  - `src/app/(dashboard)/config/page.tsx`
  - `src/app/(dashboard)/daily-login/daily-login-client.tsx`
  - `src/app/(dashboard)/daily-login/page.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- `BalanceClient` still carried its own schema/default table and still needed a parity pass against canonical seeded config values; that becomes the next block
- `getConfig()` in `admin/src/actions/config.ts` was still weaker than neighboring read helpers and needed the same auth/read-side cleanup in the next pass
