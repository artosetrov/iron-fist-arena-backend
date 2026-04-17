# Integrated Character Card — Unification Plan

**Дата:** 2026-04-10
**Автор:** Claude (по запросу Artem — "проверь чтобы эти блоки были идентичными")
**Статус:** 🟡 ПРОПОЗАЛ — ждёт утверждения, код не трогаем

> **Status boundary:** Это исторический proposal snapshot от `2026-04-10`. Документ полезен как rationale и forensic-разбор расхождения `HeroIntegratedCard` vs `OpponentIntegratedCard`, но не является текущей live-инструкцией по реализации. За актуальной правдой нужно идти в текущий Swift-код и audited `wiki/`.

---

## Проблема

В кодовой базе живут **два параллельных компонента** с одинаковым визуальным каркасом (портрет + equipment grid), но с расходящимися реализациями фасада, портрета и data-section:

| Компонент | Файл | Используется в |
|---|---|---|
| `HeroIntegratedCard` | `Hexbound/Hexbound/Views/Components/HeroIntegratedCard.swift` | `Views/Hero/HeroDetailView.swift:291` |
| `OpponentIntegratedCard` | `Hexbound/Hexbound/Views/Components/OpponentIntegratedCard.swift` | `Views/Profile/CharacterProfileView.swift:93`, `Views/Leaderboard/LeaderboardPlayerDetailSheet.swift:120` |

Визуально (скриншоты Stoneaxe MAGE Lv.1 ← `OpponentIntegratedCard` и Degon WARRIOR Lv.17 ← `HeroIntegratedCard`) пользователь ожидает увидеть одну и ту же карточку, но получает две разные.

Прямое нарушение правила из `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` и `.claude/skills/ds-code-audit/SKILL.md` — дублирование паттерна вместо переиспользования.

---

## Что совпадает (хорошо)

- Сетка слотов: `3 слева | portrait 2×3 | 3 справа`, снизу `ring · weapon · relic · belt`.
- Рендер слота: `ItemCardView(context: .equipment(slotAsset:))` — единый.
- Логика `findEquippedItem(slot:index:)` — в обоих практически идентична (с поправкой на источник `equipedItems` vs `equipment`).
- Разделитель между grid и data: `Rectangle` с `LinearGradient(borderSubtle)`.
- Data-section использует `HPBarView(size: .large, label: "HP")`.

---

## Что расходится (плохо)

### 1. Фасад карточки

| Аспект | HeroIntegratedCard | OpponentIntegratedCard |
|---|---|---|
| Фон | `RoundedRectangle(bgCardGradient)` + `.stroke(bgCardBorder)` | `RadialGlowBackground` |
| Surface lighting | — | ✅ `surfaceLighting(...)` |
| Inner border | — | ✅ `innerBorder(...)` |
| Corner brackets | — | ✅ `cornerBrackets(...)` |
| Card shadow | — | ✅ `cardShadow()` |
| Compositing group | — | ✅ `compositingGroup()` |

Opponent-карточка "премиальнее" чем Hero-карточка. Это инвертировано: собственный персонаж должен быть не беднее оформленным, чем карточка соперника.

### 2. Расчёт ширины ячейки

| Hero | Opponent |
|---|---|
| `GeometryReader` → `(containerW - 3*gap) / 4` | `UIScreen.main.bounds.width - 2*screenPadding - 2*heroCardPadding` |

Hero-версия **правильная** (адаптируется к любому контейнеру, работает в sheet, в стеке, в колонке). Opponent-версия ломается при смене paddings, хардкодит ширину экрана.

### 3. Портрет (центральный блок 2×3)

| Элемент | HeroIntegratedCard | OpponentIntegratedCard |
|---|---|---|
| Аватар | full-bleed + `portraitVignette` (3 слоя градиентов) | `RoundedRectangle(bgTertiary → bgSecondary)` + одиночный линейный фейд снизу |
| Уровень | ✅ `CardLevelBadge` (DS-компонент) | ❌ inline `Text + Capsule().fill(.gold)` — руками собран |
| Класс-иконка | `Circle` + stroke(.gold.opacity(0.35)) + shadow | `Circle().fill(bgTertiary)` — без бордера |
| Тег класса | ✅ `ClassTagView` (DS-компонент) | ❌ inline `Text(...uppercased())` |
| XP-лейбл в портрете | ✅ `XP 1,375/8,280` | — |
| XP-полоска в портрете | ✅ тонкая capsule bar (height 3) | — |
| Glow-рамка | ✅ `portraitGlowBorder` — `AngularGradient` + `CornerBracketOverlay` + `CornerDiamondOverlay` | — |
| Шиммер-свип | ✅ `LinearGradient` sweep с `shimmerOffset` | — |
| Low-HP pulse ring | ✅ | — |
| Анимации | `glowPhase` (5s rotate) + `shimmerOffset` (2.5s) | — |

Opponent-портрет **перепридуман с нуля инлайн**, минуя все DS-компоненты (`CardLevelBadge`, `ClassTagView`, `CornerBracketOverlay`, `CornerDiamondOverlay`), которые уже существуют в кодовой базе. Это прямое нарушение `ds-code-audit` и `DEVELOPMENT_RULES.md`.

### 4. Data-section под разделителем

| Hero | Opponent |
|---|---|
| `HPBarView(size: .large, label: "HP")` | `HPBarView(size: .large, label: "HP")` + Rank pill (inline `Capsule`) + Rating pill (inline `Capsule`) |

Opponent показывает Rank/Rating — это легитимная смысловая разница (у соперника мы показываем его ранг, у своего героя — нет). Но пилюли собраны руками через `Capsule().fill(...).overlay(Capsule().stroke(...))` вместо использования существующих DS-компонентов `WidgetPill` / `PayoutPill` / `GlassStatPill` со страницы **Badges & Pills**.

### 5. Слот экипировки (tap-обработка)

| Hero | Opponent |
|---|---|
| прямой `ItemCardView` + `onTapSlot` callback | `ItemCardView` внутри `Button`, + `.overlay(RoundedRectangle(cornerRadius: radiusMD).stroke(gold.opacity(0.25)))` если тапабельный |

У тапабельных слотов Opponent-карты появляется **дополнительный золотой бордер поверх** `ItemCardView` — визуальный шум, которого нет у Hero-карты. `ItemCardView` уже имеет свой рамочный стиль по rarity — двойной бордер ломает иерархию.

### 6. Падинг сетки

| Hero | Opponent |
|---|---|
| `.padding(.horizontal, LayoutConstants.spaceMS)` (12pt) | `.padding(.horizontal, LayoutConstants.heroCardPadding)` |

Несогласовано. Одно из двух — опечатка или оставленное legacy-значение.

---

## Предлагаемое решение

Создать единый компонент `IntegratedCharacterCard` и удалить оба существующих. Оба вызывающих места (`HeroDetailView`, `CharacterProfileView`, `LeaderboardPlayerDetailSheet`) переезжают на единый API.

### Новый публичный API

```swift
/// Unified character card: portrait + equipment grid + footer.
/// Used for the player's own hero, opponents in leaderboard, and
/// character profile sheets. Single source of truth for all such cards.
@MainActor
struct IntegratedCharacterCard<Footer: View>: View {
    let display: CharacterDisplay      // protocol extracted below
    let equipment: [Item]
    var onTapPortrait: (() -> Void)? = nil
    var onTapSlot: ((Item) -> Void)? = nil
    @ViewBuilder var footer: () -> Footer

    // body: full premium treatment — RadialGlowBackground + surfaceLighting
    //       + innerBorder + cornerBrackets + cardShadow + compositingGroup.
    //       Grid uses adaptive GeometryReader sizing (Hero version).
    //       Portrait uses full premium treatment (Hero version).
}
```

### Протокол источника данных

```swift
protocol CharacterDisplay {
    var characterName: String { get }
    var characterClass: CharacterClass { get }
    var avatar: String? { get }
    var level: Int { get }
    var currentHp: Int { get }
    var maxHp: Int { get }
    var experience: Int? { get }       // nil → XP-bar в портрете скрыт
    var xpNeeded: Int { get }
    var hpPercentage: Double { get }
    var xpPercentage: Double { get }
    var prestigeLevel: Int? { get }    // nil → прячем prestige-бейдж
}
```

`Character` и `OpponentProfile` оба реализуют этот протокол через `extension`. Реальных изменений в моделях нет — только добавляем conformance.

### Portrait (единый премиум)

Берём целиком реализацию из `HeroIntegratedCard.heroPortrait()`:

- full-bleed `AvatarImageView`
- `portraitVignette` (3-слойная)
- top-row: class-icon badge (Circle + gold stroke) + `CardLevelBadge` (DS)
- bottom-row: name (`body.bold`) + `ClassTagView` (DS) + XP-label + XP-bar (если `experience != nil`)
- `portraitGlowBorder` (AngularGradient + `CornerBracketOverlay` + `CornerDiamondOverlay`)
- shimmer sweep
- low-HP pulse ring
- prestige-бейдж внизу-справа (если `prestigeLevel > 0`)

Условность **единственная**: XP-блок (label + polоска) прячется, когда `experience == nil`.

### Grid (единая адаптивная)

Версия Hero через `GeometryReader` + `aspectRatioForGrid`. Убираем `UIScreen.main.bounds.width`-хардкод полностью.

### Footer через ViewBuilder

Вызывающие места передают свой контент:

```swift
// HeroDetailView
IntegratedCharacterCard(
    display: character,
    equipment: equipped,
    onTapPortrait: { ... },
    onTapSlot: { item in ... }
) {
    HPBarView(currentHp: character.currentHp, maxHp: character.maxHp, size: .large, label: "HP")
}

// LeaderboardPlayerDetailSheet / CharacterProfileView
IntegratedCharacterCard(
    display: profile,
    equipment: profile.equipment ?? [],
    onTapPortrait: nil,
    onTapSlot: { item in onItemTapped?(item, playerItem(forSlot: ...)) }
) {
    VStack(spacing: LayoutConstants.spaceSM) {
        HPBarView(currentHp: profile.currentHp, maxHp: profile.maxHp, size: .large, label: "HP")
        OpponentRankRow(rank: profile.pvpRank, rating: profile.pvpRating)
    }
}
```

Новый тонкий компонент `OpponentRankRow` — ровно две пилюли, построенные из **существующих** DS-пилюль (`WidgetPill` или `GlassStatPill`, посмотреть по месту что лучше ложится). Inline `Capsule + overlay(stroke)` выпиливаем.

### Слоты

Единая реализация — без дополнительного overlay-бордера. Tap-обработка: один `onTapSlot(item)` callback. `ItemCardView` сам рисует свою рамку по rarity — ничего сверху не накидываем.

---

## Затронутые файлы

### Новое

1. `Hexbound/Hexbound/Views/Components/IntegratedCharacterCard.swift` — новый компонент.
2. `Hexbound/Hexbound/Views/Components/OpponentRankRow.swift` — маленький footer-блок для профиля соперника.

### Удалить

3. `Hexbound/Hexbound/Views/Components/HeroIntegratedCard.swift`
4. `Hexbound/Hexbound/Views/Components/OpponentIntegratedCard.swift`

### Обновить

5. `Hexbound/Hexbound/Views/Hero/HeroDetailView.swift:291` — переключить вызов.
6. `Hexbound/Hexbound/Views/Profile/CharacterProfileView.swift:93` — переключить вызов.
7. `Hexbound/Hexbound/Views/Leaderboard/LeaderboardPlayerDetailSheet.swift:120` — переключить вызов.
8. `Hexbound/Hexbound/Models/Character.swift` — добавить `extension Character: CharacterDisplay`.
9. `Hexbound/Hexbound/Models/OpponentProfile.swift` — добавить `extension OpponentProfile: CharacterDisplay`.

### pbxproj

10. `Hexbound/Hexbound.xcodeproj/project.pbxproj` — добавить 2 новых файла (4 секции × 2 = 8 записей), удалить 2 старых (4 секции × 2 = 8 удалений). ID — `openssl rand -hex 12` (не sequential).

### Figma DS (parity)

11. На странице **Hero & Character** в Figma DS — создать/обновить компонент **Integrated Character Card** с вариантами `variant=Hero|Opponent` (разница только во футере). Portrait + grid — одна и та же master-композиция. Использовать только DS-токены, инстансы `ItemCardView`, `CardLevelBadge`, `ClassTagView`, `HPBarView (Large)`, `WidgetPill/GlassStatPill`.

### Документация

12. `docs/07_ui_ux/SCREEN_INVENTORY.md` — обновить записи HeroDetail, CharacterProfile, LeaderboardDetailSheet.
13. `docs/07_ui_ux/DESIGN_SYSTEM_AUDIT.md` — отметить unification как выполненный пункт.

---

## Исторические вопросы к Artem

Ниже оставлены исходные review-вопросы из proposal-момента. Они важны как контекст того, что тогда считалось спорным, но не должны читаться как текущий open approval queue без перепроверки live-кода.

1. **XP-блок в портрете соперника.** В Hero-портрете есть XP-лейбл + полоска. У соперника поля `experience` / `xpNeeded` в `OpponentProfile` — есть ли они там? Если нет/не хотим показывать XP соперника → оставляем условный рендер по `experience != nil`, всё ок. **Нужен твой ответ: показываем XP соперника или нет?**

2. **Rank/Rating в Hero-карточке.** Сейчас у Hero в data-section только HP. Хочешь добавить Rank/Rating и своему герою тоже (для симметрии)? Или оставляем только соперникам? По умолчанию — **оставляем как есть**, потому что у своего героя ранг показан в HUB-виджете, дублировать не нужно.

3. **Stoneaxe Lv.1, HP 1/160 + "Bronze 955".** На скрине явно отдаётся `OpponentProfile` с low-hp, ranку Bronze и рейтингом 955. Проверь что так и должно быть в UX (карточка соперника с живым HP-баром, а не `1142/1142`-полным). Если UX-неверно (соперник всегда должен показывать max HP) — это отдельный баг данных, не unification.

4. **Portrait animations** (`glowPhase` rotate + `shimmerOffset` sweep) — идут бесконечно. На экране-листе лидерборда несколько карт одновременно. Твой [feedback_no_scale_animations](/sessions/nifty-confident-cori/mnt/.auto-memory/feedback_no_scale_animations.md) про scale я помню, эти анимации — opacity/gradient-only, в запрет не попадают. Но **если несколько карт в списке → могут быть FPS-просадки**. Предлагаю: в `LeaderboardPlayerDetailSheet` (single card в sheet) — анимации включены, в потенциальных будущих list-контекстах — параметром `animated: Bool = true` отключаемо. **Подтверди.**

5. **Двойной бордер на тапабельных слотах соперника** — его убираем (читай раздел 5 выше). Если это была сознательная подсказка "этот слот тапабельный" — можно заменить на более тонкий сигнал: лёгкий scale-hover… ой, scale запрещён → на `opacity(0.92)` при press state через `.buttonStyle(.plain)` с `configuration.isPressed`. **Подтверди, что двойной бордер уходит.**

---

## Исторический план работ

Это исходный phased plan из proposal-момента. Он сохранён как след того, как предлагалось делать unification, а не как подтверждение, что этот exact план всё ещё должен выполняться без пересверки текущего состояния.

1. **Фаза 1 — протокол и новый компонент** (не ломаем ничего)
   - Добавить `CharacterDisplay` protocol + extensions на `Character` и `OpponentProfile`
   - Создать `IntegratedCharacterCard.swift` + `OpponentRankRow.swift`
   - Добавить в pbxproj
   - Собрать проект — оба старых компонента ещё живут параллельно

2. **Фаза 2 — переезд call-sites**
   - `HeroDetailView`, `CharacterProfileView`, `LeaderboardPlayerDetailSheet` — переключить на новый компонент
   - Визуальная проверка всех трёх экранов (screenshot diff против текущего состояния)

3. **Фаза 3 — удаление**
   - Удалить `HeroIntegratedCard.swift` и `OpponentIntegratedCard.swift`
   - Удалить их из pbxproj
   - `grep -rn "HeroIntegratedCard\|OpponentIntegratedCard"` — должно быть пусто

4. **Фаза 4 — Figma parity**
   - Обновить компонент на странице Hero & Character в Figma DS
   - Post-creation audit по `FIGMA_SCREEN_RULES.md` Rule 7

5. **Фаза 5 — docs + commit**
   - Обновить `SCREEN_INVENTORY.md`, `DESIGN_SYSTEM_AUDIT.md`
   - Commit message: `refactor(ui): unify Hero/Opponent integrated cards into IntegratedCharacterCard`
   - Обязательный CDO scan перед коммитом

---

## TL;DR

Два компонента делают одно и то же, но с расходящимися реализациями портрета, фасада, grid-sizing и footer-pills. Opponent-версия — **перепридумывает** DS-компоненты инлайн (`CardLevelBadge`, `ClassTagView`, `CornerBracketOverlay`), Hero-версия — **использует их правильно**. Unification = один компонент `IntegratedCharacterCard<Footer>` с адаптивной grid + премиум portrait-композицией + ViewBuilder footer. Hero передаёт просто HP-бар, Opponent — HP + rank/rating pills. Модели получают `CharacterDisplay` conformance.

**На момент создания документа предложение ожидало ответа по 4 вопросам (XP соперника, Rank/Rating у героя, animations в list, двойной бордер) перед стартом Фазы 1.**
