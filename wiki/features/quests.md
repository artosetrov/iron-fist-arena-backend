# Feature: Quests

> Single-file map of every file that touches quests — daily quest rotation with progress, bonuses, claims. Also covers tutorial quests.

## One-liner

Daily-rotated quest set (e.g. "win 3 PvP, clear 2 dungeons") with progress tracking, individual claim, and a bonus reward when all are complete.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screen:** `Hexbound/Hexbound/Views/Quests/DailyQuestsDetailView.swift`
- **iOS components:** Active Quest Banner (2 Figma variants) surfaces in hub header
- **Player action:** Hub → Quest icon → browse → claim individual / claim bonus

## Backend

### Routes

- `GET  /api/quests/daily`          — `backend/src/app/api/quests/daily/route.ts` — today's quest set + progress + claim state
- `POST /api/quests/daily`          — same file — claim a quest by key
- `POST /api/quests/daily/bonus`    — `backend/src/app/api/quests/daily/bonus/route.ts` — claim bonus after all dailies complete

### Business logic

- `backend/src/lib/game/quests.ts` — quest catalog, daily rotation, progress update, claim rules
- Cross-cutting hooks: `/api/pvp/resolve`, `/api/dungeons/*`, `/api/shop/*`, `/api/minigames/*` — fire `updateQuestProgress()` on events

### Prisma models touched

- `DailyQuest` (line 741, `@@map("daily_quests")`) — per-character per-day quest row with progress, target, claimed
- `TutorialQuest` (line 163, `@@map("tutorial_quests")`) — tutorial-specific one-shot quests
- `QuestDefinition` (line 1103, `@@map("quest_definitions")`) — admin-tunable catalog

### Game enums (CLAUDE.md-canonical)

`QuestType`: `pvp_wins`, `dungeons_complete`, `gold_spent`, `item_upgrade`, `consumable_use`, `shell_game_play`, `gold_mine_collect`
(NOT `pvp_win`, NOT `pvp_fight` — canonical list only)

### Balance constants

- `backend/src/lib/game/balance.ts` → daily quest targets + rewards + bonus reward

## iOS

### Views

- `Hexbound/Hexbound/Views/Quests/DailyQuestsDetailView.swift` — quest list screen

### ViewModel

- `Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift` — list state, claim action, bonus-unlock state

### Services

- `Hexbound/Hexbound/Services/QuestService.swift` — list + claim API wrapper

### Cache

- `GameDataCache.dailyQuests` — quest list + progress; invalidated on claim and on quest-triggering events

## Admin

- `admin/src/app/(dashboard)/quests/` — quest definition editor (type, target, reward)

## Docs

- `docs/06_game_systems/GAME_SYSTEMS.md` — quest system overview
- `CLAUDE.md` → Game Enums section (QuestType canonical list)

## Notable gotchas

- **Tracking coverage.** Each `QuestType` must be fired from the event-emitting route. Missing hook = quest stuck at 0/N. Same class of bug as achievements.
- **Enum strictness.** `pvp_win` / `pvp_fight` are NOT valid quest types — only `pvp_wins`. Refactors have repeatedly introduced wrong strings.
- **Daily rotation.** Daily quest set regenerates on server UTC day boundary — `DailyQuest` rows are per-day, not mutated across days.
- **Bonus gate.** Bonus reward only claimable when ALL dailies complete — check `bonus` endpoint guard.
- **Tutorial quests separate.** `TutorialQuest` rows live in their own table and fire from `backend/src/lib/game/tutorial.ts` (see [[tutorial]]).
- **Two catalog sources.** `quests.ts` (code-first) + `QuestDefinition` table (admin-tunable) — keep aligned.
- **Reward surface is the CLAIMED modal, not a toast.** Both the detail-screen claim (`DailyQuestsViewModel`) and the inline banner claim (`ActiveQuestBanner`, `HubBannerCards`) present rewards via `ClaimRewardModalView`. The inline banners set `appState.claimRewardConfig` (root-level overlay in `HexboundApp`); the detail screen sets its own VM-local `claimRewardConfig`. Do NOT replace with `showToast(type: .quest, subtitle: "+Xg +Y XP")` — see [[why-reward-modal-over-toast]].
- **Dungeon-quest navigation routes through Hub.** `dungeons_complete` cards in `DailyQuestsDetailView` must NOT push `AppRoute.dungeonMap` directly — that renders a bare standalone `DungeonMapView` without the hero card / floating HUD / ADVENTURES↔CASTLE button. Instead, set `appState.pendingShowDungeonMap = true` and pop with `appState.mainPath = NavigationPath()`. `HubView.onAppear` consumes the flag and runs `triggerMapTransition(toDungeon: true)` so the player lands on the embedded dungeon map under the full hub HUD, identical to pressing ADVENTURES from the hub. See `Hexbound/CLAUDE.md` → "Hub ↔ Dungeon Map Transition" for the underlying ZStack/`showDungeonMap` pattern.

## Tests / fixtures

- `backend/src/__tests__/quests/*` (if present)

## Related features

- [[tutorial]] — tutorial quests are a separate table under the same umbrella
- [[battle-pass]] — completing dailies also grants BP XP
- [[achievements]] — parallel long-term goal system
- [[daily-login]] — parallel daily-engagement mechanic
- [[pvp-combat]], [[dungeons]], [[shop]] — event sources that fire quest progress
