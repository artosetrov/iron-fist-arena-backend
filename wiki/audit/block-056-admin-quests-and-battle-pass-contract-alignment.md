---
title: Block 056 — admin quests and battle-pass contract alignment
category: audit
tags: [audit, admin, quests, battle-pass, contracts, validation]
sources:
  - admin/src/lib/quest-definitions.ts
  - admin/src/actions/quest-definitions.ts
  - admin/src/app/(dashboard)/quests/quests-client.tsx
  - admin/src/lib/battle-pass-rewards.ts
  - admin/src/actions/battle-pass-rewards.ts
  - admin/src/app/(dashboard)/battle-pass/battle-pass-client.tsx
  - backend/src/app/api/battle-pass/claim/[level]/route.ts
updated: 2026-04-15
status: Fixed
---

# Block 056 — admin quests and battle-pass contract alignment

## Scope

- `admin/src/lib/quest-definitions.ts`
- `admin/src/actions/quest-definitions.ts`
- `admin/src/app/(dashboard)/quests/quests-client.tsx`
- `admin/src/lib/battle-pass-rewards.ts`
- `admin/src/actions/battle-pass-rewards.ts`
- `admin/src/app/(dashboard)/battle-pass/battle-pass-client.tsx`
- `backend/src/app/api/battle-pass/claim/[level]/route.ts`

## Why this block

The next live admin slice had a familiar kind of drift: the UI was editing quest and battle-pass data through weaker contracts than the runtime actually expects. In practice that meant invalid quest ranges could slip through server actions, battle-pass bulk generation swallowed non-unique errors too broadly, the admin battle-pass table only deleted the free-track reward from each row, and the create/edit UI exposed only a subset of reward types even though the backend claim runtime already supports a much wider set.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[bug-patterns]]
- [[progression]]

## File notes

### `admin/src/lib/quest-definitions.ts`

- **Zone:** admin / shared quest helpers
- **Purpose:** canonical normalization and validation for quest definition payloads
- **What it now does:**
  - normalizes `questType`
  - enforces required title/description
  - validates positive min/max targets and non-negative rewards
  - rejects inverted target ranges
- **Status:** Fixed

### `admin/src/actions/quest-definitions.ts`

- **Zone:** admin / quest-definition actions
- **Purpose:** list, create, update, delete, and seed daily-quest definitions
- **Problems found:**
  - accepted raw payloads without range/reward validation
  - logged raw `data as never`
  - create path did not normalize quest types before uniqueness checks
- **What was fixed:**
  - routed create/update/seed through the shared quest sanitizer
  - added normalized duplicate check on create
  - replaced weak audit payload casts with structured JSON details
  - added seed audit logging
- **Status:** Fixed

### `admin/src/app/(dashboard)/quests/quests-client.tsx`

- **Zone:** admin / quests UI
- **Purpose:** create, edit, seed, activate, and delete quest definitions
- **Problems found:**
  - weak `any` error handling
  - stale numeric parsing via `parseInt(...) || 0`
  - status badge was read-only even though the action already supports `active`
- **What was fixed:**
  - removed weak catch-path typing
  - made numeric parsing explicit
  - kept local list sorted after mutations
  - added a safe activate/deactivate control
- **Status:** Fixed

### `admin/src/lib/battle-pass-rewards.ts`

- **Zone:** admin / shared battle-pass helpers
- **Purpose:** canonical reward-type list and validation for battle-pass rewards
- **What it now does:**
  - mirrors the live backend-supported reward types
  - validates positive level/amount values
  - requires `rewardId` for reward types that need one
- **Status:** Fixed

### `admin/src/actions/battle-pass-rewards.ts`

- **Zone:** admin / battle-pass reward actions
- **Purpose:** list, create, update, delete, and bulk-generate season rewards
- **Problems found:**
  - weak create/update validation
  - `bulkCreateBattlePassRewards()` swallowed every error, not just duplicate rows
- **What was fixed:**
  - moved create/update/default generation through the shared sanitizer
  - narrowed bulk-create skipping to Prisma `P2002` only
  - preserved explicit errors for broken reward payloads instead of silently masking them
- **Status:** Fixed

### `admin/src/app/(dashboard)/battle-pass/battle-pass-client.tsx`

- **Zone:** admin / battle-pass UI
- **Purpose:** manage season reward tables for free and premium tracks
- **Problems found:**
  - row delete action only targeted the free reward
  - bulk create used `window.location.reload()`
  - create/edit UI exposed only a partial reward-type list and had no `rewardId` path
  - touched mutation flow trusted local optimistic state instead of refetching authoritative server data
- **What was fixed:**
  - switched post-mutation refresh to `getBattlePassRewards(selectedSeasonId)`
  - moved delete action into each reward cell so both free and premium rewards are deletable
  - exposed the full backend-supported reward-type list
  - added `rewardId` create/edit support
- **Status:** Fixed

### `backend/src/app/api/battle-pass/claim/[level]/route.ts`

- **Zone:** backend / runtime reference
- **Purpose:** source of truth for claim-time supported battle-pass reward types
- **Why it mattered here:**
  - the admin helper and UI were aligned to the real supported runtime set instead of inventing their own subset
- **Status:** OK

## Problems found

1. **Quest-definition writes were weaker than the live admin contract should be**
   - Risk: invalid ranges, negative rewards, or duplicate normalized quest types could be stored from the admin surface.
   - Fix: introduced one shared quest-definition sanitizer and routed create/update/seed through it.

2. **Battle-pass bulk generation masked real failures**
   - Risk: non-duplicate write failures could be silently skipped, which makes bad season data harder to notice and harder to trust.
   - Fix: narrowed the catch path to Prisma unique conflicts only.

3. **Battle-pass UI could delete only one side of a level row**
   - Risk: premium-only rows or premium reward cleanup paths were effectively broken from the admin table.
   - Fix: moved delete controls into each reward cell.

4. **Battle-pass admin UI exposed a smaller reward vocabulary than the runtime**
   - Risk: the editor drifted away from the actual backend contract and pushed operators toward ad hoc manual edits.
   - Fix: aligned the admin helper and UI to the backend-supported reward type set and added `rewardId` support where needed.

## Verification

- targeted admin `eslint`:
  - `src/actions/quest-definitions.ts`
  - `src/app/(dashboard)/quests/quests-client.tsx`
  - `src/actions/battle-pass-rewards.ts`
  - `src/app/(dashboard)/battle-pass/battle-pass-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- battle-pass inline editing is now contract-safe, but a richer guided editor for `rewardType -> rewardId` transitions would still be nicer than the current compact inline flow
- broader admin warning-heavy surfaces still remain in `achievements`, `design-system`, and a few demo/media-heavy files
