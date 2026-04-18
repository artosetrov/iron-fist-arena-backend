---
title: Block 045 — backend tutorial achievement and weekly contracts
category: audit
tags: [audit, backend, tutorial, achievements, battle-pass, tests]
sources:
  - backend/src/app/api/tutorial/quest/route.ts
  - backend/src/app/api/achievements/route.ts
  - backend/src/lib/game/tutorial.ts
  - backend/src/lib/game/achievement-catalog.ts
  - backend/src/lib/game/weekly-challenges.ts
  - backend/tests/api/tutorial-quest.test.ts
  - backend/tests/lib/achievement-catalog.test.ts
  - backend/tests/lib/weekly-challenges.test.ts
updated: 2026-04-17
status: Fixed
---

# Block 045 — backend tutorial achievement and weekly contracts

## Scope

- `backend/src/app/api/tutorial/quest/route.ts`
- `backend/src/app/api/achievements/route.ts`
- `backend/src/lib/game/tutorial.ts`
- `backend/src/lib/game/achievement-catalog.ts`
- `backend/src/lib/game/weekly-challenges.ts`
- `backend/tests/api/tutorial-quest.test.ts`
- `backend/tests/lib/achievement-catalog.test.ts`
- `backend/tests/lib/weekly-challenges.test.ts`

## Why this block

This slice started as a warning-cleanup pass, but it contained three real contract issues:

1. tutorial quest route errors (`QUEST_LOCKED`, `ALREADY_CLAIMED`, `FORBIDDEN`, and friends) were bubbling into a generic `500`;
2. tutorial quest reward typing was still loose enough to hide malformed consumable rewards and silently drop missing item rewards;
3. achievement metadata had already moved Diamond and Grandmaster thresholds, but the live achievements route still showed the old numbers in player-facing descriptions.

There was also one intentional non-fix: tutorial quest definitions still declare `instant_mine` and `bp_levels`, but the claim route does not grant those reward types yet. That needs a product-safe runtime design, not a quick patch.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[tutorial]]
- [[achievements]]
- [[battle-pass]]
- [[bug-patterns]]

## File notes

### `backend/src/app/api/tutorial/quest/route.ts`

- **Zone:** backend / tutorial / quests
- **Purpose:** progresses or claims NPC tutorial quest rewards
- **Depends on:** auth, rate limit, tutorial quest definitions, Prisma transactions, tutorial analytics
- **Used by:** iOS tutorial and hub quest banner flows
- **Problems found:**
  - lock/ownership/config errors surfaced as generic `500`
  - progress endpoint accepted arbitrary `amount` values
  - consumable reward typing relied on casts, and missing item rewards could be silently skipped
- **What was fixed:**
  - mapped tutorial sentinel errors to stable responses (`404`, `403`, `409`, `400`)
  - progress now rejects non-positive or non-integer `amount`
  - consumable rewards now use canonical `ConsumableType`
  - item reward lookup now fails the claim transaction if the configured catalog item is missing
- **Needs review:** `instant_mine` and `bp_levels` remain declared in tutorial quest definitions but are not granted by the current claim runtime
- **Status:** Fixed

### `backend/src/lib/game/tutorial.ts`

- **Zone:** backend / tutorial config
- **Purpose:** stores unlock levels, welcome gift values, tutorial quest definitions, and tutorial progress helpers
- **Depends on:** Prisma types
- **Used by:** tutorial routes, onboarding flow, and iOS hub/tutorial surfaces
- **Problems found:** loose reward typing and minor dead-code warning noise
- **What was fixed:**
  - introduced typed tutorial reward definitions with canonical `ConsumableType`
  - removed the unused tuple placeholders in `getBuildingsUnlockedAt`
  - simplified `updateTutorialQuestProgress` typing to a direct `PrismaClient`
- **Needs review:** reward definitions still advertise `instant_mine` and `bp_levels` that the live claim route does not execute
- **Status:** Fixed

### `backend/src/lib/game/achievement-catalog.ts`

- **Zone:** backend / achievements config
- **Purpose:** provides the hardcoded/default achievement catalog and loads DB overrides
- **Depends on:** Prisma achievement definitions
- **Used by:** achievements list + claim routes and achievement reward runtime
- **Problems found:**
  - DB-loaded definitions were trusted almost blindly through `any`
  - unsupported DB reward types could leak into runtime catalog state
- **What was fixed:**
  - removed the `any` Prisma access
  - added a typed catalog-builder path that filters unsupported DB reward types instead of polluting the live catalog
- **Later follow-up:** cosmetic achievement rewards (`title/frame`) were implemented in [[block-180-backend-achievement-cosmetic-claim-runtime-parity]]
- **Status:** Fixed

### `backend/src/app/api/achievements/route.ts`

- **Zone:** backend / achievements API
- **Purpose:** returns enriched achievement progress for iOS
- **Depends on:** auth, Prisma achievements, achievement catalog
- **Used by:** iOS achievements screen
- **Problems found:** live descriptions for Diamond and Grandmaster still showed the pre-rebalance rating thresholds
- **What was fixed:** player-facing descriptions now match the actual thresholds (`3000` and `4250`)
- **Status:** Fixed

### `backend/src/lib/game/weekly-challenges.ts`

- **Zone:** backend / battle pass weekly helpers
- **Purpose:** builds deterministic weekly challenges and updates progress rows
- **Depends on:** `QuestType`, balance config, raw SQL helper
- **Used by:** battle-pass weekly routes and progression hooks across gameplay endpoints
- **Problems found:** the raw SQL executor surface still used `any[]`
- **What was fixed:** replaced the loose executor type with an explicit `unknown[]` contract and extended tests around `updateWeeklyChallengeProgress`
- **Status:** Fixed

### `backend/tests/api/tutorial-quest.test.ts`

- **Zone:** backend tests / tutorial
- **Purpose:** route-level regression coverage for tutorial quest progress and claim
- **What it covers now:**
  - locked quest progression returns `409` instead of generic `500`
  - invalid progress amount is rejected before opening a transaction
  - claim path uses canonical consumable reward typing and still returns the expected reward payload
- **Status:** Fixed

### `backend/tests/lib/achievement-catalog.test.ts`

- **Zone:** backend tests / achievements
- **Purpose:** covers DB-definition normalization for the achievement catalog
- **What it covers now:**
  - valid DB definitions are converted into runtime catalog entries
  - unsupported DB reward types are dropped instead of entering the live catalog
- **Status:** Fixed

### `backend/tests/lib/weekly-challenges.test.ts`

- **Zone:** backend tests / battle pass
- **Purpose:** protects deterministic weekly challenge generation and progress updates
- **What was added:** direct coverage for the raw SQL progress helper so its public write contract stays stable
- **Status:** Fixed

## Problems found

1. **Tutorial quest route translated expected user/config states into generic `500`s**
   - Risk: locked quests, already-claimed rewards, or forbidden access looked like backend failures instead of recoverable gameplay states.
   - Fix: mapped sentinel errors to explicit responses.

2. **Tutorial reward config allowed malformed or partially dropped rewards**
   - Risk: a broken consumable or item reward could be claimed and silently under-grant.
   - Fix: typed consumable rewards, rejected malformed consumable config, and failed item-reward claims when the catalog entry is missing.

3. **Achievement rank descriptions drifted from real thresholds**
   - Risk: UI told players Diamond was `1800` and Grandmaster was `2200` while runtime required `3000` and `4250`.
   - Fix: updated the player-facing metadata in the achievements route.

4. **Achievement DB definitions had weak validation**
   - Risk: unsupported DB reward types could enter the live catalog and only explode later during claim.
   - Fix: normalized DB definitions through a typed filter step.

5. **Achievement list metadata and claim runtime were split for cosmetic rewards**
   - Risk: the catalog could describe `title/frame` rewards that the player could not actually receive.
   - Fix: resolved later in [[block-180-backend-achievement-cosmetic-claim-runtime-parity]] by teaching claim runtime + iOS ceremony to handle cosmetic rewards end to end.

## Verification

- targeted backend `eslint`:
  - `src/app/api/tutorial/quest/route.ts`
  - `src/app/api/achievements/route.ts`
  - `src/lib/game/tutorial.ts`
  - `src/lib/game/achievement-catalog.ts`
  - `src/lib/game/weekly-challenges.ts`
  - `tests/api/tutorial-quest.test.ts`
  - `tests/lib/achievement-catalog.test.ts`
  - `tests/lib/weekly-challenges.test.ts`
- targeted backend `vitest`:
  - `tests/api/tutorial-quest.test.ts`
  - `tests/lib/achievement-catalog.test.ts`
  - `tests/lib/weekly-challenges.test.ts`
- full backend `npx vitest run` (`37/37` files, `275/275` tests)
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- tutorial quests still have two declared-but-unimplemented reward types: `instant_mine` and `bp_levels`
- achievement cosmetic rewards (`title/frame`) were later closed in [[block-180-backend-achievement-cosmetic-claim-runtime-parity]]
- the next backend warning-heavy slice is still `combat-simulator`, `combat`, `feature-flags`, `progression`, `push/send`, and adjacent helpers
