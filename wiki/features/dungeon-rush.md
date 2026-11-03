# Feature: Dungeon Rush

> Single-file map of every file that touches Dungeon Rush — roguelite 12-room endless-attack minigame, distinct from classic Dungeons.


## v2 — "The Descent" (live since 2026-10-17)

The building's route (`AppRoute.dungeonRush`) now opens **The Descent**: three depths of forking passages
(Ossuary → Shadow Warrens → Molten Heart), each ending in a guardian. The bag is at risk — dying or
abandoning loses **half** of it; campfire stashes and escapes keep everything. The v1 files below stay
in the project, unrouted, and the v1 routes ignore descent runs (`dungeonId: { not: 'descent' }`).

- **Design:** project doc `DUNGEON_RUSH_V2_DESIGN_2026-10-16`, prototype artifact "Dungeon Rush Descent" (v6),
  door-light directions canvas "Подсветка двери — варианты". All four ship, one per kind of room
  (`DescentDoorLight`): B eyes in the dark → monster/elite/guardian, D shaft of light → treasure,
  C rune thread → mystery, A aura from within → camp/merchant/unlit passage.
- **Backend:** `backend/src/lib/game/descent/{content,engine,view,server}.ts`;
  routes `POST /api/dungeon-rush/v2/start`, `GET /api/dungeon-rush/v2/state`, `POST /api/dungeon-rush/v2/act`
  (one action per request, checked against the run's `seq`, run row locked, effects in the same transaction).
  State lives in `DungeonRun.state` (`v: 2`, `difficulty 'rush'`, `dungeonId 'descent'`). Tests: `backend/tests/lib/descent-engine.test.ts`.
- **iOS:** `Models/DescentModels.swift`, `Services/DescentService.swift`, `Views/Minigames/Descent*.swift`
  (`DescentDetailView` root → HUD, scene, action panel; `DescentForkScene` door light; `DescentRoomScenes`;
  `DescentRunPanel`; `DescentSheets` map + bag; `DescentViewModel`).
- **Look:** the intro is one key art of all three depths (`rush2-bg-descent-key`, Higgsfield job `c42603d3-cfa4-45fb-ab2d-3c40215f3337`)
  with I–III tier labels and the title on its dark foot; the rules sit in a sheet that opens by itself once
  (`@AppStorage("descent.rulesSeen")`). Every option in a run is a `DescentChoiceRow`: a chamfered iron plate
  (`DescentPlate`) with a bronze medallion (`DescentMedallion`) lit in the room's colour. Buttons are the game's
  own (`.primary` main action, `.secondary` ways out) — the custom plate buttons were dropped on 2026-10-18.
- **Fights look like the arena:** the dice are the arena's `DiceDieView` tiles on its dice table — two lanes,
  your strike vs their guard and theirs vs yours, with `DiceChipView` results — and they tumble while a round is
  in flight (`DescentViewModel.isRollingRound`). Controls in one row: AUTO `.combatToggle`, Strike `.primary`,
  Brace / Potion `.combatControl`; Flee (−8% HP) is a small button on the scene, bottom left (a guardian
  cannot be fled: "No escape" in the duel strip). Hits wash the foe red (as the arena boss), crits light only
  the screen edges in gold.
- **Run screen (2026-11-03, canvas "Descent run screen", variant B):**
  - *HUD* (`DescentHUD`): one row — back · the depth's name with its track of rooms and the guardian's mark
    (the whole title opens the map) · the bag with its risk dot. Under it, out of a fight: HP, the +DMG% /
    CURSED pills and the flask. In a fight, the **duel strip** (`DescentDuelStrip`): your HP and the foe's face
    to face, the foe's kind and name, and one line of traits (`trait.short`, e.g. "Crush every 3rd"; FRENZIED in
    orange once it sets in). Nothing is drawn over the foe's art any more. Torches show on the fork's LIGHT
    button and in the bag, relics in the bag; in a fight the flask is in the action row.
  - *What comes next* — "Crushing blow next round · Brace" — is in the verdict, right above Brace.
  - *Night grade* (`DescentNightGrade.metal`, `.descentNightGrade`, on every `DescentBackdrop`): the pale paper
    and stone go slate-dark, warm saturated bright pixels (fire, lava, torches) keep their colour.
    `DescentStyle.nightExposure` brings each painting to one depth from `DescentGeometry.backdropLuma` (every
    room painting — re-measure if one is regenerated or added). `dim:` is now only extra dark for text over a scene.
  - *Kill stamps* (`DescentBanner`): `rush2-stamp-slain` / `rush2-stamp-guardian-slain`, the word painted in
    (approved exception, `docs/08_prompts/DESCENT_STAMPS_PROMPTS.md`), slammed in with a heavy haptic.
  - *Loot* (`DescentLootSummary`): wherever the panel shows loot — after a fight, the guardian's above the relic
    pick, an opened chest, an event's find — gold and XP are reward cells ("Bag 340 → 520" with the risk dot, the
    XP in the level bar), then the other loot as rows.
  - *Buttons stay on screen*: the room's buttons are a footer pinned under the panel (`DescentRunActions` in
    `DescentPanel`). The panel takes up to 58% of the screen; past that the part above the buttons scrolls and
    fades out at the bottom (a merchant's wares, relic picks, an iPhone SE).
  - *Two-way choices* are two cards side by side (`DescentChoiceCard` in `DescentChoiceCards`: a large medallion,
    the name, what it does under it): a fork of two (LIGHT inside a dark passage's card), an event of two,
    open/inspect a chest. The campfire's three short options are three cards. Longer lists stay rows. A title
    too long for one line is set as two lines of its own (`DescentCardTitle`: at " · ", else at the space that
    halves it best), so each line keeps the whole enamel gradient.
- **Art:** `Assets.xcassets/Descent/rush2-*` (82 imagesets, @1x/@2x/@3x). Door arch boxes in
  `DescentGeometry.archTable` are measured on the exact crop the imagesets keep — re-measure if a fork is regenerated.
- **Economy:** gold `× 0.3 × level × CHA × premium`, XP `× 0.75 × level`; loot is real catalog items picked at drop
  time on the global rarity table (R14.1); 30 stamina per descent.

## One-liner

12-room fixed-layout roguelite run: combat, elite, miniboss, treasure, event, shop rooms — player pushes through a seeded sequence for escalating loot until death.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushStartView.swift` — pre-run loadout / start
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` — main run host
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushRoomView.swift` — per-room interaction
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushGameOver.swift` — run resolution
- **Player action:** Hub → Minigames → Dungeon Rush → Start

## Backend

### Routes

- `POST /api/dungeon-rush/start`      — `backend/src/app/api/dungeon-rush/start/route.ts` — begin run, seed 12-room layout
- `GET  /api/dungeon-rush/status`     — `backend/src/app/api/dungeon-rush/status/route.ts` — current run state
- `POST /api/dungeon-rush/fight`      — `backend/src/app/api/dungeon-rush/fight/route.ts` — resolve combat room
- `POST /api/dungeon-rush/resolve`    — `backend/src/app/api/dungeon-rush/resolve/route.ts` — resolve non-combat room (event/treasure/shop)
- `POST /api/dungeon-rush/shop-buy`   — `backend/src/app/api/dungeon-rush/shop-buy/route.ts` — purchase from in-run shop room
- `POST /api/dungeon-rush/abandon`    — `backend/src/app/api/dungeon-rush/abandon/route.ts` — forfeit run

### Business logic

- `backend/src/lib/game/dungeon-rush.ts` — 12-room fixed layout, room-type logic, seed-driven generation
- `backend/src/lib/game/dungeon.ts` — shared Enemy type + base dungeon helpers
- `backend/src/lib/game/dungeon-run-lock.ts` — concurrent-run lock guard
- `backend/src/lib/game/combat.ts` — shared combat core

### Room layout (from `dungeon-rush.ts`)

Fixed 12-room sequence: `combat, event, combat, treasure, elite, miniboss, shop, combat, event, elite, ...` — exact layout in source.

### Room types

`combat` / `elite` / `miniboss` / `treasure` / `event` / `shop`

### Prisma models touched

- `MinigameSession` (line 695) — reused for Dungeon Rush runs (`gameType = "dungeon_rush"` or similar); holds run state
- May reference `DungeonRun` model indirectly for combat reuse

### Balance constants

- `backend/src/lib/game/balance.ts` → rush-specific drop / encounter tuning

## iOS

### Views

- `Hexbound/Hexbound/Views/Minigames/DungeonRushStartView.swift` — entry gate, stamina cost display
- `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` — run host, room progression
- `Hexbound/Hexbound/Views/Minigames/DungeonRushRoomView.swift` — per-room UI (combat delegates to CombatEngine)
- `Hexbound/Hexbound/Views/Minigames/DungeonRushGameOver.swift` — post-run summary

### ViewModel

- `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift` — run state, current room index

### Services

- Reuses `DungeonService.swift` or dedicated rush endpoints via `APIClient`
- `Hexbound/Hexbound/Services/CombatEngine.swift` — combat animation shared with classic dungeons

### Cache

- `GameDataCache.activeRushRun` — current run if resumable

## Admin

- No dedicated Dungeon Rush admin page today.
- `admin/src/app/(dashboard)/minigame-sessions/page.tsx` — read-only session review surface for recent minigame activity, including rush runs
- Shared tuning lives in the broader dungeon/config/balance surfaces rather than in a rush-specific room-catalog editor

## Docs

- `docs/06_game_systems/COMBAT.md` — combat foundation shared
- Enum `ConsumableTier` values `boss_rush`, `gold_rush` hint at rush-tier rewards

## Notable gotchas

- **Seed stability.** 12-room layout is FIXED; only encounter contents vary by seed. Changing `ROOM_LAYOUT` = breaking change.
- **Concurrent-run guard.** `dungeon-run-lock.ts` prevents starting a new rush while one is active — if lock leaks, players get "already in run" 409.
- **Death = loss.** No continue on death; all in-run loot banks at run end only. Check `resolve` semantics.
- **Shop room in-run.** Distinct from main [[shop]] — uses gold earned during run; unlock via `shop-buy` endpoint.
- **Stamina gated.** Run start consumes stamina; check `DUNGEON_RUSH_STAMINA_COST` in balance.
- **Miniboss reveal ceremony.** `DungeonRushDetailView` watches `currentRoom?.type` and fires `AppState.presentBossReveal(_:)` the first time the miniboss room becomes current in a given run (tracked by `revealedMinibossIdx`). Compact ~1.2s variant of the shared overlay; CTA commits directly to `vm.fight()`. See [[why-boss-reveal-ceremony]].

## Tests / fixtures

- `backend/tests/api/dungeon-rush-resolve.test.ts`
- No dedicated rush start/status/shop-buy backend test file is checked in today

## Related features

- [[dungeons]] — sibling PvE system (longer runs, non-roguelite)
- [[stamina]] — entry cost
- [[inventory]] — loot lands here post-run
- [[minigames]] — rush is hosted under the Minigames section
