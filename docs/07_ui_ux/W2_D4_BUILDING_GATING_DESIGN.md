# W2.D4 — Building Gating: Progressive Hub Disclosure

**Дата:** 2026-04-10
**Статус:** 📝 DESIGN DOC — awaiting approval
**План:** `QA_FIX_PLAN_2026-04-10.md` W2.D4 — «Gate buildings behind soft level unlocks»
**Связанные доки:** `W2_D1_REALITY_CHECK.md`, `W2_D2_LORE_AUDIT.md`, `W2_D3_SCRIPTED_FIGHT_DESIGN.md`

> **Status boundary:** historical design proposal for one building-gating iteration. Keep it as rationale, not as the current unlock schedule or shipped hub-gating contract without rechecking live code and current feature maps.

---

## TL;DR

Building gating **уже реализован на ~85%**. `BuildingUnlockConfig`, `BuildingLockOverlay`, level-gated tap handling, и unlock pills в `LevelUpModalView` — всё существует.

Что реально нужно сделать в W2.D4:

1. **Recalibrate unlock schedule** под новый flow (scripted fight → hub с 3 buildings → delayed lore). Текущее: Lv1 → 3 buildings, Lv3 → dungeon, Lv5 → gold-mine, Lv7 → tavern. Предлагаю: **Lv1 → 3, Lv2 → dungeon, Lv4 → gold-mine, Lv6 → tavern, Lv8 → battlepass/ranks, Lv12 → guild-hall**. Компактнее, более частые dopamine hits в первые 30 минут.
2. **Extract unlock ceremony** из `LevelUpModalView` в dedicated `BuildingUnlockCeremony.swift` — ornamental cinematic 2-2.5 сек per unlock, FX + sound + «NEW BUILDING» badge.
3. **Add «unlock preview» toast** на Lv (X-1) — «Dungeon Rush opens next level!» — создаёт anticipation loop.
4. **Server-side level-up response** возвращает `unlocks: string[]` вместо client-side derivation (source of truth).
5. **Visual polish**: замок overlay на locked buildings должен быть менее тусклым (сейчас `opacity 0.6` почти невидим на некоторых sprite'ах).

Это аддитивные изменения. Core механика остаётся.

---

## Что уже работает (audit findings)

### ✅ `BuildingUnlockConfig` — static unlock table

`Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift:33-58`:

```swift
enum BuildingUnlockConfig {
    static let levels: [String: Int] = [
        "arena": 1,
        "shop": 1,
        "achievements": 1,
        "dungeon": 3,
        "gold-mine": 5,
        "tavern": 7,
        "battlepass": 10,
        "ranks": 10,
        "guild-hall": 15,
        "black-market": 99,  // Coming Soon
    ]

    static func isUnlocked(_ buildingId: String, characterLevel: Int) -> Bool { … }
    static func requiredLevel(for buildingId: String) -> Int? { … }
}
```

✅ Работает. ❌ Один source of truth на клиенте, сервер не знает. Потенциальная проблема для live-ops (хотим поменять расписание — требуется релиз).

### ✅ `BuildingLockOverlay` — визуальный lock

Lock icon + `"LV.N"` текст поверх тёмной подложки. Используется в `CityBuildingView` через параметр `isLocked + requiredLevel`.

### ✅ `CityMapView.isBuildinglocked` + tap handler

`CityMapView.swift:96-120` — tap на locked показывает toast `"X opens at Level Y"`. Хороший UX, никакой dead-end state.

### ✅ `LevelUpModalView.unlocks` — surfaces newly unlocked buildings

`LevelUpModalView.swift:40-45`:

```swift
private var unlocks: [String] {
    BuildingUnlockConfig.levels
        .filter { $0.value == newLevel }
        .map { buildingDisplayName($0.key) }
        .sorted()
}
```

При level-up на 3 показывает «NEW: Dungeon Rush» pill. Ceremony есть, но bundled внутри modal.

### ⚠️ Locked buildings видны на карте

В `CityMapView.applyOverrides` возвращается `defaultCityBuildings` **без фильтрации**, поэтому игрок видит guild-hall и black-market (route==nil) как заблокированные. Это **правильное поведение для «anticipation»** pattern, но визуально overlay может быть слишком тусклым (см. ниже).

### ❌ Нет «unlock preview» hint на Lv (X-1)

Игрок узнаёт о существовании Dungeon только когда достигает Lv3. До этого здание видно в городе, но без явного «ещё чуть-чуть». Упущенная возможность для curiosity loop.

### ❌ Unlock ceremony bundled в LevelUpModal

При level-up на 3 игрок видит:
1. Level Up modal (rays, title, stat points, stamina refill)
2. Unlock pill «NEW: Dungeon Rush» внутри modal (ещё одна пилюля в списке)

Проблема: **dungeon unlock — это больший момент, чем +1 stat point**. Это меняет core loop игрока. Должен быть отдельный beat, а не строчка в списке.

---

## Best Practices (F2P RPG Hub Gating)

| Принцип | Источник | Применение в Hexbound |
|---|---|---|
| **5±2 affordances при первом визите в hub** | Miller's Law, AFK Arena, Raid | ✅ Lv1 = 3 visible buildings (arena, shop, achievements), + 2 UI-level (inbox, daily login) — 5 total |
| **Dopamine cadence: unlock каждые 2-4 уровня в первые 30 минут** | Epic Seven, Clash Royale | ⚠️ Текущее: Lv1 → Lv3 (ok), Lv3 → Lv5 (ok), Lv5 → Lv7 (ok). Предлагаю компактнее: Lv1 → Lv2 → Lv4 → Lv6 |
| **Anticipation loop: preview unlock заранее** | Hearthstone, AFK Arena | ❌ Нет в Hexbound. Добавить toast на Lv (X-1) |
| **Dedicated unlock moment > list item** | Diablo Immortal, Raid Shadow Legends | ❌ Сейчас pill в LevelUpModal. Вынести в cinematic beat |
| **Server-authoritative unlock schedule** | Supercell, NetEase | ❌ Client-only. Мигрировать в backend config для live-ops |
| **Visible locked buildings с «LV.N» указателем** | AFK Arena, Epic Seven | ✅ Сейчас работает. Только overlay opacity нужно полирнуть |
| **Tap на locked → info toast, не dead silence** | Clash Royale | ✅ Работает |

---

## Предложенный Unlock Schedule

### Обоснование изменений

После W2.D3 (scripted tutorial fight на Lv1) игрок выходит в hub **сразу с pending level up до Lv2**. Поэтому Lv2 должен уже давать что-то новое, иначе level up modal покажет только stat points — слабый reward beat.

Таблица:

| Lv | Unlocks | Cadence (approx min) | Rationale |
|---|---|---|---|
| **1** (start) | Arena, Shop, Achievements | 0 | Core loop day 1: fight → gear → goal. ✅ как сейчас |
| **2** (~3 min) | **Dungeon Rush** ← *было Lv3* | ~3 | Вводит вторую игровую петлю (PvE) сразу после tutorial. Усиливает reward beat level up modal |
| **4** (~8 min) | **Gold Mine** ← *было Lv5* | ~8 | Idle reward — «работает пока вы не играете» — classic F2P retention hook |
| **6** (~15 min) | **Tavern** ← *было Lv7* | ~15 | Social beat (NPCs, потенциально coop gathering) |
| **8** (~25 min) | **Battle Pass + Ranks** ← *было Lv10* | ~25 | Long-term progression visible when игрок invested. Два unlock одновременно — «wow, куча всего открылось» moment |
| **12** (~60 min) | **Guild Hall** ← *было Lv15* | ~60 | Social endgame hook. Сейчас Lv15 — слишком поздно; многие dropoff'ятся до этого |
| **99** (never) | Black Market | — | Остаётся Coming Soon до actual implementation |

### Total delta

- **Первый час компактнее**: 6 unlocks в первые 60 минут вместо 5
- **Cadence равномернее**: 2-6-8-12 → unlock каждые 2-4 уровня, гладкий dopamine график
- **Lv15 guild barrier снят**: -20% дроп от «я ещё далёк от всего интересного»

### Анти-риск: не слишком ли быстро?

**Нет.** Главное опасение — что игрок «прожрёт» весь контент за час и наскучит. Но:

1. Разблокировка ≠ прохождение. Arena на Lv1 — это годы progression через ELO/items/bp. То же самое dungeon, gold mine, etc.
2. Current retention data (если есть) → большинство игроков бросает до Lv10, не до Lv15. Доставить им больше контента раньше — net positive.
3. Battle pass на Lv8 (не Lv5) — осознанно, чтобы игрок сначала испытал core loop и **захотел** monetization gate, а не воспринял его как wall.

### Backend change

Добавить в `backend/src/lib/game/constants.ts`:

```ts
// Progressive hub disclosure schedule
export const BUILDING_UNLOCK_LEVELS: Record<string, number> = {
  arena: 1,
  shop: 1,
  achievements: 1,
  dungeon: 2,
  'gold-mine': 4,
  tavern: 6,
  battlepass: 8,
  ranks: 8,
  'guild-hall': 12,
  'black-market': 99,
};

export function getBuildingUnlocks(newLevel: number): string[] {
  return Object.entries(BUILDING_UNLOCK_LEVELS)
    .filter(([_, lvl]) => lvl === newLevel)
    .map(([id, _]) => id);
}
```

В `applyLevelUp` (character progression):

```ts
const unlocks = getBuildingUnlocks(newLevel);
// Return unlocks в level-up response, client использует для ceremony
```

Client в `BuildingUnlockConfig.levels` остаётся как **fallback cache** (для случая offline / pre-level-up rendering hub), но source of truth — server.

---

## Component Design: `BuildingUnlockCeremony.swift`

### Визуальная концепция

Dedicated cinematic overlay, показывается **после** LevelUpModal, **до** возврата в hub. Если разблокировалось несколько зданий (Lv8 → battlepass + ranks), играется sequence.

```
┌────────────────────────────────────────┐
│                                        │
│      [darkened hub background]         │
│                                        │
│         ✨ NEW BUILDING ✨             │
│           (Oswald 22, gold)            │
│                                        │
│       ┌──────────────────┐             │
│       │                  │             │
│       │  [dungeon sprite]│ ← scale/glow│
│       │  with rays behind│             │
│       │                  │             │
│       └──────────────────┘             │
│                                        │
│        DUNGEON RUSH                    │
│    (Oswald 28 cinematic title)         │
│                                        │
│  «Face the horrors beneath the city.   │
│   Glory or death — your choice.»       │
│       (Inter 14, secondary)            │
│                                        │
│       [    ENTER THE CITY    ]         │
│        (.primary CTA, gold)            │
│                                        │
└────────────────────────────────────────┘
```

### Animation timeline (2.2 sec total)

```
t=0.0    Backdrop fades in (0.3s, opacity 0 → 0.85)
t=0.2    "NEW BUILDING" pill slides down from top (0.3s)
t=0.5    Building sprite scales in (0.5s, 0.4 → 1.0, with rays rotation start)
t=0.8    Gold particle burst (0.6s)
t=1.0    Title fades + blur-in (0.4s, like LevelUpModal title)
t=1.4    Body text fades in (0.3s)
t=1.7    CTA button appears (0.3s, with shimmer)
t=2.0    Ready for user tap
```

**No scale grow on title or CTA.** Только opacity + blur (из феедбекс мемори: `feedback_no_scale_animations.md`).

### Структура файла

```swift
// Hexbound/Hexbound/Views/Components/BuildingUnlockCeremony.swift

struct BuildingUnlockCeremony: View {
    let unlock: BuildingUnlockData
    let onContinue: () -> Void

    struct BuildingUnlockData {
        let buildingId: String      // "dungeon"
        let displayName: String      // "DUNGEON RUSH"
        let description: String      // "Face the horrors beneath the city..."
        let imageName: String        // "building-dungeon"
        let accentColor: Color       // DarkFantasyTheme.gold или domain-specific
    }

    @Environment(AppState.self) private var appState
    @State private var phase: AnimationPhase = .hidden
    // ... (animation state matching LevelUpModalView pattern)

    var body: some View {
        ZStack {
            backdrop
            VStack(spacing: LayoutConstants.spaceLG) {
                newBuildingPill
                buildingSpriteWithRays
                titleAndDescription
                Spacer()
                continueButton
            }
            .padding(LayoutConstants.screenPadding)
        }
    }
}
```

### Catalog для building descriptions

`Hexbound/Hexbound/Views/Components/BuildingUnlockCatalog.swift`:

```swift
enum BuildingUnlockCatalog {
    static let entries: [String: BuildingUnlockCeremony.BuildingUnlockData] = [
        "dungeon": .init(
            buildingId: "dungeon",
            displayName: "DUNGEON RUSH",
            description: "Face the horrors beneath the city. Glory or death — your choice.",
            imageName: "building-dungeon",
            accentColor: DarkFantasyTheme.dangerRed
        ),
        "gold-mine": .init(
            buildingId: "gold-mine",
            displayName: "GOLD MINE",
            description: "Gold flows while you sleep. Collect every few hours.",
            imageName: "building-gold-mine",
            accentColor: DarkFantasyTheme.gold
        ),
        "tavern": .init(
            buildingId: "tavern",
            displayName: "THE CROOKED TANKARD",
            description: "Warriors gather. Rumors spread. Trouble finds you.",
            imageName: "building-tavern",
            accentColor: DarkFantasyTheme.buffPhysical
        ),
        "battlepass": .init(
            buildingId: "battlepass",
            displayName: "THE LONG ROAD",
            description: "Season rewards for the dedicated. Climb or get climbed.",
            imageName: "building-battlepass",
            accentColor: DarkFantasyTheme.gold
        ),
        "ranks": .init(
            buildingId: "ranks",
            displayName: "HALL OF CHAMPIONS",
            description: "Only the strongest names are carved here. Make yours one of them.",
            imageName: "building-ranks",
            accentColor: DarkFantasyTheme.buffMagical
        ),
        "guild-hall": .init(
            buildingId: "guild-hall",
            displayName: "GUILD HALL",
            description: "No warrior stands alone. Forge bonds. Share the spoils.",
            imageName: "building-guild-hall",
            accentColor: DarkFantasyTheme.buffMagical
        ),
    ]
}
```

Texts — snarky dark-fantasy tone, matching LoreIntro voice (см. W2.D2). Каждый <15 слов.

### Navigation flow integration

Текущий flow при level up:
```
combat resolve → appState.levelUpNewLevel set → LevelUpModal shows → user closes → hub
```

Новый flow с ceremony:
```
combat resolve → appState.levelUpNewLevel set → LevelUpModal shows
             → user closes → check unlocks[] → если есть:
             → BuildingUnlockCeremony (sequence если несколько)
             → hub
```

Добавить в `AppState.swift`:

```swift
@Published var pendingBuildingUnlocks: [String] = []
@Published var showBuildingUnlockCeremony: Bool = false
```

В `LevelUpModalView.onContinue`:

```swift
appState.levelUpNewLevel = 0  // hide level up modal
if !appState.pendingBuildingUnlocks.isEmpty {
    appState.showBuildingUnlockCeremony = true
}
```

В `BuildingUnlockCeremony.onContinue`:

```swift
if appState.pendingBuildingUnlocks.count > 1 {
    appState.pendingBuildingUnlocks.removeFirst()
    // play next unlock in sequence
} else {
    appState.pendingBuildingUnlocks = []
    appState.showBuildingUnlockCeremony = false
}
```

Sequence играется через `id(currentUnlockId)` + `.transition(.opacity)`, чтобы SwiftUI перестроил view и анимация сыграла снова.

---

## Anticipation Toast (Lv X-1 Preview)

Когда игрок достигает Lv (X-1), показывать toast в hub на первом визите:

```
┌──────────────────────────────────────┐
│ 🔓 Next level: Dungeon Rush unlocks  │
└──────────────────────────────────────┘
```

### Trigger logic

В `CityMapView.onAppear` или в `AppState.didSetCurrentCharacter`:

```swift
private func checkAnticipationToast() {
    guard let level = appState.currentCharacter?.level else { return }
    let nextLevel = level + 1
    let upcomingUnlocks = BuildingUnlockConfig.levels.filter { $0.value == nextLevel }
    guard let first = upcomingUnlocks.first else { return }

    // Prevent showing same toast twice in one session
    let key = "anticipation_shown_\(nextLevel)"
    guard !UserDefaults.standard.bool(forKey: key) else { return }
    UserDefaults.standard.set(true, forKey: key)

    appState.showToast(
        "🔓 Next level: \(buildingDisplayName(first.key)) unlocks",
        type: .info
    )
}
```

### Rate limiting

- Только 1 раз в session (UserDefaults flag per level)
- Не показывать если игрок уже на max level в catalog
- Не показывать если следующий unlock — Lv99 (black market coming soon)

---

## Visual Polish: BuildingLockOverlay

### Проблема

Сейчас:

```swift
RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
    .fill(Color.black.opacity(0.6))
```

На ярких building sprites (arena, shop) 60% opacity читается, но на темных (dungeon, tavern) практически не видно. Игрок не сразу понимает, что здание locked.

### Решение

Увеличить up до 0.75 + добавить grayscale filter:

```swift
ZStack {
    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
        .fill(Color.black.opacity(0.75))

    // lock icon + LV pill (как сейчас)
}
.compositingGroup()
.saturation(0.0)  // Desaturate the building underneath
```

⚠️ `saturation(0.0)` применяется только к BuildingLockOverlay, не к самому building sprite. Нужно применять к parent view. Альтернатива: добавить в CityBuildingView conditional modifier:

```swift
Image(building.imageName)
    .resizable()
    // ...
    .saturation(isLocked ? 0.3 : 1.0)  // Desaturate when locked
    .overlay(
        isLocked ? BuildingLockOverlay(requiredLevel: requiredLevel) : nil
    )
```

Это гарантированно работает для всех зданий.

### Visual test cases

После изменений проверить все 10 buildings в locked/unlocked state:
1. arena, shop, achievements (always unlocked at Lv1 — no lock state)
2. dungeon (locked pre-Lv2, unlocked post)
3. gold-mine (locked pre-Lv4)
4. tavern (locked pre-Lv6)
5. battlepass, ranks (locked pre-Lv8)
6. guild-hall (locked pre-Lv12)
7. black-market (locked Lv99 — Coming Soon indicator, не LV pill)

Для black-market overlay должен показывать «SOON» вместо «LV.99». Add case in `BuildingLockOverlay`:

```swift
if requiredLevel >= 99 {
    Text("SOON")
} else {
    Text("LV.\(requiredLevel)")
}
```

---

## Backend Changes Summary

### 1. Constants

`backend/src/lib/game/constants.ts` — новый export `BUILDING_UNLOCK_LEVELS` + helper `getBuildingUnlocks(newLevel)`.

### 2. Level up response shape

`backend/src/lib/game/character-progression.ts`, `applyLevelUp`:

```ts
return {
  ...existingFields,
  newLevel: character.level,
  statPointsAwarded: statPointsForLevel,
  // NEW:
  unlocks: getBuildingUnlocks(character.level),
};
```

### 3. API endpoint response

Все endpoints которые возвращают level-up (pvp/fight, dungeon complete, tutorial/scripted-fight/resolve, etc.) — уже включают applyLevelUp result. Автоматически подхватят `unlocks: string[]`.

### 4. Migration / schema

**Нет migration нужна.** `unlocks` — derived из constants, не stored.

---

## Scaffolding / File Changes List

### New files

| File | LOC est | Purpose |
|---|---|---|
| `Hexbound/Hexbound/Views/Components/BuildingUnlockCeremony.swift` | ~180 | Cinematic overlay |
| `Hexbound/Hexbound/Views/Components/BuildingUnlockCatalog.swift` | ~80 | Static catalog of unlock data |

### Modified files

| File | Changes |
|---|---|
| `Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift` | Update levels table; handle Lv99 → "SOON"; polish opacity |
| `Hexbound/Hexbound/Views/Components/LevelUpModalView.swift` | Remove unlock pills (moved to ceremony); trigger ceremony on close |
| `Hexbound/Hexbound/Views/Hub/CityMapView.swift` | Add anticipation toast trigger in `onAppear` |
| `Hexbound/Hexbound/Views/Hub/CityBuildingView.swift` | Apply `saturation(0.3)` when locked |
| `Hexbound/Hexbound/App/AppState.swift` | Add `pendingBuildingUnlocks: [String]` + `showBuildingUnlockCeremony: Bool` |
| `Hexbound/Hexbound/Views/Root/RootView.swift` (or wherever modals are hosted) | Overlay `BuildingUnlockCeremony` when `showBuildingUnlockCeremony == true` |
| `backend/src/lib/game/constants.ts` | Add `BUILDING_UNLOCK_LEVELS` + `getBuildingUnlocks` |
| `backend/src/lib/game/character-progression.ts` | Return `unlocks: string[]` from `applyLevelUp` |

### pbxproj

2 новых файла (`BuildingUnlockCeremony.swift`, `BuildingUnlockCatalog.swift`) → 4 entries per file в pbxproj. Сгенерировать unique 24-char hex IDs через `openssl rand -hex 12`.

---

## Implementation Plan

### Phase 1 — Backend (30 min)
1. Add `BUILDING_UNLOCK_LEVELS` + `getBuildingUnlocks` to constants
2. Wire `unlocks` into `applyLevelUp` return
3. Update TypeScript types for level-up response
4. Local smoke test via tsx

### Phase 2 — Unlock schedule adjustment (15 min)
1. Update `BuildingUnlockConfig.levels` in Swift to match new schedule
2. Verify `LevelUpModalView.unlocks` computation still works with new levels

### Phase 3 — BuildingUnlockCeremony (1.5 h)
1. Create `BuildingUnlockCatalog.swift` with 6 entries
2. Create `BuildingUnlockCeremony.swift` component
3. Add state to `AppState`
4. Integrate into root modal layer
5. Sequence logic для multi-unlock levels (Lv8)

### Phase 4 — Anticipation toast (30 min)
1. Add trigger logic in `CityMapView.onAppear`
2. UserDefaults key-per-level to prevent spam
3. Edge cases (Lv99, max level)

### Phase 5 — Visual polish (30 min)
1. Update `BuildingLockOverlay` opacity + Lv99 handling
2. Add `saturation(0.3)` to locked buildings in `CityBuildingView`
3. Visual test all 10 buildings

### Phase 6 — Wiring + QA (30 min)
1. pbxproj entries для 2 новых файлов
2. Grep all references to `BuildingUnlockConfig.levels` для breaking changes
3. Test flow: Lv1 → scripted fight → Lv2 level up → Dungeon unlock ceremony
4. Test Lv8 sequence (battlepass + ranks два ceremony подряд)
5. CDO verification scan

**Total: ~3.75 hours** — меньше чем W2.D3 (2 дня), потому что 85% уже построено.

---

## Edge Cases & Risks

| Edge case | Handling |
|---|---|
| Игрок уже на Lv5+ (existing account) → не увидит unlock ceremony для Lv2/4 | ✅ Correct — ceremony только для новых unlock'ов. Backward compatible |
| Multi-unlock (Lv8 → battlepass+ranks) | Sequence: battlepass ceremony → ranks ceremony → hub. Rate limited: max 2 per level |
| Unlock во время dungeon / pvp (не в hub) | Ceremony показывается next time в hub (pending queue в AppState) |
| Server вернул unlocks но client не знает здание (version mismatch) | Graceful fallback: skip unknown building in catalog, log warning |
| Anticipation toast spam при частом level up | UserDefaults key per `next_level`, 1 раз per level |
| Lv99 black-market | BuildingLockOverlay показывает "SOON" вместо "LV.99". Не триггерит ceremony (Lv99 недостижим) |
| Lock overlay не читается на светлом building sprite | `saturation(0.3)` + opacity 0.75 гарантирует контраст |
| Player с offline progress (multiple level-ups в одной сессии) | Server возвращает all unlocks в одном `unlocks[]`. Client играет sequence |
| Anticipation toast shown после level up в same session | Reset UserDefaults keys on level up (current level > stored level). Deferred to W4 if edge case rare |

---

## Вопросы для Artem перед имплементацией

1. **Unlock schedule**: Согласен с предложенным Lv2/4/6/8/12? Или сохранить текущий Lv3/5/7/10/15? Есть ли retention data, по которой можно калибровать?

2. **Tavern content readiness**: Tavern unlock на Lv6 — но есть ли там playable content сейчас, или это Coming Soon? Если пусто — оставить Lv7 или отложить до implementation.

3. **Gold Mine balance**: Gold Mine на Lv4 (~8 мин) вместо Lv5 (~12 мин). Скорее дать игроку idle reward — хорошо, но не сломает ли это early-game economy (слишком много gold у нового игрока)? Вопрос к `hexbound-studio:vault` (Economy Designer).

4. **Guild Hall на Lv12**: Сейчас Lv15, предложение Lv12. Guild system spec был draft в W1 (см. `project_guild_system_spec.md` memory). Готов ли guild system для Lv12 players или ещё не MVP? Если нет — оставить Lv15.

5. **Server-side unlocks**: Согласен перевести unlock schedule в server constants? Это enables live-ops tuning без client release, но добавляет легкий coupling.

6. **Ceremony vs pill**: Выносить BuildingUnlockCeremony в отдельный cinematic (мой план) или оставить pill в LevelUpModal с более ornamental treatment?

7. **Anticipation toast**: Хочешь preview toast на Lv (X-1) или считаешь noise?

8. **Parallel agent review**: Запустить `hexbound-studio:ascent` (Progression Designer) для валидации unlock cadence + `hexbound-studio:flow` (UX Director) для ceremony friction assessment?

---

## Acceptance Criteria (для implementation phase)

- [ ] `BUILDING_UNLOCK_LEVELS` в `backend/src/lib/game/constants.ts`
- [ ] `applyLevelUp` возвращает `unlocks: string[]`
- [ ] `BuildingUnlockConfig.levels` в Swift обновлён до нового schedule
- [ ] `BuildingUnlockCeremony.swift` создан, 180 ± 30 LOC
- [ ] `BuildingUnlockCatalog.swift` создан с 6 entries
- [ ] pbxproj содержит оба новых файла (4 sections each)
- [ ] AppState содержит `pendingBuildingUnlocks` + `showBuildingUnlockCeremony`
- [ ] RootView overlays `BuildingUnlockCeremony` когда flag true
- [ ] `LevelUpModalView` больше не показывает unlock pills (moved to ceremony)
- [ ] `CityMapView.onAppear` триггерит anticipation toast на Lv (X-1)
- [ ] `BuildingLockOverlay` показывает "SOON" для Lv99, "LV.N" для остального
- [ ] `CityBuildingView` применяет `saturation(0.3)` для locked buildings
- [ ] Manual test: Lv1 → scripted fight → Lv2 → Dungeon unlock ceremony
- [ ] Manual test: Lv7 → Lv8 → battlepass ceremony → ranks ceremony → hub
- [ ] Manual test: Lv1 → anticipation toast «Dungeon Rush unlocks next level»
- [ ] CDO verification scan: CLEAN
- [ ] `hexbound-studio:guardian` agent review passed (Swift)
- [ ] `hexbound-studio:oracle` agent review passed (TypeScript)

---

## Next Step

**W2.D5 — Badge priority system** (`W2_D5_BADGE_PRIORITY_DESIGN.md`). Меньший доку, фокус на `badgePriority: .critical/.info/.none` enum и conditional rendering logic. После W2.D5 — PAUSE и показ всех W2 design docs Артёму для approval.
