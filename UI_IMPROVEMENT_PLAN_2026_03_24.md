# UI Improvement Plan — 2026-03-24

## Обзор

14 задач, сгруппированных по приоритету и области. Оценка трудозатрат: S (< 15 мин), M (15–45 мин), L (45–90 мин), XL (90+ мин).

---

## ГРУППА A — Быстрые фиксы (< 15 мин каждый)

### 1. Dice button speed — ускорить генерацию имени
**Файл:** `OnboardingViewModel.swift` (~строка 265)
**Проблема:** `generateRandomName()` — синхронная, мгновенная (prefix + suffix). Скорее всего "медленно" из-за анимации или debounce на кнопке.
**План:**
- Проверить `NameStepView.swift` — найти dice button action (вероятно `.onTapGesture` с анимацией или `.disabled` guard)
- Убрать любой `DispatchQueue.main.asyncAfter` / `Task.sleep` / animation delay
- Сделать мгновенный вызов `vm.generateRandomName()` + haptic `.uiTap`
- Если есть анимация текста — оставить короткую (0.15s), но генерация должна быть instant
**Оценка:** S (5 мин)

### 2. Hub map labels lower — опустить лейблы на 10-12px
**Файл:** `CityBuildingLabel.swift` (45 строк) + `CityBuildingView.swift`
**Проблема:** Лейблы слишком высоко относительно зданий.
**План:**
- В `CityBuildingLabel` или в `CityBuildingView` найти `offset(y:)` для label
- Добавить/увеличить `offset(y: 10)` или `offset(y: 12)` к label position
- Если offset задаётся в config — изменить `labelOffsetY` в `CityBuildingConfig`
**Оценка:** S (5 мин)

### 3. Hero inventory header — убрать текст "Inventory"
**Файл:** `HeroDetailView.swift` (секция inventory tab content, ~строка 230-260)
**Проблема:** Текст "Inventory" занимает место, CurrencyDisplay обрезается.
**План:**
- Найти HStack/label с текстом "Inventory" или "INVENTORY" в inventory tab content (НЕ в tab selector — там оставить)
- Удалить текстовый элемент, оставить только `CurrencyDisplay(.compact)`
- CurrencyDisplay получит полную ширину строки
**Оценка:** S (5 мин)

### 4. Stat points banner — green → gold, убрать "spent N"
**Файл:** `HeroDetailView.swift` (~строки 321-332)
**Проблема:** Banner использует зелёный цвет (success), показывает серый "(N spent)" текст.
**План:**
- Найти `StatPointsBadge` или inline banner в `statsTabContent()`
- Заменить `.success` / `.textSuccess` → `DarkFantasyTheme.gold` / `.goldBright`
- Найти и удалить/скрыть строку `"(\(vm.pointsSpent) spent)"` или `pointsSpent`
- Убедиться что banner цвет совпадает с gold capsule badge на tab selector
**Оценка:** S (10 мин)

### 5. Hero stat numbers — увеличить размер
**Файл:** `HeroDetailView.swift` (~строки 443-448)
**Проблема:** Stat value font слишком мелкий, +/- кнопки тоже маленькие.
**План:**
- Текущий font: `DarkFantasyTheme.section(size: LayoutConstants.textCard)` — это ~14px
- Увеличить до `LayoutConstants.textSection` (18px) или `textTitle` (22px) — проверить что помещается
- +/- кнопки: увеличить touch target с текущего (вероятно 36×36) до 44×44, иконку с ~16 до ~20
- Проверить что row height не ломает layout при 8 статах
**Оценка:** S (10 мин)

---

## ГРУППА B — Средние задачи (15-45 мин)

### 6. Hub map z-order fix — лейблы перекрываются зданиями
**Файл:** `CityMapView.swift` (строки 62-79), `CityBuildingView.swift`
**Проблема:** Здания рендерятся в ForEach, label одного здания оказывается под image другого. Нет explicit z-ordering по Y-позиции.
**План:**
- **Вариант A (предпочтительный):** Разделить рендеринг на 2 слоя:
  1. ForEach buildings → только изображения зданий (ZStack, sorted by relativeY ascending)
  2. ForEach buildings → только labels + badges (поверх всех зданий)
  Это гарантирует что ВСЕ лейблы выше ВСЕХ зданий
- **Вариант B:** Добавить `.zIndex()` к каждому зданию = `1.0 - relativeY` (здания выше на экране получают меньший zIndex), а labels получают `zIndex(2.0)`
- Проверить что `.drawingGroup()` не конфликтует с zIndex (drawingGroup flatten всё)
  - Если конфликт — вынести labels из drawingGroup scope
**Оценка:** M (20 мин)

### 7. Dungeon select badge — "N bosses remaining"
**Файл:** `DungeonSelectDetailView.swift` (карточки данжей, строки 200-372) + `CityMapView.swift` (badgeFor)
**Проблема:** Нет badge на здании Dungeon на хаб-карте (как у Arena "FREE N").
**План:**
- **Hub badge:** В `CityMapView.badgeFor()` добавить case `"dungeon"`:
  - Данные: из `cache.dungeons` (или аналог) — посчитать total bosses remaining across all dungeons
  - Или проще: показать прогресс текущего данжа, e.g. `"3/10"` bosses
  - Формат: `"\(remaining)"` или `"⚔ N"` — золотой capsule как у остальных
- **На самой DungeonSelect странице:** progress bar уже есть (defeated/total), badge не нужен
- Нужно проверить: есть ли данные о dungeon progress в `GameDataCache`
**Оценка:** M (20 мин)

### 8. STATUS tab pulsing badge
**Файл:** `HeroDetailView.swift` (tab selector, ~строки 161-181)
**Проблема:** Badge на STATUS tab статичный, нет пульсации как у avatar badge в `UnifiedHeroWidget`.
**План:**
- Найти badge capsule в tab selector для STATUS tab
- Добавить `@State private var badgePulse = false`
- Overlay: `.shadow(color: DarkFantasyTheme.goldBright.opacity(badgePulse ? 0.6 : 0.2), radius: badgePulse ? 8 : 4)`
- `.onAppear { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { badgePulse = true } }`
- `.onDisappear { badgePulse = false }` (GPU rule — stop animation off-screen)
- Матчить стиль пульсации из `UnifiedHeroWidget` avatar badge
**Оценка:** M (15 мин)

### 9. Create hero preloader
**Файл:** `OnboardingViewModel.swift` + `NameStepView.swift`
**Проблема:** После нажатия "Create Hero" — белый/пустой экран пока API отвечает.
**План:**
- В `OnboardingViewModel`: уже есть `isCreating: Bool` (строка ~298)
- В `NameStepView`: добавить overlay при `vm.isCreating == true`:
  - Full-screen overlay: `DarkFantasyTheme.bgAbyss.opacity(0.85)`
  - Центр: VStack с animated sword/shield icon + "Forging your hero..." text
  - Анимация: opacity pulse на иконке (0.4 → 1.0, repeatForever)
  - Можно добавить progress dots "..." анимацию
- Стиль: ornamental frame вокруг loading card (RadialGlowBackground + brackets)
- Блокировать navigation back и повторное нажатие кнопки
**Оценка:** M (25 мин)

### 10. NameStepView stat display — redesign с иконками
**Файл:** `NameStepView.swift` (~строки 125-134)
**Проблема:** Stat bonuses показаны как простой HStack текста "+N stat". Нужны иконки в ячейках, полные названия.
**План:**
- **Иконки доступны:** `icon-strength`, `icon-agility`, `icon-vitality`, `icon-endurance`, `icon-intelligence`, `icon-wisdom`, `icon-luck`, `icon-charisma`
- Заменить текстовый HStack на grid/LazyVGrid (2 columns, 4 rows) или compact HStack with icons
- Каждая ячейка: `Image(stat.iconAsset)` 20×20 + `"+N"` text + stat name (полное: "Strength", не "STR")
- Стиль ячейки: mini panel с `DarkFantasyTheme.bgTertiary` background, rounded corners (`radiusSM`), gold border если bonus > 0
- Цвет текста: `statBoosted` для positive bonuses
- Layout: 2×4 grid (compact) или scrollable HStack если места мало
- Нужно: найти откуда берутся stat bonuses (вероятно из class definition)
**Оценка:** M (30 мин)

---

## ГРУППА C — Большие задачи (45-90 мин)

### 11. First Win bonus redesign
**Файл:** `HubView.swift` (строки 621-677, `FirstWinBonusCard`)
**Проблема:** Карточка уже ornamental, но нужно показать конкретные XP + gold amounts с иконками.
**План:**
- Текущая карточка: icon + "Win a PvP match for ×2 Gold & ×2 XP" текст
- **Redesign layout:**
  - Убрать chevron, сделать более визуально мотивирующим
  - Центральная строка: два "reward pill" блока:
    - `[icon-gold] ×2 Gold` (gold tinted)
    - `[icon-xp] ×2 XP` (accent tinted)
  - Если доступны конкретные числа (base reward × 2) — показать их: `"300 Gold"`, `"240 XP"`
  - Нужно проверить: знает ли клиент base PvP rewards (из `GOLD_REWARDS.PVP_WIN_BASE` / `XP_REWARDS.PVP_WIN_XP`)
    - Да: `balance.ts` — `PVP_WIN_BASE: 150`, `PVP_WIN_XP: 120` → показать `"300 Gold + 240 XP"`
    - Или: показать множитель `"×2"` с иконками
- Сохранить: ornamental styling (уже полный), shimmer, glowPulse, tap → arena
- Добавить: reward pills как в BattlePass/DailyLogin стиле
- Тема: `.gold` accent вместо `.success` (convention: gold for rewards)
**Оценка:** M (30 мин)

### 12. Dungeon info panel redesign — boss avatars + lore
**Файл:** `DungeonInfoSheet.swift` + `DungeonSelectDetailView.swift`
**Проблема:** Info panel скучный, нужны boss avatars и lore text.
**План:**
- **Данные доступны:** `BossInfo` struct имеет `portraitImage`, `name`, `level`, `description` (lore)
- **Новый layout для DungeonInfoSheet:**
  - Header: dungeon name + level range + theme color gradient
  - Boss list: VStack/LazyVStack с boss cards:
    - Каждый boss: `HStack { portrait (48×48, clipped circle) + VStack { name, level, lore (2 lines) } + state badge }`
    - Defeated: grayscale portrait + checkmark
    - Current: gold border + "CURRENT" badge + full color
    - Locked: dimmed + lock icon
  - Footer: total rewards summary, stamina cost
- Стиль: standard modal pattern (RadialGlowBackground + surfaceLighting + innerBorder + brackets)
- Ornamental dividers between bosses (EtchedGroove or GoldDivider)
**Оценка:** L (60 мин)

### 13. Dungeon boss cards carousel
**Файл:** `DungeonSelectDetailView.swift` (новая секция) или `DungeonRoomDetailView.swift` (уже есть TabView carousel!)
**Проблема:** Нужен horizontal swipeable carousel боссов (как hero cards), auto-scroll к текущему, tap → detail modal.
**План:**
- **ВАЖНО:** В `DungeonRoomDetailView` уже есть boss carousel (TabView, строки 355-499)! Но это внутри активного dungeon run.
- Для `DungeonSelectDetailView` нужен **preview carousel** на странице выбора данжа:
  - При тапе на dungeon card → показать carousel его боссов
  - Или: встроить mini-carousel внутрь expanded card
- **Carousel implementation:**
  - `TabView(selection: $currentBossIndex)` + `.tabViewStyle(.page(indexDisplayMode: .automatic))`
  - Каждая карточка: boss portrait (полный art из `fullImage`) + name + level + state badge
  - Auto-scroll: `.onAppear { currentBossIndex = firstUndefeatedIndex }`
  - Tap: `.sheet(item: $selectedBoss)` → detail modal
- **Detail modal:**
  - Boss full art (top 40% of sheet)
  - Stats comparison: Player vs Boss (side-by-side bars)
    - HP, Attack, Defense, Level
  - Loot drops: horizontal scroll of `ItemCardView(.loot)` cards
  - "FIGHT" button (if current boss + has stamina)
- Стиль: standard modal pattern, boss border matches state color
- Нужно проверить: есть ли boss stats в `BossInfo` (HP есть, attack/defense — возможно нет, нужно добавить или показать только level + HP)
**Оценка:** XL (120 мин) — это самая большая задача

---

## ГРУППА D — Ещё не ясно / нужно уточнить

### 14. Dungeon info panel vs boss carousel overlap
Задачи 12 и 13 частично пересекаются. Предлагаю объединить:
- **DungeonInfoSheet** → показывает boss carousel + lore + stats
- **Boss detail modal** → отдельный sheet при тапе на boss card в carousel

---

## Рекомендуемый порядок реализации

### Wave 1 — Quick Wins (30 мин total)
| # | Задача | Файлы | Оценка |
|---|--------|-------|--------|
| 1 | Dice button speed | NameStepView | S |
| 3 | Remove "Inventory" label | HeroDetailView | S |
| 4 | Stat banner green → gold | HeroDetailView | S |
| 5 | Bigger stat numbers | HeroDetailView | S |
| 2 | Lower hub labels | CityBuildingLabel/View | S |

### Wave 2 — Medium Tasks (90 мин total)
| # | Задача | Файлы | Оценка |
|---|--------|-------|--------|
| 6 | Hub z-order fix | CityMapView, CityBuildingView | M |
| 8 | Pulsing STATUS badge | HeroDetailView | M |
| 9 | Hero creation preloader | NameStepView, OnboardingVM | M |
| 10 | Stat display with icons | NameStepView | M |

### Wave 3 — Big Features (180+ мин total)
| # | Задача | Файлы | Оценка |
|---|--------|-------|--------|
| 11 | First Win bonus redesign | HubView | M |
| 7 | Dungeon select badge | CityMapView, DungeonSelectVM | M |
| 12 | Dungeon info panel | DungeonInfoSheet | L |
| 13 | Boss carousel + modal | DungeonSelectDetailView | XL |

---

## Зависимости

```
(нет зависимостей)    → 1, 2, 3, 4, 5, 8
6 (z-order) → 2 (lower labels) — лучше делать вместе
10 (stat icons) → знать StatType.iconAsset mapping
12 + 13 (dungeon redesign) → лучше планировать вместе, есть overlap
11 (first win) → нужно решить: показывать конкретные числа или множители
```

## Риски

| Задача | Риск | Митигация |
|--------|------|-----------|
| 6 (z-order) | `.drawingGroup()` может конфликтовать с zIndex | Вынести labels из drawingGroup scope |
| 13 (carousel) | Boss stats (attack/defense) могут отсутствовать в модели | Показать HP + level, без attack/defense |
| 13 (carousel) | TabView в TabView (page style) может глючить | Использовать ScrollView + snapping вместо вложенного TabView |
| 7 (dungeon badge) | Dungeon progress может не быть в GameDataCache | Добавить cache метод или вычислять из existing data |

---

## Итого

- **5 задач S** (~30 мин) — можно сделать за один проход
- **5 задач M** (~100 мин) — по одной за раз
- **1 задача L** (~60 мин) — dungeon info redesign
- **1 задача XL** (~120 мин) — boss carousel + detail modal
- **Total estimate: ~5-6 часов работы**
