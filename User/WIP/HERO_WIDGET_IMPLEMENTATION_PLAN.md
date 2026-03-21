# Unified Hero Widget — Implementation Plan

*Status: ready for implementation · 0 code changes made*

---

## Phase 0: Design System Tokens (Prerequisite)

Прежде чем трогать любой View — обновить токены. Иначе новый компонент будет ссылаться на несуществующие значения.

### 0.1 LayoutConstants.swift — добавить новую секцию

```
// MARK: - Unified Hero Widget
static let widgetPadding: CGFloat = 12         // vertical
static let widgetPaddingH: CGFloat = 16        // horizontal
static let widgetRadius: CGFloat = 12          // card radius (was 14 in old card)
static let widgetMinHeight: CGFloat = 80       // 10×8 grid
static let widgetGap: CGFloat = 12             // gap between avatar, center, right
static let widgetRowGap: CGFloat = 4           // gap between row-1, row-2, row-3

// Pill System
static let pillHeight: CGFloat = 32            // dense control minimum (Rulebook §2.5)
static let pillRadius: CGFloat = 8             // radius-md
static let pillPaddingH: CGFloat = 12          // horizontal padding
static let pillIconSize: CGFloat = 12          // icon-xs
static let pillGap: CGFloat = 4               // internal gap
static let pillFont: CGFloat = 12             // minimum font (was 11 in badges)

// Widget Avatar
static let widgetAvatarSize: CGFloat = 48      // matches touchMin
static let widgetAvatarRadius: CGFloat = 8     // rounded square
static let widgetXpRingInset: CGFloat = 4      // offset from avatar edge
static let widgetXpRingWidth: CGFloat = 3      // stroke width
static let widgetLevelBadgeFont: CGFloat = 11  // matches textBadge
```

### 0.2 DarkFantasyTheme.swift — добавить pill цвета

```
// MARK: - Pill System Colors
static let pillHealBg = Color(hex: 0x2ECC71).opacity(0.12)
static let pillHealBorder = Color(hex: 0x2ECC71).opacity(0.25)
static let pillHealText = textStatusGood

static let pillUrgentBg = Color(hex: 0xE63946).opacity(0.12)
static let pillUrgentBorder = Color(hex: 0xE63946).opacity(0.3)
static let pillUrgentText = textDanger

static let pillEnergyBg = Color(hex: 0xE67E22).opacity(0.12)
static let pillEnergyBorder = Color(hex: 0xE67E22).opacity(0.25)
static let pillEnergyText = stamina

static let pillStatBg = Color(hex: 0xD4A537).opacity(0.12)
static let pillStatBorder = Color(hex: 0xD4A537).opacity(0.3)
static let pillStatText = goldBright

static let pillWarnBg = Color(hex: 0xE63946).opacity(0.1)
static let pillWarnBorder = Color(hex: 0xE63946).opacity(0.2)
static let pillWarnText = textDanger

static let pillPvpBg = Color(hex: 0xD4A537).opacity(0.08)
static let pillPvpBorder = Color(hex: 0xD4A537).opacity(0.15)

static let pillStreakBg = Color(hex: 0xE63946).opacity(0.08)
static let pillStreakBorder = Color(hex: 0xE63946).opacity(0.15)

static let pillBonusBg = Color(hex: 0x2ECC71).opacity(0.1)
static let pillBonusBorder = Color(hex: 0x2ECC71).opacity(0.2)

static let pillErrorBg = Color(hex: 0xE63946).opacity(0.1)
static let pillErrorBorder = Color(hex: 0xE63946).opacity(0.2)

static let pillOfflineBg = Color.white.opacity(0.04)
static let pillOfflineBorder = Color.white.opacity(0.08)
static let pillOfflineText = textSecondary

// Fixed tertiary for WCAG AA compliance
static let textTertiaryAA = Color(hex: 0x8A8AA0) // ≥4.5:1 on dark bg
```

**Важно:** `textTertiary` (#6B6B80) не менять глобально — это сломает UI в местах где контраст не критичен (decorative elements). Новый `textTertiaryAA` использовать только в widget и pills где текст несёт функциональный смысл.

### 0.3 Файлы, которые НЕ нужно менять в Phase 0

- `ButtonStyles.swift` — pill это НЕ Button, это свой компонент
- Enums, Models — без изменений

**Коммит:** `feat(design-system): add unified hero widget tokens and pill colors`

---

## Phase 1: Создание UnifiedHeroWidget.swift

### 1.1 Новый файл

```
Hexbound/Hexbound/Views/Components/UnifiedHeroWidget.swift
```

### 1.2 Структура компонента

```swift
struct UnifiedHeroWidget: View {
    let character: Character
    let context: WidgetContext
    var onTap: (() -> Void)?
    var onUsePotion: (() -> Void)?
    var onUseStaminaPotion: (() -> Void)?
    var onAllocateStats: (() -> Void)?

    enum WidgetContext {
        case hub
        case arena(rating: Int, rank: PvPRank, firstWinAvailable: Bool, winStreak: Int)
        case dungeon
        case hero
    }
}
```

### 1.3 Internal Views

```
UnifiedHeroWidget
├── avatarSection
│   ├── AvatarImageView (48×48, borderRadius 8)
│   ├── XPRingShape (SVG path → SwiftUI Shape)
│   └── LevelBadge
├── centerColumn
│   ├── Row 1: name + classLabel
│   ├── Row 2: HPBarView (compact, 8pt)
│   └── Row 3: actionRow (pills)
└── rightColumn
    ├── staminaInline
    ├── goldCurrency
    └── gemsCurrency (conditional)
```

### 1.4 Pill Sub-Component

```swift
struct WidgetPill: View {
    let icon: String
    let text: String
    var count: String? = nil
    let style: PillStyle
    var isInteractive: Bool = false
    var action: (() -> Void)? = nil

    enum PillStyle {
        case heal, urgent, energy, stat, warn, pvp, streak, bonus, error, offline
    }
}
```

### 1.5 XP Ring Shape

Нужен кастомный `Shape` для SwiftUI, реплицирующий SVG path из прототипа:
- Rounded rectangle path, starting from top-center
- `trimFrom/to` для анимации заполнения (вместо stroke-dasharray)
- SwiftUI нативно поддерживает `.trim(from:to:)` на Shape

### 1.6 Action Row Logic (Row 3)

Приоритет (сверху вниз, первый match побеждает):

```
1. Critical HP + hasHealthPotion → pill-urgent "Heal Now! ×N"
2. Critical HP + no potion       → pill-warn "Critical — No Potions"
3. Low HP + hasHealthPotion      → pill-heal "Heal ×N"
4. Low stamina + hasStamPotion   → pill-energy "Restore ×N"
5. statPoints > 0                → pill-stat "+N Points → Allocate"
6. brokenGearCount > 0           → pill-warn "Broken"  (can combine with #5)
7. context == .arena             → pill-pvp + pill-streak + pill-bonus
8. error state                   → pill-error "Tap to retry"
9. offline state                 → pill-offline "Offline · Cached"
10. default                      → XP bar (thin progress)
```

Множественные pills: max 3, priorities 5+6 сочетаются, arena pills сочетаются.

### 1.7 Data Dependencies

Widget нуждается в данных которые уже есть в `AppState`:

| Data | Source | Already available? |
|------|--------|--------------------|
| Character model | `appState.currentCharacter` | ✅ |
| Health potion count | `appState.cachedInventory` filtered | ✅ (logic in HubCharacterCard) |
| Stamina potion count | `appState.cachedInventory` filtered | ✅ (same filter, different type) |
| Broken gear flag | `appState.cachedInventory` filtered by durability=0 | ⚠️ Need to add |
| PvP data | `character.pvpRating`, `.pvpWins`, etc. | ✅ |
| First win | `character.firstWinToday` | ✅ |
| Win streak | `character.pvpWinStreak` | ✅ |
| Error/offline state | Network status | ⚠️ Need to pass as param or observe |

**Broken gear check** — нужно добавить computed property:
```swift
// In AppState or as helper
var hasBrokenGear: Bool {
    cachedInventory?.contains { $0.durability == 0 && $0.isEquipped } ?? false
}
```

**Коммит:** `feat(widget): create UnifiedHeroWidget with pill system`

**Xcode project.pbxproj:** Добавить `UnifiedHeroWidget.swift` в 4 секции (PBXBuildFile, PBXFileReference, PBXGroup children в Components, PBXSourcesBuildPhase).

---

## Phase 2: Интеграция на Hub

### 2.1 HubView.swift — Изменения

**Удалить:**
- `StaminaBarView` из top HUD area
- `HubCharacterCardWrapper(character: char)` call

**Заменить на:**
```swift
UnifiedHeroWidget(
    character: char,
    context: .hub,
    onTap: { appState.selectedTab = .hero },
    onUsePotion: { await useHealthPotion() },
    onUseStaminaPotion: { await useStaminaPotion() },
    onAllocateStats: { appState.selectedTab = .hero; /* navigate to stat allocation */ }
)
```

### 2.2 Что убирается с Hub

| Элемент | Текущее место | Действие |
|---------|---------------|----------|
| `StaminaBarView` + обёртка кнопки | Top of HubView | Удалить — stamina теперь внутри widget |
| `HubCharacterCardWrapper` | Below stamina bar | Заменить на `UnifiedHeroWidget` |
| Логика useHealthPotion | В HubCharacterCardWrapper | Перенести в HubView (callback) |

### 2.3 FirstWinBonusCard

**Оставить как есть.** Это отдельный actionable CTA, не часть hero identity widget.

**Коммит:** `refactor(hub): replace StaminaBarView + HubCharacterCardWrapper with UnifiedHeroWidget`

---

## Phase 3: Интеграция на Arena

### 3.1 ArenaDetailView.swift — Изменения

**Удалить:**
- `staminaBar(vm)` helper и его вызов
- Отдельный rating/record header panel (если есть как inline)
- `HubCharacterCardWrapper(character: char)` call

**Заменить на:**
```swift
UnifiedHeroWidget(
    character: char,
    context: .arena(
        rating: char.pvpRating,
        rank: PvPRank.fromRating(char.pvpRating),
        firstWinAvailable: !(char.firstWinToday ?? true),
        winStreak: char.pvpWinStreak ?? 0
    ),
    onTap: { appState.selectedTab = .hero },
    onUsePotion: { await useHealthPotion() }
)
```

### 3.2 Что убирается с Arena

| Элемент | Действие |
|---------|----------|
| Stamina bar в header | Удалить — в widget |
| Rating / Record / Rank inline panel | Удалить — в widget pill-pvp |
| HubCharacterCardWrapper | Заменить на UnifiedHeroWidget |

**Gems скрыты** — context .arena не показывает gems.

**Коммит:** `refactor(arena): replace stamina bar + rating header + character card with UnifiedHeroWidget`

---

## Phase 4: Интеграция на Dungeon

### 4.1 DungeonRoomDetailView.swift — Изменения

**Удалить:**
- `compactHeroWidget` ViewBuilder
- Direct `HubCharacterCard(character: char, showChevron: false)` usage

**Заменить на:**
```swift
UnifiedHeroWidget(
    character: char,
    context: .dungeon,
    onUsePotion: { await useHealthPotion() },
    onUseStaminaPotion: { await useStaminaPotion() }
)
```

### 4.2 Dungeon-specific: minimal variant

Context `.dungeon` скрывает:
- Row 3 (XP bar) в default state — показывает pills только при warnings
- Gems
- Class label

**Коммит:** `refactor(dungeon): replace compactHeroWidget with UnifiedHeroWidget`

---

## Phase 5: Интеграция на Hero

### 5.1 HeroDetailView.swift — Изменения

**Удалить:**
- `heroHeader` ViewBuilder (inline name + class + origin + level + XP bar)
- Портрет в центре equipment grid

**Заменить header на:**
```swift
UnifiedHeroWidget(
    character: char,
    context: .hero,
    onAllocateStats: { /* scroll to stat allocation section */ }
)
```

### 5.2 Equipment Grid Refactor

Сейчас: equipment grid 3×4 с портретом в центре.
После: equipment grid 3×4 чистый (портрет в widget сверху).

Это **не обязательно** для Phase 5 — можно оставить grid как есть и просто заменить header. Портрет в grid и портрет в widget будут дублироваться, но это minor. Можно адресовать позже.

**Коммит:** `refactor(hero): replace heroHeader with UnifiedHeroWidget`

---

## Phase 6: Cleanup

### 6.1 Файлы для удаления

| Файл | Причина |
|------|---------|
| `HubCharacterCard.swift` | Полностью заменён UnifiedHeroWidget |
| Wrapper код в `HubView.swift` (HubCharacterCardWrapper struct) | Логика перенесена в callbacks |

### 6.2 Файлы для сохранения

| Файл | Причина |
|------|---------|
| `AvatarImageView.swift` | Используется в UnifiedHeroWidget И в других местах (Combat, Opponents, Leaderboard) |
| `HPBarView.swift` | Используется в UnifiedHeroWidget И в Combat |
| `StaminaBarView.swift` | **Может быть удалён** если больше нигде не используется. Проверить: используется ли в HeroDetailView. Если нет — удалить. |
| `CurrencyDisplay.swift` | Используется в Shop — оставить |

### 6.3 Xcode project.pbxproj

- **Удалить** записи HubCharacterCard.swift из всех 4 секций
- **Удалить** StaminaBarView.swift если подтверждено что не используется
- Entries для UnifiedHeroWidget.swift уже добавлены в Phase 1

### 6.4 Обновить docs

- `docs/07_ui_ux/SCREEN_INVENTORY.md` — обновить widget описание
- `docs/07_ui_ux/DESIGN_SYSTEM.md` — добавить pill system tokens
- `CLAUDE.md` — добавить правило: "Always use UnifiedHeroWidget for character summary, never create inline character displays"

**Коммит:** `cleanup: remove deprecated HubCharacterCard + StaminaBarView, update docs`

---

## Dependency Graph (порядок выполнения)

```
Phase 0 ──→ Phase 1 ──→ Phase 2 ──→ Phase 3
  tokens      widget     hub          arena
                │
                ├──→ Phase 4 (dungeon, parallel с 3)
                │
                └──→ Phase 5 (hero, parallel с 3-4)
                          │
                          └──→ Phase 6 (cleanup, after all)
```

Phases 2-5 можно делать **в любом порядке** после Phase 1. Но рекомендуется Hub first (основной экран, highest traffic).

---

## Риски и митигация

| Риск | Severity | Митигация |
|------|----------|-----------|
| **Xcode project.pbxproj merge conflict** | 🔴 High | Делать Phase 1 и Phase 6 в одной сессии. Генерировать уникальные 24-char hex IDs. |
| **Potion use callback architecture** | 🟡 Medium | Сейчас логика в HubCharacterCardWrapper. Нужно перенести в каждый экран как callback. Или создать shared `PotionUseHelper`. |
| **Broken gear computed property** | 🟢 Low | Простое добавление в AppState. Данные уже есть в cachedInventory. |
| **XP ring SwiftUI Shape** | 🟡 Medium | SVG path → SwiftUI `.path(in:)`. Нужно пересчитать координаты для SwiftUI coordinate system. Или использовать `.trim(from:to:)` на `RoundedRectangle`. |
| **Arena rating panel migration** | 🟡 Medium | Текущий rating panel может содержать данные которые не в Character model (W/L record). Проверить что pvpWins/pvpLosses доступны. |
| **Hero equipment grid без портрета** | 🟢 Low | Можно оставить портрет в grid и widget одновременно. Не blocker. |
| **Stamina regen countdown** | 🟡 Medium | StaminaBarView имеет optional countdown text. UnifiedHeroWidget показывает только число. Countdown можно показать в tooltip или убрать (не critical info). |

---

## Estimated Effort

| Phase | Files Changed | Lines ~Changed | Effort |
|-------|---------------|----------------|--------|
| 0. Tokens | 2 | +40 | 15 min |
| 1. Widget | 1 new + pbxproj | ~300 new | 1-2 hrs |
| 2. Hub | 1 | -80, +15 | 30 min |
| 3. Arena | 1 | -60, +20 | 30 min |
| 4. Dungeon | 1 | -30, +10 | 15 min |
| 5. Hero | 1 | -40, +10 | 30 min |
| 6. Cleanup | 3-4 + pbxproj + docs | -200 | 30 min |
| **Total** | **~10 files** | **net -150 lines** | **~4 hrs** |

Проект становится **на 150 строк короче** при добавлении одного 300-строчного компонента и удалении ~450 строк дублирования.

---

## Checklist перед каждым коммитом

- [ ] Xcode build succeeds (`Cmd+B`)
- [ ] Widget renders correctly on iPhone 15 Pro simulator
- [ ] All 11 states from V3 prototype work
- [ ] Action pills trigger correct callbacks
- [ ] HP bar gradient matches `canonicalHpGradient()`
- [ ] XP ring animates smoothly
- [ ] Level badge positioned correctly on square avatar
- [ ] All text ≥ 12px (except level badge = 11px)
- [ ] All contrast ≥ 4.5:1 for text
- [ ] No hardcoded colors — all from DarkFantasyTheme
- [ ] No hardcoded sizes — all from LayoutConstants
- [ ] pbxproj updated if new file created or old file deleted
