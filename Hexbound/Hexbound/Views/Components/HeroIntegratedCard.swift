import SwiftUI

/// Hero Integrated Card: equipment-first layout with portrait, HP/XP bars inside, resources, action pills.
/// Replaces UnifiedHeroWidget + equipmentSection + stanceSummaryCard on Hero page.
@MainActor
struct HeroIntegratedCard: View {
    let character: Character
    let equippedItems: [Item]

    var onTapPortrait: (() -> Void)? = nil
    var onTapSlot: ((Item) -> Void)? = nil
    var onRepairAll: (() -> Void)? = nil
    var onUseHealthPotion: (() -> Void)? = nil
    var onRefillStamina: (() -> Void)? = nil

    @Environment(AppState.self) private var appState

    // MARK: - Computed

    private var healthPotionCount: Int {
        guard let items = appState.cachedInventory else { return 0 }
        return items.filter { $0.consumableType?.contains("health_potion") == true }.reduce(0) { $0 + ($1.quantity ?? 0) }
    }

    private var brokenItems: [Item] {
        equippedItems.filter { ($0.durability ?? 1) <= 0 }
    }

    private var totalRepairCost: Int {
        brokenItems.reduce(0) { $0 + (($1.maxDurability ?? 0) - ($1.durability ?? 0)) * 2 }
    }

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ═══ EQUIPMENT GRID ═══
            equipmentGrid
                .padding(.horizontal, LayoutConstants.heroCardPadding)
                .padding(.top, LayoutConstants.heroCardPadding)
                .padding(.bottom, LayoutConstants.spaceLG)

            // ═══ DIVIDER ═══
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.borderSubtle, .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, LayoutConstants.heroCardPadding)

            // ═══ DATA BELOW ═══
            dataSection
                .padding(LayoutConstants.heroCardPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.heroCardRadius)
                .fill(DarkFantasyTheme.bgCardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.heroCardRadius)
                .stroke(DarkFantasyTheme.bgCardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.heroCardRadius))
    }

    // MARK: - Equipment Grid (computed cell width, no GeometryReader)

    /// Cell width for uniform 4-column grid
    private var gridCellWidth: CGFloat {
        let cardInnerW = UIScreen.main.bounds.width - 2 * LayoutConstants.screenPadding - 2 * LayoutConstants.heroCardPadding
        return floor((cardInnerW - 3 * LayoutConstants.heroSlotGap) / 4)
    }

    private var equipmentGrid: some View {
        let cw = gridCellWidth
        let slotGap = LayoutConstants.heroSlotGap
        // Portrait = exactly 2 cells + 1 gap (centered in grid)
        let portraitW = 2 * cw + slotGap
        let portraitH = 3 * cw + 2 * slotGap

        return VStack(spacing: slotGap) {
            // Top: 3 left | portrait (2-col) | 3 right
            HStack(alignment: .top, spacing: slotGap) {
                VStack(spacing: slotGap) {
                    equipSlot("helmet", size: cw)
                    equipSlot("chest", size: cw)
                    equipSlot("legs", size: cw)
                }
                .frame(width: cw)

                heroPortrait()
                    .frame(width: portraitW, height: portraitH)

                VStack(spacing: slotGap) {
                    equipSlot("amulet", size: cw)
                    equipSlot("gloves", size: cw)
                    equipSlot("boots", size: cw)
                }
                .frame(width: cw)
            }

            // Bottom: Ring, Weapon, Relic, Belt
            HStack(spacing: slotGap) {
                equipSlot("ring", size: cw, index: 0)
                equipSlot("weapon", size: cw)
                equipSlot("relic", size: cw)
                equipSlot("belt", size: cw)
            }
        }
    }

    // MARK: - Data Section (below divider)

    private var dataSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // HP bar (unified component, large size)
            HPBarView(
                currentHp: character.currentHp,
                maxHp: character.maxHp,
                size: .large,
                label: "HP"
            )

            // XP bar (unified component, large size)
            XPBarView(
                currentXp: character.experience ?? 0,
                xpNeeded: character.xpNeeded,
                size: .large
            )

            // Stamina bar (unified component, large size)
            StaminaBarView(
                currentStamina: character.currentStamina,
                maxStamina: character.maxStamina,
                size: .large
            )

            // Action pills
            HStack(spacing: LayoutConstants.spaceSM) {
                // Repair All (conditional: broken items exist)
                if !brokenItems.isEmpty {
                    WidgetPill(
                        icon: "",
                        text: "Repair All(\(brokenItems.count))",
                        imageAsset: "icon-strength",
                        style: .warn,
                        isInteractive: true,
                        action: { onRepairAll?() }
                    )
                }

                // Heal (conditional: HP low + potion available)
                if character.hpPercentage < 0.5 && healthPotionCount > 0 {
                    WidgetPill(
                        icon: "",
                        text: "Heal",
                        count: "×\(healthPotionCount)",
                        imageAsset: "pot_health_small",
                        style: character.hpPercentage < 0.25 ? .urgent : .heal,
                        isInteractive: true,
                        action: { onUseHealthPotion?() }
                    )
                }

                Spacer()
            }
        }
    }

    // MARK: - Hero Portrait

    @ViewBuilder
    private func heroPortrait() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
                        .stroke(DarkFantasyTheme.gold.opacity(0.35), lineWidth: 2)
                )

            AvatarImageView(
                skinKey: character.avatar,
                characterClass: character.characterClass,
                size: 200
            )
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius - 4))
            .overlay(
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color.clear, DarkFantasyTheme.bgSecondary.opacity(0.6), DarkFantasyTheme.bgSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius - 4))
            )

            // Name + class overlay at bottom
            VStack {
                Spacer()
                VStack(spacing: 2) {
                    Text(character.characterName)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.heroPortraitNameFont))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Text(character.characterClass.rawValue.uppercased())
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .padding(.vertical, LayoutConstants.spaceXS)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [DarkFantasyTheme.bgAbyss.opacity(0), DarkFantasyTheme.bgAbyss.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius))

            // Badges (top corners)
            VStack {
                HStack {
                    Image(character.characterClass.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .shadow(color: DarkFantasyTheme.bgAbyss, radius: 3, y: 1)

                    Spacer()

                    Text("Lv. \(character.level)")
                        .font(DarkFantasyTheme.section(size: 10).bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(
                            Capsule().fill(DarkFantasyTheme.gold)
                        )
                }
                Spacer()
            }
            .padding(LayoutConstants.spaceSM)
        }
        // Low HP red pulse overlay
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
                .stroke(DarkFantasyTheme.danger, lineWidth: 2)
                .opacity(character.hpPercentage < 0.25 ? 0.8 : 0)
                .glowPulse(color: DarkFantasyTheme.danger, intensity: 0.5, isActive: character.hpPercentage < 0.25)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTapPortrait?() }
    }

    // MARK: - Equipment Slot

    private func findEquippedItem(slot: String, index: Int = 0) -> Item? {
        // Universal slot logic
        let accepted = EquipmentViewModel.slotAccepts[slot] ?? [slot]
        switch slot {
        case "ring":
            let rings = equippedItems.filter { $0.equippedSlot == "ring" || $0.equippedSlot == "ring2" || ($0.equippedSlot == nil && $0.itemType == .ring) }
            return index < rings.count ? rings[index] : nil
        default:
            return equippedItems.first { item in
                // Check by equipped slot name
                if item.equippedSlot == slot { return true }
                // Check by accepted item types
                return accepted.contains(item.itemType.rawValue) && (item.equippedSlot == slot || item.equippedSlot == nil)
            }
        }
    }

    @ViewBuilder
    private func equipSlot(_ slot: String, size: CGFloat, index: Int = 0) -> some View {
        let item = findEquippedItem(slot: slot, index: index)
        let slotAsset = EquipmentViewModel.slotAssets[slot]

        if let item {
            ItemCardView(
                item: item,
                context: .equipment(slotAsset: slotAsset)
            ) {
                onTapSlot?(item)
            }
            .frame(width: size, height: size)
        } else {
            // Empty slot — uses ItemCardView with equipment context
            ItemCardView(
                rarity: .common,
                imageKey: nil,
                imageUrl: nil,
                fallbackIcon: "",
                context: .equipment(slotAsset: slotAsset)
            ) { }
            .frame(width: size, height: size)
        }
    }
}
