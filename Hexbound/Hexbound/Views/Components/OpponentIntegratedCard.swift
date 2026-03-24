import SwiftUI

/// Integrated portrait + equipment card for opponent profiles (leaderboard detail sheet).
/// Mirrors HeroIntegratedCard layout: portrait in center (2×3 cells), equipment slots around it.
@MainActor
struct OpponentIntegratedCard: View {
    let profile: OpponentProfile

    // MARK: - Computed

    private var equipment: [Item] {
        profile.equipment ?? []
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

            // ═══ HP + PVP RANK ═══
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

    // MARK: - Equipment Grid

    private var gridCellWidth: CGFloat {
        // Account for sheet padding (screenPadding on each side) + card padding
        let cardInnerW = UIScreen.main.bounds.width - 2 * LayoutConstants.screenPadding - 2 * LayoutConstants.heroCardPadding
        return floor((cardInnerW - 3 * LayoutConstants.heroSlotGap) / 4)
    }

    private var equipmentGrid: some View {
        let cw = gridCellWidth
        let slotGap = LayoutConstants.heroSlotGap
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
            // HP bar
            HPBarView(
                currentHp: profile.currentHp,
                maxHp: profile.maxHp,
                size: .large,
                label: "HP"
            )

            // Rank + Rating pill row
            HStack(spacing: LayoutConstants.spaceSM) {
                let rank = profile.pvpRank
                HStack(spacing: 4) {
                    Text(rank.icon)
                        .font(.system(size: 13))
                    Text(rank.rawValue)
                        .font(DarkFantasyTheme.section(size: 13))
                        .foregroundStyle(rank.color)
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    Capsule()
                        .fill(rank.color.opacity(0.12))
                        .overlay(Capsule().stroke(rank.color.opacity(0.25), lineWidth: 1))
                )

                HStack(spacing: 4) {
                    Text("⚔")
                        .font(.system(size: 12))
                    Text("\(profile.pvpRating)")
                        .font(DarkFantasyTheme.section(size: 13))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    Capsule()
                        .fill(DarkFantasyTheme.gold.opacity(0.12))
                        .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.25), lineWidth: 1))
                )

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
                skinKey: profile.avatar,
                characterClass: profile.characterClass,
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
                    Text(profile.characterName)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.heroPortraitNameFont))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                    Text(profile.characterClass.rawValue.uppercased())
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
                    Image(profile.characterClass.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(DarkFantasyTheme.bgTertiary))
                        .clipShape(Circle())

                    Spacer()

                    Text("Lv. \(profile.level)")
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

            // Prestige badge (if applicable)
            if let prestige = profile.prestigeLevel, prestige > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("P\(prestige)")
                            .font(DarkFantasyTheme.section(size: 10))
                            .foregroundStyle(DarkFantasyTheme.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(DarkFantasyTheme.cyan.opacity(0.15))
                                    .overlay(Capsule().stroke(DarkFantasyTheme.cyan.opacity(0.3), lineWidth: 1))
                            )
                    }
                }
                .padding(LayoutConstants.spaceSM)
            }
        }
    }

    // MARK: - Equipment Slot

    private func findEquippedItem(slot: String, index: Int = 0) -> Item? {
        let accepted = EquipmentViewModel.slotAccepts[slot] ?? [slot]
        switch slot {
        case "ring":
            let rings = equipment.filter { $0.equippedSlot == "ring" || $0.equippedSlot == "ring2" || ($0.equippedSlot == nil && $0.itemType == .ring) }
            return index < rings.count ? rings[index] : nil
        default:
            return equipment.first { item in
                if item.equippedSlot == slot { return true }
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
            ) { }
            .frame(width: size, height: size)
        } else {
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
