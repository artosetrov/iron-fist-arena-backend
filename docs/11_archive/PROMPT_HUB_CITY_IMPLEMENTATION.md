# Промпт: Переделать HubView — интерактивная карта города

> **Status**: `legacy` — Hub city implementation notes. Archived at `docs/11_archive/PROMPT_HUB_CITY_IMPLEMENTATION.md`

## Контекст

Мы переделываем hub-экран игры Hexbound (бывшая Iron Fist Arena). Сейчас HubView — это сетка кнопок (LazyVGrid 2×4). Нужно заменить её на **интерактивную панорамную карту тёмного фэнтезийного города**, которую игрок свайпает горизонтально. Здания на карте заменяют кнопки навигации.

## Что есть сейчас

Файл: `Hexbound/Views/Hub/HubView.swift` (~715 строк)

Текущая структура:
- TopCurrencyBar (золото, гемы)
- StaminaBarView
- HubCharacterCard (аватар Degon, HP, XP)
- FirstWinBonusCard (условный)
- **LazyVGrid с NavTile** ← ЭТО ЗАМЕНЯЕМ
- Floating actions (Daily Login, Sound, Daily Quests)

Навигация через AppRouter:
- `.arena`, `.dungeonSelect`, `.tavern`, `.shop`, `.leaderboard`, `.battlePass`, `.achievements`

Тема: `DarkFantasyTheme` (bgPrimary: 0x0D0D12, gold: 0xD4A537, goldBright: 0xFFD700)

## Что нужно сделать

Заменить `LazyVGrid` с кнопками на **горизонтально скроллящуюся панорамную карту города** с кликабельными зданиями-спрайтами.

### Архитектура слоёв (снизу вверх):

```
┌─────────────────────────────────────────────┐
│  Слой 4: UI overlay                        │  ← TopCurrencyBar, StaminaBar,
│          (остаётся как есть)                │     CharacterCard, FloatingActions
├─────────────────────────────────────────────┤
│  Слой 3: Подписи зданий                    │  ← Баннеры-лейблы с названиями
│          (опционально, overlay)             │     при наведении/тапе
├─────────────────────────────────────────────┤
│  Слой 2: Здания-спрайты                    │  ← Отдельные PNG на прозрачном фоне,
│          (кликабельные)                     │     позиционированы абсолютно
├─────────────────────────────────────────────┤
│  Слой 1: Terrain фон                       │  ← Широкая панорама 21:9 (уже есть)
│          (скроллится горизонтально)         │     hub_terrain.png
└─────────────────────────────────────────────┘
```

### Ассеты (будут в Assets.xcassets):

| Ассет | Файл | Описание |
|-------|------|----------|
| `hub-terrain` | hub_terrain.png | Широкая панорама 21:9, фон города |
| `building-arena` | building_arena.png | Гексагональный колизей (самый большой) |
| `building-dungeon` | building_dungeon.png | Вход в пещеру |
| `building-tavern` | building_tavern.png | Кривая деревянная таверна |
| `building-shop` | building_shop.png | Лавка торговца |
| `building-ranks` | building_ranks.png | Каменная башня с флагами |
| `building-battlepass` | building_battlepass.png | Мистический шатёр |
| `building-achievements` | building_achievements.png | Зал трофеев |

Все здания — PNG с прозрачным фоном, рисованные в ink/crosshatch стиле.

### Реализация: CityMapView (новый компонент)

Создать `Hexbound/Views/Hub/CityMapView.swift`:

```
struct CityMapView: View
```

**Требования:**

1. **ScrollView(.horizontal)** с панорамным terrain-фоном
   - Фон: `hub-terrain` — широкая картинка, высота = высота доступной области (от CharacterCard до FloatingActions)
   - Ширина фона = высота × (21/9) — сохраняем пропорции 21:9
   - При запуске скролл позиционируется на **центр** (арена в центре)
   - Bounce эффект при достижении краёв
   - Плавный инерционный скролл

2. **Здания — абсолютно позиционированные Image поверх terrain**
   - Каждое здание = `Image("building-xxx")` с `.resizable().aspectRatio(contentMode: .fit)`
   - Позиция каждого здания задаётся в **относительных координатах** (% от ширины и высоты terrain), чтобы работало на любом экране
   - Используй `.position(x: terrainWidth * relX, y: terrainHeight * relY)`
   - Размер каждого здания тоже в % от высоты terrain

3. **Конфигурация зданий — массив данных:**

```swift
struct CityBuilding: Identifiable {
    let id: String
    let imageName: String        // ассет
    let label: String            // название для баннера
    let route: AppRoute          // куда переходить
    let relativeX: CGFloat       // 0.0...1.0 позиция по X
    let relativeY: CGFloat       // 0.0...1.0 позиция по Y
    let relativeSize: CGFloat    // размер относительно высоты terrain
    let glowColor: Color         // цвет свечения при тапе
}

let cityBuildings: [CityBuilding] = [
    CityBuilding(
        id: "arena",
        imageName: "building-arena",
        label: "ARENA",
        route: .arena,
        relativeX: 0.50,   // центр панорамы
        relativeY: 0.40,
        relativeSize: 0.45, // самое большое здание
        glowColor: DarkFantasyTheme.goldBright
    ),
    CityBuilding(
        id: "dungeon",
        imageName: "building-dungeon",
        label: "DUNGEON",
        route: .dungeonSelect,
        relativeX: 0.20,
        relativeY: 0.45,
        relativeSize: 0.28,
        glowColor: Color(hex: "7B2D8B") // фиолетовый
    ),
    CityBuilding(
        id: "shop",
        imageName: "building-shop",
        label: "SHOP",
        route: .shop,
        relativeX: 0.33,
        relativeY: 0.60,
        relativeSize: 0.22,
        glowColor: DarkFantasyTheme.goldBright
    ),
    CityBuilding(
        id: "tavern",
        imageName: "building-tavern",
        label: "TAVERN",
        route: .tavern,
        relativeX: 0.62,
        relativeY: 0.55,
        relativeSize: 0.25,
        glowColor: Color.orange
    ),
    CityBuilding(
        id: "ranks",
        imageName: "building-ranks",
        label: "RANKS",
        route: .leaderboard,
        relativeX: 0.74,
        relativeY: 0.38,
        relativeSize: 0.30,
        glowColor: DarkFantasyTheme.goldBright
    ),
    CityBuilding(
        id: "battlepass",
        imageName: "building-battlepass",
        label: "BATTLE PASS",
        route: .battlePass,
        relativeX: 0.76,
        relativeY: 0.65,
        relativeSize: 0.22,
        glowColor: Color.purple
    ),
    CityBuilding(
        id: "achievements",
        imageName: "building-achievements",
        label: "ACHIEVEMENTS",
        route: .achievements,
        relativeX: 0.90,
        relativeY: 0.50,
        relativeSize: 0.24,
        glowColor: DarkFantasyTheme.goldBright
    ),
]
```

**ВАЖНО:** Эти координаты — начальные приблизительные значения. После подключения реальных ассетов нужно будет подкрутить позиции вручную, чтобы здания точно стояли на плоских участках terrain.

4. **Тап на здание — анимация + навигация:**
   - При тапе на здание:
     1. Здание scale 1.0 → 1.08 (bouncy spring animation, 0.3s)
     2. Золотистый glow-outline вокруг здания (shadow с цветом glowColor, radius 12)
     3. Баннер-лейбл с названием появляется над зданием (fade in + slide up)
     4. Haptic feedback (UIImpactFeedbackGenerator, .medium)
     5. Через 0.2s задержки — навигация на route через appState.mainPath.append(route)
   - При тапе в пустое место — ничего не происходит (только скролл)

5. **Idle-анимации зданий (ambient life):**
   - Арена: мягкая пульсация золотого свечения (opacity 0.3↔0.7, 3s loop)
   - Таверна: лёгкое мерцание оранжевого свечения окон (randomized, 2-4s)
   - Данжен: зелёно-фиолетовое мерцание (opacity 0.2↔0.5, 4s loop)
   - Battle Pass шатёр: фиолетовые мерцающие искры (opacity animation)
   - Остальные: subtle тёплое свечение факелов (overlay с мягким gold, пульсация)
   - Реализовать через `.overlay()` с анимированными gradient/color layers
   - Все анимации с `.animation(.easeInOut(duration: X).repeatForever(autoreverses: true))`

6. **Баннеры-лейблы зданий:**
   - НЕ показывать постоянно — только при первом визите (onboarding) или при long press
   - Стиль: маленькая тёмная плашка с золотой рамкой, текст Inter SemiBold 11pt, золотой цвет
   - Позиция: над зданием, центрировано
   - Fade in/out анимация

### Интеграция в HubView.swift

Заменить секцию `LazyVGrid` (найти по комментарию или NavTile) на:

```swift
// Было:
// LazyVGrid(columns: [...], spacing: 12) {
//     NavTile(...)
//     ...
// }

// Стало:
CityMapView()
    .frame(height: availableHeight) // рассчитать доступную высоту
```

**Расчёт доступной высоты:**
- `availableHeight` = высота экрана - TopCurrencyBar - StaminaBar - CharacterCard - FloatingActions - safe areas - bottom nav (64pt)
- Приблизительно: экран minus ~280pt (верхний UI) minus ~100pt (нижний UI)
- CityMapView должен занимать всё оставшееся пространство

**Что НЕ трогать:**
- TopCurrencyBar — оставить как есть
- StaminaBarView — оставить как есть
- HubCharacterCard — оставить как есть
- FirstWinBonusCard — оставить как есть (показывать поверх карты?)
- FloatingActionIcons — оставить как есть (поверх карты, внизу)
- Bottom tab bar — оставить как есть
- Все prefetch вызовы — оставить как есть

### Начальная позиция скролла

При появлении экрана — скролл должен быть на **центре** панорамы (арена). Используй `ScrollViewReader` + `.scrollTo()` или вычисли offset программно.

### Fallback

Если ассеты зданий ещё не готовы — показывать на месте каждого здания **placeholder**: полупрозрачный гексагон с иконкой (текущие icon-arena, icon-dungeons и т.д.) и названием. Это позволит тестировать позиции до получения финальных спрайтов.

### Файловая структура

```
Hexbound/Views/Hub/
├── HubView.swift              ← модифицировать (заменить LazyVGrid на CityMapView)
├── CityMapView.swift          ← НОВЫЙ — основной компонент карты
├── CityBuildingView.swift     ← НОВЫЙ — компонент одного здания (спрайт + тап + анимации)
├── CityBuildingConfig.swift   ← НОВЫЙ — массив CityBuilding конфигураций
└── CityBuildingLabel.swift    ← НОВЫЙ — компонент баннера-подписи

Hexbound/Resources/Assets.xcassets/
├── hub-terrain.imageset/      ← НОВЫЙ — панорама terrain
├── building-arena.imageset/   ← НОВЫЙ
├── building-dungeon.imageset/ ← НОВЫЙ
├── building-tavern.imageset/  ← НОВЫЙ
├── building-shop.imageset/    ← НОВЫЙ
├── building-ranks.imageset/   ← НОВЫЙ
├── building-battlepass.imageset/ ← НОВЫЙ
└── building-achievements.imageset/ ← НОВЫЙ
```

### Критерии готовности

- [ ] CityMapView скроллится горизонтально с terrain-фоном
- [ ] Начальная позиция скролла — центр (арена)
- [ ] 7 зданий позиционированы поверх terrain
- [ ] Тап на здание → анимация + haptic + навигация на правильный route
- [ ] Idle-анимации свечения на зданиях
- [ ] Placeholder-режим работает когда ассетов зданий нет
- [ ] TopCurrencyBar, StaminaBar, CharacterCard остаются сверху
- [ ] FloatingActions остаются снизу
- [ ] Производительность: 60fps на iPhone 12+
- [ ] Не сломана существующая навигация (все routes работают)

### Ограничения

- Не менять AppRouter, AppState, навигационную логику
- Не менять тему DarkFantasyTheme
- Не менять другие View (CharacterDetailView, ShopView и т.д.)
- Не менять backend/API
- Использовать существующие шрифты (Inter, Oswald, Cinzel) и цвета из DarkFantasyTheme
- SwiftUI only, без UIKit wrappers (если не критично для performance)
