---
title: Block 180 — backend achievement cosmetic claim runtime parity
category: audit
tags: [audit, backend, ios, achievements, cosmetics, rewards]
sources:
  - backend/src/lib/game/achievement-claims.ts
  - backend/src/app/api/achievements/claim/route.ts
  - backend/src/app/api/achievements/[key]/claim/route.ts
  - backend/tests/lib/achievement-claims.test.ts
  - backend/tests/api/achievement-claim.test.ts
  - Hexbound/Hexbound/Services/AchievementService.swift
  - Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift
  - docs/03_backend_and_api/API_REFERENCE.md
  - wiki/features/achievements.md
updated: 2026-04-17
status: Fixed
---

# Block 180 — backend achievement cosmetic claim runtime parity

## Scope

- `backend/src/lib/game/achievement-claims.ts`
- `backend/src/app/api/achievements/claim/route.ts`
- `backend/src/app/api/achievements/[key]/claim/route.ts`
- `backend/tests/lib/achievement-claims.test.ts`
- `backend/tests/api/achievement-claim.test.ts`
- `Hexbound/Hexbound/Services/AchievementService.swift`
- `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift`
- `docs/03_backend_and_api/API_REFERENCE.md`
- `wiki/features/achievements.md`

## Why this block

The achievement surface still had one real contract split: the catalog/list side could already represent cosmetic rewards (`title` / `frame`), but the live claim runtime still only granted `gold`, `gems`, and `xp`. That left admin/catalog metadata wider than the actual reward engine and made cosmetic achievement rows look valid until claim time.

This block closes that split instead of narrowing the catalog. Achievement claim runtime now understands cosmetic rewards, the API returns stable cosmetic identifiers, and the iOS reward ceremony can actually present what the player earned.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[achievements]]
- [[block-045-backend-tutorial-achievement-and-weekly-contracts]]
- [[block-057-admin-achievements-runtime-parity]]

## File notes

### `backend/src/lib/game/achievement-claims.ts`

- **Zone:** backend / achievements / runtime grants
- **Purpose:** owns authoritative claim-time reward execution for completed achievements
- **Problems found:**
  - cosmetic reward definitions were visible in catalog/list metadata but still dead-ended at claim time
  - claim result could not carry a cosmetic identifier back to the caller
- **What was fixed:**
  - runtime now supports `title` and `frame` reward types in addition to `gold`, `gems`, and `xp`
  - cosmetic rewards grant through `cosmetics` with an idempotent `findFirst -> create if missing` path
  - cosmetic claims still return an authoritative post-claim reward snapshot
  - claim result now includes `rewardId`
- **Status:** Fixed

### `backend/src/app/api/achievements/claim/route.ts`

- **Zone:** backend / achievements API
- **Purpose:** claims a completed achievement by body payload
- **What was fixed:**
  - response `reward` now includes `id`
  - route exposes stable cosmetic convenience fields `reward_title` / `reward_frame`
- **Status:** Fixed

### `backend/src/app/api/achievements/[key]/claim/route.ts`

- **Zone:** backend / achievements API
- **Purpose:** claims a completed achievement via keyed route
- **What was fixed:** keyed route now returns the same cosmetic reward contract as the canonical body-based route
- **Status:** Fixed

### `backend/tests/lib/achievement-claims.test.ts`

- **Zone:** backend tests / achievements
- **Purpose:** covers the shared claim helper directly
- **What it now proves:** title rewards create cosmetic ownership and still return authoritative gold/gems/xp snapshot data
- **Status:** Fixed

### `backend/tests/api/achievement-claim.test.ts`

- **Zone:** backend tests / achievements API
- **Purpose:** protects route-level serialization for cosmetic rewards
- **What it covers now:**
  - canonical `/api/achievements/claim` returns `reward.id` plus `reward_title`
  - keyed `/api/achievements/[key]/claim` returns `reward.id` plus `reward_frame`
- **Status:** Fixed

### `Hexbound/Hexbound/Services/AchievementService.swift`

- **Zone:** iOS / achievements service
- **Purpose:** typed loader + claim DTO wrapper for achievements
- **What was fixed:** claim result now decodes an optional typed `reward` payload with `type`, `amount`, and `id`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift`

- **Zone:** iOS / achievements UI
- **Purpose:** loads, claims, and presents achievements
- **What was fixed:** claim ceremony now converts cosmetic achievement rewards into `ClaimLootItem` entries, so the modal can present title/frame grants instead of silently dropping them
- **Status:** Fixed

### `wiki/features/achievements.md`

- **Zone:** wiki / features
- **Purpose:** source-of-truth feature map for achievements
- **What was fixed:** feature page now states that claim rewards can be currency or cosmetic (`title` / `frame`) and notes that cosmetic claim payloads carry `reward.id`
- **Status:** Fixed

### `docs/03_backend_and_api/API_REFERENCE.md`

- **Zone:** docs / backend API
- **Purpose:** quick route atlas for public endpoints
- **What was fixed:** corrected the stale achievement claim entry from `/achievements/claim/[key]` to the real body-based route `/achievements/claim`
- **Status:** Fixed

## Problems found

1. **Catalog metadata and live claim runtime had diverged**
   - Risk: valid-looking achievement definitions could still fail or under-deliver at claim time.
   - Fix: implemented cosmetic runtime support in the shared claim helper.

2. **Achievement claim routes could not serialize cosmetic identifiers**
   - Risk: even after a backend grant, clients would still have no stable way to present the cosmetic reward.
   - Fix: added `reward.id` plus top-level `reward_title` / `reward_frame`.

3. **iOS achievement ceremony silently dropped cosmetic rewards**
   - Risk: players could earn a title or frame and see no reward representation in the modal.
   - Fix: mapped cosmetic rewards into `ClaimLootItem` entries for the existing shared CLAIMED surface.

## Verification

- targeted backend `vitest`:
  - `tests/lib/achievement-claims.test.ts`
  - `tests/api/achievement-claim.test.ts`
- `npm run build` in `backend/`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

## Follow-up

- tutorial quest runtime still has two declared-but-unimplemented reward types: `instant_mine` and `bp_levels`
- if more cosmetic achievement reward categories are added later, keep them on the same shared `achievement-claims.ts` path instead of reintroducing route-local grant logic
