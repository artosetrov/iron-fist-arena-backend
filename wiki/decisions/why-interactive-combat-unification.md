---
title: Unify all combat into Interactive
status: partial (pvp + bot + dungeon_boss done, dungeon_rush deferred)
date: 2026-04-19
---

# Why: unify all combat through InteractiveBattle

## Problem

The app historically shipped **two parallel combat UIs**:

1. **OLD** — `CombatDetailView` + `CombatViewModel`. Plays a pre-resolved `combatLog` from `/pvp/prepare+resolve` (bots), `/dungeons/*/fight` (dungeons), and challenge replay. Server computes the whole fight up-front, client animates.
2. **NEW** — `InteractiveBattleView` + `InteractiveBattleViewModel`. Stance-picking round-by-round match lifecycle through `/pvp/match/start → /strike → /complete`. Was feature-flagged `INTERACTIVE_COMBAT_V1` and initially gated to real PvP only.

The player-visible symptom: Arena bot fights routed through Interactive would 404 on `/pvp/match/start` because the endpoint tried to `prisma.character.findUnique(opponent_id)` and the bot id (`npc_warrior_0_…`) has no DB row. Before this migration, bot fights fell back to old combat where all VFX/SFX work.

## Decision

Extend the match lifecycle endpoints with an explicit `opponent_type` fork so the **same** Interactive UI drives PvP and bot fights. For non-PvP opponents we store their `CharacterStats` in a new `pvp_matches.opponent_snapshot` JSONB column (no DB row needed). Server-authoritative combat math is unchanged; opponent stats just load from the snapshot instead of `loadCombatCharacter(defender.id)`.

## Scope of this migration

**Shipped:**

- DB migration `20260418_interactive_combat_unified_opponent`:
  `PvpMatch.player2Id` now nullable. New columns: `opponent_type`, `opponent_snapshot`, `dungeon_run_id`, `boss_key`, `bot_key`. Index `(opponent_type, status)`.
- `/pvp/match/start` — infers `opponent_type` from `npc_*` prefix when caller omits the field (backward-compat for pre-migration iOS builds). For `bot` mode: synthesizes stats via `generateBotCombatStats()`, stores snapshot, sets `matchType='bot'`.
- `/pvp/strike` — reads defender stats from `opponent_snapshot.combat_stats` when `opponent_type != 'pvp'`. AI zone picker (seed-based) already works for all modes.
- `/pvp/match/complete` — bot path skips `defenderUpdate`, defender gold grant, `revengeQueue.create`, and `applyLevelUp(defender.id)`. Bot ELO uses `+30%K` on win / `−10%K` on loss (matches legacy `/pvp/resolve` bot formula).
- iOS `AppRoute.interactiveBattle` gains `opponentType: InteractiveOpponentType` param (default `.pvp` for backward compat).
- `InteractiveBattleViewModel` forwards opponentType to `/match/start`.
- `ArenaViewModel` routes `npc_*` opponents through Interactive with `opponentType: .bot`.

**Shipped in follow-up (same day):**

- `/pvp/match/start` accepts `opponent_type = 'dungeon_boss'` with `dungeon_run_id`. Loads `DungeonRun` + boss enemy from `run.state.enemies[0]`, converts via an inline copy of `enemyToCharacterStats` (matches `/api/dungeons/run/[id]/fight` exactly).
- `/pvp/match/start` skips the PvP stamina / free-fight gate when `opponent_type === 'dungeon_boss'`. Dungeons consume their own resource when the run is started.
- `/pvp/match/complete` forks rewards: dungeon_boss uses `floorGoldReward(floor, difficulty)` + `floorXpReward(floor, difficulty)` with Training XP DR (`trainingXpMultiplier(clearsUsedToday)`); advances `DungeonRun.currentFloor` or deletes on completion / defeat; upserts `DungeonProgress`; skips ELO / revenge queue / pvp achievements; routes daily quest + weekly challenge to `dungeons_complete`; loot key `dungeon_<difficulty>` or `boss` on final floor.
- iOS `AppRoute.interactiveBattle` gains optional `dungeonRunId: String?` and `InteractiveOpponentType.dungeonBoss` case. `DungeonRoomViewModel.fight()` routes to `interactiveBattle(.dungeonBoss, dungeonRunId:)` when `interactiveCombatEnabled == true`; classic `service.fight()` path remains as fallback when the flag is off or locally disabled.

**Still deferred:**

- `dungeon_rush` opponent type. DungeonRush uses its own run/session endpoints (`/api/dungeon-rush/fight` + `/resolve`) with different reward/progression semantics than regular dungeons — needs a separate fork.
- Removal of `CombatDetailView` / `CombatViewModel` / `AppRoute.combat` (blocked by `dungeon_rush` + `GuildHallViewModel:593` challenge replay, both of which still use the classic flow).
- `INTERACTIVE_COMBAT_V1` feature-flag removal (kept as a kill-switch until every combat flow ships through Interactive).
- Migration of `HubBannerCards:331`, `DungeonRushViewModel:195`, `ArenaViewModel:261/313` fallback, `GuildHallViewModel:593` challenge replay.

## Why not unify dungeons in the same pass

- Dungeon bosses have scripted abilities (`BOSS_ABILITIES` map per `dungeonId,bossIndex`), phase transitions, and passive-boss variants. None of that exists in `runCombat`/`resolveSingleStrike` shape today.
- Floor progression writes to `DungeonRun.currentFloor`; loot rolls reference `dungeon.slug`; variety rooms (non-combat floors) sit between boss fights. All of that machinery lives in `/api/dungeons/*` today and would need either duplication or a cross-endpoint callback.
- Prod-risk: dungeons are actively grinded for loot and BP progression; a rewrite error would eat progression for real users. Bot fights are a contained, new-player-only flow — much safer first target.

## Side decisions

**VFX pre-wiring (iOS).** `InteractiveStrikeTurn` gained `statusApplied: String?`, `combatLogFrom()` now forwards it instead of hardcoding `nil`, and `CombatFXAssetMap.assetForDamageType` handles `"fire"`. `VFXEffectType` gained `.fireHit/.fireCrit` with fallback SFX mapping to `.hitMagical`. None of these activate until backend combat starts producing `status_applied` or `damageType: "fire"` — the combat engine (`combat.ts`) currently emits only `physical | magical | poison | true_damage` and never fills `status_applied`. The iOS layer is ready; the server layer is not.

**Speed control.** `InteractiveBattleViewModel.speedMultiplier` now mirrors `CombatViewModel.speedMode` (1x/2x). Previously hardcoded `1.0`. Keeps the two combat VMs behaviorally symmetric so the HUD speed toggle can eventually be unified.

## Validation

- Backend typecheck clean on modified routes (`npx tsc --noEmit`; test-file pre-existing errors unchanged).
- Prod deployed as `dpl_J1Vaz3EEejmrzaAWw5aziSzxEyAb`.
- 17 pre-existing drift migrations reconciled via `prisma migrate resolve --applied` + `migrate deploy`. `scripts/check_schema_drift.py` passes.
- Smoke: `POST /api/pvp/match/start {character_id, opponent_id:"npc_…", opponent_type:"bot"}` returns 401 unauth (expected without token) — route exists and doesn't 404 anymore.

## Revert plan

If bot matches misbehave in prod:

1. Flip Vercel env `INTERACTIVE_COMBAT_V1=false` — `/pvp/match/start|strike|complete` all return 404 and iOS falls through to classic `/pvp/prepare+resolve` (which already handles bots via `isNpcBot(opponent_id)`).
2. No DB rollback needed — all new columns are additive/nullable. `PvpMatch` rows created by the bot path stay in place; they just look like ranked matches with `player2_id = NULL`, which is now a valid state.
