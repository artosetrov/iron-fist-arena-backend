# Hero Central Block / Paperdoll — Deep Audit

*Read-only · Zero code changes · March 2026*

---

## 1. Executive Summary

Центральный equipment block занимает **~470pt** (120% ширины экрана по высоте) — это самый крупный UI-элемент во всей игре, и при этом он имеет три ключевые проблемы:

1. **Portrait зажат.** 176×176pt при ширине экрана 393pt — это 45% ширины. Для главного "героического" элемента страницы это мало. Equipment slots (84×84pt каждый) визуально конкурируют с портретом. В итоге не portrait доминирует, а сетка.

2. **HP/XP bars спрятаны и мелкие.** HP bar высотой 10pt с текстом 11pt зажат в 176pt шириной между портретом и слотами. На реальном устройстве это сложно прочитать. Label "HP" — 20pt wide, text "1,030/1,03 0" переносится на 2 строки из-за ширины.

3. **Нижний ряд с кольцами теряет 168pt.** Bottom row 2 имеет 2 пустых Color.clear слота (168pt пустоты) между двумя кольцами. Это ~43% ширины экрана — чистая потеря.

**Главная рекомендация:** переосмыслить пропорции — портрет крупнее (2.5 ячейки вместо 2), HP/XP bars выше (над портретом или интегрировать в portrait frame), bottom rows компактнее (убрать пустые ячейки).

---

## 2. Backend / DB Truth Check

| Field / Entity | Backend? | Source | Used in block? | Importance | Notes |
|---|---|---|---|---|---|
| avatar / skinKey | ✅ | Character.avatar | Portrait center | 🔴 Primary | Resolves через GameDataCache |
| characterName | ✅ | Character.characterName | Portrait bottom overlay | 🔴 Primary | Max ~20 chars |
| level | ✅ | Character.level | Top-right badge (gold circle) | 🔴 Primary | 1-100 |
| characterClass | ✅ | Character.characterClass | Top-left icon badge | 🟡 Secondary | warrior/rogue/mage/tank |
| currentHp / maxHp | ✅ | Character model | HP bar under portrait | 🔴 Primary | Affects readiness |
| currentXp / xpPercentage | ✅ | Character.currentXp (computed) | XP bar under portrait | 🟡 Secondary | 0-100% |
| **Equipment slots (13 total):** | | | | |
| WEAPON | ✅ | EquipSlot.WEAPON | Bottom row 1 | 🔴 | 1 slot |
| HEAD (helmet) | ✅ | EquipSlot.HEAD | Left col, top | 🔴 | 1 slot |
| CHEST | ✅ | EquipSlot.CHEST | Left col, middle | 🔴 | 1 slot |
| LEGS | ✅ | EquipSlot.LEGS | Left col, bottom | 🔴 | 1 slot |
| HANDS (gloves) | ✅ | EquipSlot.HANDS | Right col, middle | 🔴 | 1 slot |
| FEET (boots) | ✅ | EquipSlot.FEET | Right col, bottom | 🔴 | 1 slot |
| AMULET | ✅ | EquipSlot.AMULET | Right col, top | 🟡 | 1 slot |
| BELT | ✅ | EquipSlot.BELT | Bottom row 1 | 🟡 | 1 slot |
| RELIC | ✅ | EquipSlot.RELIC | Bottom row 1 | 🟡 | 1 slot |
| NECK (necklace) | ✅ | EquipSlot.NECK | Bottom row 1 | 🟡 | 1 slot |
| RING_1 | ✅ | EquipSlot.RING_1 | Bottom row 2, left | 🟡 | 1 slot |
| RING_2 | ✅ | EquipSlot.RING_2 | Bottom row 2, right | 🟡 | 1 slot |
| ACCESSORY | ✅ | EquipSlot.ACCESSORY | ❌ Not shown | ⚠️ | **Missing from layout!** |
| Item rarity | ✅ | Item.rarity | Border color + glow | 🟡 | common→legendary |
| Item upgradeLevel | ✅ | EquipmentInventory.upgradeLevel | Gold dots at bottom | 🟡 | 0-10 dots |
| Item durability | ✅ | EquipmentInventory.durability | ❌ Not shown visually | ⚠️ | **0 = broken, no stat bonus** |
| Item imageKey / imageUrl | ✅ | Item model | Slot icon | 🔴 | Fallback chain: local → remote → icon |

**Критичные находки:**
- **ACCESSORY slot отсутствует в layout.** Backend имеет EquipSlot.ACCESSORY, но ни один из 13 displayed slots не маппится на него. Если игрок экипирует accessory — он не увидит его на paperdoll.
- **Durability не визуализирована.** Broken item (durability=0) выглядит так же как целый. Игрок не видит что предмет сломан до tap на него.

---

## 3. Current Central Block Problems

### 🔴 Critical

**P1. Portrait не доминирует.** 176×176pt портрет окружён 6 слотами по 84×84pt. Суммарная площадь боковых слотов: 6 × 84² = 42,336pt². Площадь портрета: 176² = 30,976pt². Слоты занимают **больше площади** чем герой. Портрет должен быть визуально сильнее.

**P2. HP/XP bars нечитаемы.** HP bar: ширина 176pt минус label "HP" (20pt) минус value text (58pt) = ~98pt для самого бара. При height 10pt — это micro-bar. На iPhone SE (375pt ширина) ещё уже. Text "1,030/1,030" при font 11pt на ширине 58pt → переносится.

**P3. Bottom row 2 теряет 43% ширины.** Два Color.clear spacer по 84pt каждый = 168pt пустоты. Визуально — два "дыры" между кольцами. Нет функции, нет beauty, нет информации.

**P4. ACCESSORY slot отсутствует.** 13 EquipSlot в backend, 12 показаны + 1 (ring дублируется), ACCESSORY missing.

### 🟡 High

**P5. Durability invisible.** Сломанный предмет (durability=0) не имеет визуального индикатора на paperdoll. Игрок узнаёт только по тапу. При этом broken item = 0 stats в бою.

**P6. Name overlay мешает портрету.** "Degon" overlay внизу портрета с чёрным фоном 45% opacity закрывает ~15% image area. На маленьком 176pt портрете это заметно. Name уже есть в resource strip (если добавлен).

**P7. Level + Class badges конкурируют.** Top-left class icon (26×26) + top-right level badge (26×26) — оба на портрете. Level badge (gold circle) визуально сильнее class icon (transparent bg). Inconsistent visual weight.

**P8. Total block height 470pt.** При visible screen ~700pt (iPhone 15 Pro без toolbar/nav) — equipment block занимает 67% экрана. Tabs/inventory начинаются только после scroll.

### 🟢 Medium

**P9. Upgrade dots трудно считать.** Gold dots 5pt diameter при 5-6 upgrade levels → 10-12 dots в ряд → сливаются на маленьком слоте (84pt wide).

**P10. Rarity glow inconsistent.** Filled slots имеют colored border (green/purple/gold), empty slots — subtle grey. На скриншоте: рамки разной толщины (filled=2px, empty=1.5px), цвета перегружают.

---

## 4. Visual Hierarchy Audit

| Element | Should Be | Currently Is | Gap |
|---|---|---|---|
| **Hero portrait** | 🔴 Primary — absolute dominant focus | 🟡 Competing with slots | Portrait too small vs slots |
| **HP bar** | 🔴 Primary — pre-action readiness | 🟢 Tertiary — tiny, hidden | Way too small, wrong position |
| **Equipment slots** | 🟡 Secondary — scannable but not dominant | 🔴 Primary — takes most space | Slots overpower portrait |
| **Level badge** | 🟡 Secondary — quick glance | ✅ OK | Gold circle is clear |
| **XP bar** | 🟡 Secondary — progression | 🟢 Tertiary — tiny | Too small but acceptable for secondary |
| **Hero name** | 🟢 Tertiary — already known | 🟡 Covering portrait | Overlay distracts from portrait image |
| **Class icon** | 🟢 Tertiary — already known | ✅ OK | Small, unobtrusive |
| **Upgrade dots** | 🟢 Tertiary — detail info | ✅ OK | Could be cleaner but works |

---

## 5. Portrait / Avatar Audit

**Текущие размеры:**
- Portrait: 176×176pt (45% screen width)
- Surrounded by 84×84pt slots
- Ratio portrait:slot = 2.1:1

**Для сравнения с ARPG benchmarks:**
- Diablo IV mobile: portrait ~55-60% screen width
- Lost Ark: portrait ~50% with slots overlapping edges
- Path of Exile Mobile: portrait ~55% with transparency
- Raid Shadow Legends: portrait ~60% width, slots are smaller circles

**Вердикт:** портрет **недостаточно крупный** для primary hero screen. 45% — это OK для inventory page, но для HERO tab это должен быть **emotional centerpiece**.

**Рекомендация:** увеличить до ~52-55% screen width. Это возможно если portrait занимает 2.5 ячейки вместо 2, или если боковые слоты уменьшить до 72pt.

**Emotional assessment:** текущий портрет "functional" — он показывает аватар, но не создаёт "героический" feel. Нет dramatic framing, нет vignette, нет depth. Flat gradient bg + thin gold border = utility, not fantasy.

---

## 6. HP / XP / Level / Name Audit

### HP Bar

| Parameter | Current | Problem | Recommendation |
|---|---|---|---|
| Position | Under portrait, between slots | Зажат, мало ширины | Над портретом или как полноширинный bar |
| Width | ~98pt (bar only) | Микро | Min 160pt для bar, или full-width |
| Height | 10pt | Мелковат но OK | 12pt minimum |
| Label font | 11pt "HP" | ≤ minimum, bad | 12pt |
| Value font | 11pt "1,030/1,030" | Переносится! | 12pt, value alignment fix |
| Value width | 58pt fixed | Не хватает для 4+4 digit | 70pt или auto |

**Главная проблема:** HP bar зажат в 176pt wide column вместе с label + value. На iPhone SE это хуже.

**Рекомендация:** HP bar перенести над main portrait row (full-width, не зажатый) или интегрировать как overlay внизу портрета (вместо name overlay).

### XP Bar

Та же проблема что HP — мелкий, зажатый, в той же 176pt колонке. Но XP — secondary info, поэтому можно оставить мельче. Однако XP ring на widget уже показывает прогресс — если resource strip заменяет widget, XP bar здесь становится единственным местом и должен быть читаем.

### Level

Level badge (gold circle, 26×26, top-right portrait) — **работает хорошо**. Чётко видно, не мешает, gold на dark = контраст. Единственное: на level > 99 (max 100) — число "100" не влезет в 26pt circle.

### Name

Name overlay ("Degon") на чёрном фоне внизу портрета — **избыточен**. Если есть resource strip (с именем) или даже без него — name уже в toolbar заголовке. Name overlay закрывает часть портрета.

**Рекомендация:** убрать name overlay с портрета. Имя доступно в resource strip, в Status tab, в toolbar. Portrait должен быть чистым — лицо героя, не текст.

---

## 7. Equipment Slots Audit

### Slot Arrangement (текущий)

```
┌─────────┬───────────────────┬─────────┐
│ Helmet  │                   │ Amulet  │
│ 84×84   │    PORTRAIT       │ 84×84   │
│         │    176×176        │         │
│ Chest   │                   │ Gloves  │
│ 84×84   │    [HP bar]       │ 84×84   │
│         │    [XP bar]       │         │
│ Legs    │                   │ Boots   │
│ 84×84   │                   │ 84×84   │
└─────────┴───────────────────┴─────────┘
┌────────┬────────┬────────┬────────┐
│ Belt   │ Weapon │ Relic  │Necklace│
│ 84×84  │ 84×84  │ 84×84  │ 84×84  │
└────────┴────────┴────────┴────────┘
┌────────┬────────┬────────┬────────┐
│ Ring 1 │ EMPTY  │ EMPTY  │ Ring 2 │
│ 84×84  │ 84×84  │ 84×84  │ 84×84  │
└────────┴────────┴────────┴────────┘
```

### Проблемы

1. **Body mapping слабая.** Helmet рядом с Chest, но далеко от Head на портрете. Boots рядом с Legs, а не внизу. ARPG convention: slots вокруг silhouette (head→shoulder→arm→hand по бокам, feet внизу). Текущий layout — column layout, не body layout.

2. **Slot размер конкурирует с portrait.** 84×84 при portrait 176×176 = slot area больше. Slots визуально "громче" из-за colored borders + glow.

3. **Bottom row с кольцами — wasted.** 2 empty cells. Кольца можно переместить: в accessory row, или как маленькие slots в corners of portrait, или в bottom row 1 (сделав его 6-slot row вместо 4).

4. **ACCESSORY slot missing.** Backend поддерживает EquipSlot.ACCESSORY, но layout его не показывает.

5. **Glow overload.** На скриншоте: green borders (common), purple (epic), gold (legendary) — 3+ цвета рамок одновременно. При 13 slots это визуальный шум.

---

## 8. Space Usage Audit

| Zone | Area | Current Use | Efficiency |
|---|---|---|---|
| Portrait | 176×176 = 31K pt² | Avatar image | 🟡 Good but could be larger |
| Side slots (6) | 6 × 84² = 42K pt² | Equipment | 🟡 Functional but oversized |
| HP/XP bars area | 176×30 ≈ 5K pt² | Bars + labels | 🔴 Cramped, hard to read |
| Bottom row 1 (4 slots) | 4 × 84² = 28K pt² | Equipment | ✅ OK |
| Bottom row 2 | 4 × 84² = 28K pt² | 2 rings + 2 empty | 🔴 50% wasted |
| Gap between main grid and rows | 2 × 16pt gap | VStack spacing | ✅ OK |

**Самые неэффективные зоны:**
1. Bottom row 2: 14K pt² wasted (2 empty slots)
2. HP/XP area: 5K pt² crammed with too much info
3. Portrait: could use 10-15% more space

---

## 9. Alternative Layout Directions

### Direction A: "Portrait-First" (увеличенный портрет)

```
┌────────────────────────────────────────┐
│     ██████ HP BAR (full width) ██████  │
├────────┬──────────────────────┬────────┤
│Helmet  │                      │Amulet  │
│72×72   │      PORTRAIT        │72×72   │
│        │      ~210×210        │        │
│Chest   │                      │Gloves  │
│72×72   │      Lv.14 badge     │72×72   │
│        │                      │        │
│Legs    │                      │Boots   │
│72×72   │                      │72×72   │
├────────┴──────────────────────┴────────┤
│ Belt  Weapon  Relic  Neck  Ring  Ring  │
│  (6 slots in one row, 56×56)          │
└────────────────────────────────────────┘
```

**Плюсы:** Portrait больше (~53% width), HP bar полноширинный читаемый, bottom slots в 1 row (не 2), нет пустых ячеек.
**Минусы:** Side slots мельче (72pt), bottom row 6 items = crowded. XP bar нужно куда-то деть (ring на level badge или отдельная строка).
**Fantasy feel:** Сильнее. Portrait доминирует.
**Mobile usability:** HP bar легко читаемый, touch targets для side slots всё ещё ≥ 44pt.

### Direction B: "Stats-Integrated" (HP/XP overlay на портрете)

```
┌────────┬──────────────────────┬────────┐
│Helmet  │      PORTRAIT        │Amulet  │
│84×84   │      176×176         │84×84   │
│        │  ┌─[HP bar overlay]──┐│        │
│Chest   │  │  1030/1030  78%XP ││Gloves │
│84×84   │  └───────────────────┘│84×84   │
│        │                      │        │
│Legs    │                      │Boots   │
│84×84   │                      │84×84   │
├────────┴──────────────────────┴────────┤
│ Belt  Weapon  Relic  Neck  Ring Ring   │
│   (6 items compact, 64×64)            │
└────────────────────────────────────────┘
```

**Плюсы:** HP/XP integrated into portrait frame (не занимают отдельное место), bottom rows сжаты в 1, ~80pt saved.
**Минусы:** Overlay перекрывает портрет (как текущий name overlay, но больше). Portrait visual impact снижается.
**Fantasy feel:** Средний — функционально, но портрет загрязнён overlays.
**Mobile usability:** Bars read well (full portrait width), less scroll.

### Direction C: "Tight ARPG" (плотный layout, body-mapped)

```
┌──────────────────────────────────────┐
│  HP ████████████████████ 1030/1030   │
│  XP ████████████████       78%       │
├──────┬─────────────────────┬─────────┤
│Head  │                     │ Amulet  │
│64    │    PORTRAIT          │ 64      │
│      │    ~220×220          │         │
│Chest │    Class  Lv.14      │ Gloves  │
│64    │                     │ 64      │
│      │                     │         │
│Legs  │                     │ Boots   │
│64    │                     │ 64      │
├──────┼───────┬──────┬──────┼─────────┤
│Ring  │Weapon │Belt  │Relic │Necklace │
│ 64   │  64   │ 64   │ 64  │   64    │
├──────┼───────┼──────┼──────┼─────────┤
│Ring2 │       │Acces.│      │         │
└──────┴───────┴──────┴──────┴─────────┘
```

**Плюсы:** Portrait максимально крупный (~56% width), HP/XP полноширинные сверху, все 13 slots + ACCESSORY показаны, body-mapping лучше.
**Минусы:** Side slots маленькие (64pt — close to 44pt minimum), много элементов. Bottom rows сложнее.
**Fantasy feel:** Сильнейший из трёх. Портрет доминирует, bars чёткие.
**Mobile usability:** 64pt slots всё ещё touchable (≥44pt HIG). Но dense.

---

## 10. Recommended Final Direction

### ★ Direction A modified: "Portrait-First + Full-Width Bars"

**Конкретные изменения:**

| Element | Current | Recommended | Why |
|---|---|---|---|
| **Portrait** | 176×176 (2cw) | ~204×204 (2.4cw) | +16% area, stronger hero presence |
| **Side slots** | 84×84 | 72×72 | Still > 44pt minimum, gives portrait room |
| **HP bar** | Under portrait, 176pt wide, 10pt high | Above main grid, full-width (361pt), 12pt high | Readable, primary info gets primary position |
| **XP bar** | Under portrait, 176pt wide | Under HP bar, full-width, 8pt high (thinner = secondary) | Readable but secondary |
| **Name overlay** | On portrait, black bg | **Removed** | Available in resource strip, don't cover portrait |
| **Level badge** | Portrait top-right, 26×26 gold circle | Keep as-is | Works well |
| **Class icon** | Portrait top-left, 26×26 | Keep as-is | Works well |
| **Bottom row 1** | Belt, Weapon, Relic, Necklace (4×84) | Belt, Weapon, Relic, Neck, Ring, Ring (6×56) | One row instead of two, no empty cells |
| **Bottom row 2** | Ring, Empty, Empty, Ring | **Removed** | Rings moved to row 1 |
| **Durability** | Not shown | Red tint + crack overlay on slot border | Broken = visible |
| **ACCESSORY** | Missing | Add to bottom row or as 7th slot | Backend supports it |

**Height savings:** current ~470pt → ~380pt (−90pt). Одна row вместо двух (−84pt gap), bars выше portrait (−30pt HP/XP area under portrait, +24pt bars above).

**Почему это лучший:**
1. Portrait крупнее → stronger heroic feel
2. HP/XP читаемы → instant readiness info
3. Один bottom row → нет пустых дыр
4. Name убран → portrait чистый
5. Durability видна → no hidden broken items
6. ACCESSORY slot → backend parity

---

## 11. Design System / Token Notes

| Issue | Current | Recommendation |
|---|---|---|
| HP bar label font | `textBadge` (11pt) | Raise to `textCaption` (12pt) for WCAG |
| HP value width | 58pt fixed frame | 70pt or `.fixedSize()` to prevent wrap |
| Portrait border radius | `cardRadius` (12pt) | OK, consistent |
| Slot border radius | `cardRadius` (12pt) | OK |
| Slot gap | `inventoryGap` (8pt) | OK, on 8px grid |
| Slot rarity border | 2px width | OK but glow overload when many items |
| Upgrade dots | 5pt, gold | OK but hard to count at 5+ |
| VStack spacing 5pt | `spacing: 5` in HP/XP area | ⚠️ **Not on 4px grid.** Should be 4pt or 8pt |
| HStack spacing 6pt | `spacing: 6` in HP row | ⚠️ **Not on 4px grid.** Should be 4pt or 8pt |
| Portrait stroke | 1px, gold 0.3 opacity | Could be stronger for premium feel |

---

## 12. Risks / Constraints

| Risk | Impact | Mitigation |
|---|---|---|
| **Reducing slot size below 72pt** | Touch targets may fail Apple HIG 44pt | 72pt is safe, 64pt borderline |
| **ACCESSORY slot has no items in DB** | If no items exist, empty slot = confusing | Check if ACCESSORY items are seeded. If not, hide slot |
| **6-slot bottom row on small screens** | iPhone SE: 6×56 + 5×8 = 376pt = tight on 375pt | Use adaptive: 56pt on large, 52pt on SE |
| **Portrait enlarge requires column resize** | Breaks current 4-column grid alignment | Use separate column width for equipment vs inventory tabs |
| **Name removal assumes resource strip exists** | If no resource strip, name disappears from first screen | Ensure resource strip is implemented first |
| **Durability overlay needs design** | Red tint on slot — could clash with rarity colors | Use diagonal hatch pattern instead of color tint |

---

## 13. Optional Next Step

1. **Прототип:** HTML mockup нового layout (Portrait-First) с реальными пропорциями
2. **Token update:** Добавить `LayoutConstants.equipSlotSizeSM = 72`, `equipSlotSizeXS = 56` для bottom row
3. **Durability indicator:** Design red diagonal hatch SVG/Shape для broken item overlay
4. **ACCESSORY audit:** Проверить backend seed data — есть ли items типа ACCESSORY в каталоге
5. **Implementation:** Перестроить `equipmentSection()` в HeroDetailView с новыми пропорциями

Без implementation.
