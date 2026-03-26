# Hexbound — Instant UX Redesign

**Цель:** Игра должна ощущаться мгновенной. Ни одного пустого экрана. Ни одного мёртвого нажатия.

**Дата:** 2026-03-24
**Статус:** 98 API-вызовов, 22 экрана, 47 VM/Service файлов проаудированы

---

## A. Executive Summary

Hexbound уже в **хорошем состоянии** по кешированию (82% экранов используют cache-first). Но остаются **критические gaps**:

1. **Shop покупки** — кнопка блокируется спиннером на 100-200ms вместо optimistic UI
2. **Daily Login popup** — показывает голый `ProgressView` вместо skeleton
3. **Leaderboard profile sheet** — пустой лоадер при открытии
4. **Dungeon room transitions** — 2-3 секунды без кеша и без prefetch
5. **Нет prefetch при навигации** — тап на здание = cold load целевого экрана
6. **Quest reload каждый визит** — нет кеша для daily quests

**Текущее baseline:**
- 82% экранов: cache-first ✓
- 27% экранов: prefetch ✓
- Optimistic UI: только repair/equip/sell/heal + daily login claim
- Среднее время реакции: **0.1s (cache hit) / 1-3s (cache miss)**

**Цель после redesign:**
- 100% экранов: cache-first или instant placeholder
- 60% экранов: prefetch
- Optimistic UI: все мутирующие действия
- Среднее время реакции: **< 0.1s everywhere**

---

## B. All Blocking UX/API Problems

### CRITICAL (пользователь ждёт > 200ms без feedback)

| # | Экран | Проблема | Ожидание | Что видит игрок |
|---|---|---|---|---|
| B1 | Shop purchase | Кнопка BUY показывает spinner, ждёт API | 100-200ms | Замороженная кнопка |
| B2 | Daily Login popup | `ProgressView()` вместо skeleton при загрузке | 100-150ms | Пустой экран со спиннером |
| B3 | Leaderboard profile | Sheet открывается, но внутри spinner | 150-250ms | Пустой sheet |
| B4 | Dungeon room | Нет кеша между комнатами | 2-3s | Loading overlay |
| B5 | Hub → Building | Нет prefetch при навигации | 1-2s | Skeleton на целевом экране |
| B6 | Daily Quests | Всегда reload с сервера | 1-2s | Skeleton каждый визит |
| B7 | Inbox message claim | `isClaiming = true` блокирует кнопку | 100-150ms | Spinner на кнопке |
| B8 | Quest bonus claim | `isClaimingBonus = true` блокирует | 100-150ms | Spinner на кнопке |
| B9 | BattlePass tier claim | Ожидание API подтверждения | 100-200ms | Нет мгновенной анимации |
| B10 | Auth flow (login) | 300-600ms на auth + character load | 300-600ms | Полная блокировка экрана |

### HIGH (ощутимая задержка, но с visual feedback)

| # | Экран | Проблема | Ожидание |
|---|---|---|---|
| B11 | Arena tab switch | Каждый tab reload (revenge/history) | 150-300ms |
| B12 | Achievement claim | Ожидание API перед show claimed state | 100-150ms |
| B13 | Shell Game bet | Ожидание `/start` перед показом чашек | 100-200ms |
| B14 | Gold Mine collect | Partial optimistic (gold shows, но slot не обновляется мгновенно) | 100ms |
| B15 | Dungeon Rush fight | `isFighting = true` блокирует кнопку | 150-300ms |
| B16 | Character selection | Нет кеша — всегда загрузка с сервера | 100-200ms |

### LOW (уже хорошо, но можно улучшить)

| # | Экран | Текущее состояние |
|---|---|---|
| B17 | Arena opponents | Cache-first ✓ + background preload top 3 |
| B18 | Shop items | Cache-first ✓ + parallel load |
| B19 | Inventory | Cache-first ✓ + optimistic equip/sell |
| B20 | Achievements | Cache-first ✓ + auto-tab selection |

---

## C. Flow-by-Flow Redesign

### C1. Shop Purchase (CRITICAL)

**Текущее:**
```
Tap BUY → buyingItemId = item.id → API call → wait 100-200ms → success → update inventory → toast
```

**Redesign:**
```
Tap BUY → instant: remove item from grid + add to inventory + deduct gold + play SFX + toast
         → background: API call
         → on error: revert item to grid + restore gold + error toast
```

**Техническое решение:**
```swift
func buyItem(_ item: ShopItem) {
    // Optimistic UI
    let previousGold = appState.currentCharacter?.gold ?? 0
    appState.currentCharacter?.gold -= item.price
    items.removeAll { $0.id == item.id }
    appState.showToast("Purchased \(item.name)!", type: .reward)
    SFXManager.shared.play(.uiPurchase)
    HapticManager.success()

    // Background API
    Task {
        let result = await service.buyItem(id: item.id)
        if result == nil {
            // Revert
            appState.currentCharacter?.gold = previousGold
            items.append(item)
            appState.showToast("Purchase failed", type: .error)
        }
    }
}
```

**Паттерн:** Optimistic UI
**Риск:** Двойная покупка при fast double-tap → кнопка disabled после первого tap
**Fallback:** Revert + error toast

---

### C2. Hub → Building Navigation (CRITICAL)

**Текущее:**
```
Tap Building → navigate → .task { load() } → skeleton 1-2s → content
```

**Redesign:**
```
Scroll near building → prefetch target data in background
Tap Building → navigate → instant content from prefetched cache
```

**Техническое решение:**
Добавить в `CityMapView` proximity-based prefetch:
```swift
.onAppear {
    // Prefetch most visited buildings
    Task(priority: .background) {
        async let _ = cache.prefetchArena()
        async let _ = cache.prefetchShop()
        async let _ = cache.prefetchDungeons()
    }
}
```

Или при scroll offset detection — prefetch building при приближении.

**Паттерн:** Background prefetch
**Риск:** Лишний трафик → только для top-5 зданий
**Fallback:** Стандартный cache-first + skeleton

---

### C3. Dungeon Room Transitions (CRITICAL)

**Текущее:**
```
Beat boss → "ENTERING NEXT ROOM" overlay → API call 2-3s → room data → show room
```

**Redesign:**
```
Beat boss → victory animation plays (1-2s) → meanwhile prefetch next room
Navigate to next room → instant content (already loaded)
```

**Техническое решение:**
```swift
// After winning room fight:
func onRoomVictory() {
    showVictoryAnimation()

    // Prefetch next room while animation plays
    Task {
        nextRoomData = await service.getRoomState(dungeonId: dungeon.id, room: currentRoom + 1)
    }
}

// When navigating to next room:
func enterNextRoom() {
    if let data = nextRoomData {
        // Instant — already loaded
        currentRoomData = data
    } else {
        // Fallback — show loading
        isLoading = true
        currentRoomData = await service.getRoomState(...)
    }
}
```

**Паттерн:** Prefetch during animation
**Экономия:** 2-3s → 0s (100% improvement)
**Fallback:** Standard loading overlay

---

### C4. Daily Login Popup (HIGH)

**Текущее:**
```
Auto-show popup → ProgressView() spinner → API 100-150ms → content
```

**Redesign:**
```
Auto-show popup → skeleton calendar grid (7 day cells) → API loads → fill in data
```

**Паттерн:** Skeleton → content
**Альтернатива:** Cache daily login data in `/game/init` response — then popup opens with instant data

---

### C5. Leaderboard Profile Sheet (HIGH)

**Текущее:**
```
Tap player → sheet opens → blank spinner → API 150-250ms → profile
```

**Redesign:**
```
Tap player → sheet opens with KNOWN data (name, level, rating from leaderboard entry)
          → skeleton for unknown data (equipment, stats, HP)
          → API loads → fill in details progressively
```

**Техническое решение:**
```swift
// In LeaderboardPlayerDetailSheet:
var body: some View {
    VStack {
        // Phase 1: Instant from leaderboard data
        playerHeader(name: entry.characterName, level: entry.level, rating: entry.value)

        // Phase 2: Skeleton → real data
        if let profile = fullProfile {
            equipmentGrid(profile.equipment)
            statsSection(profile.stats)
        } else {
            SkeletonEquipmentGrid()
            SkeletonStatsSection()
        }
    }
    .task { fullProfile = await loadProfile(entry.characterId) }
}
```

**Паттерн:** Progressive loading (known data instant → unknown data skeleton → fill)
**Экономия:** Perceived 0ms (header always instant)

---

### C6. Arena Tab Switch (HIGH)

**Текущее:**
```
Tap REVENGE tab → API call → 150-300ms → show revenge list
```

**Redesign (уже частично сделано):**
```
loadAll() now loads all 3 tabs in parallel on entry
Tap REVENGE tab → instant (already loaded)
```

**Дополнение:** Добавить cache-first pattern для revenge/history tabs:
```swift
func loadRevenge() async {
    // Show cache instantly
    if let cached = cache.cachedRevenge() {
        revengeList = cached
    }
    // Refresh in background
    let result = await pvpService.getRevengeList()
    revengeList = result
    cache.cacheRevenge(result)
}
```

Уже реализовано! ✓ Просто проверить что parallel load работает.

---

### C7. Daily Quests (MEDIUM)

**Текущее:**
```
Open quests → always reload from server → skeleton 1-2s
```

**Redesign:**
```
Open quests → show cached quests instantly → refresh in background → update if changed
```

**Добавить в GameDataCache:**
```swift
private var questsData: [DailyQuest]?
private var questsFetchDate: Date?
private let questsTTL: TimeInterval = 300 // 5 min

func cachedQuests() -> [DailyQuest]? {
    guard let date = questsFetchDate, Date().timeIntervalSince(date) < questsTTL else { return nil }
    return questsData
}
```

---

### C8. Inbox Message Claim (MEDIUM)

**Текущее:**
```
Tap CLAIM → isClaiming = true → spinner on button → API → update
```

**Redesign:**
```
Tap CLAIM → instant: show claimed state + reward animation + SFX
         → background: API call
         → on error: revert + error toast
```

**Паттерн:** Optimistic UI (как Daily Login claim)

---

### C9. Achievement Claim (MEDIUM)

**Текущее:**
```
Tap CLAIM → wait for API → show claimed
```

**Redesign:**
```
Tap CLAIM → instant: flip card to "CLAIMED" + gold/gem animation + SFX
         → background: API call
         → on error: revert
```

---

### C10. BattlePass Tier Claim (MEDIUM)

**Текущее:**
```
Tap CLAIM → wait for API → show reward
```

**Redesign:**
```
Tap CLAIM → instant: reveal reward animation + mark as claimed
         → background: API call
         → on error: revert
```

---

## D. Background API Behavior Recommendations

### Принцип: "Fire and Forget with Reconciliation"

Для ВСЕХ мутирующих действий (кроме auth и combat):

```
1. Update local state immediately
2. Show success UI (toast, animation, SFX, haptic)
3. Fire API in detached Task
4. On success: reconcile with server values (gold, XP, items)
5. On failure: revert local state + show error toast
```

### Конкретные рекомендации:

| Действие | Текущее | Рекомендация |
|---|---|---|
| Shop buy (gold) | API → then update | Optimistic UI |
| Shop buy (gems) | Confirm → API → update | Confirm → Optimistic UI |
| Equip item | ✓ Optimistic | Keep |
| Sell item | ✓ Optimistic | Keep |
| Repair item | ✓ Optimistic | Keep |
| Heal (potion) | ✓ Optimistic | Keep |
| Claim quest bonus | API → then update | Optimistic UI |
| Claim achievement | API → then update | Optimistic UI |
| Claim BP tier | API → then update | Optimistic UI |
| Claim inbox | API → then update | Optimistic UI |
| Claim daily login | ✓ Optimistic | Keep |
| Send friend request | API → then update | Optimistic UI |
| Accept challenge | Navigate → API | Keep (combat) |
| Gold mine collect | Partial optimistic | Full optimistic |
| Fortune Wheel spin | ✓ Optimistic gold deduct | Keep |
| Shell Game bet | API → then show | Keep (server-authoritative) |

---

## E. Optimistic UI Opportunities

### Уже реализовано (5 действий):
1. ✅ Equip/Unequip item
2. ✅ Sell item
3. ✅ Repair all items
4. ✅ Heal (potion)
5. ✅ Daily Login claim

### Нужно добавить (8 действий):

| # | Действие | Безопасность | Effort |
|---|---|---|---|
| E1 | Shop buy (gold) | Безопасно — gold проверяется локально | 1h |
| E2 | Achievement claim | Безопасно — claimed status идемпотентен | 30min |
| E3 | BattlePass tier claim | Безопасно — claimed идемпотентен | 30min |
| E4 | Inbox claim | Безопасно — claimed идемпотентен | 30min |
| E5 | Quest bonus claim | Безопасно — bonus идемпотентен | 30min |
| E6 | Gold mine collect | Частично есть, довести до полного | 30min |
| E7 | Send friend request | Безопасно — сервер дедуплицирует | 15min |
| E8 | Send challenge | Безопасно — сервер дедуплицирует | 15min |

**Суммарный effort:** ~4 часа на все 8.

### НЕ подходит для optimistic UI:
- Combat (серверная авторитативность)
- Shell Game / Fortune Wheel results (серверный RNG)
- Rating changes (серверный ELO)
- Login / Auth
- Character creation

---

## F. Caching and Prefetch Strategy

### Cache Layers

```
Layer 1: In-memory (GameDataCache)
├── opponents (30s TTL)
├── leaderboard (60s TTL)
├── shop (300s TTL)
├── achievements (120s TTL)
├── battlePass (120s TTL)
├── dungeonProgress (60s TTL)
├── goldMine (15s TTL)
├── revenge (30s TTL)
├── history (60s TTL)
└── socialStatus (120s TTL)

Layer 2: AppState (session lifetime)
├── currentCharacter
├── cachedInventory
├── cachedQuests
├── dailyLoginCanClaim
└── combatData / combatResult

Layer 3: UserDefaults (disk, persists)
├── hubLayout
├── dungeonLayout
└── skyLayout
```

### Новые кеши (добавить):

| Данные | TTL | Где | Зачем |
|---|---|---|---|
| Daily quests | 300s | GameDataCache | Мгновенный показ квестов |
| Character list | 600s | GameDataCache | Мгновенный character selection |
| Leaderboard search (last 5) | 60s | LeaderboardVM | Не повторять одинаковые поиски |
| Dungeon next room | until used | DungeonRoomVM | Instant room transition |
| Opponent profiles | 120s | GameDataCache | Instant profile sheet |

### Prefetch Strategy

**При запуске:**
```
/game/init → заполняет все кеши одним вызовом ✓ (уже есть)
```

**При входе на Hub:**
```
Prefetch: arena opponents + shop items + daily quests (3 parallel calls)
```

**При входе на Arena:**
```
Prefetch: top 3 opponent /pvp/prepare ✓ (уже есть)
Новое: все 3 таба параллельно ✓ (только что добавлено)
```

**При победе в dungeon room:**
```
Prefetch: следующая комната во время victory animation
```

**При открытии leaderboard:**
```
Prefetch: top 5 opponent profiles в фоне
```

---

## G. Animation Strategy to Hide Latency

### Принцип: "Анимация = бесплатное время"

| Ситуация | Анимация | Скрытое время |
|---|---|---|
| Tap building | NavigationStack push (350ms) | 350ms для загрузки |
| Buy item | Gold counter tick-down + item shrink | 200ms для API |
| Claim reward | Coin burst particle + gold flash | 300ms для API |
| Win combat | Victory screen + loot reveal sequence | 2-3s для resolve |
| Dungeon room clear | Victory animation + XP popup | 1-2s для prefetch next room |
| Achievement unlocked | Badge flip animation | 200ms для API |
| Level up | Full-screen modal with effects | 1-2s для server update |

### Правило: Любое действие с API должно иметь анимацию ≥ длительности API call

```
API call ~150ms → анимация ≥ 200ms → пользователь никогда не ждёт
```

---

## H. Failure and Rollback Handling

### Паттерн для каждого optimistic action:

```swift
// 1. Save rollback state
let snapshot = currentState.copy()

// 2. Optimistic update
applyOptimisticUpdate()
showSuccessFeedback()

// 3. Background API
Task {
    let result = await apiCall()
    if result == nil {
        // 4. Rollback
        restoreState(from: snapshot)
        showErrorToast("Action failed. Please try again.", actionLabel: "Retry") {
            Task { await retryAction() }
        }
    } else {
        // 5. Reconcile with server truth
        reconcileWithServerData(result)
    }
}
```

### Конкретные rollback сценарии:

| Действие | Rollback | Reconciliation |
|---|---|---|
| Shop buy | Restore gold + re-add item to shop | Update gold from server response |
| Achievement claim | Unmark as claimed | Server wins — if already claimed, keep |
| Friend request | Remove "Pending" state | Server confirms or rejects |
| Inbox claim | Unmark as claimed | Server wins |
| Gold mine collect | Revert slot to "ready" | Update gold from server |

### Edge Cases:

1. **Offline** → Queue action, retry when online, show "Pending sync" badge
2. **Double tap** → Disable button on first tap (already done for most)
3. **Stale cache + optimistic** → Server may reject (e.g. item already sold) → full revert
4. **Concurrent mutations** → Use latest server state for reconciliation, not local delta

---

## I. Priority Implementation Roadmap

### Week 1: Instant Actions (8h total)

| # | Task | Effort | Impact |
|---|---|---|---|
| I1 | Optimistic shop purchase (gold items) | 1.5h | 🔴 HIGH |
| I2 | Optimistic achievement claim | 30min | 🔴 HIGH |
| I3 | Optimistic battle pass claim | 30min | 🔴 HIGH |
| I4 | Optimistic inbox claim | 30min | 🟡 MEDIUM |
| I5 | Optimistic quest bonus claim | 30min | 🟡 MEDIUM |
| I6 | Daily login popup skeleton | 1h | 🟡 MEDIUM |
| I7 | Leaderboard profile progressive loading | 1.5h | 🟡 MEDIUM |
| I8 | Daily quests cache-first | 1h | 🟡 MEDIUM |

### Week 2: Prefetch & Navigation (6h total)

| # | Task | Effort | Impact |
|---|---|---|---|
| I9 | Hub building prefetch (top 5) | 2h | 🔴 HIGH |
| I10 | Dungeon room prefetch on victory | 2h | 🔴 HIGH |
| I11 | Leaderboard top-5 profile prefetch | 1h | 🟡 MEDIUM |
| I12 | Character list cache | 30min | 🟢 LOW |
| I13 | Leaderboard search cache | 30min | 🟢 LOW |

### Week 3: Polish & Edge Cases (4h total)

| # | Task | Effort | Impact |
|---|---|---|---|
| I14 | Full optimistic gold mine collect | 30min | 🟢 LOW |
| I15 | Optimistic friend request/challenge send | 30min | 🟢 LOW |
| I16 | Quest auto-invalidation on progress | 1h | 🟢 LOW |
| I17 | Stale-while-revalidate for all screens | 2h | 🟡 MEDIUM |

---

## J. Exact Developer Tasks

### J1. Optimistic Shop Purchase

**File:** `ShopViewModel.swift`

```swift
// In buyItem() or buyOffer():
// BEFORE: await service.buy() → then update UI
// AFTER:

func buyItem(_ item: ShopItem) {
    guard let char = appState.currentCharacter else { return }
    guard char.gold >= item.price else { return }

    // 1. Snapshot for rollback
    let previousGold = char.gold
    let removedItem = item

    // 2. Optimistic update
    appState.currentCharacter?.gold -= item.price
    items.removeAll { $0.id == item.id }
    SFXManager.shared.play(.uiPurchase)
    HapticManager.success()
    appState.showToast("Purchased \(item.name)!", type: .reward)

    // 3. Background API
    Task {
        let result = await service.buyItem(id: item.id)
        if let data = result {
            // Reconcile with server gold
            appState.currentCharacter?.gold = data.gold
            appState.invalidateCache("inventory")
        } else {
            // Rollback
            appState.currentCharacter?.gold = previousGold
            items.append(removedItem)
            items.sort { $0.name < $1.name }
            appState.showToast("Purchase failed", subtitle: "Gold restored", type: .error)
        }
    }
}
```

### J2. Optimistic Achievement Claim

**File:** `AchievementsViewModel.swift`

```swift
func claimAchievement(_ achievement: Achievement) {
    // Optimistic
    if let idx = achievements.firstIndex(where: { $0.id == achievement.id }) {
        achievements[idx].claimed = true
    }
    SFXManager.shared.play(.uiRewardClaim)
    HapticManager.success()
    appState.showToast("Achievement claimed!", type: .achievement)

    // Background
    Task {
        let result = await service.claimAchievement(id: achievement.id)
        if result == nil {
            if let idx = achievements.firstIndex(where: { $0.id == achievement.id }) {
                achievements[idx].claimed = false
            }
            appState.showToast("Claim failed", type: .error)
        } else {
            // Reconcile rewards
            if let char = result?.character {
                appState.currentCharacter?.gold = char.gold
                appState.currentCharacter?.gems = char.gems
            }
        }
    }
}
```

### J3. Hub Building Prefetch

**File:** `HubView.swift` или `CityMapView.swift`

```swift
// Add to HubView .task:
.task {
    // Prefetch most-visited screens
    Task(priority: .background) {
        // These calls populate GameDataCache silently
        let arenaService = PvPService(appState: appState)
        let shopService = ShopService(appState: appState)

        async let _ = arenaService.getOpponents() // fills cache.opponents
        async let _ = shopService.getItems()       // fills cache.shop
    }
}
```

### J4. Dungeon Room Prefetch

**File:** `DungeonRoomViewModel.swift`

```swift
// After room victory:
@State private var prefetchedNextRoom: DungeonRoomState?

func onVictory() {
    showVictoryAnimation = true

    // Prefetch next room during animation
    Task {
        prefetchedNextRoom = await service.getRoomState(
            dungeonId: dungeon.id,
            room: currentRoom + 1
        )
    }
}

func proceedToNextRoom() {
    if let next = prefetchedNextRoom {
        currentRoomData = next
        prefetchedNextRoom = nil
    } else {
        isLoading = true
        Task { currentRoomData = await service.getRoomState(...) }
    }
}
```

### J5. Leaderboard Progressive Profile

**File:** `LeaderboardPlayerDetailSheet.swift`

```swift
// Phase 1: Show known data from leaderboard entry immediately
// Phase 2: Load full profile in background

var body: some View {
    ScrollView {
        // Instant — from leaderboard entry
        HStack {
            AvatarImageView(skinKey: entry.avatar ?? "", ...)
            VStack {
                Text(entry.characterName)
                Text("Level \(entry.level ?? 0)")
            }
        }

        // Progressive — loads from API
        if let profile = fullProfile {
            equipmentGrid(profile)
            statsSection(profile)
        } else {
            // Skeleton
            SkeletonEquipmentGrid()
            SkeletonStatsGrid()
        }
    }
}
```

### J6. Daily Quests Cache

**File:** `DailyQuestsViewModel.swift`

```swift
func loadQuests() async {
    // Cache-first
    if let cached = cache.cachedQuests() {
        quests = cached
        updateProgress()
    } else {
        isLoading = true
    }

    // Background refresh
    let fresh = await service.loadQuests()
    if let fresh {
        quests = fresh
        cache.cacheQuests(fresh)
    }
    isLoading = false
}
```

---

## Appendix: Current vs Target State

| Метрика | Текущее | Цель |
|---|---|---|
| Cache-first screens | 82% (18/22) | 100% |
| Prefetch screens | 27% (6/22) | 60% |
| Optimistic UI actions | 5/13 | 13/13 |
| Max perceived wait (cache hit) | 0.1s | 0.05s |
| Max perceived wait (cache miss) | 1-3s | 0.3s |
| Screens with spinners | 3 | 0 |
| Dead click points | 2 | 0 |
| Dungeon room transition | 2-3s | 0s |

**Суммарный effort на все задачи: ~18 часов**
**Ожидаемый результат: perceived load time -60-80%**
