---
title: Block 184 — achievement product doc runtime parity
category: audit
tags: [audit, docs, achievements, progression, source-of-truth]
sources:
  - backend/src/lib/game/achievement-catalog.ts
  - docs/02_product_and_features/GAME_SYSTEMS.md
  - docs/06_game_systems/BALANCE_CONSTANTS.md
  - docs/06_game_systems/PROGRESSION.md
updated: 2026-04-17
status: Fixed
---

# Block 184 — achievement product doc runtime parity

## Scope

- `backend/src/lib/game/achievement-catalog.ts`
- `docs/02_product_and_features/GAME_SYSTEMS.md`
- `docs/06_game_systems/BALANCE_CONSTANTS.md`
- `docs/06_game_systems/PROGRESSION.md`

## Why this block

After [[block-183-achievement-doc-count-and-reward-summary-parity]], the most visible wiki/docs surfaces were finally honest about achievements again. One adjacent layer still lagged behind: older product/system docs were still describing a much wider and partly fictional achievement system (`30+` objectives, extra categories, gem-only reward framing, and prestige-cycle resets).

Those files are still read as product context, so leaving them stale would keep leaking the wrong model back into planning conversations. This block aligns them with the current runtime instead of letting old concept-doc language masquerade as live behavior.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[achievements]]
- [[block-183-achievement-doc-count-and-reward-summary-parity]]

## File notes

### `backend/src/lib/game/achievement-catalog.ts`

- **Zone:** backend / achievements / authority
- **Purpose:** current code-first source of truth for live fallback definitions
- **Why it mattered here:** the docs needed to align to the actual runtime catalog: `18` achievements across `pvp`, `progression`, and `ranking`
- **Status:** OK

### `docs/02_product_and_features/GAME_SYSTEMS.md`

- **Zone:** docs / product summary
- **Purpose:** broad gameplay-system overview
- **Problems found:** achievements section still described an older concept set with `30+` objectives, extra categories, and prestige-resetting rewards
- **What was fixed:**
  - reduced the summary to the live `18`-achievement / `3`-category system
  - removed non-live category claims (`Dungeon`, `Cosmetics`, `Economy`, separate `Prestige` bucket)
  - clarified that rewards are mixed currency/cosmetic grants
  - corrected the prestige behavior so achievements do not reset per prestige cycle
- **Status:** Fixed

### `docs/06_game_systems/BALANCE_CONSTANTS.md`

- **Zone:** docs / balance constants
- **Purpose:** high-level economy/value summary
- **Problems found:** free-gem income still implied every achievement was part of a gem-only payout lane
- **What was fixed:** achievement income note now says the catalog is mixed and that gems come only from selected achievement milestones
- **Status:** Fixed

### `docs/06_game_systems/PROGRESSION.md`

- **Zone:** docs / progression systems
- **Purpose:** long-form progression reference
- **Problems found:**
  - reward-type table still implied non-live reward categories like BP XP / cosmetics bundle language
  - discovery/claim wording implied rewards might auto-claim
- **What was fixed:**
  - reward-type table now matches the real live reward surface (`gold/gems/xp/title/frame`)
  - claim wording now states rewards are claimed through the achievements UI rather than auto-granted
- **Status:** Fixed

## Problems found

1. **Older product docs still described a larger, different achievement system**
   - Risk: planning and balancing discussions could keep starting from a fictional `30+`-objective, multi-category design instead of the live runtime.
   - Fix: aligned product/system docs to the actual catalog.

2. **Reward and prestige semantics were drifting in docs**
   - Risk: contributors could assume achievements reset on prestige or that every achievement is a gem faucet.
   - Fix: rewrote those summaries to reflect persistent per-character progress and mixed reward types.

## Verification

- re-read `backend/src/lib/game/achievement-catalog.ts` against the touched docs
- `git diff --check`

## Follow-up

- if achievements expand again later, update the fallback catalog and the product docs in the same change so the old “concept doc outran runtime” pattern does not return
