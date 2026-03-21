# Hero Card Fix Plan

## Problems

1. **HP/XP bars overlap equipment slots** — GeometryReader height calculation wrong, bars render on top of bottom row slots
2. **Stamina shown as number** — should be a bar like HP/XP (third bar: Stamina 87/120)
3. **Gold/Gems in hero card** — remove from this block entirely
4. **Gold/Gems missing from inventory** — add currency display to inventory tab header

---

## Fix 1: Equipment grid height calculation

**Problem:** `equipmentGrid` uses GeometryReader with calculated frame height. The height formula doesn't account for card padding correctly → bars overlap slots.

**Current (wrong):**
```swift
let screenW = UIScreen.main.bounds.width - 2 * LayoutConstants.screenPadding - 2 * LayoutConstants.heroCardPadding
let cw = ...
return 3 * cw + 2 * gap + gap + cw  // portrait + bottom row
```

**The issue:** GeometryReader inside VStack(spacing: 0) with card padding. The geo.size.width already accounts for the card padding, but the frame height is calculated from screenW which may not match.

**Fix:** Remove frame height calculation. Use fixed-size slots in a non-GeometryReader layout, or use the geo width for BOTH width and height calculations consistently.

**Better approach:** Don't use GeometryReader at all. Use `UIScreen.main.bounds.width` for cell width calculation directly in the VStack, and let the height be intrinsic (VStack of fixed-height HStacks).

**File:** `HeroIntegratedCard.swift` — `equipmentGrid` property

---

## Fix 2: Stamina as a bar

**Current:** Stamina shown as `⚡ 87/120` text in resources row.

**New:** Third bar below XP, same style as HP/XP — stamina gradient (orange), "Stamina 87 / 120" text centered inside.

**Layout after fix:**
```
[Equipment Grid]
── divider ──
[HP ████████████  1,030 / 1,030]     ← green gradient, 24pt
[XP ██████████      4,994 / 6,000]   ← blue gradient, 20pt
[Stamina ████████     87 / 120]       ← orange gradient, 20pt
[⚔ Chest · 🛡 Chest] [⚠ Repair All] ← action pills
```

**New token:** `heroBarStaminaHeight: CGFloat = 20` (same as XP)

**Use:** `DarkFantasyTheme.staminaGradient` (already exists: orange #E67E22 → #D35400)

**File:** `HeroIntegratedCard.swift` — add `staminaBarInside` view, remove stamina from resources row

---

## Fix 3: Remove gold/gems from hero card

**Current:** Resources row shows `⚡ stamina | 🪙 gold | 💎 gems`

**After:** Resources row removed entirely. Stamina is now a bar. Gold/gems moved to inventory tab.

**Remove from HeroIntegratedCard:**
- Entire `resourcesRow` HStack
- All gold/gems formatting code
- `hc-res`, `hc-r`, `hc-sep` related views

**File:** `HeroIntegratedCard.swift` — delete resources HStack

---

## Fix 4: Add gold/gems to inventory tab header

**Current inventory header:**
```
INVENTORY                    💰 19,464 · 28 items
```

**New inventory header:**
```
INVENTORY          🪙 18,838 · 💎 151 · 28 items
```

**File:** `HeroDetailView.swift` — `inventoryInlineContent()` method, update header HStack

---

## Final data section layout

```
── divider ──
[HP ████████████████  1,030 / 1,030]   ← 24pt, green
[XP ████████████        4,994 / 6,000] ← 20pt, blue
[Stamina ██████████        87 / 120]   ← 20pt, orange
[⚔ Chest · 🛡 Chest Edit] [⚠ Repair All(3) · 420🪙]
```

No gold, no gems, no resources row. Clean: 3 bars + action pills.

---

## Files to change

| File | Change |
|---|---|
| `HeroIntegratedCard.swift` | Fix grid height, add stamina bar, remove gold/gems/resources |
| `HeroDetailView.swift` | Add 🪙💎 to inventory tab header |
| `LayoutConstants.swift` | Add `heroBarStaminaHeight: CGFloat = 20` (optional, can reuse heroBarXpHeight) |

## Estimated time: 30 min
