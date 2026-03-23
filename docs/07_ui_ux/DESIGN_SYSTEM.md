# HEXBOUND — Система дизайна (Design System)

**Версия:** 2.1.0
**Статус:** Production-ready (v2.1 — Structural Rebranding)
**Дата:** 22 марта 2026
**Платформа:** iOS SwiftUI (Portrait, 1170×2532)
**Язык:** Русский + технические термины на английском

---

## 1. Заголовок и метаданные

Этот документ является **КАНОНИЧЕСКИМ источником истины** для всех UI/UX решений в Hexbound.

- **Приложение:** Hexbound Mobile PvP RPG (Dark Fantasy Premium)
- **Целевая аудитория:** iOS players 16+, portrait orientation, touch-first interaction
- **Экраны:** 38+
- **Компоненты переиспользования:** 17+
- **Токены дизайна:** 200+ (colors, spacing, typography)
- **Баттон стили:** 20
- **Карточек стили:** 5 + 2 dividers

Этот документ заменяет все предыдущие версии и становит новый стандарт качества.

---

## 2. Философия продукового UI

### 2.1 Dark Fantasy Premium

Hexbound стремится к **мрачной красоте**:
- **Палитра:** Чёрные, тёмно-синие и фиолетовые поверхности с золотыми и оранжевыми акцентами
- **Ощущение:** Премиум, мистическое, опасное
- **Эффект:** Тёмный UI создаёт контраст с яркими боевыми эффектами и наградами
- **Психология:** Тёмнота = власть, золото = драгоценность, красный = опасность

### 2.2 Правило трёх секунд (3-Second Rule)

Игрок должен понять **суть экрана за 3 секунды**:
1. Что я смотрю? (Название, цель)
2. Что я могу сделать? (Кнопки, интерактивные элементы)
3. Почему я должен это делать? (Награда, прогресс, опасность)

Если ответ требует скролла — экран неудачен.

### 2.3 Одна цель на экран

Каждый экран имеет **одну основную кнопку действия** (Primary button):
- Browse gear → **Equip**
- View arena battle → **Fight**
- Check quest → **Accept** or **Claim**

Вторичные действия скрыты в меню или требуют свайпа.

### 2.4 Нет мёртвых концов (No Dead Ends)

Каждый экран имеет **явный выход**:
- Close button (32×32, bgTertiary)
- Back navigation
- Иногда только Back и Primary action на весь экран

### 2.5 Ясность превыше украшений (Clarity over Decoration)

- **Орнамент используется экономно:** Только на Primary buttons, modals, важных границах
- **Гляциальные эффекты (glow):** Только для активных состояний, rare items, rewards
- **Шрифт:** Oswald для заголовков (UPPERCASE), Inter для тела
- **Иконки:** Только SF Symbols или asset icons, никогда не смешивать emoji в UI

### 2.6 Награды должны ощущаться наградами

- **Reveal timing:** 0.6s intro, hold 1.2s, 0.4s outro
- **Sound:** Victory chime на LevelUp, казино-звук на RankUp
- **Particulate:** Золотая анимация при получении редкого выпада
- **Цвет:** Никогда не используй одинаковый цвет для обычного и редкого товара

### 2.7 Сравнение должно быть мгновенным (Comparison Must Be Instant)

В снаряжении, статах, ранках: **старое рядом с новым**:
```
┌─────────────┐ ┌─────────────┐
│ Current: 15 │ │ New:    20+ │
│ STR         │ │ STR     ↑   │
└─────────────┘ └─────────────┘
```

Никогда не скрывай текущее значение позади модального.

### 2.8 Игровое ощущение VS Юзабилити

- **Боевые экраны:** +40% визуальных эффектов, -10% текста, максимум скорость
- **Хаб (Hub):** -20% эффектов, +60% текста, максимум ясность
- **Экраны инвентаря:** Баланс: быстрый скан + уверенность в выборе

---

## 3. Фундаментальные принципы

### 3.1 Мобильный RPG UX

#### Зоны касания (Touch Zones)
- **Основная зона:** Bottom 40% экрана (большие пальцы)
- **Вторичная:** Top 30% (один палец)
- **Недостижимая:** Выше 90pt от top safe area без скролла
- **Apple HIG стандарт:** Минимум 44pt × 44pt, удобно — 56pt × 56pt

#### Когнитивный бюджет (Cognitive Load)
- **Одновременно видимые элементы:** Max 7 (±2)
- **Цветов на экране:** Max 5 (bg + text + accent + feedback + border)
- **Действий без скролла:** Max 3 (Primary + Secondary + Close)

#### Сессионность (Session Length)
- **Боевая сессия:** 2–8 минут (краткость = удовлетворение)
- **Хаб сессия:** 30–60 секунд (быстрый старт боя)
- **Shop/Inventory:** 3–5 минут (долгий выбор ОК)

### 3.2 Правила читаемости (Readability Rules)

1. **Минимальный размер текста:** 16pt (и это ОБЯЗАТЕЛЬНО после рефакторинга)
   - Текущее нарушение: боевой HP 7–8pt ❌ → Должно быть 18pt minimum
   - Подписи: 16pt (было 12pt) ✓

2. **Контрастность (WCAG AA):**
   - textPrimary (#F5F5F5) на bgPrimary (#0D0D12) = 18:1 ✓
   - textSecondary (#A0A0B0) на bgPrimary = 10:1 ✓
   - gold (#D4A537) на bgPrimary = 4.2:1 (marginal, только для акцентов)
   - **Правило:** Никогда не используй gold на чёрный для основного текста

3. **Иерархия текста:**
   ```
   SCREEN TITLE (28pt Oswald, textPrimary, UPPERCASE)

   Section header (22pt Oswald, textPrimary, UPPERCASE)

   Card subtitle (16pt Inter, textSecondary)
   Body text (16pt Inter, textPrimary)
   Caption / Badge (16pt Inter, textMuted)
   ```

4. **Разбиение на строки:**
   - Max 35–45 символов на строку (для Inter 16pt на iPhone 12)
   - Label truncation → ellipsis (...) в конце
   - Item names → никогда не обрезай, используй scrolling text или smaller font

### 3.3 Правила иерархии (Hierarchy Rules)

**Глубина视覼:**
1. **Screen BG:** bgPrimary (#0D0D12) — самый дальний слой
2. **Section containers:** bgSecondary (#1A1A2E) или bgTertiary (#16213E)
3. **Cards:** bgSecondary + border (borderSubtle #2A2A3E)
4. **Interactive elements:** bgTertiary + highlight
5. **Overlays/Modals:** bgModal (black@75%) + bgSecondary modal content
6. **Toasts/Notifications:** bgSecondary + shadow, top z-index

**Размер как иерархия:**
- Primary action button = 56pt (biggest)
- Secondary buttons = 48pt
- Icon buttons = 32pt–48pt (зависит от контекста)
- Close button = 32pt

### 3.4 Правила консистентности (Consistency Rules)

1. **Все цвета из DarkFantasyTheme:**
   - Никогда: `Color(red: 0.8, green: 0.2, blue: 0.2)`
   - Всегда: `.danger` или `.hpRed`

2. **Все шрифты из Font extensions:**
   - Никогда: `.font(.system(size: 16))`
   - Всегда: `.font(.body16)` или `.font(.heading28)`

3. **Все отступы из LayoutConstants:**
   - Никогда: `Spacer().frame(height: 12)`
   - Всегда: `Spacer().frame(height: .MS)` или `.padding(.MD)`

4. **Все кнопки с .buttonStyle():**
   - Никогда: VStack { Button { ... } }
   - Всегда: Button { ... }.buttonStyle(.primary)

5. **Все карточки с CardStyle:**
   - Никегда: RoundedRectangle + shadow + padding
   - Всегда: ZStack { content }.panelCard()

### 3.5 Правила визуальной интенсивности (Visual Intensity Rules)

**Когда МОЖНО использовать glow:**
- ✓ Active ability button (combat mode)
- ✓ Rare+ item border (rarity system)
- ✓ Boss encounter UI (dungeon)
- ✓ Level-up toast animation
- ✓ Equipment equipped (equipped status indicator)

**Когда НЕЛЬЗЯ использовать glow:**
- ✗ Background surfaces (noise)
- ✗ Body text (readability destruction)
- ✗ Buttons в hub (focus/priority confusion)
- ✗ Disabled elements (contrast ratio violation)

**Правило частоты мерцания:**
- Max 1 animated element per screen at rest
- Combat = исключение (2–3 animated elements ОК)
- Частота пульса: 1–2 Hz (не выше, ведь это может спровоцировать фоточувствительность)

---

## 4. Архитектура токенов (Token Architecture)

### 4.1 Цвета — Поверхности (Surface Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.bgAbyss` | #08080C | Ограничено: системные фоны, очень редко |
| `.bgPrimary` | #0D0D12 | Screen background, основной фон всех экранов |
| `.bgSecondary` | #1A1A2E | Card background, modal content, sections |
| `.bgTertiary` | #16213E | Button background (neutral), hover states |
| `.bgElevated` | #1E2240 | Top-level surfaces: bottom sheets, popovers |
| `.bgCard` | = bgSecondary | Alias для clarity в card components |
| `.bgDark` | = bgPrimary | Alias |
| `.bgModal` | black@75% | Modal overlay (полупрозрачный чёрный) |
| `.bgBackdrop` | black@85% | Darkest overlay (loading, blocking) |
| `.bgBackdropLight` | black@70% | Medium overlay (non-blocking dialogs) |
| `.bgScrim` | black@50% | Light overlay (subtle darkening) |
| `.bgDisabled` | #333340 | Disabled element backgrounds |

### 4.2 Цвета — Золотая система (Gold Accent)

| Токен | Hex | Использование |
|-------|-----|---|
| `.gold` | #D4A537 | Primary action buttons, icons, premium indicators |
| `.goldBright` | #FFD700 | Bright highlights, treasure, "just earned" state |
| `.goldDim` | #8B6914 | Ornamental dividers, subtle borders |
| `.goldGlow` | #F39C12@40% | Glow effects на gold elements |
| `.glowOrange` | #F39C12 | Fight button gradient (orange part), fire effects |

**Практика:**
- Button background = `.gold`
- Button border = `.goldDim`
- Glow effect = `.goldGlow`
- Text на gold = `.textOnGold` (#1A1A2E, DARK)

### 4.3 Цвета — Обратная связь (Feedback Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.danger` | #E63946 | Danger buttons, HP depletion, errors |
| `.dangerGlow` | #E63946@25% | Glow effect around dangerous actions |
| `.success` | #2ECC71 | Quest completion, buff applied, positive action |
| `.successGlow` | #2ECC71@25% | Success toast glow |
| `.info` | #3498DB | Informational messages, ability descriptions |
| `.cyan` | #00D4FF | Gem resource, mana, special effects |
| `.purple` | #9B59B6 | Magic effects, rarity indicator |
| `.hpRed` | = danger | Explicit HP bar color |
| `.hpBlood` | #C41E3A | Critical HP (< 25%) |
| `.stamina` | #E67E22 | Stamina bar, stamina resource |

### 4.4 Цвета — Текст (Text Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.textPrimary` | #F5F5F5 | Основной текст, заголовки, high contrast |
| `.textSecondary` | #A0A0B0 | Подписи, secondary headings, medium contrast |
| `.textTertiary` | #6B6B80 | Captions, disabled labels, low contrast |
| `.textMuted` | = textTertiary | Alias для clarity |
| `.textTertiaryAA` | #8A8AA0 | Slightly brighter tertiary (для WCAG AA) |
| `.textDisabled` | #555566 | Disabled text (очень низкий контраст, только для явно disabled) |
| `.textGold` | #FFD700 | Premium labels, special content |
| `.textOnGold` | #1A1A2E | Text на золотом фоне (DARK для контраста) |
| `.textDanger` | #FF6B6B | Error messages, critical alerts |
| `.textSuccess` | #5DECA5 | Success messages, positive feedback |

### 4.5 Цвета — Границы (Border Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.borderSubtle` | #2A2A3E | Default card border, dividers, low emphasis |
| `.borderMedium` | #3A3A50 | Interactive element borders, focused state |
| `.borderStrong` | #4A4A60 | High emphasis, decoration, ornamental |
| `.borderGold` | = gold | Gold-accented borders (rare items, premium) |
| `.borderOrnament` | #B8860B | Ornamental borders, special cards |
| `.borderDefault` | = borderSubtle | Alias |

### 4.6 Цвета — Редкость (Rarity Colors)

| Токен | Hex | Гляциальный | Использование |
|-------|-----|---|---|
| `.rarityCommon` | #999999 | `.rarityCommonGlow` @13% | Common items, neutral equipment |
| `.rarityUncommon` | #4DCC4D | `.rarityUncommonGlow` @13% | Uncommon drops |
| `.rarityRare` | #4D80FF | `.rarityRareGlow` @20% | Rare equipment, blue rarity |
| `.rarityEpic` | #A64DE6 | `.rarityEpicGlow` @25% | Epic items, purple |
| `.rarityLegendary` | #FFBF1A | `.rarityLegendaryGlow` @38% | Legendary items, maximum glow |

**Практика:** Используй rarity color как border для item cards:
```swift
.border(theme.rarityRare, width: 2)
    .shadow(color: theme.rarityRareGlow, radius: 12)
```

### 4.7 Цвета — Статы (Stat Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.statSTR` | #E6594D | Strength/Attack stat |
| `.statAGI` | #4DE666 | Agility/Speed stat |
| `.statVIT` | #E68080 | Vitality/Health stat |
| `.statEND` | #B3B34D | Endurance/Stamina stat |
| `.statINT` | #6680FF | Intelligence/Magic stat |
| `.statWIS` | #9966E6 | Wisdom/Defense stat |
| `.statLUK` | #E6D94D | Luck/Critical stat |
| `.statCHA` | #E699CC | Charisma/Social stat |

### 4.8 Цвета — Классы (Class Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.classWarrior` | #E68C33 | Warrior class indicator |
| `.classRogue` | #4DD958 | Rogue class indicator |
| `.classMage` | #6680FF | Mage class indicator |
| `.classTank` | #9999B2 | Tank class indicator |

### 4.9 Цвета — Ранги (Rank Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.rankBronze` | #B38040 | Bronze rank |
| `.rankSilver` | #BFBFCC | Silver rank |
| `.rankGold` | #FFD600 | Gold rank |
| `.rankPlatinum` | #66CCCC | Platinum rank |
| `.rankDiamond` | #99CCFF | Diamond rank |
| `.rankGrandmaster` | #FF4D4D | Grandmaster rank |

### 4.10 Цвета — Зоны стэнса (Stance Zone Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.zoneHead` | #E66666 | Stance zone: Head |
| `.zoneChest` | #6699E6 | Stance zone: Chest |
| `.zoneLegs` | #66E666 | Stance zone: Legs |

### 4.11 Цвета — Премиум (Premium Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.premiumPink` | #E5A0FF | Premium accent, special features |
| `.bgPremium` | #2A1040 | Premium section background |
| `.bgPremiumDeep` | #1A0A2E | Darkest premium background |

### 4.12 Цвета — Подземелья (Dungeon Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.bgDungeonDeep` | #0C0C18 | Deepest dungeon background |
| `.bgDungeonPurple` | #120E24 | Purple dungeon atmosphere |
| `.bgDungeonCard` | #1A1A30 | Dungeon card background |
| `.bossBorderPurple` | #6C3483 | Boss encounter border |
| `.lootGold` | #F1C40F | Treasure/loot indicator |

### 4.13 Цвета — VFX

| Токен | Hex | Использование |
|-------|-----|---|
| `.vfxPoisonGlow` | #7CFC00 | Poison effect glow (lime green) |
| `.vfxBurnGlow` | #FF6B35 | Burn effect glow (orange) |
| `.vfxStunGlow` | #FFF8DC | Stun effect glow (cornsilk, светлый) |

### 4.14 Цвета — Тосты (Toast Colors)

| Токен | Hex | Использование |
|-------|-----|---|
| `.toastAchievement` | = goldBright | Achievement unlocked toast |
| `.toastLevelUp` | #66FF66 | Level up notification |
| `.toastRankUp` | #9966FF | Rank up notification |
| `.toastQuest` | = cyan | Quest progress toast |
| `.toastReward` | = stamina | Reward claimed toast |
| `.toastInfo` | #CCCCDA | Informational toast |
| `.toastError` | = textDanger | Error toast |

### 4.15 Цвета — Пиллы (Pill/Badge System)

11 типов пиллов (pills), каждый с bg, border, text вариантом:

| Тип | BG | Border | Text | Использование |
|-----|--|----|---|---|
| Default | bgTertiary | borderSubtle | textPrimary | Standard badge |
| Gold | #2A1F0C | gold | textGold | Premium/special |
| Danger | #3D0000 | danger | textDanger | Danger badge |
| Success | #003D1F | success | textSuccess | Success badge |
| Cyan | #002640 | cyan | cyan | Gem/special badge |
| Purple | #2D0B4D | purple | purple | Magic badge |
| Info | #001F40 | info | info | Info badge |
| Stat (STR, AGI, etc.) | statColor@30% | statColor | statColor | Stat badge |
| Rank (Bronze–Grandmaster) | rankColor@20% | rankColor | rankColor | Rank badge |
| Rarity (Common–Legendary) | rarityColor@20% | rarityColor | rarityColor | Item rarity badge |
| Class (Warrior–Mage) | classColor@20% | classColor | classColor | Class badge |

### 4.16 Градиенты (Gradients)

| Токен | От | До | Использование |
|-------|---|---|---|
| `.goldGradient` | gold | goldBright | Primary button gradient |
| `.bgCardGradient` | bgSecondary | bgTertiary | Card background gradient |
| `.hpFullGradient` | success | successGlow | Full HP bar |
| `.hpGoodGradient` | gold | goldBright | Good HP (> 75%) |
| `.hpMediumGradient` | stamina | glowOrange | Medium HP (25–75%) |
| `.hpCriticalGradient` | hpRed | hpBlood | Critical HP (< 25%) |
| `.staminaButtonGradient` | stamina | glowOrange | Stamina action button |
| `.xpGradient` | cyan | info | XP progress bar |
| `.staminaGradient` | stamina | glowOrange | Stamina progress bar |
| `.progressGradient` | gold | goldBright | Generic progress bar |
| `.bgGradient` | bgPrimary | bgSecondary | Background gradient |
| `.xpGoldenGradient` | gold | goldBright | Golden XP display |
| `.bgDungeonGradient` | bgDungeonDeep | bgDungeonPurple | Dungeon screen background |
| `.bossCardGradient` | bgDungeonCard | bossBorderPurple | Boss card gradient |
| `.dungeonHpGradient` | danger | hpBlood | Boss HP bar |
| `.bgArenaSheet` | bgSecondary | bgTertiary | Arena bottom sheet |
| `.bgArenaCard` | bgTertiary | bgSecondary | Arena card gradient |
| `.fightButtonGradient` | glowOrange | gold | Fight action button |
| `.bgArenaCardPremium` | premiumPink | bgPremiumDeep | Premium arena card |

---

## 5. Типографика (Typography)

### 5.1 Шрифты (Font Families)

| Шрифт | Использование | Стиль | Case |
|-------|---|---|---|
| **Oswald** | Заголовки, кнопки, акценты | Bold (700) | UPPERCASE always |
| **Inter** | Тело, подписи, описания | Regular (400), Medium (500) | Title case or lowercase |

### 5.2 Масштаб типографики (Type Scale)

| Название | Размер | Шрифт | Использование |
|-------|--------|-------|---|
| Hero | 64pt | Oswald Bold | Редко (intro, cinematic screens) |
| Celebration | 44pt | Oswald Bold | Victory/defeat screens, big announcements |
| Cinematic | 40pt | Oswald Bold | Large title sections |
| Screen | 28pt | Oswald Bold | Screen main title, section dividers |
| Section | 22pt | Oswald Bold | Card section titles, subsections |
| Heading | 18pt | Oswald Bold | Card title, button text |
| Body | 16pt | Inter Regular | Основной текст, описания |
| Label | 16pt | Inter Medium | Form labels, stat labels |
| Caption | 16pt | Inter Regular | Small descriptions, captions |
| Badge | 16pt | Inter Medium | Badge/pill text |
| Note | 14pt | Inter Regular | Очень редко (only non-critical) |

**⚠️ ВАЖНО:** Минимум текста = 16pt. Размеры ниже 14pt ЗАПРЕЩЕНЫ (текущее нарушение: боевой HP 7–8pt).

### 5.3 Правила применения типографики

**Заголовки (Titles):**
- ВСЕГДА UPPERCASE (Oswald)
- Никогда не переносить более 2 слов на новую строку
- Max 2-line title

**Основной текст (Body):**
- Inter, 16pt, regular
- Line height: 1.5 (24pt)
- Max width: 45 characters на iPhone 12

**Числа и статы:**
- Используй monospace для выравнивания: `123 → 456` (в статах)
- Большие цифры (HP, Gems): tabular nums (Inter не имеет, но монопространство помогает)
- Форматирование: `1,234,567` с запятыми для thousands

**Сокращения (Abbreviations):**
- `STR` → strength (не пишутся полностью)
- `HP` → health points (сокращение OK)
- `XP` → experience (сокращение OK)

**Кастинги (Truncation):**
- Title: Если > 24 char → `…` в конце
- Label: Если > 20 char → `…` в конце
- Item name: Никогда не обрезай, используй wrapping или smaller font

**Числовой формат:**
- Целые числа: 123, 1,234, 1.2M (для > 1 миллиона)
- Проценты: 45% (без пробела)
- Соотношение: 3:1 (двоеточие, no spaces)
- Диапазон: 10–20 (em-dash, не дефис)

---

## 6. Система отступов (Spacing System)

### 6.1 Шкала отступов (Spacing Scale)

| Токен | Значение | Использование |
|-------|----------|---|
| `2XS` | 2pt | Микро-отступы между элементами |
| `XS` | 4pt | Очень маленькие отступы |
| `SM` | 8pt | Маленькие отступы (внутри компонентов) |
| `MS` | 12pt | Средние-маленькие отступы |
| `MD` | 16pt | **Стандартный отступ** (padding, margins) |
| `LG` | 24pt | Большие отступы (section gaps) |
| `XL` | 32pt | Очень большие отступы |
| `2XL` | 48pt | Максимальные отступы (редко) |

**Практика в коде:**
```swift
VStack(spacing: .MD) {
    Text("Title").font(.heading28)
    Text("Description").font(.body16)
}
.padding(.MD)  // 16pt со всех сторон
```

### 6.2 Область безопасности (Safe Area)

| Край | Минимум | Стандарт | Максимум |
|------|---------|----------|----------|
| Top | 59pt (notch) | 16pt + safe area | 59pt + MD |
| Bottom | 34pt (home indicator) | 16pt + safe area | 34pt + XL |
| Leading | 16pt | 16pt | 24pt |
| Trailing | 16pt | 16pt | 24pt |

**Правило:** Используй `.padding(.MD)` на ScreenLayout, он учитывает safe area автоматически.

### 6.3 Сетка (Grid)

- **Horizontal grid:** 2-3 колонки на iPhone 12 (content-dependent)
- **Column width:** (available width - padding - gap) / columns
- **Gap между колонками:** `.MD` (16pt)
- **Row gap:** `.LG` (24pt)

**Пример (2-column layout):**
```
[16pt] [content] [16pt gap] [content] [16pt]
       ← 535pt →             ← 535pt →
```

---

## 7. Система кнопок (Button System)

### 7.1 Основные кнопки (Core Buttons)

#### Primary (.primary)
| Параметр | Значение |
|----------|----------|
| Высота | 56pt |
| Шрифт | Oswald Bold 18pt, UPPERCASE, textOnGold |
| Background | goldGradient |
| Border | 1pt borderGold, ornamental style |
| Shadow | 12pt shadow, gold@30% |
| Padding | 16pt horizontal |
| Corner radius | 8pt |
| Состояние pressed | 85% opacity (no scale) |
| Использование | Main action (Fight, Equip, Accept, Claim) |

#### Secondary (.secondary)
| Параметр | Значение |
|----------|----------|
| Высота | 48pt |
| Шрифт | Oswald Bold 16pt, UPPERCASE, textGold |
| Background | transparent |
| Border | 2pt borderGold |
| Shadow | none |
| Padding | 12pt horizontal |
| Corner radius | 8pt |
| Состояние pressed | 80% opacity |
| Использование | Secondary action (View details, Compare) |

#### Danger (.danger)
| Параметр | Значение |
|----------|----------|
| Высота | 48pt |
| Шрифт | Oswald Bold 16pt, UPPERCASE, white |
| Background | danger (#E63946) |
| Border | 1pt danger (darker) |
| Shadow | 8pt shadow, danger@20% |
| Padding | 12pt horizontal |
| Corner radius | 8pt |
| Состояние pressed | 85% opacity |
| Использование | Destructive action (Dismantle, Delete, Forfeit) |

#### Ghost (.ghost)
| Параметр | Значение |
|----------|----------|
| Высота | auto (content-sized) |
| Шрифт | Inter Regular 16pt, textSecondary |
| Background | transparent |
| Border | none |
| Shadow | none |
| Padding | 8pt (no frame constraint) |
| Corner radius | 4pt |
| Состояние pressed | textTertiary color |
| Использование | Link-like actions (View all, Learn more) |

#### Neutral (.neutral)
| Параметр | Значение |
|----------|----------|
| Высота | 48pt |
| Шрифт | Inter Bold 16pt, textPrimary |
| Background | bgTertiary |
| Border | 1pt borderMedium |
| Shadow | none |
| Padding | 12pt horizontal |
| Corner radius | 8pt |
| Состояние pressed | 90% opacity |
| Использование | Neutral action (More options, Filter) |

### 7.2 Боевые кнопки (Combat Buttons)

#### CombatToggle (.combatToggle)
| Параметр | Значение |
|----------|----------|
| Высота | 48pt |
| Шрифт | Oswald Bold 16pt, UPPERCASE |
| Background (active) | goldGradient |
| Background (inactive) | bgTertiary |
| Border (active) | 1pt borderGold |
| Border (inactive) | 1pt borderMedium |
| Shadow | 4pt shadow if active |
| Padding | 12pt horizontal |
| Corner radius | 8pt |
| Использование | Ability toggle, mode switch |

#### CombatControl (.combatControl)
| Параметр | Значение |
|----------|----------|
| Высота | 48pt |
| Шрифт | Oswald Bold 14pt |
| Background | bgTertiary + neutral border |
| Border | 1pt borderMedium |
| Shadow | none |
| Padding | 8pt horizontal |
| Corner radius | 6pt |
| Использование | Battle action queue buttons |

#### CombatForfeit (.combatForfeit)
| Параметр | Значение |
|----------|----------|
| Размер | 48pt × 48pt |
| Icon | SF Symbol (xmark.circle.fill) |
| Color | danger |
| Background | bgTertiary |
| Border | 1pt danger@50% |
| Corner radius | 8pt |
| Использование | Forfeit battle action |

#### Fight (.fight)
| Параметр | Значение |
|----------|----------|
| Высота | 56pt |
| Шрифт | Oswald Bold 18pt, UPPERCASE, white |
| Background | fightButtonGradient (orange → gold) |
| Border | 2pt gold |
| Shadow | 16pt shadow, gold@40% (prominent) |
| Padding | 16pt horizontal |
| Corner radius | 8pt |
| Состояние pressed | 85% opacity (no scale) |
| Состояние loading | spinning indicator inside |
| Использование | FIGHT button (primary action in Arena) |

### 7.3 Навигация и Авторизация (Navigation & Auth Buttons)

#### NavGrid (.navGrid)
| Параметр | Значение |
|----------|----------|
| Высота | 72pt |
| Ширина | 72pt (квадрат) |
| Background | bgSecondary + metallic highlight |
| Border | 1pt borderSubtle |
| Shadow | 4pt soft shadow |
| Corner radius | 8pt |
| Иконка | SF Symbol, 32pt, textGold |
| Использование | Hub navigation grid (Battle, Inventory, Shop) |

#### SocialAuth (.socialAuth)
| Параметр | Значение |
|----------|----------|
| Высота | 56pt |
| Шрифт | System Regular 16pt, white |
| Background | black |
| Border | none |
| Shadow | 4pt shadow |
| Padding | 16pt horizontal |
| Corner radius | 8pt |
| Icon | 20pt system icon left-aligned |
| Использование | Sign in with Apple, Google Auth |

#### Close (.close)
| Параметр | Значение |
|----------|----------|
| Размер | 32pt × 32pt |
| Icon | xmark (2pt stroke) |
| Color | textSecondary |
| Background | bgTertiary |
| Border | 1pt borderSubtle |
| Corner radius | 6pt |
| Hover | textPrimary, bgSecondary |
| Использование | Dismiss modal, close card |

### 7.4 Компактные кнопки (Compact Buttons)

#### CompactPrimary (.compactPrimary)
| Параметр | Значение |
|----------|----------|
| Высота | auto (24pt minimum) |
| Шрифт | Inter Bold 14pt, textOnGold |
| Background | gold |
| Border | 1pt borderGold |
| Padding | 6pt horizontal, 4pt vertical |
| Corner radius | 4pt |
| Использование | Small action (Quick upgrade, Instant boost) |

#### DangerCompact (.dangerCompact)
| Параметр | Значение |
|----------|----------|
| Высота | auto (24pt minimum) |
| Шрифт | Inter Bold 14pt, white |
| Background | danger |
| Border | none |
| Padding | 6pt horizontal, 4pt vertical |
| Corner radius | 4pt |
| Использование | Small destructive (Quick dismantle) |

#### CompactOutline (.compactOutline)
| Параметр | Значение |
|----------|----------|
| Высота | auto (24pt minimum) |
| Шрифт | Inter Regular 14pt, customColor |
| Background | transparent |
| Border | 1pt customColor |
| Padding | 6pt horizontal, 4pt vertical |
| Corner radius | 4pt |
| Использование | Parameterized compact outline |

#### DangerOutline (.dangerOutline)
| Параметр | Значение |
|----------|----------|
| Высота | 48pt |
| Шрифт | Oswald Bold 16pt, textDanger |
| Background | transparent |
| Border | 2pt danger |
| Padding | 12pt horizontal |
| Corner radius | 8pt |
| Использование | Outlined danger action |

#### ColorToggle (.colorToggle)
| Параметр | Значение |
|----------|----------|
| Высота | 48pt |
| Шрифт | Inter Regular 16pt |
| Background | customColor |
| Border | customColor@50% |
| Padding | 12pt horizontal |
| Corner radius | 8pt |
| Использование | Toggle with custom colors |

### 7.5 Функциональные кнопки (Utility Buttons)

#### GetMore (.getMore)
| Параметр | Значение |
|----------|----------|
| Высота | 36pt |
| Шрифт | Inter Bold 14pt, textGold |
| Background | transparent |
| Border | 2pt borderGold |
| Padding | 8pt horizontal |
| Corner radius | 6pt |
| Icon | plus.circle, 16pt |
| Использование | Get more gems, stamina, etc. |

#### Premium (.premium)
| Параметр | Значение |
|----------|----------|
| Высота | 56pt |
| Шрифт | Oswald Bold 18pt, white |
| Background | gradient (premiumPink → bgPremiumDeep) |
| Border | 2pt premiumPink |
| Shadow | 12pt shadow, premiumPink@30% |
| Padding | 16pt horizontal |
| Corner radius | 8pt |
| Использование | Premium feature unlock |

#### ScalePress (.scalePress)
| Параметр | Значение |
|----------|----------|
| Feedback | opacity(0.7) on press (no scale) |
| Animation | instant |
| Использование | Custom buttons with only press feedback |

### 7.6 Animation & Feedback (Анимация и обратная связь)

**Press Feedback (стандартное):**
```swift
.buttonStyle(.primary)  // Автоматически opacity(0.85) — NO scale animations
```

> **ЗАПРЕТ:** Никогда не используй `.scaleEffect()` для анимации нажатия, пульсации, дыхания или появления.
> Только opacity feedback. Статический `.scaleEffect(0.8)` для размера иконок — допустим.

**Transitions:**
- Default: 0.15s ease-in-out
- Long action: 0.3s ease-out (для loading states)
- Reveal: 0.6s ease-out (для появления награды)

**Haptics:**
- Press: `.medium` haptic
- Success: `.success` haptic
- Error: `.error` haptic
- Disabled: no haptic

---

## 8. Система карточек (Card System)

### 8.1 panelCard

| Параметр | Значение |
|----------|----------|
| Padding | 16pt |
| Background | bgSecondary |
| Border | 1pt borderSubtle |
| Corner radius | 8pt |
| Shadow | 4pt (bgPrimary@20%) |
| Highlight | Metallic top-left corner accent |
| Использование | Standard item card, stat card, info card |

**Пример:**
```swift
ZStack {
    content
}
.panelCard()
```

### 8.2 rarityCard

| Параметр | Значение |
|----------|----------|
| Padding | 16pt |
| Background | bgTertiary |
| Border | 2pt rarity color (Common–Legendary) |
| Border glow | rarity glow (13–38% opacity, зависит от rarity) |
| Corner radius | 8pt |
| Shadow | 8pt (rarityColor@opacity) |
| Использование | Item card, equipment card, loot card |

### 8.3 infoPanel

| Параметр | Значение |
|----------|----------|
| Padding | 16pt |
| Background | bgPrimary (darker) |
| Border | 1pt borderSubtle |
| Corner radius | 8pt |
| Shadow | none |
| Использование | Informational panels, stats display, quest info |

### 8.4 modalOverlay

| Параметр | Значение |
|----------|----------|
| Padding | 24pt |
| Background | bgSecondary |
| Border | 2pt borderGold (ornamental) |
| Corner radius | 12pt |
| Shadow | 24pt shadow (black@40%) |
| Использование | Modal dialogs, important notifications, level-up |

### 8.5 screenBackground

| Параметр | Значение |
|----------|----------|
| Padding | 0pt (ignores safe area) |
| Background | bgPrimary |
| Использование | Full-screen background container |

### 8.6 Dividers (Разделители)

#### GoldDivider
```swift
ZStack(alignment: .leading) {
    LinearGradient(
        gradient: Gradient(colors: [.clear, .gold, .clear]),
        startPoint: .leading,
        endPoint: .trailing
    )
    .frame(height: 1)
}
```
**Использование:** Visual separator between sections, premium indicator

#### OrnamentalDivider (v2 — DiamondDividerMotif)
```swift
// Uses DiamondDividerMotif from OrnamentalStyles.swift
// Gradient lines + ◆◇◆ center motif
OrnamentalDivider()
```
**Использование:** Decorative separator, fantasy aesthetic. Center diamond motif with gradient lines.

#### Ornamental Primitives (`OrnamentalStyles.swift`)

Все орнаментальные элементы UI — чистый SwiftUI (без PNG). Файл: `Hexbound/Hexbound/Theme/OrnamentalStyles.swift`.

**Основные компоненты:**
- `RadialGlowBackground(baseColor:glowColor:glowIntensity:cornerRadius:)` — замена плоского `bgSecondary` fill
- `BarFillHighlight(cornerRadius:)` — глянцевый блик на верхней кромке progress bars
- `CornerBracketOverlay` / `.cornerBrackets()` — L-brackets на углах
- `CornerDiamondOverlay` / `.cornerDiamonds()` — ромбы на углах
- `SideDiamondOverlay` / `.sideDiamonds()` — ромбы на боковых центрах
- `InnerBorderOverlay` / `.innerBorder()` — gradient inner bevel stroke
- `SurfaceLightingOverlay` / `.surfaceLighting()` — convex surface effect (top bright → bottom dark)
- `.ornamentalFrame()` — комбо: brackets + diamonds + inner border

**Дополнительные структурные компоненты (v2.1):**
- `DoubleBorderOverlay` / `.doubleBorder()` — двойная рамка (inner + outer) с gap
- `ScrollworkDivider` — декоративный разделитель со свитками и ромбами
- `FiligreeLine` — тонкая филигранная линия с точками
- `EtchedGroove` — гравированная канавка между секциями
- `.premiumFrame()` — продвинутая комбо: double border + brackets + diamonds + etched groove

**Press state:** `.brightness(-0.06)` вместо `.opacity(0.85)` — более натуральный "pressed plate" эффект.

#### Standard Application Patterns (MANDATORY for new UI)

**Статус: 100% COMPLETE (v2.1 Structural Rebranding)** — 34+ файлов переделаны. Все панели усилены: surfaceLighting + cornerBrackets + abyss shadow. Модали — полный набор (brackets + diamonds + dual shadow). Завершено 2026-03-22.

**Standard panel pattern (регулярные карточки, детальные секции, игровые здания):**
```swift
RadialGlowBackground(
  baseColor: DarkFantasyTheme.bgSecondary,
  glowColor: DarkFantasyTheme.bgTertiary,
  glowIntensity: 0.4,  // усилена с 0.3 → 0.4
  cornerRadius: LayoutConstants.cardRadius
)
.innerBorder(
  cornerRadius: LayoutConstants.cardRadius - 2,
  inset: 2,
  color: DarkFantasyTheme.borderMedium.opacity(0.15)  // или accentColor.opacity(0.08) для акцентов
)
.surfaceLighting(cornerRadius: LayoutConstants.cardRadius)  // convex surface effect
.cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 12, thickness: 1.5)
.shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)  // depth shadow
```

**Standard modal pattern (боевые результаты, лут, дневной логин, авторизация, детали предмета):**
```swift
RadialGlowBackground(
  baseColor: DarkFantasyTheme.bgSecondary,
  glowColor: DarkFantasyTheme.bgTertiary,
  glowIntensity: 0.4,  // усилена
  cornerRadius: LayoutConstants.modalRadius
)
.innerBorder(
  cornerRadius: LayoutConstants.modalRadius - 3,
  inset: 3,
  color: rarityColor.opacity(0.1)  // или .gold.opacity(0.1) для нейтральных
)
.surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
.cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.4), length: 18, thickness: 2.0)
.cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.3), size: 6)
// Двойной shadow: accent glow + abyss depth
.shadow(color: accentColor.opacity(0.3), radius: 8)
.shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 10, y: 4)
```

**Circle exception (XP rings, stat rings, progress circles):**
- Используй `RadialGradient` напрямую, НЕ `RadialGlowBackground` (который для RoundedRectangle)
- `RadialGlowBackground` работает ТОЛЬКО для панелей с закругленными углами
- Паттерн: `RadialGradient(gradient: Gradient(...), center: .center, startRadius: 0, endRadius: radius)`

**Dual shadow pattern (для глубины и выделения):**
- Основное: tint-colored или accent-colored glow shadow
- Вторичное: тёмный `bgAbyss` shadow для глубины
- Используется в: ItemCardView, боевые карточки, лут, детальные листы
- Паттерн: `shadow(color: accentColor.opacity(0.6), radius: 12)` + `shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 8)`

**Исключения (плоское bgSecondary — НАМЕРЕННО):**
- `HubView` — base слой под RadialGradient небом
- `ToastOverlayView` — base перед эффектом виньетки
- `ScreenCatalogView` — инструменты разработчика

---

## 9. Библиотека компонентов (Component Library)

### 9.1 ActiveQuestBanner

**Назначение:** Отображение активного квеста в хабе с прогрессом и действием.

**Анатомия:**
```
┌─────────────────────────────────┐
│ ★ QUEST TITLE (Oswald 18)       │
│ Progress: 5/10 objectives       │
│ [Claim Reward Button]           │
└─────────────────────────────────┘
```

**Варианты:**
- In Progress (bgSecondary + gold border)
- Completed (bgSecondary + success border)
- Expired (bgSecondary + danger border)

**Использование:**
- Hub > Quests section
- После принятия квеста

**Do/Don't:**
- ✓ Показывай прогресс визуально (progress bar)
- ✗ Не показывай полное описание квеста
- ✓ Одна кнопка действия (Claim или Abandon)

### 9.2 AvatarImageView

**Назначение:** Отображение аватара персонажа с рамкой и уровнем.

**Анатомия:**
```
     ┌─────────┐
     │ AVATAR  │
     │ LVL 45  │
     │ WARRIOR │
     └─────────┘
```

**Варианты:**
- Small (64pt × 64pt, для списков)
- Medium (128pt × 128pt, для профиля)
- Large (256pt × 256pt, для выбора персонажа)

**Использование:**
- Character profile
- Party display
- Leaderboard entry

**Do/Don't:**
- ✓ Граница = rarity color класса персонажа
- ✗ Не скрывай уровень персонажа

### 9.3 BattleResultCardView

**Назначение:** Отображение результата боя с наградами и статистикой.

**Анатомия:**
```
Victory / Defeat (цветной заголовок)
─────────────────────────────
Opponent: [avatar + name]
Damage Dealt: 234 HP
Rewards: 500 Gold, 100 XP
[Claim Reward]
```

**Варианты:**
- Victory (green tint, celebration animation)
- Defeat (red tint, no animation)
- Draw (blue tint)

**Использование:**
- Экран результата боя
- Battle history

**Do/Don't:**
- ✓ Всегда покажи старые и новые статы рядом
- ✓ Награды должны ощущаться наградами (animation + sound)
- ✗ Не скрывай размер награды в скролле

### 9.4 CurrencyDisplay

**Назначение:** Отображение игровой валюты (Gold, Gems, Stamina) с иконкой.

**Анатомия:**
```
┌─────────────┐
│ $ 1,234,567 │  ← monospace number
│   GOLD      │  ← caption, gray
└─────────────┘
```

**Варианты:**
- Gold (gold color, $ icon)
- Gems (cyan color, gem icon)
- Stamina (orange color, bolt icon)

**Использование:**
- Hub header (top-right corner)
- Shop display
- Inventory stats

**Do/Don't:**
- ✓ Числа с разделителями (1,234)
- ✓ Иконка + label + number
- ✗ Никогда не пиши "Gold" без иконки

### 9.5 GuestGateView

**Назначение:** Экран с предложением войти для новых игроков.

**Анатомия:**
```
Hexbound Logo (large)
"Experience the Ultimate PvP"
[Sign in with Apple]
[Sign in with Google]
[Play as Guest]
```

**Использование:**
- Auth screen
- Before first battle
- Premium feature unlock

**Do/Don't:**
- ✓ Всегда предложи гостевой вход
- ✗ Не требуй входа до 5-й битвы
- ✓ Социальная авторизация выше гостевой

### 9.6 GuestNudgeBanner

**Назначение:** Баннер с напоминанием войти (не блокирующий).

**Анатомия:**
```
┌─────────────────────────────┐
│ Sign in to save your progress
│ [Sign in] [Not now]         │
└─────────────────────────────┘
```

**Использование:**
- Hub (после 5-й битвы)
- Всякий раз когда гость достигает миль
- Optional dismissal

**Do/Don't:**
- ✓ Dismissible
- ✗ Не показывай более 3 раз в сессию

### 9.7 HPBarView

**Назначение:** Visually display current and max HP with color feedback.

**Анатомия:**
```
HP Bar (gradient full → critical)
Label: 150 / 200 HP (monospace)
```

**Варианты:**
- Full HP (green/gold gradient)
- Good (gold gradient)
- Medium (orange gradient)
- Critical (red/blood gradient)
- Damaged (animate shrink)

**Использование:**
- Character card
- Battle UI
- Opponent display

**Do/Don't:**
- ✓ Размер шрифта = minimum 18pt
- ✓ Граница = current HP status color
- ✗ Не используй hp bar без label
- ✓ Анимирируй изменение HP (0.3s)

### 9.8 ItemImageView

**Назначение:** Display item icon/image with rarity border and level badge.

**Анатомия:**
```
┌──────────┐
│          │
│  ITEM 🗡️ │  ← SF Symbol или asset image
│  ICON    │
└──────────┘
  +12 RARE  ← level + rarity badge
```

**Варианты:**
- Equipped (checkmark overlay)
- Locked (lock overlay)
- Claimable (gold glow)
- Purchasable (price tag)

**Использование:**
- Inventory grid
- Equipment comparison
- Shop display

**Do/Don't:**
- ✓ Граница = rarity color
- ✓ Badge = level + enhancement
- ✗ Не скрывай иконку позади текста

### 9.9 LevelUpModalView

**Назначение:** Celebration modal при повышении уровня.

**Анатомия:**
```
┌──────────────────┐
│   LEVEL UP! 🎉   │ ← animated zoom
│   You reached    │
│   LEVEL 45!      │ ← large, gold
│                  │
│ +50 STR          │
│ +30 VIT          │ ← stat changes
│                  │
│ [Claim Rewards]  │
└──────────────────┘
```

**Использование:**
- После батла когда игрок достигает нового уровня
- Character progression

**Do/Don't:**
- ✓ Animated entrance (zoom + scale)
- ✓ Sound effect (victory chime)
- ✓ Particulates (golden confetti)
- ✗ Не автоматически закрывай, дайте игроку нажать

### 9.10 LoadingOverlay

**Назначение:** Show loading state without blocking interaction.

**Анатомия:**
```
┌──────────────────────┐
│     [loading bar]    │
│   Loading battles... │
└──────────────────────┘
```

**Варианты:**
- Spinner (rotating indicator)
- Progress bar (% based)
- Pulse (subtle breathing effect)

**Использование:**
- Network requests
- Battle matchmaking
- Asset loading

**Do/Don't:**
- ✓ Прозрачный фон, позволяющий видеть контент позади
- ✓ Текст = что происходит
- ✗ Не используй полную opacity overlay

### 9.11 OfflineBannerView

**Назначение:** Notify user of offline status and impact.

**Анатомия:**
```
┌─────────────────────────────┐
│ ⚠ No network connection     │
│ Some features are disabled  │
└─────────────────────────────┘
```

**Использование:**
- Top banner when offline
- Persistent (no dismiss)
- Автоматически исчезает при восстановлении

**Do/Don't:**
- ✓ Всегда видимый (top of hierarchy)
- ✓ Явная информация о чем не работает
- ✗ Не блокируй offline gameplay

### 9.12 ScreenLayout

**Назначение:** Standard screen wrapper with safe area, padding, and background.

**Анатомия:**
```swift
ScreenLayout {
    content
}
```

**Параметры:**
- Automatically adds safe area
- Applies bgPrimary background
- Standard MD padding left/right

**Использование:**
- Все основные экраны
- Обеспечивает консистентность

### 9.13 SkeletonViews

**Назначение:** Show loading placeholders while data loads.

**Варианты:**
- SkeletonCard (gray rounded rectangle)
- SkeletonText (gray line)
- SkeletonAvatar (circular gray shape)

**Использование:**
- Inventory loading
- Leaderboard loading
- Profile loading

**Do/Don't:**
- ✓ Pulse animation (1–2 Hz)
- ✗ Не используй скелеты более 5 секунд

### 9.14 StaminaBarView

**Назначение:** Display stamina with regeneration timer.

**Анатомия:**
```
Stamina: 45 / 60
[████████░░] ← gradient bar
Regenerates in 02:34
```

**Использование:**
- Hub (prominently top-right)
- Before battle
- Shop CTA ("Not enough stamina")

**Do/Don't:**
- ✓ Показывай регенерационный таймер
- ✗ Не скрывай время до регенерации
- ✓ Цвет = stamina color (#E67E22)

### 9.15 TabSwitcher

**Назначение:** Switch between inventory tabs, shop categories, etc.

**Анатомия:**
```
[All] [Weapons] [Armor] [Accessories]
  ↓ active indicator (underline)
```

**Варианты:**
- Horizontal scroll (long lists)
- Fixed width (< 4 tabs)
- Icon + label (inventory types)

**Использование:**
- Inventory filters
- Shop categories
- Battle history tabs

### 9.16 ToastOverlayView

**Назначение:** Show temporary notifications (achievements, level ups, errors).

**Анатомия:**
```
┌──────────────────────┐
│ ✓ QUEST COMPLETED!   │ ← icon + message
│   +100 XP            │ ← secondary info
└──────────────────────┘
```

**Варианты:**
- Achievement (gold toast, 3s duration)
- LevelUp (green toast, 4s + sound)
- Error (red toast, 4s + can dismiss)
- Info (gray toast, 2s)

**Использование:**
- Quest progress
- Rewards
- Errors
- Network events

**Do/Don't:**
- ✓ Auto-dismiss после timer
- ✓ Stack multiple toasts (max 3)
- ✗ Не блокируй UI с toast

### 9.17 VictoryParticlesView

**Назначение:** Celebratory particle animation on victory.

**Анатомия:**
- Golden particles falling from top
- Confetti-like burst effect
- Slow fade out (2s)

**Использование:**
- Battle victory screen
- Rank up
- Achievement unlock

**Do/Don't:**
- ✓ Disable на низких FPS устройствах (fallback = static image)
- ✗ Не анимируй более 5 секунд

---

## 10. Система состояний (State System)

Стандартизованная система состояний для всех интерактивных элементов:

| Состояние | Описание | Визуальный стиль |
|-----------|---------|---|
| **default** | Normal, inactive | Base colors, borderSubtle, no glow |
| **pressed** | Touch down / mouse down | opacity(0.85), no scale |
| **selected** | Item is chosen (equipment, tab) | borderMedium, highlight border |
| **active** | Button/toggle is ON (ability active) | goldGlow effect, borderGold |
| **focused** | Keyboard navigation or cursor hover | borderMedium, 2pt outline |
| **disabled** | Action unavailable (not enough stamina) | opacity(0.5), textDisabled, bgDisabled |
| **locked** | Feature locked (level requirement) | Lock icon overlay, opacity(0.6) |
| **loading** | Async operation pending | Spinner, disabled interaction |
| **empty** | No items/results | Placeholder message, centered |
| **error** | Operation failed | danger border, error icon, error toast |
| **equipped** | Item is currently equipped | Checkmark overlay, gold highlight |
| **claimable** | Reward ready to claim | goldGlow, animation (pulse) |
| **purchasable** | Item for sale | Price tag overlay, gold border |
| **unavailable** | Out of stock / out of range | opacity(0.4), "Coming soon" label |
| **victory** | Battle won | Green tint, celebration animation |
| **defeat** | Battle lost | Red tint, no animation |

---

## 11. Motion & Feedback (Движение и обратная связь)

### 11.1 Tap Feedback

> **ПРАВИЛО: ЗАПРЕТ SCALE-АНИМАЦИЙ**
> Никогда не используй `.scaleEffect()` для анимации увеличения/уменьшения UI-объектов.
> Это включает: press feedback, пульсацию, breathing, bounce, appear/reveal.
> Всегда используй **opacity** для визуальной обратной связи.
> Допустимые исключения: статический `.scaleEffect(0.8)` для размера, `.scaleEffect(x: -1)` для зеркалирования, частицы (RewardBurst, CoinFly, VFX).

**Press (стандартное для кнопок):**
```swift
.buttonStyle(.primary)
// Автоматически:
// - opacity(0.85) on press
// - haptic: .medium
// - NO scale animation
```

**Hold (для long-press actions):**
```swift
.onLongPressGesture {
    // opacity(0.7), haptic .heavy — NO scale
}
```

### 11.2 Transitions & Animations

| Действие | Duration | Easing | Haptic |
|----------|----------|--------|--------|
| Button press | 0.15s | ease-in-out | .medium |
| Screen transition | 0.3s | ease-out | none |
| Reward reveal | 0.6s intro, 1.2s hold, 0.4s outro | ease-out | .success |
| List row delete | 0.3s | ease-out | .warning |
| Color change | 0.2s | ease-out | none |
| Opacity pop (achievement) | 0.4s | ease-out | .success + sound |

### 11.3 Reward Animation (Награда)

Награды должны ощущаться **НАГРАДАМИ**. Последовательность:

```
1. [0.0s] Скрытое окончание боя
2. [0.2s] "VICTORY!" title fade in (opacity 0 → 1.0)
3. [0.8s] Reward card slide up + fade in
4. [1.2s] Hold (user смотрит reward)
5. [1.6s] Sound: "cha-ching" (казино звук)
6. [1.8s] Particles: золотой confetti falling
7. [2.2s] Fade out (auto-advance or user tap)
```

**Код паттерн:**
```swift
withAnimation(.easeOut(duration: 0.6)) {
    isRewardVisible = true
}
DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
    playSound(.victory)
    emitParticles()
}
```

### 11.4 Haptic Feedback Rules

| Тип | Intesity | Использование |
|-----|----------|---|
| `.light` | Низкая | Subtle feedback, disabled state |
| `.medium` | Средняя | **Standard** button press |
| `.heavy` | Высокая | Important action, danger button |
| `.success` | Custom | Reward claimed, level up |
| `.error` | Custom | Error occurred |
| `.warning` | Custom | Confirmation prompt |

**Правило:** Никогда не триггер haptic если user отключил в настройках.

### 11.5 Glow Effect Guidelines

**Когда использовать glow:**
- ✓ Active ability (combat)
- ✓ Rare+ item (rarity ≥ Rare)
- ✓ Boss encounter (visual emphasis)
- ✓ Level-up toast (celebration)
- ✓ Equipped item (status indicator)

**Когда ИЗБЕГАТЬ glow:**
- ✗ Background surfaces (noise)
- ✗ Buttons в hub (cognitive overload)
- ✗ Text labels (readability)
- ✗ Disabled elements (contrast issue)
- ✗ More than 2 glowing elements on one screen at rest

**Правило:** Каждый glow должен иметь **смысл** (статус, раритет, действие).

---

## 12. Игровые UX-правила (Game-Specific UX Rules)

### 12.1 PvP Сравнение (Comparison UX)

Когда игрок просматривает противника в Arena:

```
┌─────────────────────────────┐
│ You         vs     Opponent │
├──────────────┬──────────────┤
│ HP: 150/200  │ HP: 120/160  │
│ STR: 45      │ STR: 42      │
│ DEF: 38      │ DEF: 41  ↑   │ ← показывай разницу
│ AGI: 52      │ AGI: 50      │
└──────────────┴──────────────┘
```

**Правила:**
- ✓ Рядом друг с другом (не scroll)
- ✓ Показывай стрелки для различий (↑ worse, ↓ better, → same)
- ✗ Не скрывай статы в dropdown
- ✓ Цвета = stat colors (STR=red, AGI=green, etc.)

### 12.2 Читаемость снаряжения (Equipment Readability)

Item card должен показывать:
```
┌────────────────────────────┐
│ Sword of Fire      [Rare]  │ ← name + rarity pill
│ +12 STR, +8 AGI          │ ← stat bonuses (color-coded)
│ ▶ 2-hand weapon          │ ← type + metadata
│ [Equip]                   │ ← action button
└────────────────────────────┘
```

**Правила:**
- ✓ Граница = rarity color + glow
- ✓ Stats = stat colors
- ✗ Не скрывай усиления (enhancement level) в small text
- ✓ Type = text-secondary (меньше важности)

### 12.3 Читаемость статов (Stat Readability)

В боевом интерфейсе:
```
STR  45 ┃ ↑ +5 from items
AGI  52 ┃
VIT  38 ┃ ↓ -2 from curse
```

**Правила:**
- ✓ Monospace numbers для выравнивания
- ✓ Stat color слева (визуальный якорь)
- ✓ Бонусы/штрафы справа (textGold / textDanger)
- ✗ Не теряй базовый stat в модификаторах

### 12.4 Reward Reveal (Раскрытие награды)

После боя, последовательно покажи:
```
[1] Battle Result
    Victory / Defeat
    Opponent info

[2] XP Gained
    +250 XP ← animate count-up

[3] Item Drops
    Rare Sword (new!)
    Gold x 500

[4] Rank Progress
    You gained 15 rank points

[5] [Collect All] Button
```

**Правила:**
- ✓ Раскрывай по одному типу награды за раз
- ✓ Используй count-up animation для больших чисел
- ✓ Новые предметы должны сиять (gold glow)
- ✓ Звук для каждого раскрытия (не один раз)
- ✗ Не показывай всё сразу

### 12.5 Progression Feedback (Обратная связь прогрессии)

Всегда показывай прогресс визуально:
```
Level 44 ━━━━━━━━┃━━━━━━ Level 45 (67%)
[═════════════════░░░░░]
```

**Правила:**
- ✓ Progress bar = gradient (gold → bright)
- ✓ % or num/num оба варианта OK
- ✓ Filled portion в gold, empty в dark
- ✗ Не скрывай текущий level

### 12.6 Inventory Scanning (Сканирование инвентаря)

Inventory должен быть **быстро скануемым**:
```
[Grid View]              [List View]
┌──┬──┬──┐              Sword of Fire [Rare] [Equip]
│ 🗡│⚔️│🔱│  ← иконки видны сразу    Armor Plate [Uncommon]
│ 🛡│💍│🎒│              Ring of Fate [Epic] [Sell]
└──┴──┴──┘
```

**Правила:**
- ✓ Большие иконки (минимум 64pt × 64pt)
- ✓ Рарити граница = быстрое определение ценности
- ✓ Grid по умолчанию (для быстрого скана)
- ✗ Не скрывай рарити в меню

### 12.7 Shop Clarity (Ясность шопа)

Shop должен быть **самоинформирующимся**:
```
┌─────────────────────┐
│ Sword of Fire       │ ← clear name
│ [Rare] +12 STR     │ ← rarity + benefit
│                     │
│ Price: 500 Gold ← price CLEAR
│ [Buy] [Compare]     │
└─────────────────────┘
```

**Правила:**
- ✓ Цена БОЛЬШАЯ и видимая (gold color)
- ✓ Показывай главный бенефит
- ✓ [Compare] кнопка если item в inventory
- ✗ Не скрывай цену

### 12.8 Battle Result Reading (Чтение результата батла)

Result card должна показывать ВСЁ необходимое за одну фиксацию:
```
┌────────────────────────┐
│ VICTORY!               │ ← БОЛЬШОЙ, ЦВЕТНОЙ
│                        │
│ vs Opponent Name       │ ← кто был противник
│ Damage: 450 / 320      │ ← ты / противник
│ Duration: 3m 45s       │ ← время боя
│                        │
│ Rewards:               │
│ + 250 XP               │ ← главная награда
│ + 1 Rare Item          │
│ + 500 Gold             │
│                        │
│ [Claim Rewards]        │ ← одна кнопка
└────────────────────────┘
```

**Правила:**
- ✓ Результат (Victory/Defeat) БОЛЬШОЙ и цветной
- ✓ Статистика компактно
- ✓ Награды в порядке важности
- ✗ Не скрывай результат батла

### 12.9 Character Creation (Создание персонажа)

Экран создания должен быть **быстро пройденным** (< 1 минута):

**Шаги:**
1. Выбрать класс (Warrior, Rogue, Mage, Tank) — 3 раза выбор
2. Выбрать имя — текстовый ввод
3. Выбрать аватар — 4 опции
4. Confirm — [Play Now]

**Правила:**
- ✓ Каждый шаг = одна кнопка подтверждения
- ✓ Показывай class bonuses СРАЗУ
- ✓ Можно вернуться (Back button)
- ✗ Не требуй выбор всех 20 параметров

### 12.10 Onboarding (Введение в игру)

Onboarding ДОЛЖЕН быть в дизайн системе:

**Проблема:** Текущее onboarding имеет 30+ hardcoded значений вне системы.

**Решение:** Migrado на:
- DarkFantasyTheme цвета
- Oswald/Inter шрифты
- LayoutConstants отступы
- Button styles

**Типовой экран onboarding:**
```
┌───────────────────────┐
│ Welcome to Hexbound       │ ← Screen title (28pt Oswald)
│                           │
│ Description text goes here │ ← Body (16pt Inter)
│ and explains the feature.  │
│                           │
│ [Next Step]               │ ← Primary button (56pt)
│ [Skip Tutorial]           │ ← Ghost button
└───────────────────────┘
```

### 12.11 Empty States (Пустые состояния)

Когда нет контента, покажи helpful сообщение:

```
┌─────────────────────────┐
│      (empty icon)       │ ← SF Symbol в gray
│                         │
│ No battles yet          │ ← Clear message
│ Win your first PvP      │ ← Encouragement
│ battle to earn rewards  │
│                         │
│ [Find an Opponent]      │ ← CTA button
└─────────────────────────┘
```

**Правила:**
- ✓ Иконка + сообщение (никогда только пустой экран)
- ✓ Одна CTA кнопка
- ✗ Не показывай error код

### 12.12 Locked Content (Заблокированный контент)

Когда функция заблокирована (level requirement):

```
┌─────────────────────────┐
│     🔒 LOCKED          │ ← lock icon, reduced opacity
│                         │
│ Unlocks at Level 30     │ ← clear requirement
│ Current: Level 18       │ ← progress
│                         │
│ [Upgrade Character]     │ ← hint button (не primary)
└─────────────────────────┘
```

**Правила:**
- ✓ Lock icon очень видимая
- ✓ Clear requirement (не "???")
- ✓ Progress bar показывает как близко
- ✗ Не скрывай requirement

### 12.13 Monetization Clarity (Прозрачность монетизации)

Когда предлагаешь платежи:

```
Premium Feature
┌────────────────┐
│ Unlock with:   │
│ 🔵 10 Gems     │ ← четко иконка валюты
│ 💰 500 Gold    │
│                │
│ [Spend Gems]   │ ← разные кнопки
│ [Spend Gold]   │
└────────────────┘
```

**Правила:**
- ✓ Иконка + количество ОЧЕНЬ ЯСНО
- ✓ Разные кнопки для разных валют (no ambiguity)
- ✓ Показывай текущий баланс
- ✗ Не скрывай цену в small text

---

## 13. Доступность (Accessibility)

### 13.1 Текущий статус
- **Accessibility labels:** 0 ✗ (КРИТИЧЕСКИЙ ДЕФЕКТ)
- **Min text size:** 16pt (после рефакторинга) ✓
- **Contrast:** WCAG AA достигнуто ✓
- **Touch targets:** 56pt standard, 44pt minimum ✓ (but need verification)

### 13.2 Минимальные требования

**Размер текста:**
- Основной текст: 16pt minimum
- Заголовки: 22pt minimum
- Captions: 14pt (только если не критично)
- *Исключение:* Боевые метрики (HP, XP) = 18pt minimum (было 7-8pt ❌)

**Размер касания (Touch targets):**
- Minimum: 44pt × 44pt (Apple HIG standard)
- Comfortable: 56pt × 56pt (Hexbound standard)
- Buttons: 48–56pt (follow button style guide)
- Icons: 32pt × 32pt minimum
- Spacing között touch targets: 8pt minimum

**Контрастность (Contrast Ratio):**
- WCAG AA standard: 4.5:1 для normal text, 3:1 для large text
- WCAG AAA (ideal): 7:1 для normal text, 4.5:1 для large text

**Проверка:**
```
textPrimary (#F5F5F5) на bgPrimary (#0D0D12) = 18:1 ✓ (AAA)
textSecondary (#A0A0B0) на bgPrimary (#0D0D12) = 10:1 ✓ (AAA)
gold (#D4A537) на bgPrimary (#0D0D12) = 4.2:1 (AA, marginal)
```

### 13.3 Accessibility Labels (Ярлыки доступности)

**ВСЕ** интерактивные элементы должны иметь `.accessibilityLabel()`:

```swift
Button(action: { startBattle() }) {
    Text("Fight")
}
.buttonStyle(.primary)
.accessibilityLabel("Start battle with opponent")
.accessibilityHint("Requires 20 stamina")
```

**Правила:**
- ✓ Label = ясное, краткое описание действия
- ✓ Hint = дополнительный контекст (требования, последствия)
- ✓ Роль = автоматическая для buttons, form inputs, etc.
- ✗ Не повторяй текст кнопки в label

**Для изображений:**
```swift
Image(.itemIcon)
    .accessibilityLabel("Sword of Fire")
    .accessibilityValue("Rare, +12 STR")
```

### 13.4 Icon + Label Pairing

Иконки НИКОГДА не должны быть единственным способом донести информацию:

```swift
// ❌ ПЛОХО
Button(action: {}) {
    Image(systemName: "star.fill")  // что это делает?
}

// ✓ ХОРОШО
Button(action: {}) {
    HStack(spacing: .XS) {
        Image(systemName: "star.fill")
        Text("Favorite")
    }
}
.accessibilityLabel("Add to favorites")
```

### 13.5 Dense UI Rules

Когда UI становится ОЧЕНЬ плотным (inventory grid, leaderboard):
- ✓ Используй larger touch targets (48pt minimum)
- ✓ Gruppieren items с clear boundaries
- ✓ Use color + pattern для distinction
- ✗ Не полагайся только на цвет (colorblind users)

**Пример:**
```
Inventory Grid: 3 колонки, каждая 120pt × 140pt
Spacing между: 12pt (MS)
Touch targets: 64pt × 80pt (достаточно большие)
```

### 13.6 Semantic HTML / SwiftUI

В SwiftUI используй правильные типы элементов:

```swift
// ✓ ХОРОШО
VStack {
    Text("Character Stats")
        .accessibilityAddTraits(.isHeader)

    HStack {
        Text("STR")
            .accessibilityLabel("Strength")
        Text("45")
            .accessibilityValue("45 points")
    }
}

// ❌ ПЛОХО
VStack {
    Text("Character Stats")  // нет semantic role
    Text("STR")  // не понятно что это
    Text("45")   // не связано с STR
}
```

---

## 14. Правила реализации (Implementation Rules)

### 14.1 Что становится shared components

**ДОЛЖНЫ быть компоненты (reusable):**
- ✓ Buttons (используются 50+ раз)
- ✓ Cards (используются 20+ раз)
- ✓ HPBar / StaminaBar (используются на каждом экране)
- ✓ CurrencyDisplay (используется 10+ раз)
- ✓ Toast / Loading (общая система)
- ✓ Tab switcher (3+ экранов)
- ✓ Avatar display (5+ мест)

**МОГУТ быть компоненты (если повторяются 3+ раза):**
- ? ItemCard (inventory, shop, drops)
- ? EquipmentComparison (shop detail, inventory)
- ? OpponentCard (arena, leaderboard)

**НЕ должны быть компоненты (специфичные экраны):**
- ✗ BattleUI (только боевой экран)
- ✗ CharacterCreationStep (только onboarding)
- ✗ SpecialEventCard (event-specific)

### 14.2 Theme tokens verification

**Правило #1: Никогда не hardcode цвета**
```swift
// ❌ ПЛОХО
.backgroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))

// ✓ ХОРОШО
.backgroundColor(.danger)
```

**Правило #2: Никогда не гадай имя токена**
```swift
// ❌ ПЛОХО
.backgroundColor(.red)  // неправильный shade

// ✓ ХОРОШО
// 1. Посмотри в DarkFantasyTheme.swift
// 2. Найди exact token name (.danger, .hpRed, etc.)
// 3. Используй это имя
```

**Правило #3: Проверяй в source**
```
Hexbound/
├── Theme/
│   ├── DarkFantasyTheme.swift  ← ИСТОЧНИК ИСТИНЫ
│   ├── ButtonStyles.swift
│   ├── CardStyles.swift
│   └── LayoutConstants.swift
```

Каждый цвет, каждый размер шрифта, каждый отступ должны быть определены один раз и переиспользованы везде.

### 14.3 Common mistakes & corrections

#### Ошибка #1: Hardcoded padding
```swift
// ❌
VStack(spacing: 12) {
    Text("Title")
    Text("Description")
}
.padding(16)

// ✓
VStack(spacing: .MS) {
    Text("Title")
    Text("Description")
}
.padding(.MD)
```

#### Ошибка #2: Missing button style
```swift
// ❌
Button("Fight") { startBattle() }
.frame(height: 56)
.backgroundColor(.gold)

// ✓
Button("Fight") { startBattle() }
.buttonStyle(.fight)  // или .primary
```

#### Ошибка #3: No accessibility
```swift
// ❌
Button { startBattle() } label: {
    Text("🗡️")
}

// ✓
Button { startBattle() } label: {
    Image(systemName: "arrowtriangle.right.fill")
        .accessibilityLabel("Fight")
}
.accessibilityLabel("Start battle")
.accessibilityHint("Requires 20 stamina")
```

#### Ошибка #4: Ignoring rarity
```swift
// ❌ (все items выглядят одинаково)
.border(.gold, width: 1)

// ✓ (rarity = визуальная информация)
.border(rarityColor, width: 2)
.shadow(color: rarityGlow, radius: 8)
```

#### Ошибка #5: Mixed font sizes
```swift
// ❌
Text("HP: 150")
.font(.system(size: 8))  // слишком маленко

// ✓
Text("HP: 150")
.font(.heading18)  // из типографики шкалы
```

### 14.4 Verification checklist

Перед commit, проверь:

- [ ] Все цвета из DarkFantasyTheme (no hardcoded colors)
- [ ] Все шрифты из Font extensions (no .system)
- [ ] Все отступы из LayoutConstants (no random Spacer)
- [ ] Все кнопки имеют .buttonStyle() (no Frame + colors)
- [ ] Все интерактивные элементы имеют .accessibilityLabel()
- [ ] Minimum text size = 16pt
- [ ] Button targets ≥ 48pt
- [ ] Нет скрытого текста за модалом
- [ ] Контрастность проверена (WCAG AA)
- [ ] Градиенты используются логично (не noise)

---

## 15. Экранные заметки по рефакторингу (Screen Alignment Notes)

### 15.1 Hub Screens (6 экранов)

**Основные проблемы:**
- ❌ 50+ hardcoded colors (должны быть tokens)
- ❌ Inconsistent padding (mix of 8, 12, 16, 20)
- ❌ Button styles не используются (custom background + frame)

**Направление:**
1. Замени все colors на DarkFantasyTheme tokens
2. Standardize padding на .MD (16pt) везде
3. Примени .buttonStyle() ко всем кнопкам
4. Add accessibility labels

**Приоритет:** P0 (фундамент для всех остальных экранов)

### 15.2 Arena / PvP Screens (5 экранов)

**Основные проблемы:**
- ❌ Opponent comparison не side-by-side (user не может быстро сравнить)
- ❌ 90+ buttons без .buttonStyle()
- ❌ HP bar font size = 7pt (нарушение accessibility)

**Направление:**
1. Перемакет opponent card (side-by-side stats)
2. Примени .buttonStyle() ко всем кнопкам
3. Увеличь HP bar font на 18pt minimum
4. Standardize spacing

**Приоритет:** P1 (critical user path)

### 15.3 Character / Profile Screens (3 экрана)

**Основные проблемы:**
- ❌ Stats не color-coded (статы не сканируемые fast)
- ❌ Equipment comparison скрыта в modal (no side-by-side)
- ❌ Rarity colors не используются консистентно

**Направление:**
1. Add stat colors (STR=#E6594D, AGI=#4DE666, etc.)
2. Покажи current + new equipment рядом
3. Примени rarity borders + glow
4. Add visual progression bars

**Приоритет:** P1 (core gameplay loop)

### 15.4 Inventory Screens (2 экрана)

**Основные проблемы:**
- ❌ Grid layout неудобный (иконки слишком маленькие)
- ❌ Rarity не видна быстро (нету colored border)
- ❌ Tab switcher не используется (нет категорий)

**Направление:**
1. Увеличь grid item size (64pt × 80pt minimum)
2. Add rarity color border + glow
3. Implement TabSwitcher (Weapons, Armor, Accessories)
4. Покажи equipped indicator (checkmark overlay)

**Приоритет:** P2 (supporting screen)

### 15.5 Shop Screens (4 экрана)

**Основные проблемы:**
- ❌ Price не выделена (buried in text)
- ❌ Comparison feature отсутствует (can't compare with inventory)
- ❌ Stock status не видна

**Направление:**
1. Выведи price в БОЛЬШОЙ gold text
2. Add [Compare with Inventory] button
3. Покажи stock status (In stock / Limited)
4. Highlight best deals (gold glow)

**Приоритет:** P2 (monetization, but supporting)

### 15.6 Battle Result Screen (1 экран)

**Основные проблемы:**
- ❌ Rewards не reveal animation (flat, not rewarding)
- ❌ New items не выделены (no glow)
- ❌ Stats update не видна (no before/after)

**Направление:**
1. Implement reward reveal animation (0.6s → 1.2s hold → 0.4s fade)
2. Add gold glow для new items
3. Покажи stat changes (old → new with arrows)
4. Add celebration particles

**Приоритет:** P1 (core gameplay feeling)

### 15.7 Onboarding Screens (4+ экрана)

**Основные проблемы:**
- ❌ 30+ hardcoded values (не в design system)
- ❌ No token usage
- ❌ Font sizes не стандартизованы

**Направление:**
1. Migrado ALL hardcoded colors на DarkFantasyTheme
2. Use Oswald (titles) + Inter (body) шрифты
3. Standardize padding на LayoutConstants
4. Apply button styles

**Приоритет:** P0 (first-time user experience)

---

## 16. Роадмап миграции (Migration Roadmap)

Следовать этому порядку для успешной migration на design system.

### P0 — Blockers (начать СЕЙЧАС)

1. **Create theme constants (1–2 дня)**
   - [ ] Verify all 200+ color tokens в DarkFantasyTheme.swift
   - [ ] Verify all font definitions в Font extensions
   - [ ] Verify all spacing constants в LayoutConstants.swift
   - [ ] Документировать deprecated hardcoded values

2. **Onboarding migration (3–5 дней)**
   - [ ] Replace 30+ hardcoded values на theme tokens
   - [ ] Standardize onboarding font sizes (minimum 16pt)
   - [ ] Apply button styles

3. **Hub screens migration (3–5 дней)**
   - [ ] Replace hardcoded colors
   - [ ] Standardize padding
   - [ ] Apply button styles to 50+ buttons
   - [ ] Add accessibility labels

### P1 — Critical Quality (неделя 2–3)

4. **Arena screens (5–7 дней)**
   - [ ] Refactor opponent card (side-by-side)
   - [ ] Fix HP bar font (7pt → 18pt)
   - [ ] Apply button styles
   - [ ] Add accessibility

5. **Character screen (3–5 дней)**
   - [ ] Add stat colors
   - [ ] Implement equipment comparison (side-by-side)
   - [ ] Apply rarity system

6. **Battle result screen (3–4 дня)**
   - [ ] Implement reward reveal animation
   - [ ] Add celebration particles
   - [ ] Show stat changes

### P2 — High Quality (неделя 4)

7. **Inventory screens (3–4 дня)**
   - [ ] Refactor grid layout
   - [ ] Add rarity borders
   - [ ] Implement TabSwitcher

8. **Shop screens (3–4 дня)**
   - [ ] Highlight prices
   - [ ] Add comparison feature
   - [ ] Show stock status

### P3 — Polish (неделя 5+)

9. **Settings / Debug screens (1–2 дня)**
   - [ ] Apply theme consistently
   - [ ] Add accessibility labels

10. **Accessibility audit (3–5 дней)**
    - [ ] Verify all touch targets ≥ 44pt
    - [ ] Verify all text ≥ 16pt
    - [ ] Verify contrast ratios (WCAG AA)
    - [ ] Test с screen reader

11. **Animation polish (2–3 дня)**
    - [ ] Fine-tune timings
    - [ ] Add haptics
    - [ ] Test performance

---

## 17. Нерушимые правила (Non-Negotiable Rules)

Эти правила ОБЯЗАТЕЛЬНЫ для всех разработчиков и дизайнеров:

### Цвета
1. ✓ **Все цвета из DarkFantasyTheme.swift** — никогда не hardcode hex codes
2. ✓ **Используй правильное имя токена** — `.danger` не `.red`, `.gold` не `.yellow`
3. ✓ **Glow только для статуса или раритета** — не для decoration

### Типографика
4. ✓ **Минимум 16pt для основного текста** — никогда не ниже
5. ✓ **Oswald UPPERCASE для заголовков** — никогда Inter для titles
6. ✓ **Inter для тела и labels** — никогда system font

### Кнопки
7. ✓ **Все кнопки имеют .buttonStyle()** — никогда custom Frame + colors
8. ✓ **Primary buttons = 56pt** — никогда меньше
9. ✓ **Все кнопки имеют touch feedback** — никогда silent

### Анимации
26. ✓ **ЗАПРЕТ scale-анимаций** — никогда `.scaleEffect()` для press, pulse, bounce, breathing, appear/reveal
27. ✓ **Только opacity feedback** — `.opacity(isPressed ? 0.85 : 1)` вместо scale
28. ✓ **Допустимые scaleEffect** — только статический размер `.scaleEffect(0.8)`, зеркалирование `.scaleEffect(x: -1)`, частицы (VFX)

### Доступность
10. ✓ **Все интерактивные элементы имеют .accessibilityLabel()** — ZERO пропусков
11. ✓ **Touch targets ≥ 44pt** — Apple HIG standard
12. ✓ **Контрастность ≥ 4.5:1** — WCAG AA minimum

### Компоненты
13. ✓ **Repeated elements = shared components** — никогда copy-paste кода
14. ✓ **Cards используют CardStyle** — никогда custom RoundedRectangle
15. ✓ **HPBar / StaminaBar = компоненты** — не hardcoded в screens

### Spacing
16. ✓ **Все отступы из LayoutConstants** — `.MD` не `16`
17. ✓ **Consistent padding на всех экранах** — 16pt left/right
18. ✓ **Section gap = .LG** — 24pt між логическими группами

### Состояния
19. ✓ **Все состояния из State System** — disabled, loading, error, success, etc.
20. ✓ **Empty states имеют сообщение + CTA** — никогда пустой экран
21. ✓ **Locked content показывает requirement** — никогда просто lock icon

### QA перед commit
22. ✓ **Прошел verification checklist** (раздел 14.4)
23. ✓ **Нет hardcoded values** (colors, fonts, spacing)
24. ✓ **Accessibility labels добавлены** (100% coverage)
25. ✓ **Screen reader tested** (if applicable)

---

## 18. Changelog

### Version 2.0.0 (21 марта 2026)

**Что изменилось:**
- ✓ Полная переписка дизайн системы (была 0.8.x, фрагментарная)
- ✓ Добавлены ВСЕ 200+ color tokens (organized in 16 categories)
- ✓ Добавлены ВСЕ 20 button styles (с full specs)
- ✓ Добавлены ВСЕ 17 reusable components (с anatomy + usage)
- ✓ Добавлены 13 game-specific UX rules (comparison, equipment, etc.)
- ✓ Добавлены screen alignment notes (refactor directions)
- ✓ Добавлены accessibility requirements (target: WCAG AA)
- ✓ Добавлены migration roadmap (P0–P3 priority)
- ✓ Добавлены non-negotiable rules (25 items)

**Почему полная переписка:**
- Предыдущая версия была разбита на 5 разных документов
- Не было консистентности между документами
- Нет clear migration path
- Не было обязательных правил (вся команда гадала)
- Отсутствовали game-specific UX patterns

**Следующие шаги:**
- [ ] Обучение разработчиков на этом документе (1 часовая сессия)
- [ ] Review существующих экранов против checklist
- [ ] P0 migration (onboarding + hub)
- [ ] Weekly design system reviews (QA)

---

**ДОКУМЕНТ ЗАВЕРШЁН**

Этот документ является **КАНОНИЧЕСКИМ источником истины** для Hexbound design system.

Последнее обновление: 21 марта 2026 г.
Ответственность: Design Lead / CTO
Рецензия: Еженедельно
