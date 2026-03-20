import SwiftUI

/// Hero Integrated Card: equipment-first layout with portrait, HP/XP bars inside, resources, action pills.
/// Replaces UnifiedHeroWidget + equipmentSection + stanceSummaryCard on Hero page.
@MainActor
struct HeroIntegratedCard: View {
    let character: Character
    let equippedItems: [Item]

    var onTapPortrait: (() -> Void)? = nil
    var onTapSlot: ((Item) -> Void)? = nil
    var onEditStance: (() -> Void)? = nil
    var onRepairAll: (() -> Void)? = nil
    var onAllocateStats: (() -> Void)? = nil
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

    private var hasStatPoints: Bool {
        (character.statPoints ?? 0) > 0
    }

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ═══ EQUIPMENT FIRST ═══
            equipmentGrid
                .padding(LayoutConstants.heroCardPadding)

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

    // MARK: - Equipment Grid (no GeometryReader — computed cell width)

    /// Cell width for 4-column grid inside the card
    private var cellWidth: CGFloat {
        let cardInnerW = UIScreen.main.bounds.width - 2 * LayoutConstants.screenPadding - 2 * LayoutConstants.heroCardPadding
        return max((cardInnerW - CGFloat(LayoutConstants.inventoryCols - 1) * LayoutConstants.heroSlotGap) / CGFloat(LayoutConstants.inventoryCols), 0)
    }

    private var equipmentGrid: some View {
        let cw = cellWidth
        let portraitW = 2 * cw + LayoutConstants.heroSlotGap
        let portraitH = 3 * cw + 2 * LayoutConstants.heroSlotGap

        return VStack(spacing: LayoutConstants.heroSlotGap) {
            // Top: 3 left | portrait | 3 right
            HStack(alignment: .top, spacing: LayoutConstants.heroSlotGap) {
                VStack(spacing: LayoutConstants.heroSlotGap) {
                    equipSlot("helmet", size: cw)
                    equipSlot("chest", size: cw)
                    equipSlot("legs", size: cw)
                }

                heroPortrait()
                    .frame(width: portraitW, height: portraitH)

                VStack(spacing: LayoutConstants.heroSlotGap) {
                    equipSlot("amulet", size: cw)
                    equipSlot("gloves", size: cw)
                    equipSlot("boots", size: cw)
                }
            }

            // Bottom: Ring, Weapon, Relic, Belt
            HStack(spacing: LayoutConstants.heroSlotGap) {
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
            // HP bar with label + value INSIDE
            hpBarInside

            // XP bar with label + value INSIDE
            xpBarInside

            // Stamina bar with label + value INSIDE (orange)
            staminaBarInside

            // Action pills (no gold/gems — moved to inventory header)
            HStack(spacing: LayoutConstants.spaceSM) {
                // Stance (always)
                if let stance = character.combatStance {
                    WidgetPill(
                        icon: "⚔️",
                        text: "\(stance.attack.capitalized) · 🛡 \(stance.defense.capitalized)",
                        style: .pvp,
                        isInteractive: true,
                        action: { onEditStance?() }
                    )
                }

                // Repair All (conditional: broken items exist)
                if !brokenItems.isEmpty {
                    WidgetPill(
                        icon: "⚠️",
                        text: "Repair All(\(brokenItems.count))",
                        style: .warn,
                        isInteractive: true,
                        action: { onRepairAll?() }
                    )
                }

                // Stat Points (conditional)
                if hasStatPoints {
                    WidgetPill(
                        icon: "⭐",
                        text: "+\(character.statPoints ?? 0) Stats",
                        style: .stat,
                        isInteractive: true,
                        action: { onAllocateStats?() }
                    )
                }

                // Heal (conditional: HP low + potion available)
                if character.hpPercentage < 0.5 && healthPotionCount > 0 {
                    WidgetPill(
                        icon: "🧪",
                        text: "Heal",
                        count: "×\(healthPotionCount)",
                        style: character.hpPercentage < 0.25 ? .urgent : .heal,
                        isInteractive: true,
                        action: { onUseHealthPotion?() }
                    )
                }

                Spacer()
            }
        }
    }

    // MARK: - HP Bar (label + value inside)

    private var hpBarInside: some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                .fill(Color.white.opacity(0.06))
                .frame(height: LayoutConstants.heroBarHeight)

            // Fill
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                    .fill(DarkFantasyTheme.canonicalHpGradient(percentage: character.hpPercentage))
                    .frame(width: geo.size.width * character.hpPercentage)
            }
            .frame(height: LayoutConstants.heroBarHeight)

            // Label + Value centered
            HStack {
                Spacer()
                Text("HP  \(character.currentHp) / \(character.maxHp)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.heroBarFont).bold())
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.6), radius: 2)
                    .monospacedDigit()
                Spacer()
            }
            .frame(height: LayoutConstants.heroBarHeight)
        }
    }

    // MARK: - XP Bar (label + value inside, absolute numbers)

    private var xpBarInside: some View {
        let xpCurrent = character.experience ?? 0
        let xpMax = character.xpNeeded
        let fraction = min(Double(xpCurrent) / Double(max(xpMax, 1)), 1.0)
        let isNearLevelUp = fraction >= 0.9

        return ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                .fill(Color.white.opacity(0.06))
                .frame(height: LayoutConstants.heroBarXpHeight)

            // Fill
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                    .fill(isNearLevelUp ? DarkFantasyTheme.xpGoldenGradient : DarkFantasyTheme.xpGradient)
                    .frame(width: geo.size.width * fraction)
            }
            .frame(height: LayoutConstants.heroBarXpHeight)

            // Label + Value centered
            HStack {
                Spacer()
                Text("XP  \(xpCurrent) / \(xpMax)\(isNearLevelUp ? " ⬆" : "")")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.heroBarFont).bold())
                    .foregroundStyle(isNearLevelUp ? DarkFantasyTheme.goldBright : .white.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 2)
                    .monospacedDigit()
                Spacer()
            }
            .frame(height: LayoutConstants.heroBarXpHeight)
        }
    }

    // MARK: - Stamina Bar (orange, same style as HP/XP)

    private var staminaBarInside: some View {
        let fraction = character.maxStamina > 0 ? Double(character.currentStamina) / Double(character.maxStamina) : 0
        let isLow = character.currentStamina < 10

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                .fill(Color.white.opacity(0.06))
                .frame(height: LayoutConstants.heroBarXpHeight)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                    .fill(DarkFantasyTheme.staminaGradient)
                    .frame(width: geo.size.width * fraction)
            }
            .frame(height: LayoutConstants.heroBarXpHeight)

            HStack {
                Spacer()
                Text("Stamina  \(character.currentStamina) / \(character.maxStamina)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.heroBarFont).bold())
                    .foregroundStyle(isLow ? DarkFantasyTheme.textWarning : .white.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 2)
                    .monospacedDigit()
                Spacer()
            }
            .frame(height: LayoutConstants.heroBarXpHeight)
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

            // Name overlay at bottom
            VStack {
                Spacer()
                Text(character.characterName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.heroPortraitNameFont))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black.opacity(0.7)],
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
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(DarkFantasyTheme.bgTertiary))
                        .clipShape(Circle())

                    Spacer()

                    Text("\(character.level)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption).bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(DarkFantasyTheme.gold))
                }
                Spacer()
            }
            .padding(LayoutConstants.spaceSM)
        }
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
        let assetName = EquipmentViewModel.slotAssets[slot]
        let rarityColor = item.map { DarkFantasyTheme.rarityColor(for: $0.rarity) } ?? DarkFantasyTheme.borderSubtle
        let isBroken = (item?.durability ?? 1) <= 0

        Button {
            if let item { onTapSlot?(item) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
                    .fill(item != nil ? rarityColor.opacity(0.15) : DarkFantasyTheme.bgTertiary.opacity(0.4))

                if let item {
                    if let key = item.imageKey, UIImage(named: key) != nil {
                        Image(key)
                            .resizable().scaledToFit()
                            .frame(width: size * 0.65, height: size * 0.65)
                    } else if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFit()
                                    .frame(width: size * 0.65, height: size * 0.65)
                            default:
                                itemFallbackIcon(item: item, assetName: assetName, size: size)
                            }
                        }
                    } else {
                        itemFallbackIcon(item: item, assetName: assetName, size: size)
                    }
                } else if let assetName {
                    Image(assetName)
                        .resizable().scaledToFit()
                        .frame(width: size * 0.5, height: size * 0.5)
                        .opacity(0.35)
                }

                // Broken indicator
                if isBroken {
                    VStack {
                        HStack {
                            Spacer()
                            Text("!")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(Circle().fill(DarkFantasyTheme.danger))
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .overlay(alignment: .bottom) {
                if let item, let level = item.upgradeLevel, level > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<level, id: \.self) { _ in
                            Circle()
                                .fill(DarkFantasyTheme.goldBright)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.45))
                    .clipShape(.rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: LayoutConstants.heroSlotRadius,
                        bottomTrailingRadius: LayoutConstants.heroSlotRadius,
                        topTrailingRadius: 0
                    ))
                }
            }
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
                    .stroke(
                        isBroken ? DarkFantasyTheme.danger : (item != nil ? rarityColor.opacity(0.6) : DarkFantasyTheme.borderSubtle),
                        lineWidth: item != nil ? 2 : 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(0.95))
        .disabled(item == nil)
    }

    @ViewBuilder
    private func itemFallbackIcon(item: Item, assetName: String?, size: CGFloat) -> some View {
        let asset = assetName ?? item.itemType.iconAsset
        if let asset {
            Image(asset)
                .resizable().scaledToFit()
                .frame(width: size * 0.55, height: size * 0.55)
        } else {
            Text(item.itemType.icon)
                .font(.system(size: 22))
        }
    }
}
