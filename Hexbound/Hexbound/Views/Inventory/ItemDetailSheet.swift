import SwiftUI

struct ItemDetailSheet: View {
    let item: Item
    let comparedItem: Item?
    let playerGems: Int
    let upgradeChances: [Int]
    let onEquip: () -> Void
    let onUnequip: () -> Void
    let onSell: () -> Void
    let onUse: () -> Void
    let onUpgrade: (Bool) -> Void
    let onRepair: () -> Void
    let onClose: () -> Void

    // Shop mode (optional)
    var shopMode: ShopContext? = nil
    /// Player's current level — used for both shop level gating and inventory
    /// equip eligibility (BUG-63: shows required level in red + disables EQUIP
    /// when `playerLevel < item.itemLevel`).
    var playerLevel: Int = 1
    /// Player's class — used to check `item.classRestriction` client-side
    /// so the EQUIP button disables BEFORE we hit the server's CLASS_RESTRICTED.
    var playerClass: CharacterClass? = nil
    /// View-only mode — hides economy, upgrade, and action buttons (used for opponent item inspection)
    var viewMode: Bool = false
    /// Optional deposit-to-stash action — shown when item is unequipped and in regular inventory context
    var onDeposit: (() -> Void)? = nil

    struct ShopContext {
        let price: Int
        let isGemPurchase: Bool
        let canAfford: Bool
        let meetsLevel: Bool
        let isBuying: Bool
        let requiredLevel: Int
        /// Bug #20: set to true for stackable consumables so the buy panel
        /// shows a quantity stepper. Gem packs are excluded (single-purchase).
        let isConsumable: Bool
        /// Bug #20: player's current gold — used to clamp the stepper to what
        /// the player can actually afford (for gold-priced consumables).
        let playerGold: Int
        let onBuy: (Int) -> Void
    }

    @State var showUpgradeConfirm = false
    @State var useProtection = false
    @State var showSellConfirm = false
    /// Bug #20: selected purchase quantity for stackable consumables in shop mode.
    @State var purchaseQuantity: Int = 1

    var rarityColor: Color {
        DarkFantasyTheme.rarityColor(for: item.rarity)
    }

    var isEquipped: Bool {
        item.isEquipped ?? false
    }

    // MARK: - Equip eligibility (BUG-63)
    //
    // Mirrors the server-side checks in `backend/src/app/api/inventory/equip/route.ts`:
    //   - character.level < item.itemLevel → LEVEL_TOO_LOW
    //   - classRestriction && classRestriction !== character.class → CLASS_RESTRICTED
    //   - broken (durability == 0) → cannot equip
    //
    // Doing the check client-side lets us paint the item level red and disable
    // the EQUIP button BEFORE the user taps it, instead of surfacing an error
    // toast after a round-trip to the server.

    /// Whether we should show equip-eligibility hints at all. Shop mode has
    /// its own level gate; view mode (opponent inspection) is read-only;
    /// consumables don't "equip" and already-equipped items obviously passed
    /// the check at some point so we don't want to paint them red.
    var shouldCheckEquipEligibility: Bool {
        !viewMode && shopMode == nil && item.itemType != .consumable && !isEquipped
    }

    var levelMet: Bool {
        guard shouldCheckEquipEligibility else { return true }
        return playerLevel >= item.itemLevel
    }

    var classMet: Bool {
        guard shouldCheckEquipEligibility else { return true }
        guard let restriction = item.classRestriction?.lowercased(),
              !restriction.isEmpty,
              restriction != "none" else { return true }
        guard let playerClass else { return true }
        return restriction == playerClass.rawValue.lowercased()
    }

    /// Overall: can this item be equipped right now?
    var canEquipNow: Bool {
        levelMet && classMet && !isBroken
    }

    /// Human-readable reason the EQUIP button is disabled (shown above buttons).
    var equipBlockedReason: String? {
        guard shouldCheckEquipEligibility else { return nil }
        if !levelMet {
            return "Requires Level \(item.itemLevel) (You: Level \(playerLevel))"
        }
        if !classMet, let restriction = item.classRestriction {
            return "\(restriction.capitalized) class only"
        }
        if isBroken {
            return "Item is broken — repair it first"
        }
        return nil
    }

    /// Contextual equip SFX based on item type — metal clank vs cloth rustle vs magic shimmer.
    var equipSFX: SFX {
        switch item.itemType {
        case .weapon, .helmet, .chest, .gloves, .legs, .boots, .belt:
            return .armorClink
        case .accessory, .amulet, .necklace, .ring, .relic:
            return .magicShimmer
        case .consumable:
            return .uiEquip  // fallback
        }
    }

    var currentUpgradeLevel: Int { item.upgradeLevel ?? 0 }
    var canUpgrade: Bool { item.itemType != .consumable && currentUpgradeLevel < 10 && !isBroken }
    var upgradeCost: Int { (currentUpgradeLevel + 1) * 100 }
    var upgradeChance: Int {
        guard currentUpgradeLevel < upgradeChances.count else { return 0 }
        return upgradeChances[currentUpgradeLevel]
    }

    var hasDurability: Bool {
        item.durability != nil && item.maxDurability != nil && item.itemType != .consumable
    }
    var isBroken: Bool {
        item.durability == 0 && item.maxDurability != nil
    }
    var isDamaged: Bool {
        guard let dur = item.durability, let maxDur = item.maxDurability else { return false }
        return dur < maxDur
    }
    var repairCost: Int {
        ((item.maxDurability ?? 0) - (item.durability ?? 0)) * 2
    }
    var durabilityFraction: Double {
        guard let dur = item.durability, let maxDur = item.maxDurability, maxDur > 0 else { return 0 }
        return Double(dur) / Double(maxDur)
    }
    var durabilityColor: Color {
        if durabilityFraction > 0.6 { return DarkFantasyTheme.success }
        if durabilityFraction > 0.3 { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.danger
    }
    var durabilityGradient: LinearGradient {
        LinearGradient(
            colors: [durabilityColor, durabilityColor.opacity(0.7)],
            startPoint: .leading, endPoint: .trailing
        )
    }

    var body: some View {
        ZStack {
            // Backdrop — tap to close
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // SECTION 1 — Header
                        headerSection
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(LayoutConstants.cardPadding)

                        sectionDivider

                        // SECTION 2 — Stats
                        statsSection

                        // SECTION 2.5 — Durability
                        durabilitySection

                        // SECTION 3 — Comparison
                        comparisonSection

                        // SECTION 4 — Effects
                        effectsSection

                        // SECTION 5 — Economy (hide in shop mode and view mode)
                        if shopMode == nil && !viewMode {
                            economySection
                        }

                        // SECTION 6 — Upgrade (hide in shop mode and view mode)
                        if shopMode == nil && !viewMode {
                            upgradeInfoSection
                        }

                        // SECTION 7 — Description
                        descriptionSection
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)

                // Action buttons pinned to bottom
                actionButtons
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .padding(.vertical, LayoutConstants.spaceMD)
            }
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.08, bottomShadow: 0.14)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: rarityColor.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(rarityColor.opacity(0.5), lineWidth: 2)
            )
            .cornerBrackets(color: rarityColor.opacity(0.5), length: 18, thickness: 2.0)
            .cornerDiamonds(color: rarityColor.opacity(0.4), size: 6)
            .shadow(color: rarityColor.opacity(0.18), radius: 10, y: 0)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

}
