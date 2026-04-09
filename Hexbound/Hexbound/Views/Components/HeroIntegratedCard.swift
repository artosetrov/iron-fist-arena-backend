import SwiftUI

/// Hero Integrated Card: equipment-first layout with portrait, HP/XP bars inside, resources, action pills.
/// Replaces UnifiedHeroWidget + equipmentSection + stanceSummaryCard on Hero page.
@MainActor
struct HeroIntegratedCard: View {
    let character: Character
    let equippedItems: [Item]

    var onTapPortrait: (() -> Void)? = nil
    var onTapSlot: ((Item) -> Void)? = nil
    var onUseHealthPotion: (() -> Void)? = nil
    var onRefillStamina: (() -> Void)? = nil

    @Environment(AppState.self) private var appState

    // MARK: - Computed

    private var healthPotionCount: Int {
        guard let items = appState.cachedInventory else { return 0 }
        return items.filter { $0.consumableType?.contains("health_potion") == true }.reduce(0) { $0 + ($1.quantity ?? 0) }
    }


    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ═══ EQUIPMENT GRID ═══
            equipmentGrid
                .padding(.horizontal, LayoutConstants.spaceMS)
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

    // MARK: - Equipment Grid (GeometryReader for precise layout)

    /// Aspect ratio for the equipment grid (width / height)
    /// Grid = 4 cols × (3 rows top + 1 row bottom), gaps between
    private var aspectRatioForGrid: CGFloat {
        // Use a reference width to compute ratio (ratio is scale-independent)
        let refW: CGFloat = 400
        let slotGap = LayoutConstants.heroSlotGap
        let cw = (refW - 3 * slotGap) / 4
        let height = 3 * cw + 2 * slotGap + slotGap + cw // top 3 rows + gap + bottom row
        return refW / height
    }

    /// Computes cell width from actual container width
    private func gridCellWidth(in containerWidth: CGFloat) -> CGFloat {
        (containerWidth - 3 * LayoutConstants.heroSlotGap) / 4
    }

    private var equipmentGrid: some View {
        GeometryReader { geo in
            let containerW = geo.size.width
            let slotGap = LayoutConstants.heroSlotGap
            let cw = gridCellWidth(in: containerW)
            // Portrait = exactly 2 cells + 1 gap (centered in grid)
            let portraitW = 2 * cw + slotGap
            let portraitH = 3 * cw + 2 * slotGap

            VStack(spacing: slotGap) {
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
        .aspectRatio(aspectRatioForGrid, contentMode: .fit)
    }

    // MARK: - Data Section (below divider)

    private var dataSection: some View {
        // HP bar only — XP is now the ring around portrait, stamina moved to currency row
        HPBarView(
            currentHp: character.currentHp,
            maxHp: character.maxHp,
            size: .large,
            label: "HP"
        )
    }

    // MARK: - XP Ring constants for hero portrait
    private let heroXpRingWidth: CGFloat = 3.5
    private var heroXpRingCornerRadius: CGFloat { LayoutConstants.heroSlotRadius + 2 }

    // MARK: - Hero Portrait

    @ViewBuilder
    private func heroPortrait() -> some View {
        ZStack {
            // XP ring track (background)
            RoundedRectangle(cornerRadius: heroXpRingCornerRadius)
                .stroke(DarkFantasyTheme.xpRingTrack, lineWidth: heroXpRingWidth)

            // XP ring fill (progress)
            XPRingShape(ringCornerRadius: heroXpRingCornerRadius, ringLineWidth: heroXpRingWidth)
                .trim(from: 0, to: character.xpPercentage)
                .stroke(
                    DarkFantasyTheme.xpRing,
                    style: StrokeStyle(lineWidth: heroXpRingWidth, lineCap: .round)
                )
                .shadow(color: DarkFantasyTheme.xpRing.opacity(0.4), radius: 4)
                .animation(.easeInOut(duration: 1.0), value: character.xpPercentage)

            // Inner portrait area
            RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .padding(heroXpRingWidth + 1)

            // Inner content group (inset by ring width)
            Group {
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
                    VStack(spacing: LayoutConstants.space2XS) {
                        Text(character.characterName)
                            .font(DarkFantasyTheme.section)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                        Text(character.characterClass.rawValue.uppercased())
                            .font(DarkFantasyTheme.body)
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
                            .font(DarkFantasyTheme.body.bold())
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
            .padding(heroXpRingWidth + 1)

            // XP label (bottom center, over the ring)
            VStack {
                Spacer()
                Text("XP \(character.experience ?? 0)/\(character.xpNeeded)")
                    .font(DarkFantasyTheme.body.bold())
                    .foregroundStyle(DarkFantasyTheme.xpRing)
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        Capsule()
                            .fill(DarkFantasyTheme.bgAbyss.opacity(0.85))
                    )
                    .overlay(
                        Capsule()
                            .stroke(DarkFantasyTheme.xpRing.opacity(0.4), lineWidth: 0.5)
                    )
                    .offset(y: LayoutConstants.space2XS)
            }

            // Corner diamond accents on the XP ring frame
            CornerDiamondOverlay(color: DarkFantasyTheme.xpRing.opacity(0.5), size: 3)
        }
        // Low HP red pulse overlay
        .overlay(
            RoundedRectangle(cornerRadius: heroXpRingCornerRadius)
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
