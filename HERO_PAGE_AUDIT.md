# Hero Page — Full UX / Product / System Audit

*Read-only audit · Zero code changes · March 2026*

---

## 1. Executive Summary

Hero page имеет **три критические проблемы**:

1. **Двойной header.** UnifiedHeroWidget в safeAreaInset (80pt) + портрет с HP/XP bars в equipment section (~180pt) = 260pt дублированной identity-информации. Имя, HP, XP, level, avatar показываются **дважды** на первом экране.

2. **Widget не нужен на этой странице.** Hero page — это и есть full-detail view героя. Summary widget создан для экранов где герой — контекст (Hub, Arena, Dungeon), а не фокус. На Hero page widget дублирует то, что equipment section уже показывает лучше и подробнее.

3. **Repair flow скрыт внутри item detail sheet.** Если у игрока 5 сломанных предметов — нужно 5× тапнуть на каждый, 5× нажать "Repair", 5× подтвердить. При этом "Repair Gear" pill в widget видна, но ведёт... никуда (нет Repair All endpoint).

**Главная рекомендация:** убрать UnifiedHeroWidget с Hero page. Заменить на **compact resource strip** (одна строка: ⚡ stamina | 🪙 gold | 💎 gems | действия). Equipment section уже покрывает identity + HP + XP + portrait + level.

---

## 2. Backend / DB Truth Check

| Field / Mechanic | Backend? | Source | Used in Hero UI? | Needed on Hero? | Notes |
|---|---|---|---|---|---|
| characterName | ✅ | Character.characterName | Widget + portrait overlay | ✅ (1 место) | Дублируется |
| level | ✅ | Character.level | Widget badge + portrait badge | ✅ (1 место) | Дублируется |
| avatar | ✅ | Character.avatar | Widget avatar + portrait | ✅ (1 место) | Дублируется |
| class | ✅ | Character.characterClass | Widget class label + portrait icon | ✅ (1 место) | Дублируется |
| currentHp / maxHp | ✅ | Character model | Widget HP bar + equipment HP bar | ✅ (1 место) | Дублируется |
| currentStamina / maxStamina | ✅ | Character model | Widget only | ✅ | Единственный источник, но можно показать компактнее |
| gold | ✅ | Character.gold | Widget only | ✅ | Нужно для repair, upgrade, sell |
| gems | ✅ | User.gems → Character.gems | Widget only | ✅ | Нужно для premium upgrade |
| experience / xpPercentage | ✅ | Character.currentXp (computed) | Widget XP row + equipment XP bar | ✅ (1 место) | Дублируется |
| statPoints | ✅ | Character.statPointsAvailable | Widget stat pill + stats tab badge | ✅ | Показать 1 раз |
| pvpRating / rank | ✅ | Character.pvpRating | Status tab PvP section | ❌ widget | Не нужен в header |
| durability / repair | ✅ | EquipmentInventory per item | Item detail sheet | ✅ | Сейчас per-item only |
| Repair All endpoint | ❌ | Не существует | — | — | Только POST /api/shop/repair (per item) |
| Repair cost formula | ✅ | (maxDur - dur) × 2 gold | ItemDetailSheet | ✅ | Простая формула |
| brokenGearCount | ❌ computed | Client-side filter on inventory | Widget "Broken" pill | ✅ conditional | Показывать только если > 0 |
| combatStance | ✅ | Character.combatStance | Stance card on Hero page | ✅ | Уже отдельная секция |
| equipment stats (8 stats) | ✅ | Computed from equipped items | Status tab | ✅ | Detail-only |
| derived stats | ✅ | armor, magicResist, attackPower | Status tab | ✅ | Detail-only |
| prestige | ✅ | Character.prestigeLevel | Not shown currently | 🟡 optional | Если > 0, показать badge |
| origin | ✅ | Character.origin | Not shown in widget | 🟡 optional | Flavor, не decision data |

---

## 3. Main Jobs To Be Done of HERO Page

| # | Job | Priority | Current Status |
|---|---|---|---|
| **J1** | Посмотреть экипировку и управлять ей (equip/unequip/compare) | 🔴 Primary | ✅ Equipment grid работает |
| **J2** | Починить сломанные предметы | 🔴 Primary | 🟡 Работает, но flow — 5 тапов на 5 предметов |
| **J3** | Распределить stat points после level up | 🔴 Primary | 🟡 Уходит на отдельный экран (CharacterDetailView) |
| **J4** | Проверить stats / derived stats | 🟡 Secondary | ✅ Status tab |
| **J5** | Проверить inventory / продать мусор | 🟡 Secondary | ✅ Inventory tab |
| **J6** | Сменить stance (attack/defense) | 🟡 Secondary | ✅ Stance card |
| **J7** | Улучшить (upgrade) предмет | 🟡 Secondary | ✅ Item detail sheet |
| **J8** | Проверить PvP record / rank | 🟢 Tertiary | ✅ Status tab (нижняя секция) |
| **J9** | Respec stats (reset) | 🟢 Tertiary | ✅ Status tab (нижняя секция) |

---

## 4. Current HERO Page Problems

### 🔴 Critical

**P1. Двойной identity block — 260pt wasted.**
Widget (avatar 48px + name + HP + XP + stamina + gold + gems) занимает ~80pt в safeAreaInset.
Equipment section (portrait ~180pt + HP bar + XP bar + name overlay + level badge) показывает те же данные крупнее и красивее.
Результат: первый экран — это 260pt hero identity, а до inventory/actions нужно скроллить.

**P2. Widget "Repair Gear" pill ведёт в никуда.**
Если widget показывает "⚠ Broken" pill — куда тапнуть? Нет Repair All. Нет shortcut. Pill неинтерактивна (warn style). Игрок видит проблему, но не может решить её из widget.

**P3. Repair flow = O(n) тапов.**
5 сломанных предметов = тапнуть предмет → открыть detail sheet → тапнуть Repair → закрыть → повторить ×5. При формуле `(maxDur - dur) × 2` gold — игрок даже не видит общую стоимость всех ремонтов.

### 🟡 High

**P4. HP bar показан дважды.**
Widget: compact HP bar (8px) + text "1,030/1,030".
Equipment section: ещё один HP bar (10px) + text.
Идентичные данные в двух форматах на одном экране.

**P5. XP bar показан дважды.**
Widget: XP bar в row-3 + "78%".
Equipment section: XP bar под портретом + "78%".

**P6. Name + Level + Class показаны дважды.**
Widget: "Degon ⚔ Warrior · Demon" + level badge.
Portrait: name overlay + class icon + level badge (gold circle).

**P7. Gold/Gems/Stamina видны ТОЛЬКО в widget.**
Если widget убрать — ресурсы пропадут. Но они нужны (gold для repair/upgrade, gems для premium, stamina для context).

**P8. Stat points badge split.**
Widget показывает "⭐ +3 Points → Allocate" pill. Stats tab показывает blinking dot. Информация split между двумя UI layers.

### 🟢 Medium

**P9. Portrait занимает 2×2 ячейки в equipment grid.**
Портрет красивый, но занимает место 4 equipment slots. На маленьких экранах (iPhone SE) это сжимает side columns.

**P10. Stance card всегда видна.**
Attack/Defense stance card показана всегда, даже если игрок не собирается в PvP. Занимает ~60pt.

**P11. Status tab overload.**
Status tab содержит: 8 base stats, equipment bonuses, derived stats, HP section, PvP section (rating/rank/record), resources (gold/gems), Reset Stats button. Это 6+ секций на одном scrollable tab — слишком много.

---

## 5. Does HERO Page Need a Widget?

### Вердикт: **НЕТ. Widget не нужен на Hero page.**

**Почему:**

| Критерий | Hub/Arena/Dungeon | Hero Page |
|---|---|---|
| Герой = контекст или фокус? | Контекст (фокус = действие) | **Фокус** (вся страница о герое) |
| Нужен ли summary? | Да, 1-sec glance перед action | Нет — игрок пришёл именно за деталями |
| Есть ли identity block ниже? | Нет | ДА — портрет + HP + XP + name |
| Нужны ли ресурсы? | В widget | ДА, но можно compactнее |
| Нужны ли actions (heal, stat)? | В widget pills | Уже есть в item detail sheet + stats tab |

Widget оправдан на Hub/Arena/Dungeon потому что там **нет другого места** для identity + resources. На Hero page — есть.

**Исключение:** stamina + gold + gems не показаны нигде кроме widget. Значит нужна **замена** — не widget, а compact resource strip.

---

## 6. Best Header Approach for HERO Page

### Сравнение вариантов

| Вариант | Высота | Pros | Cons |
|---|---|---|---|
| **A. Full widget** (текущий) | ~80pt | Consistent, has resources | Дублирует 6+ полей, wastes space |
| **B. Compact resource strip** | ~36pt | Shows resources, minimal footprint | Не показывает avatar/HP (но они ниже) |
| **C. Resource strip + actions** | ~44pt | Resources + repair/stat CTA | Slightly more, but actionable |
| **D. No header** | 0pt | Max space for content | Ресурсы пропадут |
| **E. Sticky bottom bar** | ~56pt | Thumb zone, always visible | Takes bottom space from inventory |

### ★ Рекомендация: Вариант C — "Resource Strip + Contextual Actions"

```
┌──────────────────────────────────────────────────┐
│ ⚡ 87/120 [+]   🪙 18,640   💎 146   [⚠ Repair] │
└──────────────────────────────────────────────────┘
```

**Высота:** ~40pt (1 строка).
**Содержимое:**
- Stamina: ⚡ current/max + refill button
- Gold: 🪙 formatted
- Gems: 💎 number
- Conditional action: "⚠ Repair" (если есть broken items) или "⭐ +3 Stats" (если есть points)

**Почему это лучше:**
1. **-40pt** vs widget (80→40). Экономия 50%.
2. Не дублирует identity (avatar, name, level, HP, XP — всё уже в equipment section).
3. Ресурсы видны всегда (нужны для repair, upgrade, sell decisions).
4. Contextual action даёт shortcut к основному JTBD.
5. Consistent с mobile game patterns (top resource bar — стандарт).

---

## 7. Repair UX Audit

### Current Flow

```
Игрок замечает "Broken" → Тапает на slot → Открывается ItemDetailSheet →
Видит "REPAIR · 140 💰" → Тапает → Предмет починен → Закрывает sheet →
Повторяет для каждого сломанного предмета
```

**Проблемы:**
- **O(n) тапов.** 5 broken = 15 тапов минимум (open+repair+close × 5).
- **Нет summary.** Игрок не видит "у вас 5 сломанных, общая стоимость 820 gold".
- **Нет shortcut.** Widget показывает "Broken" но не даёт action.
- **Rate limit.** 15 repairs/60sec — достаточно для sequential, но UX всё равно утомительный.

### Backend Constraints

- **Repair All endpoint НЕ существует.** Только `POST /api/shop/repair` per item.
- Repair cost: `(maxDurability - durability) × 2` gold. Простая, детерминированная.
- Payment: gold only.
- Always full repair (durability → maxDurability).

### Рекомендация

**Короткий путь (без backend changes):**
Client-side "Repair All" button, который sequential вызывает `POST /api/shop/repair` для каждого broken item. Показывает:
- Список broken items + individual cost
- Общая стоимость
- "Repair All for 820 🪙" button
- Progress indicator по мере починки каждого

**Где жить:**
1. В compact resource strip как contextual action "⚠ Repair (3)" — тап открывает repair summary sheet
2. В equipment section, если есть broken items — overlay badge на broken slots + "Repair All" card под equipment grid

**Идеальный путь (с backend change):**
Добавить `POST /api/shop/repair-all` endpoint на backend. Но это отдельная задача.

### Visibility Rules

- **Нет broken items** → кнопка не показывается
- **1 broken item** → "⚠ Repair · 140 🪙"
- **N broken items** → "⚠ Repair All (N) · 820 🪙"
- **Не хватает gold** → disabled + "Not enough gold"

---

## 8. Resource Visibility Audit

| Resource | Always Visible? | Currently | Recommendation |
|---|---|---|---|
| **Stamina** ⚡ | ✅ Yes | Widget only | Move to resource strip. Needed for context (can I fight?) |
| **Gold** 🪙 | ✅ Yes | Widget only | Move to resource strip. Needed for repair, upgrade, sell |
| **Gems** 💎 | ✅ Yes | Widget only | Move to resource strip. Needed for premium features |
| **HP** ❤️ | 🟡 1 place | Widget + equipment section | Keep ONLY in equipment section (more detail, larger bar) |
| **XP** ⭐ | 🟡 1 place | Widget + equipment section | Keep ONLY in equipment section (under portrait) |
| **Level** | 🟡 1 place | Widget + portrait badge | Keep ONLY on portrait badge |
| **Name** | 🟡 1 place | Widget + portrait overlay | Keep ONLY on portrait |

**Вывод:** HP, XP, Level, Name — показывать в equipment section (они там лучше и крупнее). Stamina, Gold, Gems — показывать в resource strip (нужны для actions). Widget → удалить.

---

## 9. Layout / Hierarchy Audit

### Current Vertical Stack (scrolled)

```
[safeAreaInset] UnifiedHeroWidget          ~80pt   ← УДАЛИТЬ
[scrollable]
  Equipment Grid (portrait + 13 slots)     ~340pt  ← PRIMARY, keep
  Stance Card                              ~60pt   ← SECONDARY, make conditional
  ─── Gold Divider ───
  Tab Selector (INVENTORY | STATUS)        ~44pt   ← Keep
  Active Quest Banner                      ~48pt   ← Keep (conditional)

  IF INVENTORY:
    Inventory Grid (backpack items)        ~300pt+ ← Keep

  IF STATUS:
    Blacksmith (upgrade CTA)               ~60pt   ← Keep
    8 Base Stats (2 columns × 4)           ~200pt  ← Keep
    Health section                         ~40pt   ← REDUNDANT (already in equip section)
    Derived Stats (2 columns)              ~100pt  ← Keep
    Equipment Bonuses (2 columns × 4)      ~200pt  ← Keep
    Reset Stats                            ~60pt   ← Keep
    PvP section                            ~80pt   ← Keep
    Resources section (gold/gems)          ~60pt   ← REDUNDANT (in resource strip)
```

### Проблемы иерархии

1. **Equipment section** = PRIMARY content. Правильно наверху.
2. **Widget** = дублирует equipment section. Убрать.
3. **Stance card** всегда видна. Сделать conditional или перенести в tab.
4. **Status tab > Health** = дублирует equipment HP bar. Убрать.
5. **Status tab > Resources** = дублирует resource strip. Убрать.

---

## 10. Space Saving Opportunities

| Что | Действие | Space Saved |
|---|---|---|
| UnifiedHeroWidget → Resource Strip | Заменить | **~40pt** |
| Remove HP from Status tab | Убрать (уже в equip section) | **~40pt** |
| Remove XP from Status tab (если есть) | Убрать | **~20pt** |
| Remove Resources from Status tab | Убрать (в resource strip) | **~60pt** |
| Stance card → conditional | Показывать только если stance ≠ default | **~60pt** (иногда) |
| Compact equipment HP/XP bars | Объединить в 1 строку | **~20pt** |

**Общая экономия:** ~100-240pt в зависимости от state.

---

## 11. Recommended Final Direction

### Hero Page After Audit

```
[safeAreaInset] Resource Strip (40pt)
  ⚡ 87/120 [+]  |  🪙 18,640  |  💎 146  |  [contextual action]

[scrollable]
  Equipment Grid                           (keep as-is)
    Portrait + HP bar + XP bar
    13 equipment slots

  Stance Card                              (conditional: if stance ≠ default)

  ─── Divider ───

  Tab Selector: INVENTORY | STATUS
  Active Quest Banner (conditional)

  IF INVENTORY:
    Inventory grid (keep as-is)

  IF STATUS:
    Blacksmith CTA
    8 Base Stats
    Derived Stats
    Equipment Bonuses
    PvP Section
    Reset Stats
    (NO health section — already above)
    (NO resources section — in strip)
```

### What Stays
- Equipment grid с портретом, HP bar, XP bar (primary content)
- Tab selector (INVENTORY | STATUS)
- Inventory grid, stats, derived stats, PvP section
- Blacksmith, Reset Stats

### What Goes
- UnifiedHeroWidget (replaced by resource strip)
- HP section в Status tab (duplicate)
- Resources section в Status tab (duplicate)

### What Becomes Compact
- Header: 80pt widget → 40pt resource strip
- Stance card: always → conditional

### What Becomes Conditional
- Resource strip action: "⚠ Repair (N)" или "⭐ +N Stats" или nothing
- Stance card: hidden if default stance

---

## 12. Risks / Constraints

| Risk | Impact | Mitigation |
|---|---|---|
| **No Repair All endpoint** | Client-side sequential repair is slower | Acceptable UX with progress indicator. Backend change optional. |
| **Removing widget changes context param logic** | `.hero` context code in UnifiedHeroWidget becomes unused | Simply don't pass `.hero` context; widget not rendered on Hero |
| **Resource strip is new component** | Needs new SwiftUI View | Simple HStack, ~40 lines, uses existing tokens |
| **Status tab section removal** | May break scroll position for users who memorized layout | Minor — sections below shift up, net improvement |
| **Broken gear count computed client-side** | Depends on cachedInventory being loaded | Already loaded on Hero page via InventoryViewModel |

---

## 13. Optional Next Step

Если после аудита принято решение двигаться дальше:

1. **Создать `HeroResourceStrip.swift`** — compact resource bar (stamina + gold + gems + conditional action pill). ~40 lines, uses existing DarkFantasyTheme + LayoutConstants tokens.

2. **Заменить widget на resource strip** в `HeroDetailView.swift` safeAreaInset.

3. **Добавить "Repair Summary Sheet"** — bottom sheet с: список broken items, individual costs, total cost, "Repair All" button (sequential API calls).

4. **Удалить duplicate sections** из Status tab (Health, Resources).

5. **Сделать Stance card conditional** (hide if default stance).

Без implementation.
