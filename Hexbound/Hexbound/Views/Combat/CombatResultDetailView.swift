import SwiftUI

struct CombatResultDetailView: View {
    @Environment(AppState.self) private var appState

    // XP bar animation state
    @State private var xpBarProgress: CGFloat = 0
    @State private var showLevelUpFlash = false
    @State private var displayLevel: Int = 0
    @State private var xpSnapshotCaptured = false
    @State private var oldXpFraction: CGFloat = 0
    @State private var newXpFraction: CGFloat = 0
    @State private var didLevelUp = false

    // Loot detail modal
    @State private var selectedLootIndex: Int? = nil

    private var combatData: CombatData? {
        appState.combatResult
    }

    private var result: CombatResultInfo? {
        combatData?.result
    }

    private var isWin: Bool {
        result?.isWin ?? false
    }

    private var source: String {
        combatData?.source ?? "training"
    }

    /// Estimate enemy remaining HP from combat log to detect near-miss losses.
    /// Returns a subtitle string if the loss was close (enemy had <25% HP left).
    private var nearMissSubtitle: String? {
        guard let data = combatData, !isWin else { return nil }
        let playerId = data.player.id
        let enemyMaxHp = data.enemy.maxHp
        guard enemyMaxHp > 0 else { return nil }

        // Sum all damage dealt TO the enemy (by player)
        let totalDamageToEnemy = data.combatLog
            .filter { $0.attackerId == playerId && !$0.isMiss && !$0.isDodge }
            .reduce(0) { $0 + $1.damage }
        // Sum enemy heals
        let totalEnemyHeals = data.combatLog
            .filter { $0.attackerId != playerId }
            .compactMap { $0.heal }
            .reduce(0, +)

        let estimatedEnemyHp = max(0, enemyMaxHp - totalDamageToEnemy + totalEnemyHeals)
        let hpPercent = Double(estimatedEnemyHp) / Double(enemyMaxHp)

        if hpPercent < 0.10 {
            return "So close! Enemy had \(estimatedEnemyHp) HP left"
        } else if hpPercent < 0.25 {
            return "Almost there! A bit more and you'd win"
        }
        return nil
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let _ = combatData, let res = result {
                BattleResultCardView(config: buildConfig(res))

                // Loot detail modal overlay
                if let index = selectedLootIndex, index < appState.pendingLoot.count {
                    lootDetailModal(appState.pendingLoot[index])
                }
            } else {
                fallbackView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            captureXpSnapshot()
            // Play victory/defeat SFX
            SFXManager.shared.play(isWin ? .battleVictory : .battleDefeat)
            // Reload character immediately to reflect new XP/level
            Task {
                let charService = CharacterService(appState: appState)
                await charService.loadCharacter()
            }
            runXpBarAnimation()
        }
    }

    // MARK: - Build Config

    private func buildConfig(_ res: CombatResultInfo) -> BattleResultConfig {
        let lootItems = appState.pendingLoot.enumerated().map { (index, item) -> LootItemDisplay in
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
                sfIcon: LootDetailView.consumableSFIcon(for: consumableType, type: rawType),
                sfColor: LootDetailView.consumableSFColor(for: consumableType, type: rawType),
                fallbackIcon: type?.icon ?? "shippingbox",
                rarityTier: rarity.tier
            )
        }

        var buttons: [ResultButton] = []

        if source == "arena" || source == "pvp" {
            buttons.append(ResultButton(title: "FIGHT AGAIN", icon: "swords", style: .primary, action: {
                goBack()
            }))
            // Send message to opponent after PvP
            if let enemy = combatData?.enemy {
                buttons.append(ResultButton(title: "SEND MESSAGE", icon: "envelope.fill", style: .ghost, action: {
                    let enemyId = enemy.id
                    let enemyName = enemy.characterName
                    appState.combatData = nil
                    appState.combatResult = nil
                    appState.invalidateCache("quests")
                    // Navigate back to hub, then open message thread
                    appState.mainPath = NavigationPath()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        appState.mainPath.append(
                            AppRoute.guildHallMessage(
                                characterId: enemyId,
                                characterName: enemyName
                            )
                        )
                    }
                }))
            }
        } else {
            buttons.append(ResultButton(title: "CONTINUE", icon: nil, style: .primary, action: {
                goBack()
            }))
        }

        return BattleResultConfig(
            isVictory: isWin,
            title: isWin ? "VICTORY!" : "DEFEAT",
            subtitle: nearMissSubtitle,
            illustrationImage: isWin ? "result-victory" : "result-defeat",
            goldReward: res.goldReward,
            xpReward: res.xpReward,
            ratingChange: res.ratingChange,
            firstWinBonus: res.firstWinBonus == true,
            xpBarConfig: XPBarConfig(
                displayLevel: displayLevel,
                progress: xpBarProgress,
                leveledUp: showLevelUpFlash
            ),
            dungeonProgress: nil,
            lootItems: lootItems,
            onLootTap: { index in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedLootIndex = index
                }
            },
            buttons: buttons
        )
    }

    // MARK: - Loot Detail Modal (reused from old LootDetailView)

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
        let sfIcon = LootDetailView.consumableSFIcon(for: consumableType, type: rawType)
        let sfColor = LootDetailView.consumableSFColor(for: consumableType, type: rawType)

        ZStack {
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
                                    .padding(.horizontal, LayoutConstants.spaceXS)
                                    .padding(.vertical, LayoutConstants.space2XS)
                                    .background(Capsule().fill(DarkFantasyTheme.bgTertiary))
                                    .overlay(Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
                            }

                            Text(rarity.rawValue)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(rarityColor)
                                .padding(.horizontal, LayoutConstants.spaceXS)
                                .padding(.vertical, LayoutConstants.space2XS)
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

    // MARK: - Fallback

    @ViewBuilder
    private var fallbackView: some View {
        ErrorStateView.battleInit {
            Task { await CharacterService(appState: appState).loadCharacter() }
            goBack()
        }
    }

    // MARK: - XP Snapshot & Animation (preserved from original)

    private func xpNeededForLevel(_ level: Int) -> Int {
        let next = level + 1
        return 100 * next + 20 * next * next
    }

    private func captureXpSnapshot() {
        guard !xpSnapshotCaptured, let res = result else { return }
        xpSnapshotCaptured = true

        let xpReward = res.xpReward ?? 0
        let leveledUp = res.leveledUp == true
        let newLevel = res.newLevel
        self.didLevelUp = leveledUp

        if leveledUp, let newLvl = newLevel {
            let previousLevel = newLvl - 1
            displayLevel = previousLevel
            let prevXpNeeded = xpNeededForLevel(previousLevel)
            let currentExp = appState.currentCharacter?.experience ?? 0
            let oldXp = currentExp - xpReward
            oldXpFraction = CGFloat(max(0, oldXp)) / CGFloat(max(1, prevXpNeeded))
            let overflowXp = currentExp - prevXpNeeded
            let newXpNeeded = xpNeededForLevel(newLvl)
            newXpFraction = CGFloat(max(0, overflowXp)) / CGFloat(max(1, newXpNeeded))
        } else {
            let charLevel = appState.currentCharacter?.level ?? 1
            displayLevel = charLevel
            let xpNeeded = xpNeededForLevel(charLevel)
            let currentExp = appState.currentCharacter?.experience ?? 0
            let oldXp = currentExp - xpReward
            oldXpFraction = CGFloat(max(0, oldXp)) / CGFloat(max(1, xpNeeded))
            newXpFraction = CGFloat(max(0, currentExp)) / CGFloat(max(1, xpNeeded))
        }

        xpBarProgress = oldXpFraction
    }

    private func runXpBarAnimation() {
        if didLevelUp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    xpBarProgress = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showLevelUpFlash = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                xpBarProgress = 0
                if let newLvl = result?.newLevel {
                    displayLevel = newLvl
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    xpBarProgress = newXpFraction
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if let res = result, res.leveledUp == true, let newLevel = res.newLevel {
                    let statPoints = res.statPointsAwarded ?? 3
                    appState.triggerLevelUpModal(newLevel: newLevel, statPoints: statPoints)
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    xpBarProgress = newXpFraction
                }
            }
        }
    }

    // MARK: - Navigation

    private func goBack() {
        let currentSource = source
        appState.combatData = nil
        appState.combatResult = nil
        appState.invalidateCache("quests")

        if currentSource == "arena" || currentSource == "pvp" {
            let keepCount = min(1, appState.mainPath.count)
            let removals = appState.mainPath.count - keepCount
            if removals > 0 {
                appState.mainPath.removeLast(removals)
            }
        } else if currentSource == "dungeon" || currentSource == "dungeon_rush" {
            // Pop back to DungeonRoomDetailView (remove combatResult screen only)
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
        } else {
            appState.mainPath = NavigationPath()
        }
    }
}
