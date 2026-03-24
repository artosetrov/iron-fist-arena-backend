# Kuzya UI/UX: Item Detail Modals — Full Audit

**Scope:** `ItemDetailSheet.swift`, `LootPreviewSheet.swift`, shop presentation via `ShopDetailView`, all item states
**Platform:** iOS (SwiftUI), dark fantasy RPG
**Stage:** Production / polish pass

---

## What's Working Well

1. **Unified modal template** — `ItemDetailSheet` serves both inventory AND shop contexts via `ShopContext?`. Один компонент, два режима — отличный DRY-подход.
2. **Ornamental system** — `RadialGlowBackground`, `.surfaceLighting()`, `.innerBorder()`, `.cornerBrackets()`, `.cornerDiamonds()`, dual shadow — всё соответствует стандартному modal pattern из CLAUDE.md. Визуально премиально.
3. **Rarity-driven chrome** — Border color, inner border tint, glow shadow, badge pill — всё корректно завязано на `rarityColor`. Работает across all 5 rarities.
4. **Optimistic UI** — Equip/unequip/sell/use все используют optimistic update с rollback на failure. Sheet закрывается мгновенно — нет задержки.
5. **Comparison section** — "VS. EQUIPPED" автоматически показывает delta при наличии equipped item в том же слоте. Стрелки ▲/▼ с цветовой кодировкой (success/danger).

---

## 1. UX Heuristics

**Verdict:** Needs Work

### 1.1 — Emoji вместо game assets в кнопках и ценах (Critical)

**What:** Кнопки `REPAIR · {cost} 💰`, `UPGRADE · {cost} 💰`, и `ShopItem.displayPrice` (`"240 💎"`, `"90 💰"`) используют emoji для валюты.

**Problem:** Проект имеет `CurrencyDisplay` компонент с game-assets (`icon-gold`, `icon-gems`), который используется в Economy section. Но в кнопках и price display emoji выбиваются из visual language. Это нарушение CLAUDE.md правила: "Never use SF Symbols for currency — use CurrencyDisplay component instead."

**Impact:** Inconsistency между кнопками (emoji) и Economy section (asset icons). На скриншотах видно: price "240 💎" — это emoji, а внизу "BUY 240 💎" — тоже emoji. Выглядит дёшево vs. ornamental premium chrome вокруг.

**Fix:**
- В `ShopItem.displayPrice` — убрать emoji, вернуть raw число. Display через `CurrencyDisplay(.mini)` в UI.
- В `ItemDetailSheet.shopBuySection` — заменить `Text(shop.displayPrice)` на `CurrencyDisplay(gold:gems:size:.mini)`.
- В кнопках REPAIR/UPGRADE — заменить `💰` на inline `CurrencyDisplay(.mini)` внутри `HStack` label.

**Severity:** Critical (нарушение design system rule)

### 1.2 — catalogId виден пользователю (Major)

**What:** `descriptionSection` показывает `catalogId` (строки вроде `loot_fe5a17b0-b001-4f88-ac96-999446f0a069`) прямо в модалке.

**Problem:** Это внутренний технический ID. Пользователю он не нужен и вносит шум. На скриншоте Fine Belt: видна строка `loot_757b9def-01af-4cdd-a7fa-dae09kf33d22b`.

**Impact:** Выглядит как debug info. Нарушает KISS и "aesthetic & minimalist design" (Nielsen #8).

**Fix:** Убрать `catalogId` из `descriptionSection` полностью. Если нужен для dev — показывать только в `#if DEBUG`.

**Severity:** Major

### 1.3 — Нет sell confirmation (Major)

**What:** Кнопка SELL в inventory mode вызывает `onSell()` мгновенно — без confirm dialog.

**Problem:** Sell — деструктивное действие. Единожды проданный предмет не вернуть. Нет никакого confirmation step (в отличие от shop buy, где есть `confirmationDialog` для gem purchases).

**Impact:** Случайный тап = потеря предмета. Особенно опасно для epic/legendary items.

**Fix:** Добавить confirm dialog для sell (как минимум для rare+ items). Pattern уже есть — `confirmationDialog` в ShopDetailView. Можно reuse.

**Severity:** Major

### 1.4 — Upgrade sound играет ДО получения результата (Major)

**What:** `upgradeConfirmPanel` при нажатии UPGRADE вызывает `SFXManager.shared.play(.uiUpgradeSuccess)` синхронно, а потом `onUpgrade(useProtection)`. Результат upgrade приходит с сервера.

**Problem:** Sound "success" играет даже если upgrade failed. Server-authoritative rule: клиент не должен предполагать результат.

**Impact:** Ложная обратная связь — user слышит "успех", потом видит toast "❌ Upgrade failed".

**Fix:** Убрать `.uiUpgradeSuccess` из кнопки. Играть sound в `InventoryViewModel.upgrade()` после получения `result.success`.

**Severity:** Major

### 1.5 — Protection Scroll использует SF Symbol для gems (Minor)

**What:** В upgrade confirm panel: `Image(systemName: "diamond")` для обозначения gem cost (30 💎).

**Problem:** Нарушение того же правила — currency через SF Symbols. Нужен `CurrencyDisplay(.mini, currencyType: .gems)`.

**Fix:** Заменить `Image(systemName: "diamond")` + `Text(")")` на `CurrencyDisplay(gold: 0, gems: 30, size: .mini, currencyType: .gems)`.

**Severity:** Minor

### 1.6 — Economy section header icon: dollarsign.circle.fill (Minor)

**What:** `sectionHeader(icon: "dollarsign.circle.fill", title: "ECONOMY")`.

**Problem:** SF Symbol `dollarsign.circle.fill` для economy — западный символ. В game fantasy context лучше тематическая иконка (coin, treasure).

**Fix:** Использовать asset-icon `icon-gold` (miniатюрный) или хотя бы `"coins.circle.fill"` если есть.

**Severity:** Minor

### 1.7 — Количество не показано в модалке для stacked items (Minor)

**What:** `ItemDetailSheet` не отображает `quantity` предмета (consumables могут иметь quantity > 1).

**Problem:** Когда открываешь consumable из inventory, не видно сколько штук есть. Надо возвращаться на grid чтобы проверить.

**Impact:** Нарушает "visibility of system status" (Nielsen #1).

**Fix:** Добавить quantity badge в header рядом с item name (если `quantity > 1`): `"×3"` pill.

**Severity:** Minor

### 1.8 — "VS. EQUIPPED" не показывается для consumables, но нет USE count (Minor)

**What:** Consumable items показывают кнопку USE, но нет информации о том что произойдёт при использовании.

**Problem:** "Use" — что именно? Сколько HP восстановится? Какой эффект? Модалка не показывает consumable effect details (только generic `description`).

**Fix:** Для consumables добавить effect preview section (e.g. "Restores 50 HP" если health potion).

**Severity:** Minor

---

## 2. Form Usability

**Verdict:** N/A — No form inputs on this screen.

Upgrade toggle (`useProtection`) is the only interactive input — it's a simple toggle, well-implemented with clear label and cost display.

---

## 3. Mobile Readiness

**Verdict:** Ready (minor issues)

### 3.1 — Touch targets for action buttons (Good)

Primary buttons: 56px height (`buttonHeightLG`), secondary: 48px (`buttonHeightMD`). Both above 44px minimum. Close button uses `.closeButton` style. Good.

### 3.2 — Action buttons in thumb zone (Good)

Кнопки pinned to bottom (`actionButtons` outside ScrollView). Правильный паттерн для thumb-zone.

### 3.3 — Modal max height (Good)

`maxHeight: UIScreen.main.bounds.height * 0.75` — не перекрывает status bar. Scroll если контент длинный.

### 3.4 — Backdrop tap to close (Good)

`bgModal.onTapGesture { onClose() }` — standard dismiss pattern.

### 3.5 — No swipe-to-dismiss (Minor)

**What:** Modal is ZStack overlay, not `.sheet()`. Нет gesture для swipe-down close.

**Problem:** iOS users expect swipe-down to dismiss modals. Current implementation requires tap on X or backdrop.

**Fix:** Добавить `DragGesture` для swipe-down dismiss (threshold ~100pt vertical).

**Severity:** Minor (backdrop tap is sufficient, but swipe-down improves fluency)

---

## 4. Accessibility

**Verdict:** Partial Pass

### 4.1 — Accessibility labels present (Good)

Item icon, item name, level, rarity — all have `accessibilityLabel`. Durability bar has `.accessibilityValue`. Good baseline.

### 4.2 — Stat values use color only (Major)

**What:** В comparison section: delta > 0 = `success` (green), delta < 0 = `danger` (red). Стрелки ▲/▼ помогают, но они мелкие (10pt).

**Problem:** Partially color-dependent. WCAG 1.4.1: information must not be conveyed by color alone. Стрелки помогают, но `+/-` prefix тоже есть. Acceptable but at minimum size.

**Fix:** Increase arrow size to match label font (12-14pt) for better visibility.

**Severity:** Minor

### 4.3 — Durability bar: no BarFillHighlight (Minor)

**What:** Durability bar uses plain `RoundedRectangle.fill(durabilityGradient)` без `.overlay(BarFillHighlight(...))`.

**Problem:** CLAUDE.md: "BarFillHighlight must be applied to ALL progress bars (HP, XP, Stamina)." Durability bar missing it.

**Fix:** Add `.overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusSM))` to durability fill.

**Severity:** Minor (consistency, not accessibility per se)

### 4.4 — Close button has accessibilityLabel (Good)

`.accessibilityLabel("Close item detail")` — correct.

### 4.5 — Rarity badge pill contrast (Check needed)

Rarity COMMON badge: gray text on gray-15% background. May fail 4.5:1 contrast ratio on dark bg.

**Fix:** Verify contrast for common rarity pill. If below 4.5:1, increase text opacity or background opacity.

**Severity:** Minor

---

## 5. Design System Compliance

**Verdict:** Deviations Found

### 5.1 — Emoji currency in buttons (Critical — see 1.1)

Repeated from UX section. `💰` and `💎` emojis violate CurrencyDisplay rule.

### 5.2 — ShopItem.consumableIconColor uses raw `.cyan`, `.red`, `.green` (Major)

**What:** `ShopItem.swift` line 82-85: `return .cyan`, `return .red`, `return .green`, `return .yellow`.

**Problem:** These are SwiftUI system colors, NOT DarkFantasyTheme tokens. Should use `DarkFantasyTheme.cyan`, `.danger`, `.success`, `.goldBright`.

**Fix:** Replace raw colors with theme tokens.

### 5.3 — Section divider is plain Rectangle, not OrnamentalDivider (Minor)

**What:** `sectionDivider` is `Rectangle().fill(borderSubtle).frame(height: 1)`.

**Problem:** OrnamentalStyles has `GoldDivider`, `ScrollworkDivider`, `EtchedGroove` — all more fitting for a premium modal. Current plain line feels flat compared to ornamental chrome.

**Fix:** Replace with `EtchedGroove()` or at minimum `GoldDivider(opacity: 0.3)` for visual coherence.

### 5.4 — LootPreviewSheet duplicates badge pill code (Minor)

**What:** `LootPreviewSheet` has inline `Capsule().fill(rarityColor.opacity(0.15))` badge — same as `ItemDetailSheet.badgePill()`.

**Problem:** Should extract shared badge pill to a reusable component or at least call the same helper.

**Fix:** Extract `badgePill()` to a shared extension or component file.

### 5.5 — LootPreviewSheet missing type badge (Minor)

**What:** `ItemDetailSheet` header shows TWO badges (type + rarity). `LootPreviewSheet` shows only ONE (rarity).

**Problem:** Inconsistency between the two modal types.

**Fix:** Add item type badge to `LootPreviewSheet` if data is available.

---

## 6. Research-Informed Check

1. **Sell without confirmation** — это #1 risk. В любом мобильном RPG accidental sell — крупнейший source of frustration. Usability тест с 5 людьми гарантированно выявит это.

2. **Price clarity** — на скриншотах видно что цена показывается дважды: в текстовом поле ("240 💎") и на кнопке ("BUY 240 💎"). Redundancy OK, но emoji vs. asset inconsistency запутывает. Проверить в A/B: pure asset display vs. mixed.

3. **"Requires Level 3" red text** — видно на скрине Fine Belt. Текст мелкий и только красный. Может ли пользователь понять СВОЙ текущий level vs. required? Нет — нет контекста "You are Level X". Добавить: "Requires Level 3 (You: Level 1)".

4. **Upgrade flow mental model** — upgrade chance, protection scroll, gem cost — много информации для small panel. Рискует cognitive overload. Стоит протестировать: понимают ли новые игроки что Protection Scroll делает.

5. **LootPreviewSheet vs. ItemDetailSheet** — два разных шаблона для похожих данных. Loot sheet значительно проще (нет stats grid, нет actions). Если предмет из loot потом появляется в inventory, user видит его по-разному в двух контекстах. Может создать путаницу.

---

## Priority Actions

1. **🔴 Critical: Заменить все emoji-валюту (💰💎) на CurrencyDisplay** — в `ShopItem.displayPrice`, кнопках REPAIR/UPGRADE, price display в shop buy section, protection scroll gem cost. Это системное нарушение design rule.

2. **🔴 Major: Добавить sell confirmation** — как минимум для rare+ items. Использовать существующий pattern `confirmationDialog`.

3. **🔴 Major: Убрать catalogId из UI** — wrap в `#if DEBUG`.

4. **🔴 Major: Исправить upgrade sound timing** — перенести `.uiUpgradeSuccess` в ViewModel после получения server result.

5. **🟡 Major: Заменить raw SwiftUI colors в ShopItem** — `.cyan` → `DarkFantasyTheme.cyan` и т.д.

6. **🟡 Minor: Добавить quantity display** для stacked items в header.

7. **🟡 Minor: Добавить swipe-to-dismiss** gesture.

8. **🟡 Minor: Добавить BarFillHighlight** на durability bar.

9. **🟡 Minor: Показывать "Requires Level X (You: Level Y)"** вместо просто "Requires Level X".

10. **🟡 Minor: Заменить section dividers** на `EtchedGroove()` или `GoldDivider`.

---

## State Coverage Matrix

| State | ItemDetailSheet | LootPreviewSheet | Notes |
|---|---|---|---|
| **Inventory — normal item** | ✅ EQUIP + SELL | — | Two secondary buttons |
| **Inventory — equipped** | ✅ UNEQUIP + UPGRADE/REPAIR | — | Conditional second button |
| **Inventory — broken** | ✅ REPAIR only | — | Single primary button |
| **Inventory — damaged (not broken)** | ✅ REPAIR available | — | Shows alongside EQUIP or UPGRADE |
| **Inventory — consumable** | ✅ USE | — | Single primary button |
| **Inventory — upgradeable** | ✅ UPGRADE → confirm panel | — | Protection scroll for +5 and above |
| **Inventory — max upgrade (+10)** | ✅ No UPGRADE button | — | `canUpgrade` = false |
| **Shop — can afford, meets level** | ✅ BUY enabled | — | Gold gradient primary button |
| **Shop — can't afford** | ✅ BUY disabled + "Not enough" | — | 50% opacity + red text |
| **Shop — doesn't meet level** | ✅ BUY disabled + "Requires Level X" | — | Red text warning |
| **Shop — buying (loading)** | ✅ ProgressView spinner | — | Button disabled during request |
| **Shop — gem purchase** | ✅ Cyan price + confirm dialog | — | Two-step: request → confirm |
| **Loot preview** | — | ✅ Read-only, no actions | Simpler template |
| **Comparison (equipped exists)** | ✅ "VS. EQUIPPED" section | — | Delta arrows + colors |
| **No comparison (nothing equipped)** | ✅ Section hidden | — | Clean |
| **Special effect / passive** | ✅ Sparkles + bolt icons | ✅ (in description) | Gold / cyan text |
| **Set item** | ✅ Diamond + set name | — | Green text |
| **No description** | ✅ Section hidden | — | Clean |
| **Class restriction** | ✅ "{Class} only" text | — | Gold dim text |
| **Durability bar** | ✅ Color-coded (green/yellow/red) | — | Fraction + numeric display |

### Missing States:

| State | Missing In | Impact |
|---|---|---|
| **Empty stats** | ItemDetailSheet | If item has no stats (e.g. pure consumable), stats section hides — OK |
| **Quantity > 1** | ItemDetailSheet header | No visual indicator of stack count |
| **Loading** | Neither | No loading state inside modal — acceptable since data is pre-fetched |
| **Error** | Neither | If action fails, modal closes + toast. Could be smoother to stay open with inline error. |
| **Consumable effect preview** | ItemDetailSheet | No info about what USE does |

---

## Checklist

- [x] One clear primary action per screen
- [x] Screen understandable in 3 seconds (KISS) — except catalogId noise
- [x] Color draws attention to the right element first
- [x] Consistent patterns with rest of product — except emoji currency
- [x] 1-2-3 click rule: frequent actions easy
- [x] All critical states designed (loading, empty, error)
- [x] Touch targets >= 44px with 8px spacing
- [ ] Color contrast >= 4.5:1 for all text — needs verification for common rarity pill
- [x] No color-only information (arrows + prefix help)
- [x] Keyboard navigable (VoiceOver accessible)
- [x] Design system tokens used consistently — except emoji currency + raw system colors
- [ ] Sell confirmation for destructive action
- [ ] CurrencyDisplay used everywhere (no emoji/SF Symbol for currency)
