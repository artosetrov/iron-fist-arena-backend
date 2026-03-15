import SwiftUI

struct LootDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var revealedItems: Set<Int> = []
    @State private var selectedLootIndex: Int? = nil

    private var lootItems: [[String: Any]] {
        appState.pendingLoot
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Loot illustration
                if !lootItems.isEmpty {
                    Image("result-loot-found")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)
                }

                // Title
                Text(lootItems.isEmpty ? "NO LOOT" : "LOOT FOUND!")
                    .font(DarkFantasyTheme.section(size: 32))
                    .textCase(.uppercase)
                    .tracking(3)
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Spacer().frame(height: LayoutConstants.spaceLG)

                if !lootItems.isEmpty {
                    // Loot Items Row
                    HStack(spacing: LayoutConstants.spaceMD) {
                        ForEach(lootItems.indices, id: \.self) { index in
                            lootCard(lootItems[index], index: index)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedLootIndex = index
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }

                Spacer()

                // Take All Button
                Button("TAKE ALL") {
                    goBack()
                }
                .buttonStyle(.primary)
                .padding(.horizontal, LayoutConstants.screenPadding)

                Spacer().frame(height: 60)
            }

            // Item Detail Modal
            if let index = selectedLootIndex, index < lootItems.count {
                lootDetailModal(lootItems[index])
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            for i in lootItems.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        _ = revealedItems.insert(i)
                    }
                }
            }
        }
    }

    // MARK: - Loot Card

    @ViewBuilder
    private func lootCard(_ item: [String: Any], index: Int) -> some View {
        let name = item["name"] as? String ?? "Item"
        let rawRarity = item["rarity"] as? String ?? "common"
        let rarity = ItemRarity(rawValue: rawRarity) ?? .common
        let rawType = item["type"] as? String ?? "weapon"
        let type = ItemType(rawValue: rawType)
        let upgrade = item["upgrade_level"] as? Int ?? 0
        let lootImageUrl = item["image_url"] as? String
        let lootImageKey = item["image_key"] as? String ?? item["imageKey"] as? String
        let isRevealed = revealedItems.contains(index)
        let rarityColor = DarkFantasyTheme.rarityColor(for: rarity)
        let isGold = rawType == "gold" || rawType == "currency"
        let quantity = item["quantity"] as? Int ?? item["amount"] as? Int
        let consumableType = item["consumable_type"] as? String ?? item["consumableType"] as? String
        let sfIcon = Self.consumableSFIcon(for: consumableType, type: rawType)
        let sfColor = Self.consumableSFColor(for: consumableType, type: rawType)

        VStack(spacing: LayoutConstants.spaceSM) {
            // Icon Card
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgTertiary)

                ItemImageView(
                    imageKey: lootImageKey,
                    imageUrl: lootImageUrl,
                    systemIcon: sfIcon,
                    systemIconColor: sfColor,
                    fallbackIcon: type?.icon ?? "📦"
                )
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(width: 90, height: 90)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(rarityColor, lineWidth: 2)
            )
            .shadow(color: DarkFantasyTheme.rarityGlow(for: rarity), radius: rarity == .legendary ? 12 : 8)

            // Name
            if isGold, let qty = quantity {
                Text("\(qty) GOLD")
                    .font(DarkFantasyTheme.section(size: 13))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            } else {
                Text(upgrade > 0 ? "\(name) +\(upgrade)" : name)
                    .font(DarkFantasyTheme.section(size: 13))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }

            // Rarity
            Text(rarity.displayName)
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(rarityColor)
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(isRevealed ? 1.0 : 0.3)
        .opacity(isRevealed ? 1.0 : 0.0)
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
        let lootImageKey2 = item["image_key"] as? String ?? item["imageKey"] as? String
        let rarityColor = DarkFantasyTheme.rarityColor(for: rarity)
        let description = item["description"] as? String
        let specialEffect = item["special_effect"] as? String
        let stats = item["stats"] as? [String: Int] ?? item["base_stats"] as? [String: Int]
        let isGold = rawType == "gold" || rawType == "currency"
        let quantity = item["quantity"] as? Int ?? item["amount"] as? Int
        let consumableType2 = item["consumable_type"] as? String ?? item["consumableType"] as? String
        let sfIcon2 = Self.consumableSFIcon(for: consumableType2, type: rawType)
        let sfColor2 = Self.consumableSFColor(for: consumableType2, type: rawType)

        ZStack {
            // Backdrop
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedLootIndex = nil
                    }
                }

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(DarkFantasyTheme.bgTertiary)
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(rarityColor.opacity(0.6), lineWidth: 2)

                        ItemImageView(
                            imageKey: lootImageKey2,
                            imageUrl: lootImageUrl,
                            systemIcon: sfIcon2,
                            systemIconColor: sfColor2,
                            fallbackIcon: type?.icon ?? "📦"
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
                            }

                            Text(rarity.rawValue)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(rarityColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(rarityColor.opacity(0.15)))
                                .overlay(Capsule().stroke(rarityColor.opacity(0.4), lineWidth: 1))
                        }

                        if !isGold {
                            Text("Level \(level)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }

                    Spacer(minLength: 0)

                    // Close button
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

                // Divider
                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(height: 1)

                // Stats
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
                                Spacer()
                                Text("+\(value)")
                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                    .foregroundStyle(DarkFantasyTheme.statColor(for: key))
                            }
                        }
                    }
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .padding(.vertical, LayoutConstants.spaceMD)

                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)
                }

                // Special Effect
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

                // Description
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
            .shadow(color: .black.opacity(0.8), radius: 32, y: 8)
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
            // Pop back to Arena (keep first path item)
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
