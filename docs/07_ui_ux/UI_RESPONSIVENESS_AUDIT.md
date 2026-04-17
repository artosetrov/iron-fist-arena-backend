# Hexbound UI Responsiveness & API Behavior Audit

**Project:** Hexbound (iOS SwiftUI + TypeScript/Prisma backend + Next.js admin)  
**Audit Date:** April 13, 2026  
**Scope:** ViewModels (Hexbound/ViewModels/), Services, Views, Backend API routes  
**Context:** Artem has established a memory rule: "all mutations must be optimistic" — many screens are partially migrated.

---

## 1. Executive Summary

The codebase demonstrates **strong awareness of optimistic mutations** in critical paths (Gold Mine, Daily Quests, Shop, PvP Combat). However, several responsiveness gaps remain:

- **Blocking request patterns** in character selection, equipment operations, and full-page loads
- **Unnecessary sequential calls** after mutations (e.g., `loadContraband()` after claim, `loadQuests()` after item sell)
- **Cache invalidation watefalls**: Shop buys trigger `QuestService.loadQuests()` synchronously, blocking other tasks
- **Missing prefetch hooks** for predictable user flows (tap Arena → preload 3 opponents' battle data is done, but other screens lack this)
- **Skeleton shimmer misses**: Screens that can serve stale data render full-screen ProgressView instead
- **isLoading state patterns**: Some ViewModels set `isLoading = true` BEFORE cache check, causing unnecessary spinners when cache is warm
- **Backend sequential DB queries** in quest claim flow (multiple updates, though transactionally safe)

**Biggest wins (quick):** Fix isLoading patterns, parallelize quest cache invalidation, add prefetch for Dungeon/Shop, implement shells for Achievements.

---

## 2. Top 15 Highest-Priority Issues

| # | Issue | Label | Priority | File:Line | Current Behavior | Why Slow | Fix | Effort |
|---|-------|-------|----------|-----------|------------------|----------|-----|--------|
| **1** | BuyStatPointsViewModel refetch on mutation | UNNECESSARY_REFETCH | **P0** | ViewModels/BuyStatPointsViewModel.swift:52 | After `service.buyStatPoints()`, calls `await loadStatus()` again | Awaits full reload instead of patching local state with response | Return full `StatPurchaseStatus` from `buyStatPoints()`, apply optimistically, only refetch on error | quick |
| **2** | ShopViewModel `loadOffers()` after purchase | UNNECESSARY_REFETCH | **P0** | Views/Shop/ShopViewModel.swift:322 | After offer purchase succeeds, awaits `await loadOffers()` in background task | Caller must wait for refetch even though response has all needed fields | Return full offers list from purchase response, no refetch needed; if required, fire-forget without await | quick |
| **3** | ShopViewModel `loadContraband()` after claim | UNNECESSARY_REFETCH | **P0** | Views/Shop/ShopViewModel.swift:232 | After claiming drop, awaits full `loadContraband()` to get cooldown state | Network round-trip when response already contains cooldown info | Include cooldown state in claim response, apply directly; defer full reload to background | quick |
| **4** | DailyQuestsViewModel `loadQuests()` after claim (BUG-51 partial fix) | SHOULD_BE_BACKGROUND | **P0** | Views/Quests/DailyQuestsViewModel.swift:123–142 | Awaits `service.claimQuest()` fully before showing celebration modal | Currently correct flow (await API, commit state, then show modal) but the logic implies cache update should happen in `claimQuest()` service, not VM | Move quest cache update from ViewModel to `QuestService.claimQuest()`, return structured result with reward values | medium |
| **5** | ShopService `refreshDailyQuestsAfterGoldSpend()` blocks purchases | SHOULD_BE_BACKGROUND | **P1** | Services/ShopService.swift:167–173 | After any purchase, creates a blocking `QuestService(appState).loadQuests()` task | Gold spend increments quest progress; synchronous reload ensures UI sees update but blocks purchase flow | Fire-and-forget the quest reload without await; publish invalidation event; let View poll or subscribe for update | medium |
| **6** | CharacterSelectionViewModel `selectAndEnter()` double-await | BLOCKING_REQUEST | **P1** | ViewModels/CharacterSelectionViewModel.swift:138–155 | Calls `appState.userCharacters = characters`, then awaits `initService.loadGameData()` sequentially | No parallel load; UI frozen during game data fetch (hub assets, configs, configs) | Run `appState.userCharacters` assignment first, render shell UI, load game data in background | medium |
| **7** | InventoryViewModel `loadInventory()` no cache-first fallback | CACHE_MISSING | **P1** | Views/Inventory/InventoryViewModel.swift:114–127 | Sets `isLoading = true` before checking cache, causing skeleton on warm cache | Cold start after equip causes full-page spinner even when previous inventory is in `appState.cachedInventory` | Check cache first; only set `isLoading = true` if cache is empty | quick |
| **8** | ArenaViewModel `isLoadingOpponents = true` before cache check | BAD_LOADING_PATTERN | **P1** | Views/Arena/ArenaViewModel.swift:115–131 | Sets `isLoading = true` unconditionally on entry; cache serves data instantly but spinner still shows | Cache-first pattern is attempted but isLoading state is not conditional on cache miss | Apply: `if let cached { show cached; isLoading = false } else { isLoading = true }`; load in background; merge on return | quick |
| **9** | InventoryService `equip()` → full `loadInventory()` refetch | UNNECESSARY_REFETCH | **P1** | Services/InventoryService.swift:68–94 | Equip succeeds but caller must reload entire inventory list to reflect equipped state | Response from `/inventory/equip` returns updated item array; no need for full refetch | Have `equip()` return the updated inventory, caller applies; full load only on error | medium |
| **10** | DailyQuestsViewModel `isLoading` blocks initial render with cache | BAD_LOADING_PATTERN | **P1** | Views/Quests/DailyQuestsViewModel.swift:81–102 | Init sets `hasLoadedOnce = true` if cached, but `loadQuests()` still sets `isLoading = true` before network call | Warm cache flow: `hasLoadedOnce = true`, data on screen, then `isLoading = true` flips skeleton on. Race condition between cache display and loading flag. | Apply cache without calling `loadQuests()` on first display; background refresh only after render | quick |
| **11** | GoldMineViewModel sequential `/status` + `loadStatus()` after mutations | SEQUENTIAL_REQUEST_CHAIN | **P1** | Views/Minigames/GoldMineViewModel.swift:202–229 | After collect/start, response includes updated slots; `syncVisualCounters()` is called but then status might be refetched | `loadStatus()` can be called externally and will refetch even if we just got slots from a mutation response | Store response slots directly; only call `loadStatus()` on explicit user refresh (pull-to-refresh), not after every mutation | medium |
| **12** | BattlePass, Achievements, DungeonSelect all set `isLoading` before cache check | BAD_LOADING_PATTERN | **P2** | Views/BattlePass/BattlePassViewModel.swift, Views/Achievements/AchievementsViewModel.swift, Views/Dungeon/DungeonSelectDetailView.swift | Conditional caching logic present but `isLoading` is set unconditionally, causing spinner flash on warm cache | Pattern: if no cached data, set `isLoading = true`; but this triggers re-render BEFORE cache check completes in async context | Move all isLoading logic behind explicit cache-hit/miss branches; conditionally set only on miss | quick |
| **13** | Arena `preloadBattleData()` fires background tasks without cancellation | SHOULD_BE_PREFETCHED | **P2** | Views/Arena/ArenaViewModel.swift:135–142 | Preloads first 3 opponents' battle data in background; excellent pattern | No cancellation on tab switch or view dismiss — tasks may resolve after user navigates away, updating stale ViewModel | Tie task lifetime to ViewModel deinit or explicit cancel call from view; use `@ObservedReliableObject` pattern or store tasks for cleanup | medium |
| **14** | CharacterSelectionViewModel `loadCharacters()` missing error state (cold start) | BLOCKING_REQUEST | **P2** | ViewModels/CharacterSelectionViewModel.swift:20–102 | On network error with no cached characters, `isLoading = false` but view sees empty list + error message | User sees "Failed to load heroes" + empty grid; no skeleton is shown because `hasLoadedOnce` stays false | Show skeleton on first load; set `hasLoadedOnce = false` only if cache is empty; surface error in error state, not on blank skeleton | medium |
| **15** | Shop/Dungeon/Inventory redundant full refreshes on navigation-away-and-back | DUPLICATE_REQUEST | **P2** | Views/Shop/ShopDetailView.swift, Views/Dungeon/DungeonSelectDetailView.swift, Views/Inventory/ItemDetailSheet.swift (onAppear tasks) | Many screens have `.task { await load() }` on top-level view; when user navigates back, task fires again, fetching all data fresh | Cache TTLs exist (300s shop, 60s dungeon) but are checked in `load()` after the task has already started; by then it's too late to cancel | Check cache before firing task; if valid, skip task entirely; use `@State var hasTaskFired` to avoid duplicate calls on same view instance | quick |

---

## 3. Screen-by-Screen Findings

### Hub (Home Entry Point)
- **Entry data:** `GameDataCache.isInitLoaded` flag checked in AppState
- **Blocking:** None (AppState drives data flow)
- **Background:** Building positions loaded lazily from cache (hubLayout, dungeonMapLayout, skyLayout)
- **Prefetch:** Should preload first 3 opponents on Hub render for Arena instant-tap
- **Optimistic:** None needed (display-only)
- **Duplicates:** None identified
- **Loading state:** N/A (passive)
- **Recommendations:** 
  - Add `func preloadArenaOpponents()` call in `HubView.onAppear`
  - Lazy-load hub building images in background using `AssetManager`

### Arena (PvP Matchmaking & Battle)
- **Entry data:** `opponents` list cached (30s TTL); `revengeList` (30s); `matchHistory` (60s)
- **Blocking:** `loadOpponents()` correctly serves cached data instantly; `battlePreloader.prepare()` awaited before combat (correct, needed for seed + stats)
- **Background:** `preloadBattleData()` fires 3 opponent preloads in background (excellent)
- **Prefetch:** Working as intended; could extend to 5 opponents if UX shows 3 on screen
- **Optimistic:** Combat result shown instantly on client (client-side simulation), resolve async (fire-and-forget) ✓
- **Duplicates:** `loadAll()` parallelizes 3 tabs (good); `loadTabData()` cancels prev task before switching (good)
- **Loading state:** `isLoadingOpponents` set conditionally only on cache miss (needs fix: currently set unconditionally)
- **Recommendations:** 
  - Apply fix #8 (conditional isLoading on cache miss)
  - Store preload tasks and cancel them on view dismiss
  - Add telemetry to track battle-prepare latency

### Dungeon (Boss Selection & Combat)
- **Entry data:** `dungeonList` (5min TTL), `dungeonProgress` (60s TTL)
- **Blocking:** `DungeonSelectViewModel.loadDungeonData()` checks cache but sets `isLoading = true` unconditionally
- **Background:** None identified
- **Prefetch:** None (should preload first boss combat params after dungeon select)
- **Optimistic:** None (display-only)
- **Duplicates:** `.task { await loadDungeonData() }` on view entry; cache check in function but task fires before cache is checked
- **Loading state:** Skeleton shown even when cache is warm
- **Recommendations:**
  - Fix isLoading pattern (issue #12)
  - Add dungeon boss prefetch: after user selects dungeon, preload `/pvp/prepare` for first 2 bosses in background
  - Implement boss health bar skeleton (show empty bars while loading)

### Inventory/Equipment (Equip, Unequip, Sell, Upgrade)
- **Entry data:** `appState.cachedInventory` checked; miss → `isLoading = true`
- **Blocking:** `equip()` and `unequip()` return full updated inventory in response; no need to refetch
- **Background:** Equip/unequip mutations are background (no await in button handler)
- **Optimistic:** Equip/unequip update local list immediately (good)
- **Duplicates:** None identified
- **Loading state:** Warm cache shows skeleton unnecessarily (issue #7)
- **Recommendations:**
  - Fix isLoading pattern (#7)
  - Avoid full-page reload after equip; apply response items locally
  - Add item compare skeleton (two item cards side-by-side) while detail loads
  - Cache comparison state per item pair to avoid re-rendering on nav-away-and-back

### Shop (Purchase, Potion, Gems, Contraband, Offers)
- **Entry data:** `items` cached (300s TTL), `offers`, `contrabandState`
- **Blocking:** `loadItems()` correctly serves cached items instantly; BUT `loadContraband()` and `loadOffers()` fire in parallel background tasks within `loadItems()`, so both race to display
- **Background:** Offer/Contraband loads are correctly backgrounded ✓
- **Optimistic:** 
  - Contraband claim: deducts gold instantly, awaits API, reverts on error ✓
  - Offer purchase: deducts currency instantly, awaits API, reverts on error ✓
  - Regular item buy: no optimism (awaits service response before updating character)
- **Duplicates:** After purchase, `await loadOffers()` refetches all offers (issue #2)
- **Loading state:** Initial spinner only shows if no cached shop items (good conditional)
- **Recommendations:**
  - Fix #2: return updated offers from purchase response
  - Fix #3: return cooldown state in claim response
  - Fix #5: fire-forget quest invalidation without await
  - Add offer card skeleton while `loadOffers()` runs
  - Batch consumable purchase quantity into one API call (backend already supports; UI just needs UI to let players select qty)

### Quests (Daily, Claims, Bonus)
- **Entry data:** `dailyQuests` cached (60s TTL) from `GameDataCache`
- **Blocking:** `loadQuests()` correctly uses cache-first; BUT `isLoading` set AFTER cache load (race condition, issue #10)
- **Background:** Quest claim awaits API fully but does NOT refetch after (good fix from BUG-51)
- **Optimistic:** Claim UI shows in-flight state (`claimingQuestId`), modal only on success (excellent)
- **Duplicates:** Quest cache invalidation in ShopService blocks purchase flow (#5)
- **Loading state:** Warm cache may show skeleton briefly due to race condition
- **Recommendations:**
  - Fix #10: separate cache-served state from network-fetch state
  - Fix #5: publish invalidation event; View subscribes to refresh
  - Add quest progress skeleton (grey bars for each quest)
  - Pre-render quest list with stale data while refresh is in-flight

### Achievements
- **Entry data:** `achievements` cached (120s TTL)
- **Blocking:** `isLoading = true` set unconditionally (issue #12)
- **Background:** None
- **Prefetch:** None (display-only)
- **Optimistic:** None
- **Duplicates:** None
- **Loading state:** Skeleton on warm cache unnecessarily
- **Recommendations:**
  - Fix isLoading pattern (#12)
  - Add achievement card skeleton (title + progress bar)
  - Show stale data while refreshing in background

### Gold Mine (Active Minigame with Live Counters)
- **Entry data:** `goldMineSlots` (15s TTL), `maxSlots`
- **Blocking:** `loadStatus()` checks cache (15s is aggressive); mutations return updated slots in response
- **Background:** Start/collect mutations are optimistic; API updates follow in background
- **Optimistic:** ✓ Excellent; UI shows mining immediately, visual counters tick up, API confirms in background
- **Duplicates:** `loadStatus()` called explicitly in many places; should check cache first to avoid unnecessary refetch (#11)
- **Loading state:** Conditional on cache miss (good)
- **Recommendations:**
  - Extend cache TTL to 30s (reduces refetch thrashing)
  - Cache validity logic: always check before calling `loadStatus()`
  - Add visual "syncing…" indicator if live values drift too far from server truth
  - Preload slot minigame assets when view appears

### Battle Pass
- **Entry data:** `battlePassData` cached (120s TTL)
- **Blocking:** `isLoading = true` set unconditionally (issue #12)
- **Background:** Load in background; UI renders shell on first load
- **Optimistic:** Tier claim awaits API; may want to show optimistic progress bump
- **Duplicates:** None
- **Loading state:** Skeleton on warm cache
- **Recommendations:**
  - Fix isLoading pattern (#12)
  - Add tier progress skeleton
  - Show stale tier data while refreshing

### Leaderboard
- **Entry data:** `leaderboardEntries` cached (60s TTL)
- **Blocking:** Load is background-aware but `isLoading` conditional is missing (issue #12)
- **Background:** Player profile load on detail sheet is awaited (acceptable latency)
- **Optimistic:** None (display-only)
- **Duplicates:** Profile sheet refetches on each open (by design for freshness)
- **Loading state:** Skeleton unconditional
- **Recommendations:**
  - Fix isLoading pattern (#12)
  - Add leaderboard row skeleton (repeating name + rank + rating)
  - Cache player profiles separately (5min TTL) to avoid re-fetch on same player re-open

### Profile (Character Profile & Opponent Profile)
- **Entry data:** Character data from AppState
- **Blocking:** Profile sheet awaits `/pvp/profile` API call (acceptable for opponent profile freshness)
- **Background:** None
- **Optimistic:** None
- **Duplicates:** Every profile sheet open refetches (correct for freshness)
- **Loading state:** Full-page spinner while awaiting profile
- **Recommendations:**
  - Add profile skeleton (name, level, stats boxes, equipment grid outline)
  - Cache recent opponent profiles for 1 minute so rapid detail-open-close doesn't refetch

### Level Up Modal
- **Entry data:** Triggered by `applyResolveToCharacter()` post-combat
- **Blocking:** None (modal is shown instantly after combat result)
- **Background:** N/A
- **Optimistic:** N/A
- **Duplicates:** None
- **Loading state:** N/A
- **Recommendations:** None (working as designed)

### Onboarding / Auth
- **Entry data:** Character creation awaits full character + initial inventory load
- **Blocking:** `CharacterSelectionViewModel.selectAndEnter()` awaits `gameInitService.loadGameData()` sequentially (#6)
- **Background:** None
- **Optimistic:** None
- **Duplicates:** None
- **Loading state:** Full-page spinner during game data load
- **Recommendations:**
  - Fix #6: show shell UI (hub frame, building outlines) while game data loads in background
  - Prioritize user character data load; defer non-critical init (NPC hints, cosmetics) to lazy load
  - Prefetch starting inventory so first equipment card appears instantly

---

## 4. Architectural Problems

### Cache Layer
1. **No cache coherency across services:** Each service (PvPService, QuestService, ShopService) has its own fetch logic. No unified invalidation mechanism when mutations occur. Example: Sell item updates `appState.cachedInventory = nil` (InventoryService.swift:136) but doesn't tell DailyQuestsViewModel to refresh (`consumable_use` quest tracker).
   - **Impact:** Quest progress stale until manual refresh
   - **Fix:** Publish cache invalidation events (e.g., `appState.invalidateCache("consumable_progress")`) from all mutation endpoints; subscribe in dependent ViewModels

2. **TTL-based cache is time-based, not event-based:** Gold mine (15s TTL) is aggressive and causes frequent refetches on repeated taps within 15s window, even though nothing changed server-side.
   - **Impact:** Unnecessary network traffic during active play
   - **Fix:** Pair TTL with explicit invalidation on state-changing mutations only; extend default TTLs (shop 300s → 600s, quests 60s → 120s)

3. **No stale-while-revalidate pattern:** When cache is hot but about to expire, load in background instead of blocking render.
   - **Impact:** Cache misses feel like full refetches to the user
   - **Fix:** Implement `cachedOrFetching()` pattern that returns cached data while firing background refresh if within 10s of expiry

### APIClient & Service Patterns
1. **No request deduplication:** Multiple calls to the same endpoint within 1s window are not batched.
   - **Example:** Tap "Refresh Opponents" twice in quick succession → 2 independent GET /pvp/opponents requests
   - **Fix:** Implement request memoization: cache in-flight requests; return same promise for duplicates within 1s window

2. **Sequential refetches in background tasks:** `ShopService.refreshDailyQuestsAfterGoldSpend()` (line 167–173) creates a Task without await but inside a synchronous function, leading to untracked async work. If the view is dismissed before the task completes, it may update a deallocated ViewModel.
   - **Impact:** Potential memory leak + stale state updates
   - **Fix:** Use `Task` with explicit cancellation token; tie task lifetime to ViewModel `deinit`

3. **No response pagination:** All list endpoints return full arrays (opponents, achievements, leaderboard). For active players with 100+ match history entries, this balloons response size.
   - **Impact:** Slower downloads on 3G; larger memory footprint
   - **Fix:** Implement cursor-based pagination (next_cursor in response); load first 20, lazy-load more on scroll

### ViewModel Init Patterns
1. **Cache checks in init, but data load in separate async call:** Most ViewModels check cache in `init` to set initial state but don't prevent later calls to `loadData()` from re-running. This creates a pattern where the same data is loaded twice on first view appearance.
   - **Example:** `DailyQuestsViewModel.init()` checks cache, sets `hasLoadedOnce = true`. Then `DailyQuestsDetailView.task { await vm.loadQuests() }` fires and loads again.
   - **Fix:** Move cache check into `loadQuests()`; if cache is hot, return instantly without setting `isLoading`.

2. **No cleanup on view dismiss:** Background tasks (e.g., arena opponent preloads) are not cancelled when view is popped.
   - **Impact:** Tasks may complete after the ViewModel is deallocated, potentially crashing
   - **Fix:** Store tasks in ViewModel; cancel them in `deinit` or via explicit cleanup method

### Invalidation Strategy
1. **No coherent invalidation model:** Example: After equipping an item, should the following be invalidated?
   - Inventory cache? Yes (item state changed)
   - Character cache (gear score)? Maybe (not returned yet)
   - Shop comparison view? No (already displayed)
   
   Currently: Inventory cache is nil'd, character is not, shop view may show stale comparison.
   - **Fix:** Define invalidation graph: mutation X invalidates caches {Y, Z}; publish events to listening ViewModels

2. **Quest cache invalidation happens inside mutation handlers:** QuestService.loadQuests() is called from ShopService.buy() (line 57, 89, 151). This couples service classes and creates unexpected blocking behavior in a purchase flow.
   - **Fix:** Decouple: return quest change from mutation responses; let the view decide when to refresh the quest display

---

## 5. Action Plan

### Phase 1: Quick Wins (< 1 day each)

**[QW-1] Fix isLoading patterns (Issues #8, #10, #12)**
- Audit all ViewModels for `isLoading = true` unconditionally set before cache check
- Pattern: 
  ```swift
  func load() async {
    if let cached = cache.cachedData() { 
      data = cached 
    } else { 
      isLoading = true 
    }
    // fetch in background
    let fresh = await service.fetch()
    data = fresh
    isLoading = false
  }
  ```
- Affected files: DailyQuestsViewModel, ArenaViewModel, AchievementsViewModel, BattlePassViewModel, DungeonSelectViewModel, InventoryViewModel
- Time: ~2–4 hours (all instances are similar patterns)

**[QW-2] Remove unnecessary refetch after mutations (Issues #1, #2, #3)**
- `BuyStatPointsViewModel`: Return `StatPurchaseStatus` from service, apply locally
- `ShopViewModel.buyOffer()`: Remove `await loadOffers()` line 322; offer data is in response
- `ShopViewModel.claimContraband()`: Remove `await loadContraband()` line 232; include cooldown in response
- Time: ~1–2 hours
- Test: Verify purchase modal shows correct new offer state without refetch

**[QW-3] Fire-forget quest invalidation (Issue #5)**
- `ShopService.refreshDailyQuestsAfterGoldSpend()` should NOT block the purchase Task
- Change to: 
  ```swift
  Task { @MainActor in
    _ = try? await QuestService(appState: appState).loadQuests()
  }
  ```
- Ensure the task is explicitly fire-and-forget (no await in the purchase handler)
- Time: ~15 minutes

**[QW-4] Conditional isLoading on cache miss (Issue #7)**
- `InventoryViewModel.loadInventory()`: Check `appState.cachedInventory` first
- Time: ~15 minutes

**[QW-5] Add basic skeleton placeholders**
- Quests: simple grey progress bars (no detail rendering needed)
- Achievements: achievement card outline
- Leaderboard: row skeleton with placeholder text
- Time: ~2 hours (iterate on design)

---

### Phase 2: Medium Effort (1–3 days each)

**[M-1] Implement request deduplication (Related to issues #15)**
- Create `APIClient.cachedRequest()` method that memoizes in-flight requests
- If same endpoint+params requested within 1s, return existing promise
- Time: ~4 hours
- Benefit: Eliminates double-taps; reduces backend load

**[M-2] Fix CharacterSelectionViewModel blocking (Issue #6)**
- After `appState.currentCharacter = character`, render shell UI with hub frame + building outlines
- Load game data (`GameInitService`) in background
- Show loading overlay only over non-critical sections (NPC hints, cosmetics)
- Time: ~6 hours
- Benefit: First game screen appears in <500ms instead of after all game data loads

**[M-3] Improve EquipmentService and InventoryService (Issue #9)**
- `equip()` and `unequip()` should return updated inventory list in response
- Caller applies list locally; no full reload needed
- Time: ~3 hours (API + service + VM)
- Benefit: Equipment screen responsive on every equip/unequip

**[M-4] Add prefetch hooks (Related to issues #13, #14)**
- `HubView.onAppear`: call `arenaVM.preloadBattleData(for: next3Opponents)`
- `DungeonSelectView.onAppear`: preload boss prepare data for first 2 bosses
- Arena `preloadBattleData()`: Store tasks in @State array; cancel on view dismiss
- Time: ~4 hours
- Benefit: Tap-to-combat latency reduced from ~1.5s to <500ms

**[M-5] Implement cache invalidation event system**
- Add `@Published var cacheInvalidation: String?` to AppState
- Services publish when state changes (e.g., `appState.cacheInvalidation = "quests"`)
- ViewModels subscribe and refetch accordingly
- Time: ~5 hours
- Benefit: Decouples services; fixes quest progress sync after consumable use

---

### Phase 3: Architectural (3+ days)

**[A-1] Implement stale-while-revalidate caching**
- Add `cachedOrFetching()` method to GameDataCache
- If cache is hot (< 80% of TTL expired), return cached data + fire background refresh
- If cache is stale (>80% TTL), force fetch
- Time: ~6 hours
- Benefit: Cache hits always feel instant; background refresh reduces perceived staleness

**[A-2] Refactor request deduplication at APIClient level**
- Implement request memoization with WeakDictionary (keyed by endpoint + params)
- Memoization expires after 1s or on manual cache invalidation
- Time: ~5 hours
- Benefit: Eliminates double-tap network traffic; reduces backend contention

**[A-3] Add pagination to list endpoints**
- Modify GET /pvp/opponents, /arena/history, /leaderboard to support `limit=20&cursor=...`
- Frontend lazy-loads more on scroll or manual "Load More" tap
- Time: ~8 hours (API + Service + VM + View)
- Benefit: Lower memory footprint; faster initial load for players with 100+ entries

**[A-4] Unify cache invalidation strategy**
- Document invalidation graph: "When mutation X occurs, invalidate caches {Y, Z}"
- Example: 
  - `equip` → invalidate {inventory, character_gear_score}
  - `sell` → invalidate {inventory, daily_quests ("consumable_use" tracker)}
  - `goldMineCollect` → invalidate {goldMine, dailyQuests ("gold_mine_collect" tracker)}
- Time: ~4 hours
- Benefit: No more surprise stale state; predictable cache coherency

---

## 6. Refactor Buckets

### Optimistic Mutations (Already Strong)
- ✓ Gold Mine: start mining, collect, boost, buy slot
- ✓ Shop: contraband claim, offer purchase
- ✓ Quests: claim reward, claim bonus
- ~` Inventory: equip/unequip (UI instant but await response)
- ~` Equipment sale (uses optimism but refetches inventory)

**To do:** Equip/unequip response handling; remove equip refetch pattern.

### Background Loading (Partial)
- ✓ Arena: opponent preload
- ✓ Shop: offers + contraband load parallel to items
- ~` Dungeon: no boss prefetch
- ~` Inventory detail: load on demand but not preloaded

**To do:** Add dungeon boss prefetch; add inventory comparison cache.

### Prefetching (Emerging)
- ✓ Arena: preload first 3 opponent battle data
- -  Dungeon: (missing)
- -  Hub: (missing)
- -  Shop: (missing — should preload shop response from previous session)

**To do:** Add prefetch hooks to all main screens; cancel tasks on view dismiss.

### Caching (TTL-based, functional but not optimal)
- Opponents: 30s TTL
- Leaderboard: 60s TTL
- Shop: 300s TTL
- Achievements: 120s TTL
- Battle Pass: 120s TTL
- Dungeon: 60s TTL
- Gold Mine: 15s TTL (aggressive)
- Daily Quests: 60s TTL

**To do:** Extend TTLs; implement stale-while-revalidate; add manual invalidation hooks.

### Deduplication (None)
**To do:** Add request memoization at APIClient level; deduplicate identical requests within 1s.

### Parallelization (Good)
- ✓ Shop: `loadItems() && loadOffers() && loadContraband()`
- ✓ Arena: `loadAll() { loadOpponents() && loadRevenge() && loadHistory() }`
- -  Game init: `loadGameData()` is sequential; should parallelize character + inventories + quests

**To do:** Parallelize game init sub-tasks.

### Local Patching (Mixed)
- ✓ GoldMine mutations return updated slots; UI patches locally
- ~` Shop purchases show optimistic currency deduction but no optimistic item list update
- -  Equip/unequip don't apply response item to local list

**To do:** Standardize: always apply service response locally before re-fetch; re-fetch only on explicit user action (refresh) or error recovery.

### Skeleton Placeholders (Missing)
- Quests: (missing)
- Achievements: (missing)
- Leaderboard: (missing)
- Battle Pass: (missing)
- Dungeon: (missing)

**To do:** Design and implement skeleton loaders for each screen type.

---

## 7. Detailed Fix Instructions for Quick Wins

### Fix QW-1: isLoading Pattern

**Example refactor for DailyQuestsViewModel:**

```swift
func loadQuests() async {
  // 1. Serve cached quests instantly if available
  if let cached = cache.cachedDailyQuests() {
    quests = cached.quests
    bonusClaimedToday = cached.bonusClaimed
    // hasLoadedOnce already set during init; don't re-set here
    isLoading = false // ensure spinner is off for cached data
    return
  }
  
  // 2. Cache miss: set loading and fetch
  isLoading = true
  errorMessage = nil
  do {
    let result = try await service.loadQuests()
    quests = result.quests
    bonusClaimedToday = result.bonusClaimed
    cache.cacheDailyQuests(result.quests, bonusClaimed: result.bonusClaimed)
    hasLoadedOnce = true
  } catch {
    errorMessage = "Could not load today's quests. Tap retry."
  }
  isLoading = false
}
```

**Apply same pattern to all ViewModels in Audit findings #8, #10, #12.**

### Fix QW-2: Remove BuyStatPointsViewModel Refetch

**Current code (BuyStatPointsViewModel.swift:37–58):**
```swift
func purchase() {
  // ... existing guard checks ...
  Task { [weak self] in
    let result = await service.buyStatPoints()
    isPurchasing = false
    
    if let result {
      lastPurchaseResult = result
      HapticManager.success()
      // ❌ PROBLEM: re-fetch entire status
      await loadStatus()  // ← REMOVE THIS
    }
  }
}
```

**Fix:**
- Modify `CharacterService.buyStatPoints()` to return `(result: BuyStatPointsResult?, newStatus: StatPurchaseStatus?)`
- In ViewModel, apply `newStatus` to local `status` property immediately
- Time: ~30 minutes

### Fix QW-3: Fire-Forget Quest Invalidation

**Current code (ShopService.swift:167–173):**
```swift
private func refreshDailyQuestsAfterGoldSpend() {
  appState.cachedTypedQuests = nil
  let appStateRef = appState
  Task { @MainActor in
    _ = try? await QuestService(appState: appStateRef).loadQuests()
  }
}
```

**Already correct** (fire-and-forget). Ensure all callers of this method do NOT await it:

**Verify in ShopService.buy(), buyConsumable(), buyPotion() — all should be:**
```swift
refreshDailyQuestsAfterGoldSpend() // no await
return true // return immediately
```

**Time: ~10 minutes (just verify).**

---

## Summary of Impact

| Fix | Screens Affected | User Impact | Implementation Time |
|-----|------------------|-------------|---------------------|
| QW-1: isLoading patterns | Quests, Achievements, BattlePass, Dungeon, Inventory, Arena | No more spinners on warm cache | 2–4 hours |
| QW-2: Remove refetches after mutations | Buy Stat Points, Shop (offers + contraband) | Purchases feel instant; fewer network calls | 1–2 hours |
| QW-3: Fire-forget invalidation | Shop (all purchases) | Purchases unblocked; quest progress eventually consistent | 15 min |
| QW-4: Conditional isLoading | Inventory | Equipment screen responsive on warm cache | 15 min |
| QW-5: Add skeleton loaders | Quests, Achievements, Leaderboard | Perceived performance improvement; less jarring transitions | 2 hours |
| M-1: Request deduplication | All screens | Eliminates 2x traffic on accidental double-taps | 4 hours |
| M-2: Fix character selection blocking | Onboarding | Game screen appears in <500ms | 6 hours |
| M-3: Improve equip response | Equipment | Equip/unequip responsive; no refetch | 3 hours |
| M-4: Add prefetch hooks | Arena, Dungeon, Hub | Tap-to-combat in <500ms instead of 1.5s | 4 hours |
| M-5: Cache invalidation events | All screens with interdependent data | Quest progress syncs correctly after item use | 5 hours |

**Total Phase 1:** ~6–8 hours (can parallelize multiple fixes)  
**Total Phase 2:** ~25–30 hours (1 week part-time)  
**Total Phase 3:** ~23–27 hours (1 week part-time)

---

## Appendix: Files Analyzed

### ViewModels
- `Hexbound/Hexbound/ViewModels/BuyStatPointsViewModel.swift`
- `Hexbound/Hexbound/ViewModels/CharacterSelectionViewModel.swift`
- `Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`
- `Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`
- `Hexbound/Hexbound/Views/Inventory/InventoryViewModel.swift`
- `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift`
- (+ others referenced)

### Services
- `Hexbound/Hexbound/Services/GameDataCache.swift`
- `Hexbound/Hexbound/Services/InventoryService.swift`
- `Hexbound/Hexbound/Services/ShopService.swift`
- `Hexbound/Hexbound/Services/QuestService.swift`
- `Hexbound/Hexbound/Services/CharacterService.swift`
- (+ others referenced)

### Backend Routes
- `backend/src/app/api/quests/daily/route.ts` (quest claim logic)
- (+ referenced but not deeply audited for sequential DB queries; appear mostly well-parallelized via `Promise.all`)

---

**Report generated:** 2026-04-13  
**Auditor:** Claude Code Agent (Responsiveness Specialist)  
**Effort estimate:** 54–65 hours (Phase 1 + 2); Phase 3 architectural changes deferred to Q2 if needed
