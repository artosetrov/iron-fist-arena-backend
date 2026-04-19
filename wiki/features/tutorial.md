# Feature: Tutorial

> Single-file map of every file that touches the tutorial — scripted first-run flow with tooltip overlays, a guided PvE fight, tutorial-specific quests, and a skip path.

## One-liner

New players go through a scripted tutorial: NPC hints → equip an item → scripted first fight → tutorial quests unlock → free-play. Every step is server-tracked so tutorial rewards can't be double-claimed.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Tutorial/TutorialView.swift` — host
  - `Hexbound/Hexbound/Views/Tutorial/TutorialStepCard.swift` — step presentation
  - `Hexbound/Hexbound/Views/Onboarding/TutorialFightView.swift` + `TutorialFightViewModel.swift` — scripted PvE battle
  - `Hexbound/Hexbound/Tutorial/TutorialTooltipView.swift` — NPC-guide tooltip
  - `Hexbound/Hexbound/Views/Components/TutorialOverlayView.swift` — full-screen dim overlay w/ spotlight
  - `Hexbound/Hexbound/Views/Components/TutorialQuestBanner.swift` — quest banner
- **Trigger:** Character creation → automatic
- **Player action:** Follow arrows / tap highlighted elements → Skip (if allowed)

## Backend

### Routes

- `GET  /api/tutorial`                         — `backend/src/app/api/tutorial/route.ts` — state machine: current step, flags, hints to show
- `POST /api/tutorial/step`                    — `backend/src/app/api/tutorial/step/route.ts` — advance `tutorialStep`
- `POST /api/tutorial/skip`                    — `backend/src/app/api/tutorial/skip/route.ts` — set `tutorialSkipped`, grant skip-bundle
- `GET/POST /api/tutorial/quest`               — `backend/src/app/api/tutorial/quest/route.ts` — list / claim tutorial quests
- `POST /api/tutorial/scripted-fight/preload`  — `backend/src/app/api/tutorial/scripted-fight/preload/route.ts` — fetch fixed opponent + script
- `POST /api/tutorial/scripted-fight/resolve`  — `backend/src/app/api/tutorial/scripted-fight/resolve/route.ts` — scripted win, set `tutorialCompleted`
- `POST /api/tutorial/referral`                — `backend/src/app/api/tutorial/referral/route.ts` — bind referral code during tutorial (see [[referral]])

### Business logic

- `backend/src/lib/game/tutorial.ts` — step advancer, skip flow, quest grant
- `backend/src/lib/game/tutorial-opponents.ts` — scripted opponent roster (by class / origin)
- `backend/src/lib/game/tutorial-analytics.ts` — per-step funnel events (for lens/analytics)

### Prisma models touched

- `TutorialQuest` (line 163, `@@map("tutorial_quests")`) — per-character tutorial quest row
- `Character.tutorialStep` (line 435) — int 0=new, 1=equipped, 2=first_fight, 3=completed
- `Character.tutorialSkipped` (line 436) — bool
- `Character.tutorialCompleted` (line 437) — bool (scripted fight victory)
- `Character.tutorialCompletedAt` (line 438) — DateTime

## iOS

### Views + overlay primitives

- `Hexbound/Hexbound/Views/Tutorial/TutorialView.swift`
- `Hexbound/Hexbound/Views/Tutorial/TutorialStepCard.swift`
- `Hexbound/Hexbound/Tutorial/TutorialTooltipView.swift`
- `Hexbound/Hexbound/Views/Components/TutorialOverlayView.swift`
- `Hexbound/Hexbound/Views/Components/TutorialQuestBanner.swift`
- `Hexbound/Hexbound/Views/Onboarding/TutorialFightView.swift`

### ViewModel / Manager

- `Hexbound/Hexbound/Tutorial/TutorialManager.swift` — step progression, hint visibility, highlight target tracking
- `Hexbound/Hexbound/Views/Onboarding/TutorialFightViewModel.swift` — scripted fight state

### Services

- `Hexbound/Hexbound/Services/TutorialService.swift` — tutorial + scripted-fight API wrappers

### Cache

- Tutorial state is derived from `GameDataCache.currentCharacter` (`tutorialStep`, flags) — no dedicated cache bucket

## Admin

- `admin/src/app/(dashboard)/players/` — admin can reset a character's tutorial flags for QA

## Docs

- `docs/02_product_and_features/GAME_SYSTEMS.md` — tutorial overview + funnel
- `docs/06_game_systems/GAME_SYSTEMS.md` — step definitions

## Notable gotchas

- **4-state ladder.** `tutorialStep`: 0 = new, 1 = equipped, 2 = first_fight, 3 = completed. Always advance via `/step` endpoint; never write directly from client.
- **Scripted fight ≠ real PvP.** Uses `/api/tutorial/scripted-fight/*`, NOT `/api/pvp/fight`. Opponent is fixed; result is scripted win. Does NOT count towards PvP stats or ELO.
- **Skip bundle.** `/api/tutorial/skip` grants a starter bundle + flags `tutorialSkipped = true`. Gate this rewards path on server; client should not be able to skip and still unlock tutorial quests.
- **Tutorial quests separate.** `TutorialQuest` ≠ `DailyQuest` — separate table, separate endpoints. Do NOT conflate with [[quests]].
- **Referral bind window.** Referral code can be entered during tutorial (`/api/tutorial/referral`). After tutorial completes, the window closes — see [[referral]] for the full rule.
- **Analytics split.** Tutorial funnel logging lives in `backend/src/lib/game/tutorial-analytics.ts` and currently emits 8 structured JSON events; this is separate from the 7-event provider-agnostic core contract in `backend/src/lib/analytics.ts`.
- **Reset path.** `tutorialCompleted` + `tutorialStep` reset is admin-only. In-game replay of tutorial is NOT supported.

## Tests / fixtures

- `backend/src/__tests__/tutorial/*` (if present)

## Related features

- [[characters]] — Character row holds the state flags
- [[quests]] — tutorial quests are a parallel system
- [[referral]] — referral binding window
- [[pvp-combat]] — scripted fight shares the combat UI shell but runs a scripted resolver
- [[onboarding]] — tutorial kicks in after character creation (onboarding handles name/class/appearance)
