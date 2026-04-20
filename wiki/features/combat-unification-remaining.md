---
title: Combat Unification — Remaining Work
status: in-flight
last-updated: 2026-04-19
parent: decisions/why-interactive-combat-unification.md
---

# Combat Unification — Remaining Work

Tracks the unfinished slice of migrating every combat flow into `AppRoute.interactiveBattle` + `/pvp/match/{start,strike,complete}`. For scope/rationale/revert plan see `wiki/decisions/why-interactive-combat-unification.md`.

## Done on prod (2026-04-19)

- Prisma migration `20260418_interactive_combat_unified_opponent` applied. `pvp_matches.player2_id` nullable; new columns `opponent_type`, `opponent_snapshot`, `dungeon_run_id`, `boss_key`, `bot_key`.
- 17 pre-existing drift migrations reconciled via `prisma migrate resolve --applied` + `migrate deploy`.
- `/pvp/match/start` — forks on `opponent_type` in `{pvp, bot, dungeon_boss}`. Synthesizes bot stats via `generateBotCombatStats`. Loads dungeon boss via `DungeonRun.state.enemies[0]` + `dungeonEnemyToCharacterStats`. Stores snapshot on `opponent_snapshot`. Skips PvP stamina gate for `dungeon_boss`.
- `/pvp/strike` — reads defender from `opponent_snapshot.combat_stats` when non-PvP; PvP still reloads from characters table.
- `/pvp/match/complete` — forked reward paths: PvP keeps existing ELO + revenge + defender update; bot uses ±K factor (`+30% win / −10% loss`) skips defender + revenge + pvp achievements; dungeon_boss uses `floorGoldReward / floorXpReward` with Training XP DR, advances `DungeonRun.currentFloor` or deletes on completion, upserts `DungeonProgress`, routes quest to `dungeons_complete`, loot key `dungeon_<difficulty>` or `boss`.
- iOS `AppRoute.interactiveBattle(opponentType:dungeonRunId:)` extended; `ArenaViewModel` auto-detects `npc_*` bots; `DungeonRoomViewModel.fight()` routes through Interactive when flag is on. `InteractiveStrikeTurn.statusApplied` + `VFXEffectType.fire{Hit,Crit}` + `CombatFXAssetMap` fire case + `speedMultiplier` in `InteractiveBattleViewModel` pre-wired.

## TODO (explicitly NOT done in the 2026-04-19 session)

### 1. Port dungeon_rush to Interactive

**Why it was skipped:** dungeon_rush has its own state machine that's non-trivial to port — minimal-effort hack would break live runs.

**State to handle** (from `/api/dungeon-rush/fight`):
- `RushState.rooms[]` — 15 rooms, mixed types (combat / miniboss / shop / event / rest / treasure). Non-combat rooms route to `/api/dungeon-rush/resolve` and cannot use Interactive UI.
- `state.currentRoomIndex` advance; run deleted when index reaches `TOTAL_RUSH_ROOMS`.
- `state.currentHpPercent` — HP persists between rooms as a percentage of `maxHp`, not as absolute. Interactive's `/strike` tracks absolute HP per round. Conversion: seed each match with `effectiveHp(maxHp, state.currentHpPercent)`, then at `/complete` compute `hpPercentAfterCombat(finalHp, effectiveMaxHp)` and write back to `state.currentHpPercent`.
- `state.buffs` — `applyRushBuffs(playerStats, state.buffs)` BEFORE combat.
- `state.artifacts[]` — `applyArtifactStatBoosts(playerStats, ownedArtifacts)` BEFORE combat. Also `applyArtifactGoldMult` + `applyArtifactXpMult` on rewards, and `getHealOnKillPercent` to bump `currentHpPercent` on win.
- After miniboss rooms: `generateArtifactChoices(seed, ownedIds)` and surface on `/complete` response so the client can present the picker. Non-trivial UI state.

**Contract changes required:**
- `/pvp/match/start` accept `opponent_type: 'dungeon_rush'` with `dungeon_run_id`. Load rush run (`difficulty: 'rush'`). Validate `currentRoom` is a combat room; reject with the existing `RUSH_ROOM_NON_COMBAT` style error otherwise.
- `/pvp/match/start` — apply `buffs` + `artifacts` BEFORE storing `opponent_snapshot.combat_stats` for the player. Seed player HP from `currentHpPercent`.
- `/pvp/match/complete` — new fork: rewards via `getRoomRewards(index, type)` + artifact mults; advance `rooms[idx].resolved = true`, bump `currentRoomIndex`, delete run on completion; compute + persist new `currentHpPercent`; return `artifactChoices` when room was `miniboss`.
- `/pvp/match/complete` — loot via `rollAndPersistLoot(..., roomRewards.lootDifficulty, ...)` (different difficulty keys than regular dungeon).
- iOS — new `InteractiveOpponentType.dungeonRush`. Route `DungeonRushViewModel:195` through Interactive only for `isCombatRoom(current.type)`. Non-combat rooms stay on `/resolve` + their current UI.
- iOS — post-match, if response includes `artifactChoices`, show artifact picker before navigating back. Today that's a flow inside `DungeonRushView`, needs re-hook.

**Estimated effort:** 3–5 hours focused + testing on dev DB.

**Risk:** medium-high. dungeon_rush is a monetization-adjacent loop (premium players grind it). Bugs in HP%/artifact math reach real users immediately.

### 2. Guild Hall challenge replay

**Call site:** `GuildHallViewModel.swift:593` — appends `AppRoute.combat` after the server already resolved the challenge. The iOS screen is in replay-only mode: server sent a pre-computed `combatLog` and the client animates it without any input.

**Why it doesn't fit Interactive as-is:** `InteractiveBattleViewModel` drives round-by-round server calls (`/strike`). There's no "replay" mode. Piping a pre-resolved log through it would require either (a) a new `InteractiveBattleViewModel.Phase.replay` that reads `combatLog` and plays it back without calling `/strike`, or (b) keeping a replay-only view.

**Options:**
- **A. Replay phase on InteractiveBattleViewModel.** Add `.replay(CombatData)` init path that skips `/match/start` and feeds `combatLog` directly into `animateStrike`. Unifies the UI. Cost: 1–2h + test.
- **B. Keep `CombatDetailView` as replay-only.** Rename/scope it to replay, document that Interactive is the authoritative live combat screen. Cost: trivial, just docs.

**Decision owner:** product. Both work. A is cleaner, B is safer.

### 3. Remove old combat code + flag

**Blocked on:** #1 and #2 above. Do not attempt until both land.

**What to remove** (once unblocked):
- `Hexbound/Views/Combat/CombatDetailView.swift`
- `Hexbound/Views/Combat/CombatViewModel.swift`
- `Hexbound/App/AppRouter.swift` — `case .combat` + destination
- `backend/src/app/api/pvp/strike/route.ts` — `process.env.INTERACTIVE_COMBAT_V1 === 'false'` guard
- `backend/src/app/api/pvp/match/start/route.ts` — same guard
- `backend/src/app/api/pvp/match/complete/route.ts` — same guard
- `backend/src/app/api/pvp/match/match-interactive/*` (if any legacy paths)
- `backend/src/app/api/game/init/route.ts:315` — drop `interactiveCombatEnabled` field from response
- iOS `AppState.interactiveCombatLocallyDisabled` and all call-site checks
- iOS `cache.gameConfig?.interactiveCombatEnabled == true` guards in `ArenaViewModel`, `DungeonRoomViewModel`, etc.
- Vercel env `INTERACTIVE_COMBAT_V1` — delete from all environments

**Verification before removal:**
- `grep -r 'AppRoute.combat' Hexbound/Hexbound` returns zero.
- `grep -r 'INTERACTIVE_COMBAT_V1' backend/src` returns zero.
- Full regression on all combat flows (PvP rated, PvP revenge, bot, dungeon boss, dungeon rush, guild challenge replay).

### 4. Remaining routing call-site migrations

These also still point at `AppRoute.combat` but each has its own caveat:

- `HubBannerCards.swift:331` — context unclear, low traffic. Audit before migrating.
- `ArenaViewModel.swift:261` (classic fight fallback), `:313` (revenge) — only fire when `interactiveCombatEnabled == false`. Safe to delete once the flag goes.
- `DungeonRushViewModel.swift:195` — covered by TODO #1 above.
- `GuildHallViewModel.swift:593` — covered by TODO #2 above.

## Prisma drift (resolved 2026-04-19)

The earlier note about `characters.active_slot_count` drift is no longer current.

- `20260419_character_active_slot_count` is now recorded in Prisma history.
- The shared database referenced by `backend/.env` now has a reconstructed `_prisma_migrations` table with all repo migrations recorded as applied.
- Follow-up schema reconcile aligned `schema.prisma` with the actual legacy Postgres shape (timestamps, named indexes, FK actions, `updated_at` defaults) instead of replaying risky historical SQL.
- Current verification:
  - `backend: npm run db:migrate:status` → `Database schema is up to date!`
  - `backend: npx prisma migrate diff --from-url "$DIRECT_URL" --to-schema-datamodel prisma/schema.prisma --exit-code` → `No difference detected.`
  - `python3 scripts/check_schema_drift.py` → pass

There is no remaining Prisma drift blocker for the combat-unification follow-up work tracked on this page.

## Status toggles / kill switch

`INTERACTIVE_COMBAT_V1` env var on Vercel:
- Unset / any value other than the literal string `'false'` → Interactive flows on (current prod state).
- Set to `'false'` → all `/pvp/match/*` routes return 404 and iOS falls back to classic combat (`/pvp/prepare+resolve`, `/dungeons/run/[id]/fight`). Use this as a kill switch if Interactive breaks before TODO #1 ships.
