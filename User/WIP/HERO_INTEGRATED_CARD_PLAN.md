# Hero Integrated Card — Implementation Plan

*Replaces: UnifiedHeroWidget on Hero page + equipmentSection + stanceSummaryCard*
*Keeps: UnifiedHeroWidget on Hub/Arena/Dungeon (unchanged)*

---

## Current State

HeroDetailView.swift currently has:
1. **safeAreaInset** → `UnifiedHeroWidget(context: .hero)` (~80pt)
2. **equipmentSection()** → portrait 2×3 + 6 side slots + 4 bottom + 2 rings + 2 empty (~470pt)
3. **stanceSummaryCard()** → ATTACK/DEFENSE card (~60pt)
4. **tabSelector()** → INVENTORY | STATUS tabs
5. **Tab content** → inventory grid or stats

Total header before tabs: **~610pt**. Target: **~420pt** (−31%).

---

## Phase 0: Design System Tokens

### LayoutConstants.swift — add section

```swift
// MARK: - Hero Integrated Card

static let heroCardRadius: CGFloat = 12          // card outer radius
static let heroCardPadding: CGFloat = 12         // header padding
static let heroBarHeight: CGFloat = 12           // HP bar height
static let heroBarXpHeight: CGFloat = 8          // XP bar height (secondary)
static let heroBarRadius: CGFloat = 4            // bar corner radius

// Equipment grid inside hero card (same as inventory grid)
static let heroSlotSize: CGFloat = 84            // SAME as inventory — no change
static let heroSlotGap: CGFloat = 8              // SAME as inventoryGap
static let heroSlotRadius: CGFloat = 12          // SAME as cardRadius
static let heroBottomSlotCount: Int = 5          // weapon, belt, relic, ring, ring
```

No changes to existing tokens. New tokens only.

### DarkFantasyTheme.swift — no changes needed

All pill colors, bar gradients, card backgrounds already exist from earlier phases.

**Commit:** `feat(design-system): add heroCard layout tokens`

---

## Phase 1: Create HeroIntegratedCard.swift

### New file: `Hexbound/Hexbound/Views/Components/HeroIntegratedCard.swift`

### Structure

```swift
@MainActor
struct HeroIntegratedCard: View {
    let character: Character
    let equippedItems: [Item]

    // Callbacks
    var onTapPortrait: (() -> Void)? = nil     // → appearance editor
    var onTapSlot: ((Item) -> Void)? = nil     // → item detail sheet
    var onEditStance: (() -> Void)? = nil      // → stance selector
    var onRepairAll: (() -> Void)? = nil        // → repair summary sheet
    var onAllocateStats: (() -> Void)? = nil    // → character detail
    var onUseHealthPotion: (() -> Void)? = nil
    var onUseStaminaPotion: (() -> Void)? = nil
    var onRefillStamina: (() -> Void)? = nil

    @Environment(AppState.self) private var appState
}
```

### Internal layout (matches HERO_GRID_LAYOUT.html prototype)

```
┌─ Card (bgCardGradient, 12px radius) ────────────────────┐
│                                                          │
│  HEADER:                                                 │
│  Degon · ⚔ Warrior · Lv.14                              │
│  ██████████████ HP ██████████ 1,030 / 1,030              │
│  ██████████ XP ████             78%                      │
│  ⚡87/120 [+] | 🪙18,640 | 💎146                        │
│  [⚔Chest·🛡Chest Edit] [⚠Repair All(2)·280🪙]         │
│                                                          │
│  ─── divider ───                                         │
│                                                          │
│  EQUIPMENT (4-col grid, 84pt slots):                     │
│  [Head]   [  PORTRAIT 2×3  ]   [Amulet]                 │
│  [Chest]  [  176×268pt     ]   [Gloves]                  │
│  [Legs]   [               ]   [Boots]                    │
│                                                          │
│  BOTTOM ROW (centered):                                  │
│  [Ring1] [Weapon] [Belt] [Relic] [Ring2]                 │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Key sub-views (private)

1. **headerSection** — identity line + HP bar + XP bar + resources + action pills
2. **equipmentGrid** — CSS Grid-style 3-column layout (slot | portrait | slot) × 3 rows
3. **bottomSlotRow** — 5 centered slots
4. **heroPortrait** — 176×268pt, clean (no name overlay), level + class badges
5. **equipSlot()** — reuse existing slot rendering logic from HeroDetailView
6. **stancePill** — inline pill replacing stanceSummaryCard
7. **repairPill** — conditional, shows count + total cost

### Slot layout (11 slots total, same 84pt)

| Position | Slot |
|---|---|
| Left row 1 | HEAD |
| Left row 2 | CHEST |
| Left row 3 | LEGS |
| Center (span 3 rows) | PORTRAIT |
| Right row 1 | AMULET |
| Right row 2 | HANDS (Gloves) |
| Right row 3 | FEET (Boots) |
| Bottom 1 | RING_1 |
| Bottom 2 | WEAPON |
| Bottom 3 | BELT |
| Bottom 4 | RELIC |
| Bottom 5 | RING_2 |

### Data dependencies (all already available)

- `character` — from AppState.currentCharacter
- `equippedItems` — from InventoryViewModel.items filtered
- Health/stamina potion counts — from AppState.cachedInventory (same as UnifiedHeroWidget)
- Broken gear check — same client-side filter
- Repair cost — `(maxDur - dur) × 2` per broken item
- Stance — `character.combatStance ?? .default`

**Commit:** `feat(hero): create HeroIntegratedCard component`

**Xcode pbxproj:** Add HeroIntegratedCard.swift to 4 sections.

---

## Phase 2: Integrate on Hero Page

### HeroDetailView.swift — changes

**Remove:**
1. `safeAreaInset` block with `UnifiedHeroWidget(context: .hero)` (lines 183-196)
2. `equipmentSection()` call (line 154) and the entire `equipmentSection` method (~90 lines)
3. `stanceSummaryCard()` call (line 157) and the entire `stanceSummaryCard` method (~35 lines)
4. `heroPortrait()` method (~65 lines) — portrait rebuilt inside HeroIntegratedCard

**Replace with:**
```swift
ScrollView {
    VStack(spacing: LayoutConstants.spaceMD) {
        // ── Integrated Hero Card (replaces widget + equipment + stance) ──
        HeroIntegratedCard(
            character: char,
            equippedItems: equippedItems,
            onTapPortrait: { appState.mainPath.append(AppRoute.appearanceEditor) },
            onTapSlot: { item in inventoryVM?.selectItem(item) },
            onEditStance: { appState.mainPath.append(AppRoute.stanceSelector) },
            onRepairAll: { Task { await repairAllBrokenItems() } },
            onAllocateStats: { appState.mainPath.append(AppRoute.character) },
            onUseHealthPotion: { Task { await useHealthPotion() } },
            onRefillStamina: { appState.mainPath.append(AppRoute.shop) }
        )
        .padding(.horizontal, LayoutConstants.screenPadding)

        GoldDivider().padding(.horizontal, LayoutConstants.screenPadding)

        // ── Tab selector ──
        tabSelector()

        // Active quest banner
        ActiveQuestBanner(questTypes: ["item_upgrade", "consumable_use"])
            .padding(.horizontal, LayoutConstants.screenPadding)

        // ── Tab content ──
        switch selectedTab {
        case .equipment:
            if let vm = inventoryVM { inventoryInlineContent(vm) }
        case .stats:
            if let vm = characterVM { statsTabContent(char, vm: vm) }
        }
    }
    .padding(.top, LayoutConstants.spaceMD)
    .padding(.bottom, LayoutConstants.spaceLG)
}
// NO safeAreaInset — card is inside scroll
```

**Add method:** `repairAllBrokenItems()` — sequential API calls:
```swift
private func repairAllBrokenItems() async {
    let brokenItems = inventoryVM?.items.filter {
        ($0.durability ?? 1) <= 0 && ($0.isEquipped ?? false)
    } ?? []

    let service = ShopService(appState: appState)
    for item in brokenItems {
        let _ = await service.repair(inventoryId: item.id)
    }
    appState.invalidateCache("inventory")
    await inventoryVM?.loadInventory()
    appState.showToast("All gear repaired!", type: .reward)
}
```

**Commit:** `refactor(hero): replace widget + equipment + stance with HeroIntegratedCard`

---

## Phase 3: Clean up Status tab

### Remove duplicate sections from statsTabContent:

1. **Health section** — HP is now in card header. Remove from Status tab.
2. **Resources section** — Gold/Gems in card header. Remove from Status tab.

These were identified as duplicates in the Hero Page Audit.

**Keep:** Base stats, derived stats, equipment bonuses, PvP section, Reset Stats.

**Commit:** `cleanup(hero): remove duplicate HP and resource sections from Status tab`

---

## Phase 4: Broken item durability indicator

### Equipment slots need visual broken state

In HeroIntegratedCard's `equipSlot()`:
```swift
if (item.durability ?? 1) <= 0 {
    // Red border
    RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
        .stroke(DarkFantasyTheme.danger, lineWidth: 2)

    // Warning badge top-right
    Circle()
        .fill(DarkFantasyTheme.danger)
        .frame(width: 16, height: 16)
        .overlay(Text("!").font(.system(size: 8, weight: .bold)).foregroundColor(.white))
        .offset(x: 4, y: -4)
}
```

**Commit:** `feat(hero): add broken item durability indicator on equipment slots`

---

## Phase 5: Update docs + CLAUDE.md

### CLAUDE.md — update Unified Hero Widget section

Add note:
```
- Hero page uses `HeroIntegratedCard` (NOT UnifiedHeroWidget)
- HeroIntegratedCard combines: header + equipment grid + bottom slots + stance pill + repair action
- UnifiedHeroWidget is for Hub/Arena/Dungeon only
```

### Update docs:
- `docs/07_ui_ux/SCREEN_INVENTORY.md` — Hero page layout changed
- `docs/07_ui_ux/DESIGN_SYSTEM.md` — new heroCard tokens

**Commit:** `docs: update Hero page layout documentation`

---

## Dependency Graph

```
Phase 0 (tokens) → Phase 1 (component) → Phase 2 (integrate) → Phase 3 (cleanup)
                                                                → Phase 4 (durability)
                                                                → Phase 5 (docs)
```

Phases 3, 4, 5 are parallel after Phase 2.

---

## Files Changed Summary

| Phase | Action | File | Lines ~Changed |
|---|---|---|---|
| 0 | Edit | LayoutConstants.swift | +10 |
| 1 | **Create** | HeroIntegratedCard.swift | ~350 new |
| 1 | Edit | project.pbxproj | +4 entries |
| 2 | Edit | HeroDetailView.swift | −250, +30 |
| 2 | Edit | HeroDetailView.swift | +20 (repairAll method) |
| 3 | Edit | HeroDetailView.swift | −80 (remove duplicate sections) |
| 4 | Edit | HeroIntegratedCard.swift | +15 (durability overlay) |
| 5 | Edit | CLAUDE.md | +5 |
| 5 | Edit | docs (2 files) | +20 |
| **Total** | | **~5 files** | **net −250 lines** |

---

## Risk Mitigation

| Risk | Mitigation |
|---|---|
| Equipment slot logic is complex (findEquippedItem, ring index, etc.) | Copy existing slot logic from HeroDetailView into HeroIntegratedCard — same code, new container |
| Portrait tap → appearance editor navigation | Same `AppRoute.appearanceEditor` already used |
| Repair All sequential API calls | Rate limit 15/60sec. For 5 items = 5 calls. Safe. Show progress toast. |
| Item detail sheet trigger | Same `inventoryVM?.selectItem(item)` pattern |
| Bottom row 5 slots: 5×84+4×8 = 452pt > 361pt content width | Bottom slots stay 84pt BUT use centered flex. On 393pt screen: 5×84+4×8 = 452. **Won't fit!** Need 5×64+4×8 = 352pt. Bottom row uses smaller slots (64pt). OR scroll horizontally. |

### ⚠️ Bottom row width issue

5 × 84pt slots + 4 × 8pt gaps = 452pt. Content width = 361pt. **Doesn't fit.**

**Options:**
1. Bottom row slots = 64pt: `5×64 + 4×8 = 352pt` ✅ fits
2. Bottom row slots = 68pt: `5×68 + 4×8 = 372pt` ❌ too wide
3. Keep 4 bottom slots (remove Belt): `4×84 + 3×8 = 360pt` ✅ fits, but loses Belt

**Recommendation:** Option 1 — bottom row slots 64pt. Still > 44pt touch min. Add token `heroBottomSlotSize: CGFloat = 64`.

---

## Estimated Effort

| Phase | Time |
|---|---|
| 0. Tokens | 10 min |
| 1. HeroIntegratedCard | 2-3 hrs |
| 2. Integrate on Hero page | 45 min |
| 3. Cleanup Status tab | 15 min |
| 4. Durability indicator | 15 min |
| 5. Docs | 15 min |
| **Total** | **~4 hrs** |
