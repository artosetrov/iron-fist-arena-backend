import SwiftUI

/// Standalone loot screen — shown when navigating to AppRoute.loot directly.
/// Now uses the unified BattleResultCardView for consistent styling.
struct LootDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedLootIndex: Int? = nil

    private var lootItems: [PendingLootItem] {
        appState.pendingLoot
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            BattleResultCardView(config: buildConfig())

            // Item Detail Modal
            if let index = selectedLootIndex, index < lootItems.count {
                lootDetailModal(lootItems[index])
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Build Config

    private func buildConfig() -> BattleResultConfig {
        let items = lootItems.map { item -> LootItemDisplay in
            let rarity = ItemRarity(rawValue: item.rarityKey) ?? .common
            let rawType = item.resolvedTypeKey
            let type = ItemType(rawValue: rawType)

            return LootItemDisplay(
                name: item.displayTitle,
                rarityName: rarity.displayName,
                rarityColor: DarkFantasyTheme.rarityColor(for: rarity),
                imageKey: item.imageKey,
                imageUrl: item.imageUrl,
                sfIcon: Self.consumableSFIcon(for: item.consumableType, type: rawType),
                sfColor: Self.consumableSFColor(for: item.consumableType, type: rawType),
                fallbackIcon: type?.icon ?? (item.isShard ? "diamond.fill" : "shippingbox"),
                rarityTier: rarity.tier
            )
        }

        return BattleResultConfig(
            isVictory: true,
            title: lootItems.isEmpty ? "NO LOOT" : "LOOT FOUND!",
            subtitle: nil,
            illustrationImage: lootItems.isEmpty ? nil : "result-loot-found",
            goldReward: nil,
            xpReward: nil,
            ratingChange: nil,
            firstWinBonus: false,
            xpBarConfig: nil,
            dungeonProgress: nil,
            lootItems: items,
            onLootTap: { index in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedLootIndex = index
                }
            },
            buttons: [
                ResultButton(title: "TAKE ALL", icon: nil, style: .primary) {
                    goBack()
                }
            ]
        )
    }

    // MARK: - Loot Detail Modal

    @ViewBuilder
    private func lootDetailModal(_ item: PendingLootItem) -> some View {
        let name = item.displayName
        let rawRarity = item.rarityKey
        let rarity = ItemRarity(rawValue: rawRarity) ?? .common
        let rawType = item.resolvedTypeKey
        let type = ItemType(rawValue: rawType)
        let level = item.resolvedLevel
        let upgrade = item.resolvedUpgradeLevel
        let lootImageUrl = item.imageUrl
        let lootImageKey = item.imageKey
        let rarityColor = DarkFantasyTheme.rarityColor(for: rarity)
        let description = item.description
        let specialEffect = item.specialEffect
        let stats = item.resolvedStats
        let isGold = item.isGoldLike
        let quantity = item.resolvedQuantity
        let consumableType = item.consumableType
        let sfIcon = Self.consumableSFIcon(for: consumableType, type: rawType)
        let sfColor = Self.consumableSFColor(for: consumableType, type: rawType)
        let typeLabel = type?.displayName ?? (item.isShard ? "Shard" : rawType.capitalized)

        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedLootIndex = nil
                    }
                }

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
                    ZStack {
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(DarkFantasyTheme.bgTertiary)
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(rarityColor.opacity(0.6), lineWidth: 2)

                        ItemImageView(
                            imageKey: lootImageKey,
                            imageUrl: lootImageUrl,
                            systemIcon: sfIcon,
                            systemIconColor: sfColor,
                            placeholderIcon: type?.icon ?? (item.isShard ? "diamond.fill" : "shippingbox")
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius - 2))
                    }
                    .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                        if isGold, let qty = quantity {
                            Text("\(qty) Gold")
                                .font(DarkFantasyTheme.section)
                                .foregroundStyle(rarityColor)
                        } else {
                            Text(upgrade > 0 ? "\(name) +\(upgrade)" : name)
                                .font(DarkFantasyTheme.section)
                                .foregroundStyle(rarityColor)
                                .lineLimit(2)
                        }

                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text(typeLabel.lowercased())
                                .font(DarkFantasyTheme.body.weight(.semibold))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                                .padding(.horizontal, LayoutConstants.spaceXS)
                                .padding(.vertical, LayoutConstants.space2XS)
                                .background(Capsule().fill(DarkFantasyTheme.bgTertiary))
                                .overlay(Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
                                .accessibilityLabel("Item type: \(typeLabel)")

                            Text(rarity.rawValue)
                                .font(DarkFantasyTheme.body.weight(.semibold))
                                .foregroundStyle(rarityColor)
                                .padding(.horizontal, LayoutConstants.spaceXS)
                                .padding(.vertical, LayoutConstants.space2XS)
                                .background(Capsule().fill(rarityColor.opacity(0.15)))
                                .overlay(Capsule().stroke(rarityColor.opacity(0.4), lineWidth: 1))
                                .accessibilityLabel("Rarity: \(rarity.rawValue)")
                        }
                        .accessibilityElement(children: .combine)

                        if !isGold {
                            Text("Level \(level)")
                                .font(DarkFantasyTheme.body)
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }

                    Spacer(minLength: 0)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedLootIndex = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.closeButton)
                }
                .padding(LayoutConstants.cardPadding)

                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(height: 1)

                if let stats = stats, !stats.isEmpty {
                    VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "shield.fill")
                                .font(DarkFantasyTheme.body)
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                            Text("STATS")
                                .font(DarkFantasyTheme.body.weight(.semibold))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                                .tracking(1.2)
                        }

                        ForEach(stats.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(Item.statLabels[key] ?? key.capitalized)
                                    .font(DarkFantasyTheme.body)
                                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                                    .accessibilityLabel("Stat: \(Item.statLabels[key] ?? key)")
                                Spacer()
                                Text("+\(value)")
                                    .font(DarkFantasyTheme.cardTitle)
                                    .foregroundStyle(DarkFantasyTheme.statColor(for: key))
                                    .accessibilityLabel("+\(value) \(Item.statLabels[key] ?? key)")
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .padding(.vertical, LayoutConstants.spaceMD)

                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)
                }

                if let effect = specialEffect, !effect.isEmpty {
                    HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "sparkles")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                        Text(effect)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .padding(.vertical, LayoutConstants.spaceMD)

                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)
                }

                // Comparison vs equipped item
                if !isGold, let type = type, let stats = stats {
                    let equipped = appState.cachedInventory?.first {
                        $0.isEquipped == true && $0.itemType == type
                    }
                    let equippedStats = equipped?.effectiveStats ?? [:]
                    let allKeys = Set(stats.keys).union(Set(equippedStats.keys))
                    let deltas = allKeys.compactMap { key -> (String, Int)? in
                        let val = stats[key] ?? 0
                        let comp = equippedStats[key] ?? 0
                        let delta = val - comp
                        return delta != 0 ? (key, delta) : nil
                    }.sorted(by: { $0.0 < $1.0 })

                    if !deltas.isEmpty {
                        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                            HStack(spacing: LayoutConstants.spaceXS) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(DarkFantasyTheme.body)
                                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                                Text(equipped != nil ? "VS. EQUIPPED" : "STAT BONUS")
                                    .font(DarkFantasyTheme.body.weight(.semibold))
                                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                                    .tracking(1.2)
                            }

                            ForEach(deltas, id: \.0) { key, delta in
                                lootComparisonRow(key: key, delta: delta, itemValue: stats[key] ?? 0)
                            }
                        }
                        .padding(.horizontal, LayoutConstants.cardPadding)
                        .padding(.vertical, LayoutConstants.spaceMD)

                        Rectangle()
                            .fill(DarkFantasyTheme.borderSubtle)
                            .frame(height: 1)
                    }
                }

                // Sell price
                if !isGold {
                    let sellPrice = item.resolvedSellPrice
                    if sellPrice > 0 {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text("Sell:")
                                .font(DarkFantasyTheme.body)
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                            CurrencyDisplay(gold: sellPrice, size: .compact, currencyType: .gold, animated: false)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, LayoutConstants.cardPadding)
                        .padding(.vertical, LayoutConstants.spaceMD)

                        Rectangle()
                            .fill(DarkFantasyTheme.borderSubtle)
                            .frame(height: 1)
                    }
                }

                if let desc = description, !desc.isEmpty {
                    Text(desc)
                        .font(DarkFantasyTheme.body)
                        .italic()
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, LayoutConstants.cardPadding)
                        .padding(.vertical, LayoutConstants.spaceMD)
                }
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
            .fixedSize(horizontal: false, vertical: true)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .transition(.opacity)
    }

    // MARK: - Loot Comparison Row

    private func lootComparisonRow(key: String, delta: Int, itemValue: Int) -> some View {
        let statType = StatType.allCases.first(where: { $0.apiKey == key })
        let deltaColor = delta > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger
        let arrow = delta > 0 ? "▲" : "▼"
        let label = delta > 0 ? "\(arrow)+\(delta)" : "\(arrow)\(delta)"

        return HStack(spacing: LayoutConstants.spaceXS) {
            if let statType {
                Image(statType.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
            }

            Text(Item.statLabels[key] ?? key.capitalized)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Spacer(minLength: 4)

            Text(label)
                .font(DarkFantasyTheme.body.bold())
                .foregroundStyle(deltaColor)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(deltaColor.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .stroke(deltaColor.opacity(0.4), lineWidth: 1)
                        )
                )

            Text("+\(itemValue)")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .frame(minWidth: 30, alignment: .trailing)
        }
    }

    // MARK: - Navigation

    private func goBack() {
        let currentSource = appState.combatResult?.source ?? "training"
        appState.combatData = nil
        appState.combatResult = nil
        if currentSource == "arena" || currentSource == "pvp" {
            let keepCount = min(1, appState.mainPath.count)
            let removals = appState.mainPath.count - keepCount
            if removals > 0 {
                appState.mainPath.removeLast(removals)
            }
        } else {
            appState.mainPath = NavigationPath()
        }
    }

    // MARK: - Consumable Icon Helpers

    static func consumableSFIcon(for consumableType: String?, type: String) -> String? {
        if type == "shard" { return "diamond.fill" }
        guard type == "consumable" else { return nil }
        let ct = consumableType ?? ""
        if ct.contains("gem_pack") { return "diamond.fill" }
        if ct.contains("health") { return "heart.fill" }
        if ct.contains("stamina") { return "bolt.fill" }
        return "flask.fill"
    }

    static func consumableSFColor(for consumableType: String?, type: String) -> Color? {
        if type == "shard" { return DarkFantasyTheme.cyan }
        guard type == "consumable" else { return nil }
        let ct = consumableType ?? ""
        if ct.contains("gem_pack") { return DarkFantasyTheme.cyan }
        if ct.contains("health") { return DarkFantasyTheme.hpBlood }
        if ct.contains("stamina") { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.goldBright
    }
}
