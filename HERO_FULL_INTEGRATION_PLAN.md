# Hero Integrated Card + Universal Slots — Full Integration Plan

---

## Overview

Два изменения в одном плане:
1. **Hero Integrated Card** — новый layout Hero page (equipment first, data below, portrait + name overlay, bars with values inside)
2. **Universal Bottom Slots** — нижние 4 слота принимают несколько типов предметов (Ring/Necklace, Weapon/Accessory, Relic/Accessory, Belt/Ring2)

---

## Part 1: Universal Slots — Backend Changes

### Current State

`ITEM_TYPE_TO_SLOT` в `backend/src/app/api/inventory/equip/route.ts` — жёсткая маппа 1:1:
```typescript
weapon → weapon
helmet → helmet
chest → chest
gloves → gloves
legs → legs
boots → boots
accessory → accessory  // ← отдельный слот, не показан в UI
amulet → amulet
belt → belt
relic → relic
necklace → necklace    // ← отдельный слот, не показан в UI
ring → ring/ring2       // ← уже поддерживает 2 слота
```

13 item types → 13 slots. Ring уже имеет logic для 2 слотов (ring/ring2).

### Target State: 10 Visual Slots, 13 Item Types

**UI slots (10) — 2 universal, 8 strict:**

| Visual Slot | Position | Accepted Item Types | Type |
|---|---|---|---|
| Head | Left col, row 1 | helmet | Strict |
| Chest | Left col, row 2 | chest | Strict |
| Legs | Left col, row 3 | legs | Strict |
| **Amulet** | Right col, row 1 | **amulet, necklace** | **Universal** |
| Gloves | Right col, row 2 | gloves | Strict |
| Boots | Right col, row 3 | boots | Strict |
| Ring | Bottom row, pos 1 | ring, ring2 | Dual-ring (existing) |
| Weapon | Bottom row, pos 2 | weapon | Strict |
| **Off-Hand** | Bottom row, pos 3 | **weapon, accessory, relic** | **Universal** |
| Belt | Bottom row, pos 4 | belt | Strict |

**Summary:** 13 item types → 10 visual slots. Two universal slots:
- **Amulet slot** accepts Amulet OR Necklace
- **Off-Hand slot** accepts Weapon (dual wield), Accessory, OR Relic

### Backend Change 1: Expand ITEM_TYPE_TO_SLOT to multi-slot mapping

```typescript
// NEW: Item type can map to multiple possible slots (priority order)
const ITEM_TYPE_TO_SLOTS: Record<ItemType, EquippedSlot[]> = {
  weapon:    ['weapon', 'relic'],    // weapon primary, off-hand secondary (dual wield)
  helmet:    ['helmet'],
  chest:     ['chest'],
  gloves:    ['gloves'],
  legs:      ['legs'],
  boots:     ['boots'],
  accessory: ['relic'],              // ← goes to off-hand (relic) slot
  amulet:    ['amulet'],
  necklace:  ['amulet'],             // ← shares amulet slot
  belt:      ['belt'],
  relic:     ['relic'],              // off-hand slot
  ring:      ['ring', 'ring2'],      // already supported
}
```

**Two universal slots:**
- **Amulet slot** (`amulet`): accepts `amulet` and `necklace` item types
- **Off-Hand slot** (`relic`): accepts `relic`, `accessory`, and `weapon` (secondary) item types

### Backend Change 2: Update equip logic

Current logic: `let slot = ITEM_TYPE_TO_SLOT[itemType]` → single slot.
New logic:
```typescript
const possibleSlots = ITEM_TYPE_TO_SLOTS[itemType]
if (!possibleSlots?.length) return error('Item cannot be equipped')

// Find first empty slot, or replace the first occupied one
let targetSlot: EquippedSlot | null = null

for (const candidate of possibleSlots) {
  const occupied = await prisma.equipmentInventory.findFirst({
    where: { characterId, equippedSlot: candidate, isEquipped: true }
  })
  if (!occupied) {
    targetSlot = candidate
    break
  }
}

// If all full, replace first slot in priority order
if (!targetSlot) targetSlot = possibleSlots[0]
```

**Remove** the special-case ring logic (lines 103-130) — it's now handled by the generic multi-slot logic.

### Backend Change 3: Prisma Schema

**No schema changes needed.** `EquippedSlot` enum already has all 13 values. The multi-slot logic is purely in the equip route handler.

### Backend Change 4: Migration

**No database migration needed.** Only TypeScript code change.

### Files Changed (Backend)

| File | Change |
|---|---|
| `backend/src/app/api/inventory/equip/route.ts` | Replace `ITEM_TYPE_TO_SLOT` with `ITEM_TYPE_TO_SLOTS`, update equip logic |

**Estimated time:** 30 min

---

## Part 2: iOS Model Changes

### Character.swift / Item.swift

**No model changes needed.** `equippedSlot` is already a String? on Item. The backend sends the slot name, iOS displays it.

### EquipmentViewModel.swift

Current `slotOrder` array defines which slots appear and their order. Needs update to reflect new layout:

```swift
// OLD
static let slotOrder = ["helmet", "amulet", "chest", "gloves", "legs", "boots",
                         "belt", "necklace", "ring", "ring2", "weapon", "relic"]

// NEW: 10 visual slots
static let sideSlots = [
  ["helmet", "chest", "legs"],      // left column
  ["amulet", "gloves", "boots"]     // right column (amulet accepts necklace too)
]
static let bottomSlots = ["ring", "weapon", "relic", "belt"]  // universal
```

### Slot-to-ItemType mapping (iOS)

Need a new mapping for findEquippedItem to know which item types can go in which visual slot:

```swift
static let slotAccepts: [String: [ItemType]] = [
  "helmet": [.helmet],
  "chest":  [.chest],
  "legs":   [.legs],
  "amulet": [.amulet, .necklace],              // ← UNIVERSAL: amulet OR necklace
  "gloves": [.gloves],
  "boots":  [.boots],
  "ring":   [.ring],                            // ring + ring2 (existing dual logic)
  "weapon": [.weapon],                          // strict: main weapon only
  "relic":  [.relic, .accessory, .weapon],      // ← UNIVERSAL: relic OR accessory OR 2nd weapon
  "belt":   [.belt],
]
```

**Two universal slots on iOS:**
- `"amulet"` — accepts `.amulet` and `.necklace`
- `"relic"` — accepts `.relic`, `.accessory`, and `.weapon` (off-hand/dual wield)

### Files Changed (iOS Models)

| File | Change |
|---|---|
| `Hexbound/Views/Inventory/EquipmentViewModel.swift` | Update slotOrder, add slotAccepts |

**Estimated time:** 20 min

---

## Part 3: HeroIntegratedCard — iOS Component

### New File: `HeroIntegratedCard.swift`

**Full structure from approved prototype (HERO_GRID_LAYOUT + HERO_ALL_STATES):**

```
┌─────────────────────────────────────────────────┐
│ EQUIPMENT GRID (84pt slots, 4-col grid)         │
│                                                  │
│ [Head]   [ PORTRAIT 2×3 ] [Amulet]              │
│ [Chest]  [  + name      ] [Gloves]              │
│ [Legs]   [  overlay     ] [Boots]               │
│                                                  │
│ [Ring] [Weapon] [Relic] [Belt]  ← universal     │
│                                                  │
│ ─── divider ───                                  │
│                                                  │
│ [HP ████████████ 1,030 / 1,030]  ← inside bar  │
│ [XP ████████    4,680 / 6,000]   ← inside bar  │
│ ⚡87/120 [+] | 🪙18,640 | 💎146                │
│ [⚔Chest·🛡Chest Edit] [⚠Repair All(2)·280🪙] │
└─────────────────────────────────────────────────┘
```

### Key Features

1. **Equipment first, data below** — portrait + slots are primary
2. **Name on portrait** overlay (gradient transparent → black)
3. **HP/XP bars with values inside** — centered, text-shadow for readability
4. **XP shows absolute** values (currentXp / xpNeeded) not percentage
5. **Universal bottom slots** — display accepted item types
6. **Broken item indicator** — red border + ! badge
7. **Repair All pill** — conditional, shows count + total cost
8. **Stance inline pill** — replaces old 56pt stance card
9. **All 11 states** from prototype

### Sub-components

- Portrait with name overlay + level badge + class badge
- Equipment grid (CSS Grid-style layout in SwiftUI)
- Bottom slot row
- Data section (HP bar, XP bar, resources, action pills)

### Files Created

| File | Lines ~ |
|---|---|
| `Hexbound/Views/Components/HeroIntegratedCard.swift` | ~400 |

### Xcode pbxproj

Add to 4 sections (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase).

**Estimated time:** 2-3 hrs

---

## Part 4: HeroDetailView Integration

### Remove

1. `safeAreaInset` with `UnifiedHeroWidget(context: .hero)` — replaced by card
2. `equipmentSection()` method (~90 lines) — rebuilt inside HeroIntegratedCard
3. `stanceSummaryCard()` method (~35 lines) — replaced by inline pill
4. `heroPortrait()` method (~65 lines) — rebuilt inside card
5. HP section in Status tab — HP is now in card
6. Resources section in Status tab — resources in card

### Add

1. `HeroIntegratedCard()` call with callbacks
2. `repairAllBrokenItems()` method (sequential API calls)
3. `useHealthPotion()` and `useStaminaPotion()` methods (if not already present)

### Keep

- tabSelector() — INVENTORY | STATUS
- inventoryInlineContent() — backpack grid
- statsTabContent() — base stats, derived, equipment bonuses, PvP, reset

**Estimated time:** 45 min

---

## Part 5: Design System Tokens

### LayoutConstants.swift — add

```swift
// MARK: - Hero Integrated Card
static let heroCardRadius: CGFloat = 12
static let heroCardPadding: CGFloat = 12
static let heroSlotSize: CGFloat = 84       // same as inventory
static let heroSlotGap: CGFloat = 8         // same as inventoryGap
static let heroBarHeight: CGFloat = 24      // HP bar with text inside
static let heroBarXpHeight: CGFloat = 20    // XP bar with text inside
static let heroBarRadius: CGFloat = 4
static let heroBarFont: CGFloat = 11        // text inside bars
static let heroPortraitNameFont: CGFloat = 16  // name overlay on portrait
```

### DarkFantasyTheme.swift — no new colors needed

All pill colors, bar gradients, portrait styles already exist.

**Estimated time:** 10 min

---

## Part 6: Cleanup + Docs

### Files to update

- `CLAUDE.md` — add HeroIntegratedCard rule, update universal slots info
- `docs/07_ui_ux/SCREEN_INVENTORY.md` — Hero page layout
- `docs/07_ui_ux/DESIGN_SYSTEM.md` — heroCard tokens
- `docs/04_database/SCHEMA_REFERENCE.md` — note about universal slot mapping

### Files to NOT delete yet

- `HubCharacterCard.swift` — still used indirectly? Check if fully replaced by UnifiedHeroWidget
- `StaminaBarView.swift` — check if used anywhere besides Hero (if not, delete)

**Estimated time:** 15 min

---

## Execution Order

```
Part 5 (tokens)     ──→ Part 1 (backend) ──→ Part 2 (iOS models)
                         │
                         └──→ Part 3 (HeroIntegratedCard)
                                    │
                                    └──→ Part 4 (HeroDetailView) ──→ Part 6 (cleanup)
```

Parts 1+2 (backend + iOS models) are independent from Parts 3+4 (UI). Can be done in parallel.

---

## Total Effort

| Part | Time |
|---|---|
| 1. Backend universal slots | 30 min |
| 2. iOS model updates | 20 min |
| 3. HeroIntegratedCard | 2-3 hrs |
| 4. HeroDetailView integration | 45 min |
| 5. Design tokens | 10 min |
| 6. Cleanup + docs | 15 min |
| **Total** | **~4-5 hrs** |

---

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Accessory in Weapon slot confuses players | Medium | Show slot label tooltip on long-press: "Accepts: Weapon, Accessory" |
| Necklace in Amulet slot — which item wins? | Low | Same logic as ring: first empty → replace oldest |
| Backend equip logic becomes more complex | Low | Generic multi-slot logic is actually simpler than special-case ring handling |
| Repair All sequential API calls | Low | Already validated: rate limit 15/60sec, 5 items = 5 calls = safe |
| Bottom row 4×84 = 360pt tight on 361pt | Low | 1pt margin — fine on real device |

---

## Checklist Before Merge

- [ ] Backend: `ITEM_TYPE_TO_SLOTS` replaces `ITEM_TYPE_TO_SLOT`
- [ ] Backend: Generic multi-slot equip logic works for all types
- [ ] Backend: Ring special case removed (handled generically)
- [ ] Backend: All existing items still equippable
- [ ] iOS: `slotAccepts` mapping correct
- [ ] iOS: HeroIntegratedCard renders correctly on iPhone 15 Pro
- [ ] iOS: All 11 states work (default, low HP, critical, stamina, level up, stat points, broken, empty, skeleton, error, offline)
- [ ] iOS: Equipment grid matches 4-col grid (84pt slots)
- [ ] iOS: Portrait shows name overlay
- [ ] iOS: HP/XP bars have values inside, centered
- [ ] iOS: XP shows absolute (current / needed), not percentage
- [ ] iOS: Repair All pill shows correct count + total cost
- [ ] iOS: Broken items have red border + ! badge
- [ ] iOS: Stance pill works (navigates to StanceSelector)
- [ ] iOS: Xcode build succeeds
- [ ] iOS: pbxproj updated for new file
- [ ] Docs: CLAUDE.md updated
- [ ] Docs: Schema reference updated
