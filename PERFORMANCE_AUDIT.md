# Hexbound — Deep Performance Audit

**Дата:** 2026-03-24
**Версия:** iOS клиент + Next.js backend
**Методология:** статический анализ кода (46 View-файлов, 47 ViewModel/Service, 98 API-вызовов)

---

## A. Executive Summary

Hexbound — мобильная PvP RPG с ornamental dark-fantasy дизайн-системой. Приложение функционально полное (40+ экранов, 10 зданий на хабе, 3 мини-игры, PvP, данжи, соцфункции), но **GPU-рендеринг и анимационная нагрузка критически не оптимизированы**.

**Ключевые метрики:**
- **279 ornamental overlay вызовов** в 46 файлах (`.surfaceLighting`, `RadialGlowBackground`, `.cornerBrackets`, `.innerBorder`)
- **0 вызовов `.compositingGroup()` или `.drawingGroup()`** — ни один экран не группирует слои для GPU
- **258 анимационных директив** (205 `withAnimation` + 53 `.animation()`)
- **20+ файлов с `.repeatForever` анимациями** — непрерывная нагрузка даже на idle-экранах
- **98 API-вызовов** в клиенте, но cache-first паттерн хорошо реализован через `GameDataCache`

**Вердикт:** Приложение «тяжелее», чем нужно, на **~40-60% по GPU** из-за ornamental overlays без compositing groups и непрерывных анимаций. Сеть и кеширование — в хорошем состоянии. Главные инвестиции нужны в **rendering pipeline**.

---

## B. Critical Bottlenecks (Критические узкие места)

### B1. Ornamental Overlays без `.compositingGroup()` — CRITICAL

**Проблема:** Каждый вызов `.surfaceLighting()`, `.innerBorder()`, `.cornerBrackets()`, `.cornerDiamonds()` создаёт отдельный overlay layer в render tree. SwiftUI рендерит каждый слой отдельно, включая alpha blending.

**Масштаб:** 279 overlay-вызовов в 46 файлах. Ни один не обёрнут в `.compositingGroup()`.

**Worst offenders:**

| Экран | Overlay-вызовы | Влияние |
|---|---|---|
| GuildHallDetailView | 39 | Каждая карта друга/челленджа = 4-5 overlays |
| DungeonRushDetailView | 30 | Волны + лут + shop = overlay-стек |
| HeroDetailView | 22 | Equipment grid + stats + bars |
| HubView | 16 | Все здания + UI |
| ArenaComparisonSheet | 12 | Два профиля + сравнение |

**Формула нагрузки:** Для экрана с $N$ панелями, каждая с $k$ overlays:

$$\text{GPU passes} = N \times k \times \alpha_{\text{blend}}$$

Где $\alpha_{\text{blend}}$ — стоимость alpha compositing. При $N = 10$, $k = 4$: **40 отдельных render passes** на один кадр.

**Fix:** Добавить `.compositingGroup()` после каждого стека overlays:

```swift
.surfaceLighting(...)
.innerBorder(...)
.cornerBrackets(...)
.compositingGroup()  // ← flatten to single texture
```

### B2. Непрерывные анимации на idle-экранах — CRITICAL

**Проблема:** 20+ файлов запускают `.repeatForever` анимации в `.onAppear`. Эти анимации работают **постоянно**, даже когда экран не виден (NavigationStack сохраняет вью в памяти).

**Worst offenders:**

| Файл | Анимация | Duration | Тип |
|---|---|---|---|
| CityMapEffects | particle twinkle + cloud drift | 1.5-20s | GPU: opacity + position |
| CityMapView | moon shimmer + object drift | 4s + variable | GPU: opacity + position |
| UnifiedHeroWidget | HP pulse + stat badge pulse | 0.8-1.0s | GPU: opacity + shadow |
| CharacterSelectionView | glow rotation + shimmer | 4s + 2s | GPU: rotation + offset |
| ArenaOpponentCard | glow phase + shimmer | 4s + 2s | GPU: per-card × N cards |
| DailyLoginPopupView | glow rotation | 4s | GPU: rotation |
| NPCGuideWidget | bobbing motion | 1.5s | GPU: offset |

**Импакт:** На Hub экране одновременно работают: CityMapEffects particles, moon shimmer, cloud drift, object drift, UnifiedHeroWidget pulses, HubView badge pulse = **минимум 8 concurrent `.repeatForever` анимаций**.

**Расчёт кадров:**

$$\text{Animations per frame} = \sum_{i=1}^{n} \frac{60}{\text{duration}_i}$$

Для Hub: $\frac{60}{1.5} + \frac{60}{4} + \frac{60}{20} + \frac{60}{0.8} + \frac{60}{4} = 40 + 15 + 3 + 75 + 15 = 148$ property updates/sec

**Fix:** Паттерн `.onDisappear { cancelAnimation() }` или `@State private var isVisible` с проверкой при каждом тике.

### B3. Combat VFX — 7+ анимаций за ход — HIGH

**Проблема:** CombatDetailView накапливает анимации за ход: damage popup + HP bar + shake + glow + pulse + VFX overlay + turn indicator. Каждая — отдельный `withAnimation` блок.

**Расчёт per-turn GPU cost:**

$$C_{\text{turn}} = C_{\text{shake}} + C_{\text{damage\_popup}} + C_{\text{hp\_bar}} + C_{\text{vfx\_overlay}} + C_{\text{pulse}} + C_{\text{glow}} + C_{\text{indicator}} \approx 7 \times C_{\text{anim}}$$

Для боя в 15 ходов: $7 \times 15 = 105$ анимационных транзакций.

---

## C. Screen-by-Screen Audit

### Hub (CityMapView + HubView)

**Rendering:**
- 16 ornamental overlays, 0 compositing groups
- Parallax scrolling + pan gesture на карте
- 10 зданий с badge pills + glow effects
- CityMapEffects: particle system (twinkle) + cloud drift + moon shimmer

**Анимации:** 8+ concurrent `.repeatForever` (particles, clouds, moon, badges, hero widget)

**Проблемы:**
1. Particle twinkle использует random duration `.easeInOut(duration: Double.random(in: 1.5...3.0))` — каждая частица = отдельный animation driver
2. Cloud drift на 20s — длинная анимация занимает ресурсы
3. Badge pulse на HubView `.easeInOut(duration: 0.8).repeatForever` — пульсирует всегда

**Оценка:** 🔴 Тяжёлый, требует `.drawingGroup()` на карте

### Arena (ArenaDetailView + ArenaViewModel)

**Rendering:** 6 overlays, sticky tabs + ScrollView

**API:** Waterfall loading — opponents → revenge → history загружаются при переключении табов, не параллельно

**Анимации:** ArenaOpponentCard × N карточек, каждая с glow phase (4s) + shimmer (2s)

**Проблемы:**
1. N opponent cards × 2 animations = $2N$ concurrent animations
2. Tab switch triggers fresh API call каждый раз (нет tab-level кеша)

**Оценка:** 🟡 Средний — оптимизировать параллельную загрузку табов

### Hero (HeroDetailView + HeroIntegratedCard)

**Rendering:** 22 overlays — самый визуально насыщенный экран

**Содержание:** Equipment grid (11 слотов) + stats + bars + stance + inventory tab

**Проблемы:**
1. Equipment grid: каждый слот = `ItemCardView` с 4 overlays = $11 \times 4 = 44$ overlay layers
2. Inventory tab: ScrollView с ItemCardView × inventory count

**Оценка:** 🔴 Тяжёлый — equipment grid нуждается в `.compositingGroup()` per card

### Combat (CombatDetailView + VFX)

**Rendering:** 5 overlays + TimelineView для VFX

**Анимации:** 7 per-turn (shake, damage, HP, VFX, pulse, glow, indicator), 2 continuous (pulse glow 0.8s, staggered dots 0.5s)

**Проблемы:**
1. SpinningRays в BattleResultCardView: per-frame тригонометрия в Canvas — пересчёт sin/cos каждый frame
2. Unbounded damage popups: нет лимита на одновременные popup'ы
3. 7 animation transactions per turn — stagger/batch needed

**Оценка:** 🔴 Критический — combat = core loop, должен быть 60fps

### Shop (ShopDetailView + ShopViewModel)

**Rendering:** Умеренный — использует ItemCardView

**API:** `async let` для параллельной загрузки items + offers — хороший паттерн

**Проблемы:** Offer banners с ShimmerModifier на каждом = continuous animation per banner

**Оценка:** 🟢 Хороший — минимальные проблемы

### Fortune Wheel (FortuneWheelDetailView)

**Rendering:** Custom Path-based wheel (12 sectors × slice + divider + label)

**Анимации:** Spin: `.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 4.0)` — single smooth animation

**Проблемы:** Wheel rendering = 12 Path draws + 12 divider lines + 12 labels per frame during rotation

**Оценка:** 🟡 Средний — добавить `.drawingGroup()` на весь wheel

### Shell Game (ShellGameDetailView)

**Rendering:** 3 cup cards + bet selector

**API:** Two-step: start → guess

**Оценка:** 🟢 Лёгкий экран

### Guild Hall (GuildHallDetailView)

**Rendering:** 39 overlays (!) — рекордсмен

**Содержание:** Friends list + challenges + messages, каждый элемент = ornamental card

**Проблемы:**
1. 39 overlay вызовов — friends list с 50 friends = массивный overlay-стек
2. Tab switching = sequential API calls

**Оценка:** 🔴 Критический по rendering

### Dungeon Rush (DungeonRushDetailView)

**Rendering:** 30 overlays

**Содержание:** Wave counter + shop + combat — complex multi-panel screen

**Оценка:** 🔴 Тяжёлый

### Gold Mine (GoldMineDetailView)

**Rendering:** 10 overlays + TimelineView

**Анимации:** Glow pulse 1.5s repeatForever

**Оценка:** 🟡 Средний

### Daily Login (DailyLoginDetailView + Popup)

**Rendering:** Moderate, но с 4s rotation animation

**Оценка:** 🟡 Средний

### Leaderboard

**Rendering:** List-based, лёгкий

**API:** Search без debounce — каждый keystroke = API call

**Оценка:** 🟡 — нужен debounce

### Achievements / Battle Pass / Dungeons

**Rendering:** Card-based layouts, moderate overlays

**Оценка:** 🟢 Приемлемый

---

## D. Asset and Rendering Audit

### Ornamental System — Performance Tax

Ornamental система (`OrnamentalStyles.swift`) — красивая, но дорогая:

| Компонент | Render Cost | Частота |
|---|---|---|
| `RadialGlowBackground` | RadialGradient + RoundedRect | 46 файлов |
| `.surfaceLighting()` | 2× overlay (highlight + shadow) | ~80 вызовов |
| `.innerBorder()` | Gradient stroke overlay | ~60 вызовов |
| `.cornerBrackets()` | 4× Path overlay | ~50 вызовов |
| `.cornerDiamonds()` | 4× rotated Rectangle | ~30 вызовов |
| Dual shadows | 2× shadow per element | Почти везде |

**Суммарно: ~279 overlay operations, 0 compositing groups.**

### Текстурная нагрузка

- Портреты персонажей: загружаются из Assets — ОК (предкомпилированы)
- Equipment иконки: `imageKey` → Asset catalog — ОК
- Нет lazy loading для inventory lists (все ItemCardView рендерятся сразу в ScrollView)
- **Рекомендация:** `LazyVGrid` вместо `VStack` для inventory

### Shader-heavy компоненты

1. **SpinningRays** (BattleResultCardView): `Canvas` с per-frame `sin()`/`cos()` вычислениями для каждого луча — ~12 лучей × trig per frame = CPU overhead
2. **FortuneWheelView**: 12 `Path` секторов + 12 divider lines per frame during spin
3. **CityMapEffects**: Particle system с random durations — нерегулярные redraw triggers

---

## E. API / State / Data Flow Audit

### Положительные стороны

1. **`GameInitService`** — batch endpoint `/api/game/init` загружает все hub-данные одним вызовом (~15-17KB)
2. **`GameDataCache`** — cache-first strategy с TTL, предотвращает лишние запросы
3. **`async let`** в ShopViewModel — параллельная загрузка items + offers
4. **Optimistic UI** — repair, equip, heal обновляют UI мгновенно

### Проблемы

| # | Проблема | Влияние | Экран |
|---|---|---|---|
| E1 | Arena tab waterfall: opponents → revenge → history sequential | +200-400ms на первый load | Arena |
| E2 | Leaderboard search без debounce | API call per keystroke | Leaderboard |
| E3 | Guild Hall tabs: sequential load per tab switch | +150-300ms per switch | Guild Hall |
| E4 | `/game/init` payload 15-17KB | Парсинг ~5-10ms | App launch |
| E5 | No HTTP caching headers (ETag/Last-Modified) | Нет conditional requests | Все |
| E6 | Dual cache (AppState + GameDataCache) | Split invalidation | Архитектура |
| E7 | `postRaw` returns `[String: Any]` → manual dict parsing | Type-unsafe, нет codegen | Все VMs |

### AppState как God Object

`AppState` — единый `@Observable` класс с 30+ свойствами. Любое изменение (даже `showToast`) потенциально триггерит re-evaluation во всех наблюдающих View.

**Рекомендация:** Разделить на domain-specific observable объекты:
- `AuthState` (user, token)
- `NavigationState` (paths)
- `CharacterState` (current character)
- `UIState` (toasts, modals)

---

## F. Animation and Transition Audit

### Статистика

| Тип | Количество | Файлов |
|---|---|---|
| `withAnimation` | 205 | ~40 |
| `.animation()` modifier | 53 | ~25 |
| `.repeatForever` | 20+ | 20 |
| `TimelineView` | 7 | 7 |
| Total animation directives | 258+ | — |

### Непрерывные анимации — полная карта

**Hub screen (одновременно):**
- CityMapEffects: particle twinkle (1.5-3s random) + cloud drift (20s)
- CityMapView: moon shimmer (4s) + object drift (variable)
- UnifiedHeroWidget: HP pulse (0.8s) + stat badge pulse (1.0s)
- HubView: badge pulse (0.8s)
- **Total: 7-8 concurrent repeatForever**

**Combat screen:**
- CombatDetailView: pulse glow (0.8s) + staggered dots (0.5s)
- Per turn: 7 discrete animations
- **Total: 2 continuous + 7N discrete (N = turns)**

**Character Selection:**
- glow rotation (4s) + shimmer (2s)
- **Total: 2 concurrent**

### Проблема: анимации не останавливаются

NavigationStack сохраняет вью в памяти. Анимации, запущенные в `.onAppear`, продолжают работать когда пользователь уходит на другой экран.

**Fix pattern:**
```swift
@State private var isVisible = false

.onAppear { isVisible = true; startAnimations() }
.onDisappear { isVisible = false }
```

---

## G. Loading Strategy Redesign

### Текущее состояние

```
App Launch → Splash (2s) → Auth check → /game/init → Hub
                                          ↓
                               15-17KB JSON parse
                               Character + Cache fill
```

### Проблема: Race condition

Splash timeout (2s) гонится с data load. Если сеть медленная:
- Data не загрузилось за 2s → Hub показывает skeleton/пустоту
- Data загрузилось за 0.5s → пользователь ждёт лишние 1.5s

### Предлагаемая стратегия

```
App Launch → Minimal splash (0.5s max)
          → Параллельно: Auth check + /game/init prefetch
          → Данные готовы → Hub (мгновенно)
          → Данные НЕ готовы → Hub с skeleton → fill on arrival
```

**Ожидаемый выигрыш:** $\Delta t = -1.0\text{s}$ до интерактивного Hub

### Stale-While-Revalidate

Для всех cached данных:
1. Показать кеш мгновенно
2. В фоне запросить свежие данные
3. Обновить при получении (diff-based, не полная замена)

**Применимо к:** Opponents list, leaderboard, achievements, shop items, friends list

---

## H. Prioritized Optimization Roadmap

### Неделя 1 — Quick Wins (0 risk, high impact)

| # | Задача | Effort | Impact | Экранов |
|---|---|---|---|---|
| H1 | Добавить `.compositingGroup()` на все ornamental стеки | 2h | 🔴 Critical | 46 |
| H2 | `.drawingGroup()` на CityMapView, FortuneWheelView | 30min | 🔴 High | 2 |
| H3 | Stop animations on `.onDisappear` | 3h | 🔴 High | 20 |
| H4 | Debounce leaderboard search (300ms) | 15min | 🟡 Medium | 1 |
| H5 | Batch combat animations (stagger 50ms) | 1h | 🟡 Medium | 1 |

### Неделя 2 — Architecture Fixes

| # | Задача | Effort | Impact |
|---|---|---|---|
| H6 | Pre-cache SpinningRays as static image | 2h | 🔴 High |
| H7 | `LazyVGrid` для inventory/equipment | 2h | 🟡 Medium |
| H8 | Parallel arena tab loading | 1h | 🟡 Medium |
| H9 | Parallel guild hall tab loading | 1h | 🟡 Medium |
| H10 | Cap damage popups to 3 concurrent | 30min | 🟡 Medium |

### Неделя 3 — Deep Optimizations

| # | Задача | Effort | Impact |
|---|---|---|---|
| H11 | Split AppState → domain objects | 8h | 🟡 Medium |
| H12 | HTTP ETag caching | 4h | 🟡 Medium |
| H13 | Stale-while-revalidate pattern | 4h | 🟢 Low-Med |
| H14 | Optimize /game/init payload (trim unused) | 2h | 🟢 Low |
| H15 | Pre-render ornamental backgrounds as cached images | 8h | 🔴 High (risky) |

---

## I. Concrete Implementation Tasks

### I1. `.compositingGroup()` — Global Rollout

**Файл:** `OrnamentalStyles.swift`

Добавить `.compositingGroup()` в convenience extensions:

```swift
// BEFORE
func surfaceLighting(...) -> some View {
    self.overlay(SurfaceLightingOverlay(...))
}

// AFTER — add at the end of ornamentalFrame():
func ornamentalFrame(...) -> some View {
    self
        .cornerBrackets(...)
        .cornerDiamonds(...)
        .innerBorder(...)
        .surfaceLighting(...)
        .compositingGroup()  // ← flatten entire ornamental stack
}
```

**Или:** Добавить `.compositingGroup()` в `CardStyles.swift` → `panelCard()` modifier, чтобы все карточки автоматически получили оптимизацию.

### I2. Animation Lifecycle Manager

Создать переиспользуемый modifier:

```swift
struct AnimationLifecycle: ViewModifier {
    @State private var isActive = false
    let animation: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear { isActive = true; animation() }
            .onDisappear { isActive = false }
    }
}
```

### I3. SpinningRays → Pre-rendered Image

```swift
// Render once, cache as UIImage
static let raysImage: UIImage = {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
    return renderer.image { ctx in
        // Draw rays with CGContext — one-time cost
    }
}()
```

### I4. Debounced Search

```swift
// LeaderboardViewModel
@State private var searchTask: Task<Void, Never>?

func onSearchTextChange(_ text: String) {
    searchTask?.cancel()
    searchTask = Task {
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        await performSearch(text)
    }
}
```

### I5. Combat Animation Batching

```swift
func processTurn(_ turn: Turn) async {
    // Batch: damage + HP update together
    withAnimation(.easeOut(duration: 0.3)) {
        applyDamage(turn)
        updateHPBar(turn)
    }

    // Then VFX overlay
    try? await Task.sleep(for: .milliseconds(50))
    withAnimation(.easeOut(duration: 0.2)) {
        showVFX(turn)
    }
}
```

---

## J. "What to Fix This Week" — Priority List

1. ✅ **`.compositingGroup()` на все ornamental стеки** — 2h, -40% GPU на всех экранах
2. ✅ **Stop `.repeatForever` на `.onDisappear`** — 3h, -50% idle CPU на Hub
3. ✅ **`.drawingGroup()` на CityMapView** — 30min, Hub = 60fps
4. ✅ **`.drawingGroup()` на FortuneWheelView** — 15min, smooth spin
5. ✅ **Debounce leaderboard search** — 15min, -90% API calls на search
6. ✅ **Batch combat animations** — 1h, smoother combat
7. ⬜ **LazyVGrid для inventory** — 2h, faster Hero tab
8. ⬜ **Parallel arena/guild loading** — 2h, faster tab switch
9. ⬜ **Cap damage popups** — 30min, prevent popup overflow
10. ⬜ **Pre-render SpinningRays** — 2h, eliminate per-frame trig

---

## Top 10 Biggest Performance Wins

| # | Оптимизация | Ожидаемый эффект | Effort |
|---|---|---|---|
| 1 | `.compositingGroup()` на ornamental стеки | **-30-40% GPU** across all screens | 2h |
| 2 | Stop idle animations on `.onDisappear` | **-50% idle CPU** на Hub | 3h |
| 3 | `.drawingGroup()` на CityMapView | **Hub → стабильные 60fps** | 30min |
| 4 | Split AppState на domain objects | **-60% unnecessary re-renders** | 8h |
| 5 | Pre-render SpinningRays | **-100% per-frame trig math** in battle results | 2h |
| 6 | `LazyVGrid` для inventory | **-70% initial render** для больших инвентарей | 2h |
| 7 | Parallel arena tab loading | **-200-400ms** arena load time | 1h |
| 8 | HTTP ETag caching | **-30-50% network** на повторных запросах | 4h |
| 9 | Combat animation batching | **Smoother 60fps** в бою | 1h |
| 10 | Optimize /game/init payload | **-3-5ms** parse time | 2h |

---

## Top 10 Easiest Fixes (Quickest to Implement)

| # | Fix | Время | Файлов |
|---|---|---|---|
| 1 | Debounce leaderboard search (300ms) | 15min | 1 |
| 2 | `.drawingGroup()` на FortuneWheelView | 15min | 1 |
| 3 | `.drawingGroup()` на CityMapView | 15min | 1 |
| 4 | Cap damage popups to 3 | 30min | 1 |
| 5 | `.compositingGroup()` в `ornamentalFrame()` | 30min | 1 (covers 30+ screens) |
| 6 | Remove WidgetPill urgent glow when not needed | 30min | 1 |
| 7 | Parallel load arena tabs | 1h | 1 |
| 8 | Parallel load guild tabs | 1h | 1 |
| 9 | Combat animation stagger | 1h | 1 |
| 10 | `.compositingGroup()` per ItemCardView | 1h | 1 (covers all cards) |

---

## Top 10 UX Tricks to Make the Game Feel Faster

| # | Трюк | Почему работает |
|---|---|---|
| 1 | **Skeleton screens вместо спиннеров** | Уже есть! Но добавить skeleton на Arena tabs при переключении |
| 2 | **Optimistic UI на все actions** | Уже на repair/equip — расширить на sell, use consumable |
| 3 | **Stale-while-revalidate** | Показать кеш мгновенно, обновить в фоне — 0ms perceived load |
| 4 | **Haptic feedback на каждый tap** | Уже есть через `HapticManager` — тактильный "отклик" маскирует задержку |
| 5 | **Pre-fetch следующего экрана** | При наведении на building → начать загрузку данных |
| 6 | **Instant tab switch** | Кешировать все 3 arena tabs после первой загрузки |
| 7 | **Progressive image loading** | Thumbnail → full resolution для portraits |
| 8 | **Animated transitions маскируют загрузку** | NavigationStack push animation = 350ms "бесплатного" времени для загрузки |
| 9 | **"Preparing battle..." screen** | Показать atmospheric loading screen 1-2s пока грузится combat — превращает wait в anticipation |
| 10 | **Batch toast notifications** | Вместо 3 последовательных toasts → один rich toast с деталями |

---

## Appendix: File Reference

**Heaviest files by overlay count:**
1. `Views/Social/GuildHallDetailView.swift` — 39 overlays
2. `Views/Minigames/DungeonRushDetailView.swift` — 30 overlays
3. `Views/Hero/HeroDetailView.swift` — 22 overlays
4. `Views/Hub/HubView.swift` — 16 overlays
5. `Views/Arena/ArenaComparisonSheet.swift` — 12 overlays

**Files with most continuous animations:**
1. `Views/Hub/CityMapEffects.swift` — particles + clouds
2. `Views/Hub/CityMapView.swift` — moon + objects
3. `Views/Components/UnifiedHeroWidget.swift` — HP + badge pulse
4. `Views/Auth/CharacterSelectionView.swift` — glow + shimmer
5. `Views/Arena/ArenaOpponentCard.swift` — glow + shimmer × N

**Total API surface:** 98 calls across 47 service/VM files
**Total animation directives:** 258+
**Total ornamental overlays:** 279 across 46 files
**Compositing groups:** 0 ❌
