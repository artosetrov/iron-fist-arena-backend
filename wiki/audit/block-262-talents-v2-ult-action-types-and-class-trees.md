---
title: Audit Block 262 — Talents v2 Ult Action Types + Class Trees + Combat V2 Decisions
category: audit
tags: [audit, talents, passives, combat, interactive-combat, balance, migration]
sources:
  - backend/prisma/schema.prisma
  - backend/prisma/migrations/20260429_talent_action_v2_ults/migration.sql
  - backend/prisma/seeds/passives-rogue-v2.sql
  - backend/prisma/seeds/passives-mage-v2.sql
  - backend/prisma/seeds/passives-tank-v2.sql
  - backend/prisma/seeds/seed-passives-v2.ts
  - backend/src/app/api/pvp/strike/route.ts
  - admin/prisma/schema.prisma
  - Hexbound/Hexbound/Models/PassiveTree.swift
  - Hexbound/Hexbound/Models/CombatLogEvent.swift
  - Hexbound/Hexbound/Views/Combat/ActiveSkillsHUD.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift
  - docs/06_game_systems/SKILL_TREE_DESIGN_V2.md
  - docs/07_ui_ux/COMBAT_UX_INTEGRATION_PLAN.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 262 — Talents v2 Ult Action Types + Class Trees + Combat V2 Decisions

## Scope

This block documents three coordinated landings on 2026-04-29:

1. `TalentSlotAction` Postgres enum extended from 5 → 9 values.
2. Three class passive trees seeded into prod (Rogue / Mage / Tank, 60 nodes total).
3. `COMBAT_UX_INTEGRATION_PLAN.md` §8 closed — 5 design questions resolved.

## Why this block

The Talents v2 spec (`docs/06_game_systems/SKILL_TREE_DESIGN_V2.md`) had been
locked since 2026-04-19 with backend Phase 1 already shipped (currentRank
column, /unlock, /respec, /tree). Three gaps remained:

- The 4 ultimates needed by Rogue/Mage/Tank used `actionType` strings that the
  Postgres enum did not accept (`stealth`, `aoe_damage`, `cooldown_reset`,
  `aoe_stun`). Firing any of these from a real ult would have hit the same
  enum-boundary 500 documented in `block-010` and `block-260`'s
  migration-before-deploy lesson.
- Only Warrior had a v2 seed (`passives-warrior-v2.sql`). The other 3 classes
  were unreachable from a content perspective.
- The Combat V2 3-state UX refactor scaffold had been shipped under the
  `combatUXV2` flag (default off) but couldn't progress past PR-2 because §8
  of the integration plan listed 5 unresolved design questions.

## Changes shipped

### 1. Enum migration + strike resolver (backend)

- New migration `20260429_talent_action_v2_ults/migration.sql`:

  ```sql
  ALTER TYPE "public"."TalentSlotAction" ADD VALUE IF NOT EXISTS 'stealth';
  ALTER TYPE "public"."TalentSlotAction" ADD VALUE IF NOT EXISTS 'aoe_damage';
  ALTER TYPE "public"."TalentSlotAction" ADD VALUE IF NOT EXISTS 'cooldown_reset';
  ALTER TYPE "public"."TalentSlotAction" ADD VALUE IF NOT EXISTS 'aoe_stun';
  ```

  Applied to prod via Supabase MCP **before** code deploy, following the same
  migration-before-deploy rule reinforced by the earlier interactive-combat
  and schema audit wave.

- `backend/prisma/schema.prisma` + mirror `admin/prisma/schema.prisma` enum
  updated to match (9 values total).

- `backend/src/app/api/pvp/strike/route.ts` strike resolver extended:

  - **`InteractiveActivesState`** gained `p1_buffs` / `p2_buffs:
    ActiveBuffsState` optional fields. Currently `stunRoundsRemaining` is the
    only buff, but the shape is reusable for any future cross-round effect
    (DoTs, charges, multi-round shields).
  - **Player switch-case** now covers all 9 action_types:
    - `stealth` — force-crit on the player's current-round attack via
      `CRIT_MULTIPLIER` from live config; if RNG already crit, no extra hit.
    - `aoe_damage` — 1v1 alias of `burst_damage`, distinct VFX/label only.
      Same `applyBurstDamage` math.
    - `cooldown_reset` — post-advance hook that zeroes
      `cooldown_remaining` on the firing side's OTHER non-consumable slots.
      The fired slot itself stays at full cooldown so it cannot chain-reset.
    - `aoe_stun` — multi-round stun via `stunRoundsRemaining` carry-over.
      End-of-round decrement removes one round.
  - **Opponent counter-strike block** mirrors the offensive subset
    (`burst_damage` / `aoe_damage` / `execute` / `stealth`). `aoe_stun`,
    `stun_enemy`, `cooldown_reset` from opp are no-op in v1 — opp moves
    SECOND, so applying these has no in-round effect (cross-round application
    is reserved for human-vs-human PvP).
  - **`pickOpponentActive` AI** now picks `stealth` as Tier 2 finisher when
    `playerHP < 50%`, treats `aoe_damage` exactly like `burst_damage`, and
    filters out `aoe_stun` / `cooldown_reset` (rationale documented in the
    function header).
  - **`removePlayerActiveSlot`** now passes through `p1_buffs` / `p2_buffs` so
    a mid-stun consumable reconcile cannot silently grant the opponent free
    counters.

### 2. Class passive trees (data, applied to prod via execute_sql)

Three new seed files in `backend/prisma/seeds/`:

- `passives-rogue-v2.sql` — 20 nodes, 24 connections.
  - Lanes: Assassin (offense) · Duelist (balance) · Saboteur (defense).
  - Ultimates: `vanish` → `stealth`, `shadow_reaper` → `burst_damage`.
- `passives-mage-v2.sql` — 20 nodes, 24 connections.
  - Lanes: Pyromancer (offense) · Arcanist (balance) · Cryomancer (defense).
  - Ultimates: `meteor` → `aoe_damage`, `timewarp` → `cooldown_reset`.
- `passives-tank-v2.sql` — 20 nodes, 24 connections.
  - Lanes: Protector (offense) · Warden (balance) · Juggernaut (defense).
  - Ultimates: `fortress` → `shield_self` (spec calls for `damage_reduction`,
    not in enum; `shield_self` is mathematically equivalent), `earthshatter`
    → `aoe_stun`.

Each seed follows the same scope-limited-wipe pattern as
`passives-warrior-v2.sql`: deletes only `node_key LIKE '<class>.%'` rows from
`character_passives`, `passive_connections`, `character_active_slots`, and
`passive_nodes` before inserting fresh data. Safe to re-run pre-launch; NOT
safe once players have unlocked v2 nodes.

A thin TS runner now exists alongside the SQL files:

- `backend/prisma/seeds/seed-passives-v2.ts`

It applies the four class SQL seeds in deterministic order and gives local/CI
bootstrap a single checked-in entrypoint without re-encoding the tree data in a
second TS source of truth.

### 3. Balance pass #1 (prod + seed files synced)

After applying the seeds, one quick magnitude/cooldown sanity sweep flagged
two outliers, fixed inline:

- `tank.ult.earthshatter` `aoe_stun` magnitude **2 → 1 rounds**. 2-round
  silence on a 15-round duel = ~25% of the match the opponent loses counter
  attacks, plus a +30% passive damage stack = OP combo at 120s CD. 1 round
  matches `stun_enemy` semantics; uniqueness preserved by the +30% passive
  and the 120s cooldown.
- `rogue.ult.vanish` `active_cooldown` **60 → 75s**. 60s was the shortest
  cooldown in the game while Vanish carries only +15% passive (peers carry
  +25–30%). 75s aligns it with Champion (Warrior, 75) and Shadow Reaper
  (Rogue, 75).

Other ult magnitudes/CDs left at first-pass values pending a full
ledger/scales playtest.

### 4. iOS extensions

`TalentSlotAction` Swift enum in `Hexbound/Hexbound/Models/PassiveTree.swift`
gained 4 cases: `stealth`, `aoeDamage`, `cooldownReset`, `aoeStun`. All
exhaustive switches updated:

- `PassiveTree.swift` — `shortLabel`, `sfSymbol`
- `CombatLogEvent.swift` — `kind`, `talentAsset`
- `ActiveSkillsHUD.swift` — `ActiveFireStyle.forAction`
- `InteractiveBattleViewModel.swift` — SFX dispatch in `playActiveFireSFX`

Asset / SFX use closest-fit fallbacks (`fx-magical-burst`, `bolt.horizontal`,
etc.) until dedicated VFX/audio is commissioned. TODO markers in place.

### 5. Combat V2 design decisions (docs only)

`docs/07_ui_ux/COMBAT_UX_INTEGRATION_PLAN.md` §8 rewritten from "Open
questions for Artem" to "Decisions (locked 2026-04-29)":

| ID  | Topic | Decision |
| --- | ----- | -------- |
| D-1 | Ranked rewards | Show delta + new total (not delta-only). |
| D-2 | Round log in END | Keep, collapsed by default, single-tap expand. |
| D-3 | Round strip | `ROUND 3 / 15`. Drop "BEST OF N" — engine is hard-capped, not bo-N. |
| D-4 | Objectives in END | Filter by `delta > 0`; hide block entirely if nothing changed. |
| D-5 | SKIP in CHOOSE | Confirmation micro-sheet (matches prototype). |

Decisions D-1, D-3, D-4 require small spec updates inside
`Hexbound/Views/Combat/V2/CombatV2EndComponents.swift` and
`CombatV2ChoosePhase.swift`. Folded into PR-3 / PR-5 of the existing
sequence; no new PRs needed. This unblocks the entire 7-PR Combat V2
implementation track.

## Verification

Run against prod (project `gqnyozmqbhgzprsftdzp`) immediately after the
landings:

- `pg_enum` query returns 9 `TalentSlotAction` values in correct order:
  `burst_damage, heal_self, shield_self, stun_enemy, execute, stealth,
  aoe_damage, cooldown_reset, aoe_stun`.
- `passive_nodes` count by class: warrior 23 / rogue 20 / mage 20 / tank 20 =
  83 total.
- `tank.ult.earthshatter` row: `active_magnitude = 1`,
  `active_action_type = aoe_stun`, `active_cooldown = 120`.
- `rogue.ult.vanish` row: `active_cooldown = 75`,
  `active_action_type = stealth`, `active_magnitude = 1`.
- `python3 scripts/check_schema_drift.py` — clean (65 models / 705 columns /
  118 enum values, all migrations match schema).
- `git status --short` clean on `main`; commits `5892a49 / e30f479 / 769558d
  / 75765b6` on `origin/main` covering the four landings.

Swift exhaustive-switch enforcement caught two extra non-V2 callers that
needed to grow to 9 cases (`CombatLogEvent.kind` and the SFX dispatch in
`InteractiveBattleViewModel.playActiveFireSFX`) — they would have broken iOS
build had they been missed.

## Result

Talents v2 is content-complete in prod for all 4 classes, the strike
resolver supports the full 9-action-type vocabulary, the iOS HUD covers
every type, and Combat V2 is unblocked for PR-3 / PR-4 / PR-5
implementation. The cross-round buff-state pattern for future multi-round
effects is now documented directly in this audit block plus the checked-in
Interactive Combat and Passive Tree wiki pages.

## Open follow-ups (deferred, not blockers)

- Full ledger / scales playtest pass: 4 classes × 3 canonical builds, target
  no >55% win-rate dominant strategy (per spec §11 QA gates). First-pass
  magnitudes/CDs on 6 of 8 ults are unverified.
- Dedicated VFX / SFX assets for Vanish / Cataclysm / Rewind / Quake.
  Currently fallback assets with `TODO(canvas)` / `TODO(audio)` markers in
  `CombatLogEvent.swift` and `InteractiveBattleViewModel.swift`.
- Unit tests for the 4 new strike-resolver handlers — currently no fixture
  coverage of stealth / aoe_damage / cooldown_reset / aoe_stun paths.
- TS-parity seed scripts (`seed-passives-{class}-v2.ts`) — gatekeeper §6c
  formal violation, but ROI is low until a CI pipeline actually consumes
  them; deferred.
- Combat V2 PR-3 (CHOOSE phase content) → PR-6 (finishing-blow polish) —
  scaffold exists, decisions locked, ready to start.

## Cross-references

- Spec: `docs/06_game_systems/SKILL_TREE_DESIGN_V2.md`
- Combat V2 plan: `docs/07_ui_ux/COMBAT_UX_INTEGRATION_PLAN.md`
- Combat V2 architecture: `docs/07_ui_ux/COMBAT_UX_REFACTOR_3_STATE.md`
- Migration-before-deploy rule: `block-010-prisma-migrations-hotfixes-stash-interactive-premium`
- Combat feature map: `wiki/features/interactive-combat.md`
- Passive tree system map: `wiki/systems/passive-tree.md`
- Combat feature-map memory boundary sync: `block-260-combat-feature-map-memory-boundary-sync`
