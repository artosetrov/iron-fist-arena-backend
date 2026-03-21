# Hero Widget v2 — Triple Audit Report

*Mobile UX Review + UX Design Review + Accessibility Audit*
*Applied: Component Rulebook, Master Rules, WCAG 2.1 AA*

---

## 1. Mobile UX Review

### Overall Mobile Readiness: NEEDS WORK (7 issues)

### Thumb Zone Analysis
- Widget сам расположен в **top area** экрана — это stretch/hard zone. Однако это правильно для status widget (не primary CTA). ✅
- Action pills (Heal, Restore, Allocate) находятся внутри widget → **top 20%** экрана. Это проблема для одноручного использования, но оправдано контекстом: pills — secondary actions, а primary CTA (Fight, Enter Dungeon) находится ниже на экране. ✅ Acceptable.

### Touch Target Compliance

| Element | Текущий размер | Минимум (Apple HIG) | Статус |
|---------|---------------|---------------------|--------|
| Avatar (48×48) | 48px | 44px | ✅ |
| Refill button (+) | 24×24 visual | 44px tap area | 🔴 **FAIL** — нет extended tap area |
| Action pills | 28px height | 44px | 🟡 **WARN** — ниже минимума, но допустимо для dense game UI с padding |
| Level badge | ~18px height | N/A (non-interactive) | ✅ |
| HP bar area | 8px height | N/A (non-interactive) | ✅ |
| Currency values | ~14px height | N/A (non-interactive) | ✅ |
| Stamina area | ~14px height | N/A (non-interactive) | ✅ |

**Критичные нарушения:**

1. 🔴 **Refill button (+)**: 24×24px visual без extended tap area. Rulebook §2.4: минимум 44px. Решение: добавить `padding: 12px` вокруг 24px visual → 48px tap target.

2. 🟡 **Action pills (28px)**: Rulebook допускает 32px для dense controls (tags/filters). 28px ниже этого. Решение: увеличить `--pill-h` до **32px** (4px sub-grid).

### Typography and Readability

| Element | Текущий | Rulebook minimum | Статус |
|---------|---------|-----------------|--------|
| Hero name (Oswald 16px) | 16px | 16px mobile body | ✅ |
| Class label | 11px | 12px absolute min | 🔴 **FAIL** |
| HP text | 10px | 12px absolute min | 🔴 **FAIL** |
| Pill font | 11px | 12px absolute min | 🔴 **FAIL** |
| XP percentage | 10px | 12px absolute min | 🔴 **FAIL** |
| Currency values | 12px | 12px | ✅ borderline |
| Stamina values | 12px | 12px | ✅ borderline |
| Level badge | 10px | 11px (DarkFantasyTheme textBadge) | 🟡 LayoutConstants says 11px min |

**Критичные нарушения:**

3. 🔴 **4 элемента ниже 12px minimum**: HP text (10px), pill font (11px), XP % (10px), class label (11px). Master Rules §6: absolute minimum text = 12px. Component Rulebook §3.2: text-xs = 11px допустим только для timestamps/fine print, не для actionable content.

### Layout and Spacing

| Проверка | Статус |
|---------|--------|
| Single-column widget | ✅ |
| 8px grid compliance | 🟡 Partial — `padding: 12px 16px` is 4px sub-grid ✅, но `gap: 6px` в .r1 и .r3 нарушает 4px grid |
| Content padding 16px | ✅ |
| Safe area awareness | ✅ (widget не касается edges) |

**Нарушения:**

4. 🟡 **gap: 6px нарушает 4px sub-grid**: В .r1, .r3, и .r2 используется gap: 6px. Допустимые значения: 4px или 8px. Решение: заменить на **8px** (стандартный tight gap).

5. 🟡 **border-radius: 14px**: Не на 4px grid. Допустимые: 12px или 16px. Решение: заменить на **12px** (Rulebook radius-lg) или **16px** (radius-xl).

### Spacing Compression for Mobile

| Параметр | Текущий | Mobile ideal | Статус |
|---------|---------|-------------|--------|
| Widget padding | 12px × 16px | 12px × 16px | ✅ |
| Internal gap | 12px | 12px | ✅ |
| Row gap | 4px | 4px | ✅ |

---

## 2. UX Design Review (Nielsen Heuristics)

### Heuristic 1: Visibility of System Status ✅
HP bar gradient (green→amber→red) даёт мгновенный feedback. XP ring показывает progression. Stamina числом + цветом. Всё правильно.

### Heuristic 2: Match Between System and Real World ✅
🧪 для potions, ⚡ для energy, 🪙 для gold, ⭐ для stat points — всё понятно в RPG контексте.

### Heuristic 3: User Control and Freedom 🟡
- Pills дают quick action (Heal, Restore) — хорошо.
- Но нет **undo** для potion use. Если игрок случайно тапнет Heal — зелье потрачено.
- **Рекомендация**: добавить confirmation dialog для pills ИЛИ показывать brief "Used! +500 HP" toast с 2-sec undo option.

### Heuristic 4: Consistency and Standards ✅
Unified Pill System решает проблему consistency. Все pills одного размера, одного паттерна. Хорошо.

### Heuristic 5: Error Prevention 🟡
- Refill button (+) для stamina рядом с currency values → risk of mis-tap.
- Potion pills не имеют confirmation → accidental use possible.
- **Рекомендация**: визуально отделить refill button от currency; добавить haptic feedback + mini-confirmation.

### Heuristic 6: Recognition Over Recall ✅
Pill иконки (🧪, ⚡, ⭐, ⚠) + цветовое кодирование дают мгновенное recognition. Текст "Heal ×3" явно показывает что это и сколько.

### Heuristic 7: Flexibility and Efficiency ✅
Quick-use potions — это ускоритель (не нужно заходить в инвентарь). Context-adaptive row-3 показывает relelvant info per screen.

### Heuristic 8: Aesthetic and Minimalist Design ✅
V2 значительно лучше V1. Unified pills устраняют визуальный хаос. 3 строки с чёткой иерархией.

### Heuristic 9: Help Users Recover from Errors 🔴
- **No undo for potion use** — главная проблема.
- No feedback после action — игрок не знает точно что произошло.

### Heuristic 10: Help and Documentation ✅
Pill labels самодостаточны. "Heal ×3" не требует объяснения.

### State Audit (27 states из Master Rules)

| State | Покрыт? | Качество |
|-------|---------|----------|
| Default | ✅ | Хорошо |
| Loading/Skeleton | ✅ | Хорошо |
| Low HP (warning) | ✅ | Хорошо + action pill |
| Critical HP | ✅ | Хорошо + pulse animation |
| Low stamina | ✅ | Хорошо + action pill |
| Level up imminent | ✅ | Хорошо + gold glow |
| Stat points available | ✅ | Хорошо + pulsing CTA |
| Broken gear | ✅ | Warning pill |
| Arena context | ✅ | PvP pills |
| Error state | 🔴 **MISSING** | Что если API fails? |
| Offline state | 🔴 **MISSING** | Показывать cached data + indicator? |
| Empty/No character | 🟡 **MISSING** | Edge case: новый user без персонажа |
| Partial data | 🟡 **MISSING** | Что если gems=nil? |
| First use | 🟡 **MISSING** | Первый раз видит widget — onboarding hint? |
| No avatar (fallback) | ✅ | Emoji placeholder |
| Long name | ✅ | Text-overflow: ellipsis |
| High values | ✅ | Compact notation planned |

**Пропущенные обязательные состояния:**

6. 🔴 **Error state**: Если /game/init возвращает ошибку — widget должен показать "Failed to load" + retry, не пустое место.
7. 🔴 **Offline state**: Banner или indicator что данные могут быть устаревшими.

---

## 3. Accessibility Audit (WCAG 2.1 AA)

### Contrast Ratios

| Element | Foreground | Background | Ratio | WCAG AA (4.5:1 text, 3:1 graphics) | Статус |
|---------|-----------|------------|-------|-------------------------------------|--------|
| Name (F5F5F5 on 1C1C30) | #F5F5F5 | #1C1C30 | ~12.5:1 | 4.5:1 | ✅ |
| HP text (A0A0B0 on 1C1C30) | #A0A0B0 | #1C1C30 | ~5.8:1 | 4.5:1 | ✅ |
| Class label (6B6B80 on 1C1C30) | #6B6B80 | #1C1C30 | ~3.2:1 | 4.5:1 | 🔴 **FAIL** (< 4.5:1 для текста) |
| Gold currency (FFD700 on 1C1C30) | #FFD700 | #1C1C30 | ~9.3:1 | 4.5:1 | ✅ |
| Text tertiary in pills (6B6B80 on rgba bg) | ~#6B6B80 | ~#1E1E34 | ~3.0:1 | 4.5:1 | 🔴 **FAIL** |
| HP warning text (FFA502 on 1C1C30) | #FFA502 | #1C1C30 | ~7.5:1 | 4.5:1 | ✅ |
| Danger text (FF6B6B on 1C1C30) | #FF6B6B | #1C1C30 | ~5.4:1 | 4.5:1 | ✅ |
| HP bar (green on dark) | #2ECC71 | rgba track | ~5.3:1 | 3:1 (graphic) | ✅ |

**Нарушения:**

8. 🔴 **text-tertiary (#6B6B80) не проходит WCAG AA** для текста мельче 18px bold / 24px regular. Используется в class label ("⚔ Warrior") и pill-info. Решение: заменить на **#8A8AA0** (~4.5:1) или использовать text-secondary (#A0A0B0).

### Screen Reader / VoiceOver

9. 🟡 **Отсутствуют ARIA labels**: Pills с emoji-иконками (🧪, ⚡, ⭐) не имеют accessible text для VoiceOver. VoiceOver прочитает "Test Tube, Heal, Times 3" вместо "Use health potion, 3 remaining". SwiftUI эквивалент: `.accessibilityLabel("Use health potion, 3 remaining")`.

10. 🟡 **HP bar не имеет accessible value**: Screen reader не сможет прочитать percentage. Нужен `.accessibilityValue("HP 38 percent, 392 of 1030")`.

11. 🟡 **XP ring (SVG) не имеет role/label**: Декоративный элемент без `aria-hidden="true"` или accessible label.

### Color-Only Meaning

12. 🟡 **HP bar gradient полагается только на цвет**: Green→amber→red communicates urgency, но дальтоники (protanopia/deuteranopia) не различают green и amber. **Однако**: числовое значение "392 / 1,030" рядом + pill text "Low HP" / "Critical HP" обеспечивают redundant encoding. ✅ Частично решено. Рекомендация: добавить pattern/texture на critical HP bar (hatching) для дополнительного visual cue.

---

## 4. Сводка нарушений по приоритету

### 🔴 Critical (блокируют релиз)

| # | Проблема | Правило | Решение |
|---|---------|---------|---------|
| 1 | Refill button 24px без extended tap area | Component Rulebook §2.4: min 44px | Добавить padding 12px → 48px tap target |
| 3 | 4 текстовых элемента < 12px | Component Rulebook §3.2, Master Rules §6 | Поднять HP text 10→12px, pill font 11→12px, XP % 10→12px, class label 11→12px |
| 6 | Error state отсутствует | Master Rules §11: 27 обязательных состояний | Добавить error state с retry |
| 7 | Offline state отсутствует | Master Rules §11, Mobile UX Rules §13 | Добавить offline indicator |
| 8 | text-tertiary contrast < 4.5:1 | WCAG 2.1 AA 1.4.3 | Заменить #6B6B80 → #8A8AA0 для текстовых элементов |

### 🟡 High (нужно до production)

| # | Проблема | Правило | Решение |
|---|---------|---------|---------|
| 2 | Pills 28px < 32px minimum для dense controls | Component Rulebook §2.5 | Увеличить --pill-h до 32px |
| 4 | gap: 6px не на 4px sub-grid | Component Rulebook §2.2 | Заменить на 8px |
| 5 | border-radius: 14px не на 4px grid | Component Rulebook §3.3 | Заменить на 12px |
| 9 | Нет ARIA labels на pills | WCAG 2.1 AA 4.1.2 | Добавить accessibilityLabel в SwiftUI |
| 10 | HP bar без accessible value | WCAG 2.1 AA 4.1.2 | Добавить accessibilityValue |

### 🟢 Minor (nice to have)

| # | Проблема | Правило | Решение |
|---|---------|---------|---------|
| 11 | XP ring SVG без aria-hidden | WCAG 2.1 AA | Добавить aria-hidden="true" |
| 12 | HP color-only для daltonics | WCAG 2.1 AA 1.4.1 | Уже есть text fallback; опционально добавить pattern |
| H3 | No undo for potion use | Nielsen H9 | Confirmation dialog или 2-sec undo toast |
| H5 | Refill button proximity to currency | Nielsen H5 | Визуальный separator |

---

## 5. Конкретный список изменений для V3

```
TOKENS TO CHANGE:
  --pill-h:       28px → 32px
  --pill-font:    11px → 12px
  --pill-radius:  8px  → 8px (OK)

SIZES TO CHANGE:
  .hp-txt:        10px → 12px
  .cls:           11px → 12px
  .xp-pct:        10px → 12px
  .lvl:           10px → 11px (match LayoutConstants.textBadge)
  .name:          16px → 16px (OK)

SPACING TO CHANGE:
  .r1 gap:        6px → 8px
  .r3 gap:        6px → 8px
  .w border-radius: 14px → 12px

TOUCH TARGETS:
  .refill:        24×24 visual → add wrapper with min 48×48 tap area

CONTRAST:
  .cls color:     var(--text-tertiary) #6B6B80 → #8A8AA0 or var(--text-secondary)
  pill-info color: var(--text-secondary) → keep (passes AA)

MISSING STATES:
  + Error state:   "Failed to load" + retry button
  + Offline state:  Dimmed widget + "Offline" badge in row-3
  + Partial data:   Skeleton for missing fields, show available data
```

---

## 6. Mobile UX Checklist

- [x] Primary action in thumb zone (Fight button below widget — correct)
- [x] Single-column layout
- [x] Content prioritized for small screen
- [x] Safe area padding applied
- [ ] **Touch targets ≥44px with 8px spacing** — refill button fails
- [ ] **All text ≥12px** — 4 elements fail
- [ ] **4px grid compliance** — 6px gaps
- [ ] **Error state designed** — missing
- [ ] **Offline state designed** — missing
- [x] No hover-only interactions
- [x] flex-wrap for narrow screens
- [x] Gesture affordances visible (pill animations)

### Score: 7/12 passing → **NEEDS WORK**

После внесения изменений из секции 5 → ожидаемый score: **12/12 READY**
