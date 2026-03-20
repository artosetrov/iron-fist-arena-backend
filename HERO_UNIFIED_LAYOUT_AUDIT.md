# Hero Page — Unified Layout Hypothesis Audit

*Read-only · Zero code changes · March 2026*

---

## 1. Executive Summary

**Гипотеза сильная, но требует уточнения.**

Что правильно: объединить portrait zone с summary info, убрать дублирование верхнего widget, перенести secondary slots вниз. Это решает главную проблему — **два слоя hero identity на одном экране** (widget 80pt + portrait block 270pt = 350pt только на identity, ноль actionable content).

Что нужно уточнить:
- "Attack / Defense tabs" — это **не tabs**, а **stance selector card**. Это один tappable card (ATTACK: CHEST / DEFENSE: CHEST) с навигацией на StanceSelector экран. Его нельзя "убрать" — stance реально влияет на PvP combat. Но его можно **сжать** до inline pill/badge.
- Weapon slots вниз — логично, если portrait zone расширяется. Но нижний ряд не должен быть перегружен (6+ слотов в 1 линию при 64pt = tight).

**Главная рекомендация:** Integrated Hero Block — portrait + bars + resources + actions в одном cohesive блоке. Equipment slots: core armor по бокам портрета, weapons + jewelry в compact нижнем ряду. Stance — inline pill внутри hero block. Верхний widget → удалить полностью.

---

## 2. Backend / DB Truth Check

| Field / Mechanic | Backend? | Source | Used in Hero UI? | Relevance | Notes |
|---|---|---|---|---|---|
| characterName | ✅ | Character.characterName | Widget + portrait overlay | Merge into 1 place | |
| characterClass | ✅ | Character.characterClass | Widget class label + portrait icon | Merge | |
| level | ✅ | Character.level | Widget badge + portrait badge | Merge | |
| avatar / skinKey | ✅ | Character.avatar | Widget thumbnail + portrait | Merge | |
| currentHp / maxHp | ✅ | Character model | Widget HP bar + equip section HP bar | Merge | |
| currentXp / xpPercentage | ✅ | Character.currentXp (computed) | Widget XP row + equip section XP bar | Merge | |
| currentStamina / maxStamina | ✅ | Character model | Widget only | Keep | |
| gold | ✅ | Character.gold | Widget only | Keep | Needed for repair/upgrade |
| gems | ✅ | User.gems → Character.gems | Widget only | Keep | Needed for premium |
| **combatStance** | ✅ | Character.combatStance | stanceSummaryCard (~60pt) | **Not a tab — it's a card** | {attack: "chest", defense: "chest"} |
| Stance API | ✅ | POST /api/characters/stance | StanceSelector screen | Used in PvP combat resolution | |
| Equipment: 13 EquipSlots | ✅ | EquipmentInventory | Equipment grid | All have items | ACCESSORY missing from UI |
| Repair per-item | ✅ | POST /api/shop/repair | ItemDetailSheet | Cost = (maxDur - dur) × 2 gold | |
| Repair All | ❌ | Does not exist | — | Client-side sequential possible | |
| statPoints | ✅ | Character.statPointsAvailable | Widget stat pill + Status tab | | |
| durability / broken | ✅ | EquipmentInventory per item | ItemDetailSheet only | **Not visible on paperdoll** | |

---

## 3. Main Problems of Current HERO Layout

### Structural

| # | Problem | Severity | Vertical Cost |
|---|---|---|---|
| P1 | **Two hero identity blocks** — widget (80pt) repeats what portrait section shows | 🔴 Critical | 80pt wasted |
| P2 | **HP/XP shown twice** — widget bars + equip section bars | 🔴 Critical | ~30pt wasted |
| P3 | **Name shown twice** — widget + portrait overlay | 🟡 High | — |
| P4 | **Level shown twice** — widget badge + portrait badge | 🟡 High | — |
| P5 | **Bottom ring row has 168pt empty** — 2 Color.clear spacers | 🟡 High | 84pt wasted |
| P6 | **Stance card is always visible** — even when default (non-changed) | 🟡 High | 60pt always |
| P7 | **Resources only in widget** — if widget goes, resources go too | 🔴 Critical | Need replacement |

### Visual / UX

| # | Problem | Impact |
|---|---|---|
| P8 | Equipment slots (84×84) visually outweigh portrait (176×176) | Слабый hero feel |
| P9 | HP bar crammed into 176pt wide zone with 11pt text | Нечитаемо |
| P10 | Durability not visible on paperdoll | Broken items invisible |
| P11 | 4 UI layers before inventory: widget → equip → stance → tabs | Cognitive overload |

**Суммарная потеря:** ~240pt вертикального пространства на дублирование + пустые ячейки + oversize stance card. На 700pt visible screen — это **34%**.

---

## 4. Attack / Defense "Tabs" Audit

### Факт: это НЕ tabs

На скриншоте "ATTACK / DEFENSE / CHEST / CHEST" — это **стance summary card**, не tab selector. Код: `stanceSummaryCard()` в HeroDetailView line 798.

```swift
Button {
    appState.mainPath.append(AppRoute.stanceSelector)
} label: {
    HStack { "⚔️ ATTACK" + stance.attack + divider + "🛡️ DEFENSE" + stance.defense }
    .panelCard(highlight: true)
}
```

Это **один tappable card** (56pt high), который навигирует на отдельный StanceSelector экран при тапе.

### Backend relevance

`combatStance` — реальное поле Character, содержит `{attack: "chest", defense: "chest"}`. Используется в PvP combat resolution (`pvp/prepare/route.ts` line 191). Влияет на бой: определяет зону атаки и зону защиты.

### Вердикт: нельзя убрать, но можно сжать

Stance — функционален. Убрать нельзя. Но **отдельная 56pt карточка** — overkill для двух слов ("Chest" / "Chest").

**Рекомендация:** заменить stance card на **inline pill** внутри hero block:
```
⚔ Chest · 🛡 Chest  [Edit]
```
Одна строка ~28pt вместо 56pt карточки с панелью. Экономия: ~28pt.

---

## 5. Central Hero Block Audit

### Текущее состояние

Portrait zone = 176×176pt портрет + 30pt HP/XP bars + margins = ~220pt. Вокруг: 6 слотов по 84×84. Внизу: 2 ряда (4+4 слотов, но 2 пустых).

**Проблема:** portrait zone — чисто visual. Информация (name overlay, level badge, class icon, HP/XP bars) scattered, мелкая, дублирована. Это не "hero command center" — это "equip screen с картинкой".

### Гипотеза: превратить в integrated hero block

Если объединить в portrait zone:
- Portrait (крупнее, ~55% width)
- Name + Class + Level (в header area)
- HP / XP bars (full-width, над или под portrait)
- Resources (stamina, gold, gems)
- Stance (inline pill)
- Repair action (conditional pill)
- Stat points action (conditional pill)

Тогда:
- **Widget полностью удаляется** (−80pt)
- **HP/XP bars не дублируются** (−30pt)
- **Stance card сжимается** (−28pt)
- **Name overlay убирается** с портрета (чистый portrait)
- **Bottom ring row без пустых ячеек** (−84pt)

**Выигрыш: ~220pt freed** — это 31% экрана.

---

## 6. Slot Layout Audit

### Текущий arrangement

```
3 left (Head, Chest, Legs) | Portrait | 3 right (Amulet, Gloves, Boots)
4 bottom row 1 (Belt, Weapon, Relic, Necklace)
4 bottom row 2 (Ring, EMPTY, EMPTY, Ring)
```

13 displayed (ACCESSORY missing), 2 empty cells.

### Гипотеза: weapon slots вниз

Weapon + Relic — "combat" slots. Логично рядом. Если убрать из bottom row и Belt, создать:

**Side slots (armor, 6):** Head, Chest, Legs, Gloves, Boots, Belt — по 3 с каждой стороны.
**Bottom row (combat + jewelry, 5):** Weapon, Relic, Amulet, Ring 1, Ring 2.

Это 11 слотов. Necklace и Accessory — removed (как обсуждено ранее).

**Impact:**
- ✅ Body mapping: armor вокруг тела, combat/jewelry ниже — логично
- ✅ No empty cells
- ✅ Portrait gets more space (belt freed from side column or moved down)
- 🟡 Bottom row 5 × 64pt + 4 × 8gap = 352pt — fits в 361pt content width. Tight но OK.

---

## 7. Resource & Summary Embedding Audit

### Что должно жить в central block

| Data | Embed in hero block? | Why |
|---|---|---|
| Portrait (large) | ✅ Yes — primary | Hero identity anchor |
| Name | ✅ Yes — text above portrait | Single source |
| Class + Level | ✅ Yes — inline with name | "Degon · Warrior · Lv.14" |
| HP bar | ✅ Yes — full-width above or below portrait | Primary readiness info |
| XP bar | ✅ Yes — thinner, under HP | Secondary progression |
| Stamina | ✅ Yes — inline resource | Needed for decisions |
| Gold | ✅ Yes — inline resource | Needed for repair/upgrade |
| Gems | ✅ Yes — inline resource | Needed for premium |
| Stance | ✅ Yes — inline pill | Compact, functional |
| Repair action | ✅ Yes — conditional pill | Shows only when broken items |
| Stat points | ✅ Yes — conditional pill | Shows only when > 0 |

### Что НЕ должно жить в central block

| Data | Why Not |
|---|---|
| Full stats (STR, AGI, etc.) | Detail screen — Status tab |
| PvP record | Arena concern, not Hero screen |
| Equipment bonuses | Status tab |
| Derived stats | Status tab |
| Inventory grid | Below tabs — needs its own space |

### Вывод: верхний widget полностью заменяется

Всё что widget показывал — теперь внутри central hero block. Widget удаляется. Ноль дублирования.

---

## 8. HP / XP / Level Placement Audit

### Варианты

| Placement | Pros | Cons |
|---|---|---|
| **A. Above portrait, full-width** | Читаемо, 361pt wide, 12px font fits | Отделяет bars от hero identity |
| **B. Inside hero block header** | Compact, name+bars+resources в одном header | Может быть тесно |
| **C. Below portrait, inside hero block** | Связано с portrait визуально | Crammed (текущая проблема) |
| **D. Overlay на портрете (bottom edge)** | Space-efficient | Covers portrait, hurts fantasy feel |

**Рекомендация: Вариант A** — HP/XP bars full-width в hero block header, над слотами но внутри одного card/container. Name + Class + Level строкой выше bars. Resources строкой ниже bars. Всё — один visual unit.

### Hierarchy

```
1. Name + Class + Lv.14             ← identity line
2. ████████ HP ████████  1030/1030  ← primary bar (12pt high)
3. ████ XP ████          78%        ← secondary bar (8pt high)
4. ⚡87/120  🪙18.6K  💎146         ← resources line
5. [⚔Chest·🛡Chest] [⚠Repair(3)]  ← action pills (conditional)
───────────────────────────────────
6. [Head] [PORTRAIT 55%] [Gloves]  ← equipment grid
   [Chest]              [Boots]
   [Legs]               [Belt]
───────────────────────────────────
7. Weapon  Relic  Amulet  Ring Ring ← bottom slot row
```

---

## 9. Repair All Audit

### Backend

- `POST /api/shop/repair` — per-item only. Принимает `{character_id, inventory_id}`.
- Repair All endpoint **не существует**.
- Cost: `(maxDurability - durability) × 2` gold.
- Rate limit: 15 repairs/60sec.

### Client-side Repair All

Возможно: sequential вызов API для каждого broken item. Показать:
1. Summary: "3 broken items · Total: 420🪙"
2. Button: "Repair All"
3. Progress: починить один за другим с UI feedback

### Placement

Conditional pill внутри action line (строка 5 в hierarchy):
- **Нет broken items** → pill не показывается
- **1+ broken** → `⚠ Repair (3) · 420🪙` pill
- **Not enough gold** → pill disabled + "Need 420🪙"
- Tap → confirmation bottom sheet с деталями

### Вердикт: Repair All оправдан

Без backend change. Client-side sequential. Pill внутри hero block. Показывать только когда нужно.

---

## 10. Alternative Layout Directions

### Direction A: Integrated Hero Card

```
┌─────────────────────────────────────────┐
│ Degon · Warrior · Lv.14                 │
│ ████████████████ HP ████ 1030/1030      │
│ ████████ XP ████         78%            │
│ ⚡87/120  🪙18.6K  💎146                │
│ [⚔Chest·🛡Chest]  [⚠Repair(3)]        │
├─────┬─────────────────────┬─────────────┤
│Head │                     │ Gloves      │
│Chest│     PORTRAIT        │ Boots       │
│Legs │     (55% width)     │ Belt        │
├─────┴─────────────────────┴─────────────┤
│ Weapon  Relic  Amulet  Ring  Ring       │
└─────────────────────────────────────────┘
```

**Плюсы:** Один unified block. Ноль дублирования. Portrait доминирует. Bars читаемы. Actions видны.
**Минусы:** Много контента в одном card — может быть visually heavy.
**Fantasy feel:** Сильный — "hero card" как в коллекционной карточке.
**Mobile UX:** ✅ Bars full-width, slots ≥ 64pt, pills 32pt.

### Direction B: Minimal Header + Expanded Center

```
⚡87/120  🪙18.6K  💎146    [⚠Repair]
─────────────────────────────────────────
HP ██████████████████████  1030/1030
XP ████████████              78%
─────────────────────────────────────────
Head  │     PORTRAIT      │  Gloves
Chest │   (very large)    │  Boots
Legs  │  Degon · Lv.14    │  Belt
      │  ⚔Chest·🛡Chest  │
─────────────────────────────────────────
Weapon  Relic  Amulet  Ring  Ring
```

**Плюсы:** Портрет максимально крупный. Name + stance на портрете. Resources minimal strip.
**Минусы:** Name/stance overlay на портрете — снижает clean portrait feel.
**Fantasy feel:** Средний — portrait dominant но cluttered.
**Mobile UX:** ✅ Resources доступны.

### Direction C: Two-Zone Split (Portrait-Hero + Equipment-Grid)

```
Resource Strip (⚡ 🪙 💎)
─────────────────────
│  PORTRAIT (60% w)  │
│  Degon · Lv.14     │
│  Warrior            │
│  HP bar overlay     │
│  XP bar overlay     │
─────────────────────
[⚔Chest·🛡Chest] [⚠Repair] [⭐+3 Stats]
─────────────────────
Equipment Grid (4×3 or custom layout)
    All 11 slots same size, no portrait in grid
─────────────────────
Inventory / Status tabs
```

**Плюсы:** Portrait очень крупный (60% width), чистый. Equipment отдельно.
**Минусы:** Equipment отключён от body — нет "slot вокруг героя" mapping. Потеря ARPG feel.
**Fantasy feel:** Слабый — feels like a profile card, not paperdoll.
**Mobile UX:** ✅ Spacious.

---

## 11. Recommended Final Direction

### ★ Direction A: Integrated Hero Card

**Конкретно:**

1. **Удалить** UnifiedHeroWidget с Hero page (оставить на Hub/Arena/Dungeon).
2. **Создать** HeroEquipmentCard — единый block:
   - Header area: name + class + level | HP bar full-width | XP bar | resources | action pills
   - Grid area: 6 armor slots (3 left, 3 right) вокруг portrait
   - Bottom row: 5 slots (weapon, relic, amulet, ring, ring) — compact
3. **Stance card** → inline pill в action line: `⚔ Chest · 🛡 Chest [Edit]`
4. **Repair** → conditional pill в action line
5. **Stat points** → conditional pill в action line
6. **Portrait** → чистый, без name overlay, 55% width
7. **Level badge** → в header text line ("Lv.14"), не на портрете
8. **HP bar** → 12pt high, full-width, с value text
9. **XP bar** → 8pt high, full-width, secondary
10. **Durability** → red border + ⚠ badge на broken slot icons

**Height estimate:** header (~80pt) + grid (~210pt) + bottom row (~64pt) + gaps (~24pt) = **~378pt**
vs current ~470pt equip block + 80pt widget = **550pt → 378pt = −172pt saved (31%)**

**Почему лучший:**
- **Ноль дублирования** — каждый data point показан 1 раз
- **Portrait доминирует** — 55% width, clean
- **Bars читаемы** — full-width, 12px font
- **Resources видны** — inline в header, не в отдельном widget
- **Actions accessible** — repair, stance, stats в pill line
- **Compact** — 378pt vs 550pt
- **RPG feel** — slots around hero = paperdoll, unified card = collector's card

---

## 12. Risks / Constraints

| Risk | Impact | Mitigation |
|---|---|---|
| Repair All needs sequential API calls | 5 items = 5 round-trips | Show progress, rate limit OK (15/60sec) |
| Stance pill loses visual prominence | Players might miss stance config | Gold border + "Edit" text. Still tappable |
| 11 slots (not 13) means 2 slot types hidden | NECKLACE + ACCESSORY items orphaned | Either re-assign items to other slots in DB, or add expandable section |
| Header + grid + bottom = complex single component | SwiftUI layout complexity | Modular sub-views: HeroCardHeader, HeroEquipmentGrid, HeroBottomSlots |
| Portrait 55% on iPhone SE (375pt) | Portrait 206pt, slots 60pt each | Test on SE. Slots still ≥ 44pt minimum |

---

## 13. Optional Next Step

1. **Прототип** — HTML mockup Direction A с реальными размерами и всеми state variations
2. **Token update** — Добавить `LayoutConstants.heroCard*` tokens для нового layout
3. **HeroEquipmentCard.swift** — Создать новый компонент, заменить equipmentSection + widget
4. **Stance pill** — Новый inline StancePill.swift компонент (reuse WidgetPill pattern)
5. **Repair summary sheet** — Bottom sheet с broken items list + total cost + sequential repair
6. **Durability indicator** — Red border + ⚠ badge на slot icons для broken items
7. **Remove widget from Hero** — Заменить safeAreaInset на HeroEquipmentCard
8. **Test** — iPhone 15 Pro + iPhone SE + всех 11 states

Без implementation.
