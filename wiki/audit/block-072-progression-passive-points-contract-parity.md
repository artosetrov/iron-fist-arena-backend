---
title: Block 072 — progression passive-points contract parity
category: audit
tags: [audit, backend, ios, progression, rewards, passive-tree, contracts]
sources:
  - backend/src/lib/game/progression.ts
  - backend/src/app/api/quests/daily/route.ts
  - backend/src/app/api/quests/daily/bonus/route.ts
  - backend/src/app/api/achievements/claim/route.ts
  - backend/src/app/api/achievements/[key]/claim/route.ts
  - backend/src/app/api/battle-pass/claim/[level]/route.ts
  - backend/src/app/api/shop/offers/route.ts
  - backend/src/app/api/shop/contraband/route.ts
  - backend/src/app/api/mail/[id]/claim/route.ts
  - backend/src/app/api/pvp/fight/route.ts
  - backend/src/app/api/pvp/match/complete/route.ts
  - backend/src/app/api/pvp/resolve/route.ts
  - backend/src/app/api/dungeons/fight/route.ts
  - backend/src/app/api/dungeons/run/[id]/fight/route.ts
  - backend/src/app/api/dungeon-rush/fight/route.ts
  - backend/src/app/api/dungeon-rush/resolve/route.ts
  - Hexbound/Hexbound/App/AppState.swift
  - Hexbound/Hexbound/Views/Components/LevelUpModalView.swift
  - Hexbound/Hexbound/Models/CombatData.swift
  - Hexbound/Hexbound/Services/BattlePreloader.swift
  - Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift
  - Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift
  - Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift
  - Hexbound/Hexbound/Services/AchievementService.swift
  - Hexbound/Hexbound/Services/QuestService.swift
  - Hexbound/Hexbound/Models/BattlePassData.swift
  - Hexbound/Hexbound/Models/MailMessage.swift
  - Hexbound/Hexbound/Models/ShopOffer.swift
  - Hexbound/Hexbound/Models/ContrabandState.swift
  - Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift
  - Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift
  - Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift
  - Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift
  - Hexbound/Hexbound/Views/Shop/ShopViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift
  - Hexbound/Hexbound/Views/Hub/HubBannerCards.swift
  - Hexbound/Hexbound/Views/Components/ActiveQuestBanner.swift
  - Hexbound/Hexbound/Services/TutorialService.swift
updated: 2026-04-15
status: Fixed
---

# Block 072 — progression passive-points contract parity

## Scope

- backend progression response surfaces:
  - `backend/src/app/api/quests/daily/route.ts`
  - `backend/src/app/api/quests/daily/bonus/route.ts`
  - `backend/src/app/api/achievements/claim/route.ts`
  - `backend/src/app/api/achievements/[key]/claim/route.ts`
  - `backend/src/app/api/battle-pass/claim/[level]/route.ts`
  - `backend/src/app/api/shop/offers/route.ts`
  - `backend/src/app/api/shop/contraband/route.ts`
  - `backend/src/app/api/mail/[id]/claim/route.ts`
  - `backend/src/app/api/pvp/fight/route.ts`
  - `backend/src/app/api/pvp/match/complete/route.ts`
  - `backend/src/app/api/pvp/resolve/route.ts`
  - `backend/src/app/api/dungeons/fight/route.ts`
  - `backend/src/app/api/dungeons/run/[id]/fight/route.ts`
  - `backend/src/app/api/dungeon-rush/fight/route.ts`
  - `backend/src/app/api/dungeon-rush/resolve/route.ts`
- iOS progression state and ceremony:
  - `Hexbound/Hexbound/App/AppState.swift`
  - `Hexbound/Hexbound/Views/Components/LevelUpModalView.swift`
  - `Hexbound/Hexbound/Models/CombatData.swift`
  - `Hexbound/Hexbound/Services/BattlePreloader.swift`
  - `Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift`
  - `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`
  - `Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift`
- iOS reward DTO and consumer chain:
  - `Hexbound/Hexbound/Services/AchievementService.swift`
  - `Hexbound/Hexbound/Services/QuestService.swift`
  - `Hexbound/Hexbound/Models/BattlePassData.swift`
  - `Hexbound/Hexbound/Models/MailMessage.swift`
  - `Hexbound/Hexbound/Models/ShopOffer.swift`
  - `Hexbound/Hexbound/Models/ContrabandState.swift`
  - `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift`
  - `Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift`
  - `Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift`
  - `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift`
  - `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift`
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`
  - `Hexbound/Hexbound/Views/Hub/HubBannerCards.swift`
  - `Hexbound/Hexbound/Views/Components/ActiveQuestBanner.swift`
- reference file:
  - `backend/src/lib/game/progression.ts`
  - `Hexbound/Hexbound/Services/TutorialService.swift`

## Why this block

Block 071 deliberately removed passive-point rows from the level-up ceremony because the live contract did not reliably expose them.

That was the right short-term move, but it left a deeper drift unresolved: backend progression already knew how many passive points a level-up awarded, while many player-facing response surfaces quietly dropped that value before it ever reached the iOS client.

This block closes that gap end to end.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[progression]]
- [[passive-tree]]
- [[block-015-claim-progression-achievements-quests-battle-pass]]
- [[block-016-backend-daily-login-battle-pass-reward-contracts]]
- [[block-071-ios-hub-daily-login-and-levelup-contract-cleanup]]

## File notes

### `backend/src/lib/game/progression.ts`

- **Zone:** backend / progression
- **Purpose:** authoritative level-up calculation
- **Why it mattered here:**
  - this file was already computing `passivePointsAwarded`
  - the main drift was not in the calculation itself, but in the response surfaces that failed to expose the result
- **Status:** OK

### Backend reward and resolve routes

- **Zone:** backend / reward and progression response surfaces
- **Files:**
  - `backend/src/app/api/quests/daily/route.ts`
  - `backend/src/app/api/quests/daily/bonus/route.ts`
  - `backend/src/app/api/achievements/claim/route.ts`
  - `backend/src/app/api/achievements/[key]/claim/route.ts`
  - `backend/src/app/api/battle-pass/claim/[level]/route.ts`
  - `backend/src/app/api/shop/offers/route.ts`
  - `backend/src/app/api/shop/contraband/route.ts`
  - `backend/src/app/api/mail/[id]/claim/route.ts`
  - `backend/src/app/api/pvp/fight/route.ts`
  - `backend/src/app/api/pvp/match/complete/route.ts`
  - `backend/src/app/api/pvp/resolve/route.ts`
  - `backend/src/app/api/dungeons/fight/route.ts`
  - `backend/src/app/api/dungeons/run/[id]/fight/route.ts`
  - `backend/src/app/api/dungeon-rush/fight/route.ts`
  - `backend/src/app/api/dungeon-rush/resolve/route.ts`
- **Problems found:**
  - many routes already returned `stat_points_awarded` but silently dropped `passive_points_awarded`
  - this made backend progression only partially authoritative to downstream clients
  - direct PvP, dungeon, mail, shop, and claim flows could level the player up while still hiding part of the reward contract
- **What was fixed:**
  - added `passive_points_awarded` to all touched response surfaces that already expose level-up metadata
  - kept the field aligned with the same `levelUpResult` object used for `new_level` and `stat_points_awarded`
- **What still needs attention:**
  - the response-shape assembly is still duplicated across many routes; a shared progression-response helper would reduce future drift
- **Status:** Fixed

### `Hexbound/Hexbound/App/AppState.swift`

- **Zone:** iOS / app state / progression
- **Purpose:** canonical client-side character sync and level-up modal trigger
- **Problems found:**
  - authoritative reward sync updated level and stat points but not passive-point inventory
  - the level-up modal trigger had no way to receive passive-point awards
- **What was fixed:**
  - added `levelUpPassivePoints`
  - extended `applyAuthoritativeRewardState(...)` with `passivePointsAwarded`
  - authoritative level-up sync now increments `currentCharacter.passivePointsAvailable`
  - level-up modal triggers now carry both stat points and passive points
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Components/LevelUpModalView.swift`

- **Zone:** iOS / progression / ceremony UI
- **Purpose:** level-up celebration modal
- **Problems found:**
  - after Block 071, passive points were intentionally hidden because the active contract could not be trusted
- **What was fixed:**
  - reintroduced passive-point reward rendering only when `appState.levelUpPassivePoints > 0`
  - kept the stamina-refill row removed, because that value is still not part of the authoritative contract
  - updated the animation/reset path so passive points tick up honestly with the rest of the ceremony
- **Status:** Fixed

### Direct combat and dungeon result bridges

- **Zone:** iOS / combat and dungeon result handling
- **Files:**
  - `Hexbound/Hexbound/Models/CombatData.swift`
  - `Hexbound/Hexbound/Services/BattlePreloader.swift`
  - `Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift`
  - `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`
  - `Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift`
- **Problems found:**
  - direct resolve/victory flows could parse `stat_points_awarded` but still drop passive points
  - optimistic character updates after battle/dungeon victories were undercounting the character's real post-level-up state
- **What was fixed:**
  - added `passivePointsAwarded` to the live combat result DTOs
  - parsed `passive_points_awarded` from combat/dungeon responses
  - propagated the value into optimistic character updates and the level-up modal trigger
- **Status:** Fixed

### Reward DTO and consumer chain

- **Zone:** iOS / reward DTOs and reward consumers
- **Files:**
  - `Hexbound/Hexbound/Services/AchievementService.swift`
  - `Hexbound/Hexbound/Services/QuestService.swift`
  - `Hexbound/Hexbound/Models/BattlePassData.swift`
  - `Hexbound/Hexbound/Models/MailMessage.swift`
  - `Hexbound/Hexbound/Models/ShopOffer.swift`
  - `Hexbound/Hexbound/Models/ContrabandState.swift`
  - `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift`
  - `Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift`
  - `Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift`
  - `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift`
  - `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift`
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`
  - `Hexbound/Hexbound/Views/Hub/HubBannerCards.swift`
  - `Hexbound/Hexbound/Views/Components/ActiveQuestBanner.swift`
- **Problems found:**
  - reward DTOs across claim/purchase flows could not decode passive-point awards
  - even when the backend started returning the field, the client would still ignore it
- **What was fixed:**
  - added `passivePointsAwarded` to all touched DTOs
  - threaded the field through existing authoritative reward-sync call sites
  - updated local helper signatures so contraband/shop and other reward flows do not truncate the new field
- **Status:** Fixed

### `Hexbound/Hexbound/Services/TutorialService.swift`

- **Zone:** iOS / tutorial
- **Purpose:** parses tutorial-specific reward and level-up payloads
- **Problems found:**
  - tutorial level-up parsing was also missing passive-point awareness
- **What was fixed:**
  - added `passivePointsAwarded` to the tutorial `LevelUpInfo`
- **What still needs attention:**
  - tutorial still uses a camelCase nested level-up shape while the main API surfaces use snake_case response fields
  - it works, but it remains a contract inconsistency worth normalizing later
- **Status:** Fixed

## Problems found

1. **Backend progression already computed passive points, but major reward routes dropped them**
   - Risk: clients could present only part of the real level-up reward, especially in claim and resolve flows.
   - Fix: exposed `passive_points_awarded` across the touched progression-bearing routes.

2. **Authoritative iOS reward sync updated stat points but not passive-point inventory**
   - Risk: client character state could lag behind the server after level-up, especially before the next full refresh.
   - Fix: extended `AppState.applyAuthoritativeRewardState(...)` and updated all touched reward consumers to pass the new field through.

3. **Direct combat and dungeon victory paths still lost passive-point rewards**
   - Risk: the highest-visibility level-up moments in the app could under-report rewards and mis-state the character's post-battle state.
   - Fix: added passive-point parsing to combat/dungeon result DTOs, optimistic character updates, and modal triggers.

4. **Block 071 removed passive points for honesty, but the ceremony still needed a truthful way to bring them back**
   - Risk: without a real contract pass, the modal would either stay incomplete forever or regress back to hardcoded UI fiction.
   - Fix: restored passive-point display only when a server-backed value exists; stamina refill remains intentionally absent.

5. **Progression response contracts are still not fully uniform**
   - Risk: future route additions can reintroduce the same omission if they hand-roll response shapes again.
   - Fix in this block: repaired the live surfaces.
   - Remaining debt: centralize level-up response serialization and normalize the tutorial sub-contract.

## Verification

- `npm run build` in `backend/`
- `npx vitest run` in `backend/`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `rg -n 'passive_points_awarded|passivePointsAwarded' backend/src/app/api Hexbound/Hexbound -g'*.ts' -g'*.swift'`
- `git diff --check`

## Follow-up

- factor the repeated backend `new_level / stat_points_awarded / passive_points_awarded` response assembly into a shared helper
- normalize tutorial progression payload shape so the project does not have both snake_case and camelCase level-up contracts in parallel
- continue the residual iOS/Hexbound pass from this stronger progression baseline instead of letting these reward fields drift apart again
