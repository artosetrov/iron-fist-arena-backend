---
title: Block 182 — backend achievement list definition text parity
category: audit
tags: [audit, backend, achievements, admin, contracts, text]
sources:
  - backend/src/lib/game/achievement-catalog.ts
  - backend/src/app/api/achievements/route.ts
  - backend/tests/lib/achievement-catalog.test.ts
  - backend/tests/api/achievement-list.test.ts
  - wiki/features/achievements.md
updated: 2026-04-17
status: Fixed
---

# Block 182 — backend achievement list definition text parity

## Scope

- `backend/src/lib/game/achievement-catalog.ts`
- `backend/src/app/api/achievements/route.ts`
- `backend/tests/lib/achievement-catalog.test.ts`
- `backend/tests/api/achievement-list.test.ts`
- `wiki/features/achievements.md`

## Why this block

After [[block-181-admin-achievement-cosmetic-authoring-parity]], the admin surface could author the full live achievement contract again, including custom `title`, `description`, and cosmetic reward metadata. One player-facing seam still lagged behind that reality: `GET /api/achievements` continued to prefer hardcoded display text from the route layer instead of the active definition rows.

That meant operators could update achievement copy in the live definitions table and still see the old text in the player list. This block restores one source of truth for achievement presentation by letting the list route prefer admin-authored definition text and only fall back to legacy hardcoded metadata when definitions omit it.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[achievements]]
- [[block-180-backend-achievement-cosmetic-claim-runtime-parity]]
- [[block-181-admin-achievement-cosmetic-authoring-parity]]

## File notes

### `backend/src/lib/game/achievement-catalog.ts`

- **Zone:** backend / achievements / catalog
- **Purpose:** canonical code fallback and live-definition normalization layer for achievements
- **Problems found:** live definition text (`title` / `description`) was not preserved in the normalized catalog type even though admin definitions already stored it
- **What was fixed:**
  - `AchievementDef` now preserves optional `title` and `description`
  - `buildAchievementCatalogFromDefinitions(...)` now carries `title`, `description`, and `rewardId` through from active definition rows
- **Status:** Fixed

### `backend/src/app/api/achievements/route.ts`

- **Zone:** backend / achievements API
- **Purpose:** returns the player-facing achievement list with progress and claim state
- **Problems found:** route still preferred hardcoded route-local display metadata even when live definitions already contained operator-authored text
- **What was fixed:**
  - list serialization now prefers `def.title` / `def.description`
  - legacy hardcoded display metadata remains only as fallback for definitions that omit text
  - cosmetic reward serialization keeps using the normalized live-definition reward data
- **Status:** Fixed

### `backend/tests/lib/achievement-catalog.test.ts`

- **Zone:** backend tests / achievements catalog
- **Purpose:** protects normalized catalog shape
- **What it now proves:** DB-backed definitions preserve `title`, `description`, and `rewardId` instead of dropping them on the floor
- **Status:** Fixed

### `backend/tests/api/achievement-list.test.ts`

- **Zone:** backend tests / achievements API
- **Purpose:** protects the player-facing list contract
- **What it covers now:** `GET /api/achievements` prefers admin-authored title/description from live definitions and still serializes cosmetic reward metadata correctly
- **Status:** Fixed

### `wiki/features/achievements.md`

- **Zone:** wiki / features
- **Purpose:** source-of-truth feature map for achievements
- **What was fixed:** feature map now explicitly states that the list route prefers active definition text rather than route-local hardcoded copy
- **Status:** Fixed

## Problems found

1. **Player-facing achievement copy could drift from the admin-authored definitions**
   - Risk: operators could update achievement text in the live definitions table and still ship stale copy to players.
   - Fix: made the list route prefer definition text first.

2. **The catalog normalization layer dropped definition text**
   - Risk: even if the route wanted to honor DB-backed text later, the shared catalog type had already erased it.
   - Fix: preserved `title` and `description` in the normalized catalog shape.

## Verification

- targeted backend `vitest`:
  - `tests/lib/achievement-catalog.test.ts`
  - `tests/api/achievement-list.test.ts`
- targeted backend `eslint`:
  - `src/lib/game/achievement-catalog.ts`
  - `src/app/api/achievements/route.ts`
  - `tests/lib/achievement-catalog.test.ts`
  - `tests/api/achievement-list.test.ts`
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- if the hardcoded `ACHIEVEMENT_DISPLAY` map eventually becomes pure fallback-only legacy residue, it is now a good future delete candidate
- achievement summary docs still needed a separate truth-sync pass for the real live count (`18`, not `21`) and the widened reward surface
