---
title: Block 181 — admin achievement cosmetic authoring parity
category: audit
tags: [audit, admin, achievements, cosmetics, runtime, contracts]
sources:
  - admin/src/lib/achievement-definitions.ts
  - admin/src/actions/achievement-definitions.ts
  - admin/src/app/(dashboard)/achievements/achievements-client.tsx
  - wiki/features/achievements.md
  - wiki/audit/block-057-admin-achievements-runtime-parity.md
  - wiki/audit/block-180-backend-achievement-cosmetic-claim-runtime-parity.md
updated: 2026-04-17
status: Fixed
---

# Block 181 — admin achievement cosmetic authoring parity

## Scope

- `admin/src/lib/achievement-definitions.ts`
- `admin/src/actions/achievement-definitions.ts`
- `admin/src/app/(dashboard)/achievements/achievements-client.tsx`
- `wiki/features/achievements.md`
- `wiki/audit/block-057-admin-achievements-runtime-parity.md`
- `wiki/audit/block-180-backend-achievement-cosmetic-claim-runtime-parity.md`

## Why this block

After [[block-180-backend-achievement-cosmetic-claim-runtime-parity]], the live runtime could finally grant cosmetic achievement rewards (`title` / `frame`) end to end. That left one obvious residual mismatch: the admin achievements surface was still artificially narrowed to currency-only authoring, because it had previously been constrained around the old runtime gap.

This block widens admin authoring back to the real live contract instead of leaving operators stuck on yesterday's guardrail.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[achievements]]
- [[block-057-admin-achievements-runtime-parity]]
- [[block-180-backend-achievement-cosmetic-claim-runtime-parity]]

## File notes

### `admin/src/lib/achievement-definitions.ts`

- **Zone:** admin / shared achievement helpers
- **Purpose:** canonical validation and normalization for admin achievement writes
- **Problems found:** helper still treated `title/frame` as legacy-only update compatibility, even after the live runtime started supporting them
- **What was fixed:**
  - widened `ACHIEVEMENT_REWARD_TYPES` to include `title` and `frame`
  - added explicit `rewardTypeRequiresRewardId(...)`
  - now requires `rewardId` for cosmetic rewards and clears it for currency rewards
- **Status:** Fixed

### `admin/src/actions/achievement-definitions.ts`

- **Zone:** admin / achievement-definition actions
- **Purpose:** create, update, delete, and seed achievement definitions
- **Why it mattered here:** the action layer already routed writes through `sanitizeAchievementDefinitionInput(...)`, so widening the shared sanitizer immediately brought create/update flows into parity with the live runtime
- **Status:** Fixed

### `admin/src/app/(dashboard)/achievements/achievements-client.tsx`

- **Zone:** admin / achievements UI
- **Purpose:** operator-facing definition editor
- **Problems found:**
  - reward type picker still hid `title/frame`
  - form had no `rewardId` field for cosmetic rewards
  - helper copy still claimed live claims supported only gold/gems/xp
- **What was fixed:**
  - reward picker now exposes cosmetic reward types
  - form conditionally shows a required `rewardId` field for cosmetic rewards
  - definitions table now shows the stored `rewardId` when present
  - helper copy now reflects the real live contract
- **Status:** Fixed

### `wiki/features/achievements.md`

- **Zone:** wiki / features
- **Purpose:** source-of-truth feature map for achievements
- **What was fixed:** admin authoring notes now match the widened live achievement reward surface instead of implying a currency-only editor
- **Status:** Fixed

## Problems found

1. **Admin authoring had become narrower than the live runtime**
   - Risk: operators could not create new cosmetic achievement rewards even though the player-facing claim/runtime path already supported them.
   - Fix: widened the shared reward-type parser and the admin UI.

2. **Cosmetic rewards lacked a required identifier field in the editor**
   - Risk: a title/frame definition could be authored without the `rewardId` needed to unlock the actual cosmetic.
   - Fix: made `rewardId` explicit and required for cosmetic reward types.

## Verification

- targeted admin `eslint`:
  - `src/lib/achievement-definitions.ts`
  - `src/actions/achievement-definitions.ts`
  - `src/app/(dashboard)/achievements/achievements-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- if future achievement reward types expand again, keep the admin parser/UI on the same shared reward-type contract instead of reintroducing a “legacy-only” side list
