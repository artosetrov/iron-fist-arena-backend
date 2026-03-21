import SwiftUI

/// Standalone loot screen — shown when navigating to AppRoute.loot directly.
/// Now uses the unified BattleResultCardView for consistent styling.
struct LootDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedLootIndex: Int? = nil

    private var lootItems: [[String: Any]] {
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
            let name = item["name"] as? String ?? "Item"
            let rawRarity = item["rarity"] as? String ?? "common"
            let rarity = ItemRarity(rawValue: rawRarity) ?? .common
            let rawType = item["type"] as? String ?? "weapon"
            let type = ItemType(rawValue: rawType)
            let upgrade = item["upgrade_level"] as? Int ?? 0
            let isGold = rawType == "gold" || rawType == "currency"
            let quantity = item["quantity"] as? Int ?? item["amount"] as? Int
            let consumableType = item["consumable_type"] as? String ?? item["consumableType"] as? String

            let displayName: String
            if isGold, let qty = quantity {
                displayName = "\(qty) Gold"
            } else {
                displayName = upgrade > 0 ? "\(name) +\(upgrade)" : name
            }

            return LootItemDisplay(
                name: displayName,
                rarityName: rarity.displayName,
                rarityColor: DarkFantasyTheme.rarityColor(for: rarity),
                imageKey: item["image_key"] as? String ?? item["imageKey"] as? String,
                imageUrl: item["image_url"] as? String,
                sfIcon: Self.consumableSFIcon(for: consumableType, type: rawType),
                sfColor: Self.consumableSFColor(for: consumableType, type: rawType),
                fallbackIcon: type?.icon ?? "shippingbox",
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
    private func lootDetailModal(_ item: [String: Any]) -> some View {
        let name = item["name"] as? String ?? "Item"
        let rawRarity = item["rarity"] as? String ?? "common"
        let rarity = ItemRarity(rawValue: rawRarity) ?? .common
        let rawType = item["type"] as? String ?? "weapon"
        let type = ItemType(rawValue: rawType)
        let level = item["item_level"] as? Int ?? item["level"] as? Int ?? 1
        let upgrade = item["upgrade_level"] as? Int ?? 0
        let lootImageUrl = item["image_url"] as? String
        let lootImageKey = item["image_key"] as? String ?? item["imageKey"] as? String
        let rarityColor = DarkFantasyTheme.rarityColor(for: rarity)
        let description = item["description"] as? String
        let specialEffect = item["special_effect"] as? String
        let stats = item["stats"] as? [String: Int] ?? item["base_stats"] as? [String: Int]
        let isGold = rawType == "gold" || rawType == "currency"
        let quantity = item["quantity"] as? Int ?? item["amount"] as? Int
        let consumableType = item["consumable_type"] as? String ?? item["consumableType"] as? String
        let sfIcon = Self.consumableSFIcon(for: consumableType, type: rawType)
        let sfColor = Self.consumableSFColor(for: consumableType, type: rawType)

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
                            fallbackIcon: type?.icon ?? "shippingbox"
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius - 2))
                    }
                    .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                        if isGold, let qty = quantity {
                            Text("\(qty) Gold")
                                .font(DarkFantasyTheme.section(size: 20))
                                .foregroundStyle(rarityColor)
                        } else {
                            Text(upgrade > 0 ? "\(name) +\(upgrade)" : name)
                                .font(DarkFantasyTheme.section(size: 20))
                                .foregroundStyle(rarityColor)
                                .lineLimit(2)
                        }

                        HStack(spacing: LayoutConstants.spaceXS) {
                            if let t = type {
                                Text(t.displayName.lowercased())
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(DarkFantasyTheme.bgTertiary))
                                    .overlay(Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
                                    .accessibilityLabel("Item type: \(t.displayName)")
                            }

                            Text(rarity.rawValue)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(rarityColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(rarityColor.opacity(0.15)))
                                .overlay(Capsule().stroke(rarityColor.opacity(0.4), lineWidth: 1))
                                .accessibilityLabel("Rarity: \(rarity.rawValue)")
                        }
                        .accessibilityElement(children: .combine)

                        if !isGold {
                            Text("Level \(level)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
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
                                .font(.system(size: 12))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                            Text("STATS")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                                .tracking(1.2)
                        }

                        ForEach(stats.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(Item.statLabels[key] ?? key.capitalized)
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                                    .accessibilityLabel("Stat: \(Item.statLabels[key] ?? key)")
                                Spacer()
                                Text("+\(value)")
                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
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
                            .font(.system(size: 12))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                        Text(effect)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .padding(.vertical, LayoutConstants.spaceMD)

                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)
                }

                if let desc = description, !desc.isEmpty {
                    Text(desc)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .italic()
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, LayoutConstants.cardPadding)
                        .padding(.vertical, LayoutConstants.spaceMD)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(rarityColor.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: .bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .transition(.opacity)
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
        guard type == "consumable" else { return nil }
        let ct = consumableType ?? ""
        if ct.contains("gem_pack") { return "diamond.fill" }
        if ct.contains("health") { return "heart.fill" }
        if ct.contains("stamina") { return "bolt.fill" }
        return "flask.fill"
    }

    static func consumableSFColor(for consumableType: String?, type: String) -> Color? {
        guard type == "consumable" else { return nil }
        let ct = consumableType ?? ""
        if ct.contains("gem_pack") { return DarkFantasyTheme.cyan }
        if ct.contains("health") { return DarkFantasyTheme.hpBlood }
        if ct.contains("stamina") { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.goldBright
    }
}
