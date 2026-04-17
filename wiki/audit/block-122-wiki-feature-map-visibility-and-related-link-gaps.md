---
title: Block 122 — Wiki feature-map visibility and related-link gaps
category: audit
tags: [audit, wiki, navigation, features, source-of-truth]
sources:
  - wiki/index.md
  - wiki/features/achievements.md
  - wiki/features/auth.md
  - wiki/features/battle-pass.md
  - wiki/features/characters.md
  - wiki/features/daily-login.md
  - wiki/features/dungeon-rush.md
  - wiki/features/dungeons.md
  - wiki/features/events.md
  - wiki/features/inventory.md
  - wiki/features/leaderboard.md
  - wiki/features/mail.md
  - wiki/features/minigames.md
  - wiki/features/passive-tree.md
  - wiki/features/prestige.md
  - wiki/features/quests.md
  - wiki/features/session-summary.md
  - wiki/features/social.md
  - wiki/features/stamina.md
  - wiki/features/stash.md
  - wiki/features/tutorial.md
updated: 2026-04-16
status: Fixed
---

# Block 122 — Wiki feature-map visibility and related-link gaps

## Scope

- `wiki/index.md`
- `wiki/features/achievements.md`
- `wiki/features/auth.md`
- `wiki/features/battle-pass.md`
- `wiki/features/characters.md`
- `wiki/features/daily-login.md`
- `wiki/features/dungeon-rush.md`
- `wiki/features/dungeons.md`
- `wiki/features/events.md`
- `wiki/features/inventory.md`
- `wiki/features/leaderboard.md`
- `wiki/features/mail.md`
- `wiki/features/minigames.md`
- `wiki/features/passive-tree.md`
- `wiki/features/prestige.md`
- `wiki/features/quests.md`
- `wiki/features/session-summary.md`
- `wiki/features/social.md`
- `wiki/features/stamina.md`
- `wiki/features/stash.md`
- `wiki/features/tutorial.md`

## Why this block

The feature-map layer had quietly outgrown the index:

- multiple feature pages already existed on disk
- the main `wiki/index.md` still surfaced only the older short list
- the footer counts were therefore understating how much feature coverage already existed

That is a source-of-truth problem, even if the pages themselves are good.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-114-wiki-feature-maps-and-index-visibility]]
- [[block-121-prototypes-link-parity-and-transition-state]]

## File notes

### `wiki/index.md`

- **Zone:** wiki navigation root
- **Purpose:** primary entrypoint for discovering systems, decisions, entities, features, and audit blocks
- **Problems found:**
  - feature section still surfaced only the earlier subset of feature maps
  - footer counts were lagging the real number of feature pages and total wiki pages
- **What was fixed:**
  - expanded the feature section to surface the full current feature-map layer, including `passive-tree`, `prestige`, `quests`, `session-summary`, `social`, `minigames`, `stamina`, `stash`, and `tutorial`
  - synchronized the footer counts with the current feature-map set
- **Status:** Fixed

### `wiki/features/auth.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for guest/email/OAuth auth, guest upgrade, linking, reset, and deletion
- **Review outcome:**
  - useful and substantive map that deserved index visibility
  - `[[tutorial]]` and `[[session-summary]]` now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/achievements.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for achievement tracking, claim flows, admin tuning, and touchpoints
- **Review outcome:**
  - strong page with concrete backend/iOS/admin coverage
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/battle-pass.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for seasonal progression, premium lane, rewards, and weekly challenge XP feeds
- **Review outcome:**
  - deserved index visibility
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/characters.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for character creation, stats, appearance, profile, and respec
- **Review outcome:**
  - useful live map with solid backend/iOS coverage
  - `[[passive-tree]]`, `[[inventory]]`, and `[[prestige]]` now resolve, but `[[opponent-profile]]` still dead-ends
- **Needs separate decision:** create an `opponent-profile` feature page or remap that dependency onto an existing canonical page
- **Status:** Needs review

### `wiki/features/daily-login.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for the calendar/streak reward system
- **Review outcome:**
  - deserved index visibility
  - `[[events]]` and `[[session-summary]]` now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/dungeons.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for structured dungeon progression and room/victory flows
- **Review outcome:**
  - deserved index visibility
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/dungeon-rush.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for endless rush runs, room shops, resolve/abandon, and related iOS/backend surfaces
- **Review outcome:**
  - new enough that it was invisible from the main index despite being a real page
  - should now be discoverable as a first-class feature map
- **Status:** OK

### `wiki/features/events.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for live-event scheduling, active-event reads, and banner/modifier application
- **Review outcome:**
  - deserved index visibility
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/inventory.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for equipment, consumables, upgrade/use/sell flows, and bag expansion
- **Review outcome:**
  - deserved index visibility
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/leaderboard.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for leaderboard list/search and opponent profile drill-down
- **Review outcome:**
  - deserved index visibility
  - `[[social]]` and `[[achievements]]` now resolve, but `[[opponent-profile]]` still dead-ends
- **Needs separate decision:** create an opponent-profile feature page or remap the dependency reference
- **Status:** Needs review

### `wiki/features/mail.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for inbox mail, reward claim flow, unread counts, and admin broadcast delivery
- **Review outcome:**
  - deserved index visibility
  - now links cleanly to existing `social`, `shop`, `battle-pass`, and `events` pages
- **Status:** OK

### `wiki/features/passive-tree.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for talent nodes, respec, active-slot binding, and skill-slot interplay
- **Review outcome:**
  - strong bridge page between character progression and interactive combat
  - deserved first-class visibility from the main index
- **Status:** OK

### `wiki/features/minigames.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for Tavern minigames, shared `MinigameSession` boundaries, and the Shell Game / Fortune Wheel loop
- **Review outcome:**
  - closes a useful gap between the broad systems page and the actual Tavern runtime surface
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/prestige.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for max-level prestige reset, multiplier carryover, and badge/UI implications
- **Review outcome:**
  - useful progression map that had been effectively hidden despite being live
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/quests.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for daily quests, bonus claims, tutorial quest overlap, and event-source hooks
- **Review outcome:**
  - important missing atlas page that also resolves several older cross-links from `achievements`, `battle-pass`, `events`, and `dungeons`
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/session-summary.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for since-you-last-played summary diffs, aggregated offline deltas, and summary modal boundaries
- **Review outcome:**
  - closes the older `auth` and `daily-login` dependency gap cleanly
  - deserved first-class visibility because it documents a real cross-system player surface, not just an implementation detail
- **Status:** OK

### `wiki/features/social.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for friends, challenges, direct messages, and guild hall surfaces
- **Review outcome:**
  - deserved visibility as a real feature atlas page, not just a system note
  - still links to missing `[[opponent-profile]]`
- **Needs separate decision:** create an opponent-profile feature page or re-anchor the shared-entry explanation
- **Status:** Needs review

### `wiki/features/stamina.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for regen, refill diminishing returns, stamina spenders, and potion-vs-refill rules
- **Review outcome:**
  - useful cross-cutting feature page that ties together economy, PvP, dungeons, and inventory
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/stash.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for account-level shared storage, deposit/withdraw, and cross-character item transfer
- **Review outcome:**
  - closes the real inventory dependency gap that was still open when this block started
  - related links now resolve against the current feature-map set
- **Status:** OK

### `wiki/features/tutorial.md`

- **Zone:** feature map
- **Purpose:** end-to-end map for first-run progression, scripted fights, tutorial quests, and referral bind window
- **Review outcome:**
  - important onboarding-adjacent map that resolves older `auth` and `quests` feature-atlas gaps
  - still links to missing `[[onboarding]]`
- **Needs separate decision:** create an `onboarding` feature page or remap that dependency onto the current character-creation/tutorial entrypoint pages
- **Status:** Needs review

## Problems found

1. **Feature-map discovery had fallen behind actual coverage**
   - Risk: people think the wiki has only a curated handful of feature maps when the repo already has a much broader feature atlas.
   - Fix: surfaced the missing feature pages in `wiki/index.md`.

2. **Footer counts understated the real wiki surface**
   - Risk: the main index communicates the wrong project-documentation coverage level.
   - Fix: resynchronized the footer counts with the current feature-map set.

3. **A smaller set of true related-page gaps still remains**
   - Risk: the feature layer feels less trustworthy because a few dependency links still dead-end.
   - Fix: narrowed the open gaps to the real missing pages and recorded them explicitly instead of carrying forward stale gap lists.

## Verification

- inspected the current `wiki/features/*.md` set after the latest feature-map growth
- checked the main feature section in `wiki/index.md`
- rescanned related-link targets for the reviewed feature pages against the current wiki page set
- `git diff --check`

## Follow-up

- Create or remap the remaining missing related pages referenced from the feature-map layer: `opponent-profile` and `onboarding`.
- Keep the feature section in `wiki/index.md` synchronized whenever new `wiki/features/*.md` pages are added.
