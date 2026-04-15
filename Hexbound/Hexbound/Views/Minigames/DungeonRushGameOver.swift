import SwiftUI

extension DungeonRushDetailView {
    @ViewBuilder
    func gameOverView(vm: DungeonRushViewModel) -> some View {
        let isVictory = vm.rushComplete
        let isEscaped = !vm.rushComplete && vm.lastFightWon
        let isDefeat  = !vm.rushComplete && !vm.lastFightWon
        let accentColor = gameOverAccentColor(vm: vm)

        ZStack {
            // Atmospheric background
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            if isVictory || isEscaped {
                RadialGradient(
                    gradient: Gradient(colors: [accentColor.opacity(0.12), Color.clear]),
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0, endRadius: 420
                )
                .ignoresSafeArea()
            } else {
                RadialGradient(
                    gradient: Gradient(colors: [DarkFantasyTheme.danger.opacity(0.18), Color.clear]),
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0, endRadius: 400
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                // Central art
                VStack(spacing: LayoutConstants.spaceXS) {
                    Group {
                        if isVictory {
                            Image("result-victory")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .shadow(color: DarkFantasyTheme.goldGlow, radius: 30)
                                .shadow(color: DarkFantasyTheme.gold.opacity(0.2), radius: 60)
                        } else if isEscaped {
                            Image("rush-ui-victory-banner")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .shadow(color: DarkFantasyTheme.stamina.opacity(0.4), radius: 24)
                        } else {
                            Image("result-defeat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .shadow(color: DarkFantasyTheme.danger.opacity(0.55), radius: 28)
                                .shadow(color: DarkFantasyTheme.danger.opacity(0.2), radius: 60)
                        }
                    }

                    Text(isVictory ? "RUSH COMPLETE!" : isEscaped ? "ESCAPED!" : "DEFEATED")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(accentColor)
                        .shadow(color: accentColor.opacity(0.4), radius: 12)
                        .tracking(2)

                    Text("Reached Room \(vm.currentFloor) of \(vm.totalRooms)")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                Spacer().frame(height: LayoutConstants.spaceLG)

                // Rewards or defeat card
                if vm.accumulatedGold > 0 || vm.accumulatedXp > 0 {
                    rewardCard(vm: vm)
                } else if isDefeat {
                    defeatMessage()
                }

                Spacer()

                // Actions
                VStack(spacing: LayoutConstants.spaceSM) {
                    if !appState.pendingLoot.isEmpty {
                        Button("VIEW LOOT") { appState.mainPath.append(AppRoute.loot) }
                            .buttonStyle(.primary)
                    }
                    if isVictory || isEscaped {
                        if appState.pendingLoot.isEmpty {
                            Button { vm.exit() } label: { Text("EXIT") }
                                .buttonStyle(.primary)
                        } else {
                            Button { vm.exit() } label: { Text("EXIT") }
                                .buttonStyle(.secondary)
                        }
                    } else {
                        Button { vm.resetForRetry() } label: { Text("TRY AGAIN") }
                            .buttonStyle(.primary)
                        Button { vm.exit() } label: { Text("EXIT") }
                            .buttonStyle(.secondary)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceLG)
            }
        }
    }

    // MARK: - Reward Card

    @ViewBuilder
    func rewardCard(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("REWARDS")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1.5)

            OrnamentalDivider()

            // Single centered horizontal line (matches ClaimRewardModalView pattern)
            HStack(spacing: LayoutConstants.spaceLG) {
                if vm.accumulatedGold > 0 {
                    rewardItem(value: "+\(vm.accumulatedGold)",
                               valueColor: DarkFantasyTheme.goldBright, iconName: "icon-gold")
                }
                if vm.accumulatedXp > 0 {
                    rewardItem(value: "+\(vm.accumulatedXp)",
                               valueColor: DarkFantasyTheme.xpRing, iconName: "icon-xp")
                }
                if vm.accumulatedItems > 0 {
                    rewardItem(value: "×\(vm.accumulatedItems)",
                               valueColor: DarkFantasyTheme.cyan, iconName: "reward-loot")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, LayoutConstants.space2XS)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .compositingGroup()
        .cardShadow()
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    func rewardItem(value: String, valueColor: Color, iconName: String) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            Text(value)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(valueColor)
                .monospacedDigit()
        }
    }

    // MARK: - Defeat Message

    @ViewBuilder
    func defeatMessage() -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("All rewards lost!")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.danger)
            Text("Better luck next time.")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.danger.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.danger.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Helpers

    /// Derives the full-art asset name from enemy name.
    /// "Cursed Bandit" → "rush-cursed-bandit-full"
    func enemyAssetName(for name: String) -> String {
        let slug = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "of", with: "")
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let candidate = "rush-\(slug)-full"
        // Fallback to portrait, then generic skull
        if UIImage(named: candidate) != nil { return candidate }
        let portrait = "rush-\(slug)-portrait"
        if UIImage(named: portrait) != nil { return portrait }
        return "rush-ui-combat-skull"
    }

    /// Maps room type to node icon asset.
    func roomNodeAsset(for type: String) -> String {
        switch type {
        case "combat":   return "rush-node-combat"
        case "elite":    return "rush-node-elite"
        case "miniboss": return "rush-node-miniboss"
        case "event":    return "rush-node-event"
        case "treasure": return "rush-node-treasure"
        case "shop":     return "rush-node-shop"
        default:         return "rush-node-combat"
        }
    }

    /// Maps buff stat to asset name.
    func buffAssetName(for stat: String) -> String {
        switch stat.lowercased() {
        case "str", "strength":   return "rush-buff-strength"
        case "def", "defense":    return "rush-buff-defense"
        case "vit", "vitality":   return "rush-buff-vitality"
        case "agi", "speed":      return "rush-buff-speed"
        case "lck", "fortune":    return "rush-buff-fortune"
        case "per", "perception": return "rush-buff-perception"
        case "poison":            return "rush-buff-poison"
        default:                  return "rush-buff-strength"
        }
    }

    /// Returns accent color for shop item type.
    func shopItemAccentColor(for type: String) -> Color {
        switch type {
        case "heal":  return DarkFantasyTheme.danger
        case "buff":  return DarkFantasyTheme.stamina
        default:      return DarkFantasyTheme.gold
        }
    }

    /// Derives shop item image asset from item icon string.
    func shopItemAssetName(for item: RushShopItem) -> String {
        // Item icon may be an SF symbol name or an asset name — try as asset first
        if UIImage(named: item.icon) != nil { return item.icon }
        // Map by item type
        if item.type == "heal" { return "rush-ui-health-potion" }
        return buffAssetName(for: item.name.lowercased())
    }

    func roomActionLabel(for type: String) -> String {
        switch type {
        case "combat", "elite", "miniboss": return "FIGHT"
        case "treasure":                     return "OPEN CHEST"
        case "event":                        return "EXPLORE"
        case "shop":                         return "ENTER SHOP"
        default:                             return "CONTINUE"
        }
    }

    func gameOverAccentColor(vm: DungeonRushViewModel) -> Color {
        if vm.rushComplete   { return DarkFantasyTheme.goldBright }
        if vm.lastFightWon   { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.danger
    }
}
