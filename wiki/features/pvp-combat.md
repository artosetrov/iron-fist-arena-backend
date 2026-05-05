# Feature: PvP Combat

> Single-file map of every file that touches PvP combat — matchmaking, simulation, interactive combat, resolution, rating.

## One-liner

Async PvP where players queue against like-rated opponents, resolve a multi-round combat (either classic auto-resolve or Interactive Combat with active skills), and gain/lose ELO rating plus rewards.

## Status

- **Phase:** In production
- **Last major change:** 2026-05-03 — Interactive Combat v3.1 shipped its latest client readability pass (optimistic cold-start shell, compact duel header, collapsed verdict summary, plain-English combat labels). 2026-04-29 — `/api/pvp/resolve` now emits absolute `rating_before`/`rating_after` for both PvP and bot fights, and iOS plumbs the pair through `PvpResolveResultPayload` → `ResolveResult` → `CombatResultInfo`; the live interactive summary still keeps the actual rating tile as a bounded follow-up instead of pretending it already renders there. See `block-275-backend-pvp-resolve-rating-bounds-parity`. 2026-04-14 — Fight 404 → classic fallback shipped; UUID id decoding fix; Interactive Combat Phase 3.B shipped 2026-04-13
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
- `POST /resolve`               — `backend/src/app/api/pvp/resolve/route.ts` — final match resolution; emits `rating_change` plus absolute `rating_before` / `rating_after` for both PvP and bot fights (Combat V2 D-1, 2026-04-29)
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

- `admin/src/app/(dashboard)/matches/page.tsx` — PvP match monitoring and rating-delta review
- `admin/src/app/(dashboard)/players/page.tsx` — player search / account review entry point
- `admin/src/app/(dashboard)/players/[id]/page.tsx` — adjacent player drill-down with purchases, bans, and character review
- `admin/src/app/(dashboard)/economy/page.tsx` — adjacent economy review surface with PvP/balance panels

## Docs

- `docs/06_game_systems/COMBAT.md` — canonical combat spec (damage, crit, ELO)
- `docs/06_game_systems/BALANCE_CONSTANTS.md` — formula constants
- `docs/03_backend_and_api/API_REFERENCE.md` — route reference
- `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md` — checked-in interactive-combat rollout/deferred-work plan
- `wiki/features/combat-unification-remaining.md` — current remaining combat unification tails

## Victory Stars (UI flourish)

Stars appear on **two layers** with identical criteria. They are visual — they do not affect rating, rewards, or matchmaking.

### Canonical — `CombatResultDetailView`
`CombatResultDetailView.buildConfig(_:)` derives three labelled `StarCondition` slots from `CombatData.combatLog` on the win path only (guarded by `isWin`).

### Pre-result teaser — `BattleSummaryView`
Interactive Combat's end-of-battle summary screen shows the same three stars above the stats header. Computed from `vm.battleLog` + final attacker HP (`BattleSummaryView.stars`), so the player sees the recap *before* the rewards modal loads. Defeat: survivor star is never lit.

### Criteria
1. **Claim victory** — player wins the match
2. **Stay above 50% HP** — final HP / max HP > 0.5
3. **Land a critical hit** — any player-side crit landed

Summary view: tiles use `BattleVictoryStars` + `BattleStarTile` (in `BattleSummaryView.swift`). Missed tiles render dim with `opacity 0.3` fill + tertiary border. Rationale: [[why-victory-star-conditions]].

## Interactive Combat UX polish (2026-04-19)

Four UX upgrades shipped alongside the existing zone-picker + actives HUD. All client-only — server contract untouched.

- **Round strip** (`InteractiveBattleView.roundStrip`) — `ROUND N · CHOOSE YOUR STRIKE` / `STRIKING…` / `REVEAL` label above the predict panel. `vm.currentRoundNumber = battleLog.count + 1`. Hidden in `.summary` / `.finished` / `.error`.
- **Inline micro-log** (`InteractiveMicroLogView`) — auto-expiring ticker showing the last two strikes (you + enemy) per round. `MicroLogEntry` with `ttl = 2.4s`, visible buffer capped at 3 entries. The view drives fade-out via a 300ms ticker updating a local `now` state — no new `@Observable` property, no VM prod per frame. Colour-coded: gold = crit, blue = block, muted = miss/dodge.
- **Auto-submit** — `vm.pickAttack(_:)` / `vm.pickDefend(_:)` set `attackTouched` / `defendTouched` flags. When both are true, `scheduleAutoSubmitIfReady()` arms a 350ms delayed `submitStrike()`. Changing a zone again cancels and restarts the task so the reflex window always follows the most recent pick. Flags reset on round advance (`revealCompleted()`) and match start (`applyMatchStart`).
- **Long-press own portrait = skip** — 0.5s hold on the player's `DuelFighterCard` → `vm.skipAndSubmit()` + medium haptic. The existing `SKIP` button stays for discoverability; long-press is the shortcut.

### Server-authoritative guard
None of these touch resolution. Crit/block/dodge decisions still come from `/pvp/strike`. The view derives all displayable outcomes from `InteractiveStrikeTurn` flags (`isCrit`, `isDodge`, `isMiss`, `damage == 0`).

## Notable gotchas

- **Server-authoritative only.** Client MUST NOT compute combat results, damage, or ratings. See CLAUDE.md architecture rules.
- **UUID vs Int IDs.** PvpMatch ids are UUIDs — iOS must decode as `String`. A past `as number` assumption around `/match/start` broke this path.
- **Matchmaking widened 2026-03-23.** Live search now uses the broader ±10 level / ±80% gear-score / 3-phase cascade fallback model; don't quietly narrow one axis without rechecking queue health.
- **Fight 404 fallback.** Client still carries a classic fallback when `/pvp/fight` is unavailable; keep that compatibility path in mind when touching Arena routing.
- **`/pvp/history` now skips snapshot-less rows with no resolved opponent relation.** Old bot/non-PvP residue with `player2Id = null` no longer crashes the whole history response.
- **Interactive `strike` and `match/complete` now explicitly reject missing PvP opponents.** If an Interactive Combat v1 row is incomplete and `player2Id` is absent, both routes now return `409 Player-vs-player opponent missing` instead of falling into nullability/type drift.
- **Prisma migration on `pvp_matches.status`.** Must run ALTER TABLE via Supabase MCP before deploy; Interactive Combat already paid this failure tax once.
- **Schema field additions without migration** = prod 500s. 2026-04-11 Gold Mine incident pattern applies here too.
- **Codable memberwise-init blast radius.** Adding any field — even `Int?` — to a `Codable` struct without an explicit `init` breaks every direct constructor across the codebase, since Swift's auto-synthesized memberwise init requires every property to be passed. The 2026-04-29 `CombatResultInfo` rating-bounds addition surfaced two Xcode errors but actually broke 5 `CombatResultInfo` + 4 `ResolveResult` callsites. Always grep all callers when extending such structs (see `block-275-backend-pvp-resolve-rating-bounds-parity`).
- **Interactive summary vs result modal are different surfaces.** The payload already carries `rating_before` / `rating_after`, but `BattleSummaryView` still intentionally omits the rating tile until `prefetchCompleteResult` is wired there cleanly. Do not read the backend payload plumbing as proof that the interactive summary already shows the final rating numbers.

## Tests / fixtures

- `backend/tests/api/pvp-resolve.test.ts`
- `backend/tests/api/pvp-prepare-bot-ticket.test.ts`
- `backend/tests/api/pvp-history.test.ts`
- `backend/tests/api/social-challenges.test.ts` — adjacent challenge/PvP integration coverage
- `backend/tests/lib/bot-ticket.test.ts`
- Seed: admin has opponent seed + rating distribution tools

## Related features

- [[interactive-combat]] — subsystem of PvP, round-by-round active-skill layer
- [[shop]] — consumables used in combat
- [[gold-mine]] — gold source that funds combat prep
