# Feature: PvP Combat

> Single-file map of every file that touches PvP combat — matchmaking, simulation, interactive combat, resolution, rating.

## One-liner

Async PvP where players queue against like-rated opponents, resolve a multi-round combat (either classic auto-resolve or Interactive Combat with active skills), and gain/lose ELO rating plus rewards.

## Status

- **Phase:** In production
- **Last major change:** 2026-04-14 — Fight 404 → classic fallback shipped; UUID id decoding fix; Interactive Combat Phase 3.B shipped 2026-04-13
- **Owner / last hands:** Artem

## Entry points

- **iOS screen(s):**
  - `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift` — opponent carousel + fight CTA
  - `Hexbound/Hexbound/Views/Combat/CombatDetailView.swift` — classic auto-resolve combat
  - `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` — interactive combat (active skills)
- **Navigation route:** `AppRouter.arena` → `AppRouter.combat` → `AppRouter.combatResult`
- **Player action:** Tap Arena building → pick opponent → Fight → combat resolves → result screen

## Backend

### Routes (all under `/api/pvp/`)

- `POST /fight`                 — `backend/src/app/api/pvp/fight/route.ts` — classic auto-resolve combat
- `POST /find-match`            — `backend/src/app/api/pvp/find-match/route.ts` — matchmaking search
- `GET  /history`               — `backend/src/app/api/pvp/history/route.ts` — recent matches for player
- `POST /match/start`           — `backend/src/app/api/pvp/match/start/route.ts` — start interactive match
- `GET  /opponents`             — `backend/src/app/api/pvp/opponents/route.ts` — carousel opponent list
- `POST /prepare`               — `backend/src/app/api/pvp/prepare/route.ts` — pre-fight state lock
- `POST /resolve`               — `backend/src/app/api/pvp/resolve/route.ts` — final match resolution
- `POST /revenge`               — `backend/src/app/api/pvp/revenge/route.ts` — rematch against recent opponent
- `POST /strike`                — `backend/src/app/api/pvp/strike/route.ts` — single round in interactive combat

### Business logic

- `backend/src/lib/game/combat.ts` — classic combat simulator entry
- `backend/src/lib/game/combat-simulator.ts` — round-by-round simulation
- `backend/src/lib/game/combat-loader.ts` — load combat context (stats, actives, passives)
- `backend/src/lib/game/elo.ts` — rating deltas
- `backend/src/lib/game/balance.ts` — combat constants (damage formulas, crit chance, etc.)

### Prisma models touched

- `PvpMatch` (line 562) — match record with rounds, damage log, resolution state
- `PvpBattleTicket` (line 912) — daily ticket gate
- `Character` — rating, pvp_wins, pvp_losses, gear references
- `Item` (equipped slots) — weapon/armor stats

### Balance constants

- Source: `backend/src/lib/game/balance.ts`
- Canonical values: `docs/06_game_systems/BALANCE_CONSTANTS.md`

## iOS

### Views

#### Arena
- `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift` — main arena screen
- `Hexbound/Hexbound/Views/Arena/ArenaCarouselView.swift` — opponent carousel
- `Hexbound/Hexbound/Views/Arena/ArenaOpponentCard.swift` — single opponent card
- `Hexbound/Hexbound/Views/Arena/OpponentCardView.swift` — legacy/alternate variant
- `Hexbound/Hexbound/Views/Arena/ArenaComparisonSheet.swift` — side-by-side stat compare
- `Hexbound/Hexbound/Views/Arena/RankUpCeremonyView.swift` — rank-up moment

#### Combat
- `Hexbound/Hexbound/Views/Combat/CombatDetailView.swift` — classic combat screen
- `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` — interactive combat screen
- `Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift` — post-fight result
- `Hexbound/Hexbound/Views/Combat/BattleSummaryView.swift` — summary card
- `Hexbound/Hexbound/Views/Combat/LootDetailView.swift` — drop reveal
- `Hexbound/Hexbound/Views/Combat/ActiveSkillsHUD.swift` — cooldown HUD for actives
- `Hexbound/Hexbound/Views/Combat/InteractiveCombatComponents.swift` — shared subviews
- `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift` — round log card
- `Hexbound/Hexbound/Views/Combat/CombatLogRow.swift` — row in combat log
- `Hexbound/Hexbound/Views/Combat/LogDivider.swift` — visual separator
- `Hexbound/Hexbound/Views/Combat/YourChoiceButton.swift` — player action button

#### VFX
- `Hexbound/Hexbound/Views/Combat/VFX/CombatVFXOverlay.swift`
- `Hexbound/Hexbound/Views/Combat/VFX/CombatVFXEffect.swift`
- `Hexbound/Hexbound/Views/Combat/VFX/CombatVFXManager.swift`
- `Hexbound/Hexbound/Views/Combat/VFX/CombatFXImageOverlay.swift`
- `Hexbound/Hexbound/Views/Combat/VFX/CombatFXAssetMap.swift`

### ViewModels

- `Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`
- `Hexbound/Hexbound/Views/Combat/CombatViewModel.swift` — classic flow
- `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift` — interactive flow

### Services

- `Hexbound/Hexbound/Services/PvPService.swift` — API wrapper for pvp routes
- `Hexbound/Hexbound/Services/CombatEngine.swift` — client-side combat animation driver (server-authoritative for results)
- `Hexbound/Hexbound/Services/BattlePreloader.swift` — prefetch asset/data before combat screen

### Cache

- `GameDataCache.arenaOpponents` — opponent list prefetched on app init
- `GameDataCache.pvpHistory` — last history response

## Admin

- `admin/src/app/` — PvP match monitoring, rating distribution, player search

## Docs

- `docs/06_game_systems/COMBAT.md` — canonical combat spec (damage, crit, ELO)
- `docs/06_game_systems/BALANCE_CONSTANTS.md` — formula constants
- `docs/03_backend_and_api/API_REFERENCE.md` — route reference
- Interactive Combat phases: see memory `project_interactive_combat_phase1.md`, `project_interactive_combat_phase3_shipped.md`, `project_interactive_combat_phase3b_shipped.md`

## Notable gotchas

- **Server-authoritative only.** Client MUST NOT compute combat results, damage, or ratings. See CLAUDE.md architecture rules.
- **UUID vs Int IDs.** PvpMatch ids are UUIDs — iOS must decode as `String`. Past TS `as number` cast crashed `/match/start` on 2026-04-14. See memory `feedback_uuid_vs_int_ids.md`.
- **Matchmaking widened 2026-03-23**: ±10 level, ±80% gear score, 3-phase cascade fallback. See memory `project_matchmaking_widened.md`.
- **Fight 404 fallback**: client falls back to classic when `/pvp/fight` 404s (shipped 2026-04-14). Memory `project_pvp_fight_routing_shipped.md`.
- **`/pvp/history` now skips snapshot-less rows with no resolved opponent relation.** Old bot/non-PvP residue with `player2Id = null` no longer crashes the whole history response.
- **Interactive `strike` and `match/complete` now explicitly reject missing PvP opponents.** If an Interactive Combat v1 row is incomplete and `player2Id` is absent, both routes now return `409 Player-vs-player opponent missing` instead of falling into nullability/type drift.
- **Prisma migration on `pvp_matches.status`**: must run ALTER TABLE via Supabase MCP before deploy. Past incident 2026-04-13 (Interactive Combat), memory `feedback_migration_mcp_apply_to_prod.md`.
- **Schema field additions without migration** = prod 500s. 2026-04-11 Gold Mine incident pattern applies here too.

## Tests / fixtures

- `backend/src/__tests__/` — combat simulator unit tests
- Seed: admin has opponent seed + rating distribution tools

## Related features

- [[interactive-combat]] — subsystem of PvP, round-by-round active-skill layer
- [[shop]] — consumables used in combat
- [[gold-mine]] — gold source that funds combat prep
