# Game Systems Overview (Source of Truth)

*Updated: 2026-04-29 — runtime-parity rewrite; brittle numeric tables moved to canonical economy/balance docs*

High-level map of the live gameplay systems in Hexbound.

This file is intentionally **overview-first**. It describes what systems exist,
how they relate, and where authority lives. Exact prices, reward tables,
upgrade odds, and pacing numbers drift quickly and now belong in narrower
source-of-truth docs:

- `docs/02_product_and_features/ECONOMY.md`
- `docs/06_game_systems/BALANCE_CONSTANTS.md`
- `docs/06_game_systems/COMBAT.md`
- `wiki/features/*.md`

All player-facing systems below are **server-authoritative** unless explicitly
noted otherwise.

---

## Core Runtime Principles

- **Server-authoritative gameplay:** combat outcomes, reward grants, rating
  changes, loot rolls, progression state, and live-economy transactions are
  resolved on the backend.
- **Thin client rendering:** iOS and admin render server-returned state,
  trigger actions, and cache snapshots, but do not own canonical gameplay math.
- **Config-backed liveops:** many knobs are adjustable through admin/config
  surfaces, but the authoritative runtime still lives in backend routes and
  helpers.
- **Feature-map detail lives elsewhere:** use `wiki/features/*` when you need
  exact routes, view models, Prisma models, or runtime gotchas for one feature.

---

## PvP Combat

PvP remains the core repeatable gameplay loop.

- **Format:** 1v1 class-vs-class combat with shared combat math and reward
  resolution.
- **Modes:** the repo carries both classic resolve flows and the newer
  interactive match lifecycle, with different entry points depending on the
  surface.
- **Tactical layer:** stance, active skills, passives, crit/dodge/block, and
  fatigue-style pacing all feed into the same server-owned combat resolution.
- **Rating:** PvP rank, matchmaking spread, revenge bonuses, and leaderboard
  placement are all backend-owned and feed adjacent systems like achievements,
  battle pass, and daily quests.

For formulas and combat-specific rules, see:

- `docs/06_game_systems/COMBAT.md`
- `wiki/features/pvp-combat.md`
- `wiki/features/interactive-combat.md`

---

## Dungeons and Dungeon Rush

Hexbound ships two PvE progression flavors:

- **Classic Dungeons:** structured runs with server-owned run state, room
  progression, boss encounters, and end-of-run rewards.
- **Dungeon Rush:** endless/minigame-adjacent run variant with shop pauses,
  pressure scaling, and separate run-state rules.

Common principles:

- run state is backend-owned
- abandon/defeat/victory have distinct reward outcomes
- boss reveals, reward ceremonies, and loot presentation are client surfaces on
  top of server-returned results

See:

- `wiki/features/dungeons.md`
- `wiki/features/dungeon-rush.md`

---

## Skills and Passive Progression

Character buildcraft comes from two linked layers:

- **Active skills:** class-restricted learned abilities that bind into active
  combat slots
- **Passive tree:** node graph with unlock prerequisites, respec flows, and
  permanent stat/combat modifiers

Important runtime truth:

- slot ownership and effect resolution are server-authoritative
- iOS renders the tree, picker, and bind UX, but the backend validates unlocks,
  respecs, and slot mutations
- prestige and level progression feed the point economy around these systems

See:

- `wiki/features/passive-tree.md`
- `docs/06_game_systems/COMBAT.md`
- `docs/06_game_systems/BALANCE_CONSTANTS.md`

---

## Characters, Levels, and Prestige

Progression revolves around a persistent character row with layered advancement:

- **levels and XP**
- **stat-point allocation**
- **passive-point allocation**
- **gear growth**
- **prestige carryover**

Live truth:

- level-up rewards and passive/stat point grants are backend-owned
- prestige logic is live backend-side and affects long-term multiplier state
- prestige presentation exists in shipped UI surfaces, while the concrete
  prestige-action entry surface is narrower and more backend-driven than older
  product docs implied

See:

- `wiki/features/characters.md`
- `wiki/features/prestige.md`
- `docs/06_game_systems/BALANCE_CONSTANTS.md`

---

## Equipment, Inventory, and Stash

The gear loop includes:

- equipment acquisition
- rarity/rolled stat presentation
- upgrades and durability
- sell/use/equip/unequip flows
- bag expansion
- account-scoped stash storage

Important live rules:

- effective item stats come from backend authority, including rolled stats and
  upgrade-aware calculations
- iOS and admin now consume typed snapshots rather than inventing local stat
  math whenever possible
- stash is a real account-level surface, not just overflow flavor text

See:

- `wiki/features/inventory.md`
- `wiki/features/stash.md`
- `wiki/features/shop.md`

---

## Economy, Shop, and Monetization

The live economy is now best thought of as an interconnected system rather than
one giant table in this document.

Key surfaces:

- **gold and gems**
- **repair / upgrade / potion sinks**
- **shop purchases and offers**
- **contraband and special offers**
- **battle pass premium purchase**
- **IAP gem packs, mixed bundles, monthly card, premium transition**

Important live truth:

- Economy v3 is the current baseline
- flat gold packs are legacy/disabled, replaced by mixed bundles
- premium entitlement is in transition: legacy lifetime ownership still exists,
  while the newer subscription path is present in backend/runtime plumbing
- exact prices and sink ratios should be read from economy/balance docs, not
  duplicated here

See:

- `docs/02_product_and_features/ECONOMY.md`
- `docs/06_game_systems/BALANCE_CONSTANTS.md`
- `wiki/features/shop.md`

---

## Gold Mine and Minigames

Hexbound includes several side-economy engagement loops:

- **Gold Mine:** idle accrual + collect flows + slot unlocks + bonus minigame
- **Shell Game**
- **Fortune Wheel**
- **Tavern-hosted minigame surfaces**

Live truth:

- Gold Mine is production runtime, not a concept stub
- payout/bonus/slot rules are backend-owned
- reward ceremony behavior has been normalized across several client flows, so
  currency payouts increasingly use the shared modal language instead of ad hoc
  toasts

See:

- `wiki/features/gold-mine.md`
- `wiki/features/minigames.md`

---

## Daily Loops and Liveops Systems

The retention layer is a set of connected systems, not isolated checklists:

- **Daily Login:** live 7-day cycle with popup + calendar view
- **Daily Quests:** rotating tracked objectives with bonus overlap and tutorial
  interaction
- **Battle Pass:** seasonal free/premium reward track with weekly challenge
  feeds
- **Achievements:** claimable long-tail progression goals
- **Events:** time-boxed runtime modifiers and admin-managed event definitions
- **Mail:** claim surface for rewards, admin messages, and compensation
- **Referral:** invite flow with qualification rewards and backfill-aware repair
  tooling

These systems frequently share reward infrastructure, progression hooks, and
admin review/edit surfaces.

See:

- `wiki/features/daily-login.md`
- `wiki/features/quests.md`
- `wiki/features/battle-pass.md`
- `wiki/features/achievements.md`
- `wiki/features/events.md`
- `wiki/features/mail.md`
- `wiki/features/referral.md`

---

## Leaderboards, Social, and Cosmetics

Meta and identity systems sit around the core loop:

- **leaderboard and profile drill-downs**
- **friends / messages / challenges / guild hall social surfaces**
- **titles, frames, skins, and other cosmetic progression**

Important live truth:

- social exists as a real runtime surface, not a placeholder guild idea
- leaderboard/admin review surfaces are narrower than some older docs implied
- cosmetics are distributed through several systems, including battle pass,
  achievements, shop, and events

See:

- `wiki/features/leaderboard.md`
- `wiki/features/opponent-profile.md`
- `wiki/features/social.md`

---

## Admin and Live Tuning Relationship

Admin is real and broad, but it should be described carefully:

- many gameplay systems have live admin pages or review surfaces
- not every imagined analytics, scheduling, simulation, or rollback feature is
  present as a dedicated page
- some systems expose CRUD/config editing directly, while others expose review
  dashboards or seed flows only

When you need current admin truth, use:

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- relevant `wiki/features/*.md` admin sections

---

## Server Authority Rules

The client must not invent canonical gameplay outcomes.

### Client must not own

- combat resolution
- RNG outcomes
- reward values
- rating changes
- authoritative economy math
- progression grants
- live slot/passive/equipment validation

### Client should own

- presentation
- navigation
- cached snapshots
- local animation state
- ceremony UX layered over authoritative payloads

### Server should own

- all balance formulas
- progression transactions
- entitlement checks
- anti-cheat / integrity guards
- persistent run and match state

---

## Where to Go Next

- For **numbers and formulas**: `docs/02_product_and_features/ECONOMY.md`,
  `docs/06_game_systems/BALANCE_CONSTANTS.md`, `docs/06_game_systems/COMBAT.md`
- For **feature-by-feature runtime maps**: `wiki/features/*.md`
- For **admin surface truth**: `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- For **schema and model-level detail**: `docs/04_database/SCHEMA_REFERENCE.md`
