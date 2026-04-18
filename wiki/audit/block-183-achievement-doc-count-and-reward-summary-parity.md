---
title: Block 183 — achievement doc count and reward summary parity
category: audit
tags: [audit, docs, wiki, achievements, source-of-truth]
sources:
  - backend/src/lib/game/achievement-catalog.ts
  - wiki/index.md
  - wiki/features/achievements.md
  - wiki/systems/achievements.md
  - docs/features/achievements/ACHIEVEMENTS_OVERVIEW.md
  - docs/01_source_of_truth/DOCUMENTATION_INDEX.md
updated: 2026-04-17
status: Fixed
---

# Block 183 — achievement doc count and reward summary parity

## Scope

- `backend/src/lib/game/achievement-catalog.ts`
- `wiki/index.md`
- `wiki/features/achievements.md`
- `wiki/systems/achievements.md`
- `docs/features/achievements/ACHIEVEMENTS_OVERVIEW.md`
- `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`

## Why this block

Once [[block-180-backend-achievement-cosmetic-claim-runtime-parity]] and [[block-182-backend-achievement-list-definition-text-parity]] landed, the docs around achievements still told an older story: multiple wiki/docs surfaces kept saying the live system had `21` achievements and gem-only rewards, even though the current backend catalog has `18` entries and the reward surface now spans currency plus cosmetics.

This block is the boring but necessary source-of-truth cleanup: it aligns the summary layers with the actual live catalog instead of leaving stale copy in the most visible docs.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[achievements]]
- [[block-180-backend-achievement-cosmetic-claim-runtime-parity]]
- [[block-182-backend-achievement-list-definition-text-parity]]

## File notes

### `backend/src/lib/game/achievement-catalog.ts`

- **Zone:** backend / achievements / authority
- **Purpose:** current source of truth for the code-first fallback catalog
- **Why it mattered here:** the catalog currently defines `18` achievements (`9` PvP, `5` progression, `4` ranking), so the repeated `21` count in docs was simply stale
- **Status:** OK

### `wiki/index.md`

- **Zone:** wiki / navigation
- **Purpose:** top-level atlas for systems and features
- **What was fixed:** achievements summary line now describes the real live shape (`18` achievements, claimable currency/cosmetic rewards) instead of the stale gem-only wording
- **Status:** Fixed

### `wiki/features/achievements.md`

- **Zone:** wiki / features
- **Purpose:** detailed feature map for achievements
- **What was fixed:**
  - swapped stale `21-entry` copy for the real `18-entry` catalog count
  - clarified that `GET /api/achievements` prefers active definition text
  - clarified that rewards can be currency or cosmetic, not gem-only
- **Status:** Fixed

### `wiki/systems/achievements.md`

- **Zone:** wiki / systems
- **Purpose:** legacy system summary
- **What was fixed:** updated the count to `18` and rewrote the reward section to reflect the widened live reward surface (`gold/gems/xp/title/frame`)
- **Status:** Fixed

### `docs/features/achievements/ACHIEVEMENTS_OVERVIEW.md`

- **Zone:** docs / feature overview
- **Purpose:** historical-but-still-useful local feature summary
- **Problems found:** overview simultaneously claimed `21` achievements while its own category table still only totaled `18`
- **What was fixed:**
  - status and overview count now match the live catalog
  - reward wording now reflects claimable currency/cosmetic rewards
  - “adding achievements” notes now acknowledge that the list route can use live definition text instead of only route-local display metadata
- **Status:** Fixed

### `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`

- **Zone:** docs / source-of-truth index
- **Purpose:** map of major docs
- **What was fixed:** achievements feature-doc summary now says `18 achievements` instead of `21`
- **Status:** Fixed

## Problems found

1. **High-visibility summaries still overstated the live achievement count**
   - Risk: operators and future contributors would reason from `21` even though the current catalog only contains `18`.
   - Fix: aligned all summary layers to the live catalog.

2. **Multiple doc surfaces still implied gem-only rewards**
   - Risk: reward-contract work around `gold/xp/title/frame` could be missed because the docs kept advertising a narrower system.
   - Fix: updated summaries to describe the real mixed currency/cosmetic reward surface.

## Verification

- re-read `backend/src/lib/game/achievement-catalog.ts` against all touched docs
- `git diff --check`

## Follow-up

- if more achievements are added later, update the summary counts from the catalog in the same change instead of letting the wiki drift again
