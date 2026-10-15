import SwiftUI

struct DailyQuestsDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: DailyQuestsViewModel?
    @State private var showQuestBurst = false
    @State private var burstQuestId: String?
    @State private var appearCount = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    // Reset timer
                    Text(vm.resetTimeText)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .padding(.top, LayoutConstants.spaceSM)
                        .accessibilityLabel("Daily quests reset: \(vm.resetTimeText)")

                    if vm.quests.isEmpty {
                        // No data to show. Decide between skeleton and error:
                        // - If we have a real errorMessage → show the themed
                        //   error state with the hud-daily-quests asset.
                        // - Otherwise → skeleton (covers first-load and the
                        //   window before `.task` fires loadQuests()).
                        if vm.errorMessage != nil {
                            ErrorStateView(
                                assetIcon: "hud-daily-quests",
                                assetUsesOriginalColor: true,
                                title: "Failed to Load",
                                message: "We couldn't load today's quests. Tap retry to try again.",
                                retryAction: { Task { await vm.loadQuests() } }
                            )
                        } else {
                            ScrollView {
                                LazyVStack(spacing: LayoutConstants.spaceSM) {
                                    ForEach(0..<4, id: \.self) { _ in
                                        SkeletonQuestCard()
                                    }
                                }
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.vertical, LayoutConstants.spaceSM)
                            }
                        }
                    } else if vm.allClaimed && vm.bonusClaimedToday {
                        // "All Done!" ceremony — only when every quest is claimed
                        // AND the bonus is already collected for today.
                        allDoneCeremony(vm: vm)
                            .transition(.opacity)
                    } else {
                        // Quest cards scroll; the daily chest stays pinned at
                        // the bottom so the "finish them all" goal is always in view.
                        VStack(spacing: 0) {
                            ScrollView {
                                LazyVStack(spacing: LayoutConstants.spaceMS) {
                                    ForEach(Array(vm.sortedQuests.enumerated()), id: \.element.id) { index, quest in
                                        questCard(quest, vm: vm)
                                            .staggeredAppear(index: index)
                                    }
                                }
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.vertical, LayoutConstants.spaceSM)
                            }

                            chestBar(vm: vm)
                        }
                        .transition(.opacity)
                    }
                }
                .transaction { $0.animation = nil }
            }
        }
        .claimRewardModal(config: Binding(
            get: { vm?.claimRewardConfig },
            set: { vm?.claimRewardConfig = $0 }
        ))
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            if vm == nil { vm = DailyQuestsViewModel(appState: appState, cache: cache) }
            appearCount += 1
            SFXManager.shared.play(.scrollUnfurl)
        }
        .task(id: appearCount) {
            // Reload quests every time view appears (e.g., after PvP/dungeon)
            guard appearCount > 0 else { return }
            await vm?.loadQuests()
        }
    }

    // MARK: - Quest Icon Asset

    /// Returns the asset image name for a quest type.
    /// For `item_upgrade` uses the hero's avatar (dynamic).
    private func questIconAsset(for questType: String) -> String {
        switch questType {
        case "pvp_wins":          return "building-arena"
        case "dungeons_complete": return "building-dungeon"
        case "gold_spent":        return "building-shop"
        case "item_upgrade":
            return appState.currentCharacter?.avatar ?? "knight"
        case "consumable_use":    return "health-potion-medium"
        case "shell_game_play":   return "shell-cup"
        case "gold_mine_collect": return "building-gold-mine"
        default:                  return "icon-xp" // safe fallback
        }
    }

    // MARK: - Helpers

    private func timeUntilReset() -> String {
        let now = Date()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        guard let tomorrow = utc.date(byAdding: .day, value: 1, to: now),
              let midnight = utc.date(from: utc.dateComponents([.year, .month, .day], from: tomorrow))
        else { return "" }
        let remaining = Int(midnight.timeIntervalSince(now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        return "\(h)h \(m)m"
    }

    // MARK: - Layout

    private static let bannerHeight: CGFloat = 104
    private static let bannerArtSize: CGFloat = 150
    private static let bannerTextWidth: CGFloat = 220
    private static let chestArtSize: CGFloat = 56
    private static let rewardTileHeight: CGFloat = 44
    private static let goButtonMinHeight: CGFloat = 28   // + compactOutline padding = 44pt target


    // MARK: - Quest Type → Destination Mapping

    private func destinationRoute(for quest: Quest) -> AppRoute? {
        switch quest.type {
        case "pvp_wins":
            return .arena
        case "dungeons_complete":
            return .dungeonMap
        case "gold_spent":
            return .shop
        case "consumable_use", "item_upgrade":
            return .hero
        case "shell_game_play":
            return .shellGame
        case "gold_mine_collect":
            return .goldMine
        default:
            return nil
        }
    }

    /// CTA copy for the "go do it" button on an unfinished quest.
    private func destinationLabel(for quest: Quest) -> String {
        switch quest.type {
        case "pvp_wins":          return "TO THE ARENA"
        case "dungeons_complete": return "TO DUNGEONS"
        case "gold_spent":        return "TO THE SHOP"
        case "consumable_use",
             "item_upgrade":      return "TO THE HERO"
        case "shell_game_play":   return "TO THE TAVERN"
        case "gold_mine_collect": return "TO THE MINE"
        default:                  return "GO"
        }
    }

    private func navigate(to destination: AppRoute) {
        if destination == .shop {
            appState.shopInitialTab = 0
        }
        if destination == .dungeonMap {
            // Mirror the hub ADVENTURES button: pop back to the hub
            // and let HubView toggle its embedded dungeon map. The
            // standalone .dungeonMap route renders without the hero
            // card / floating HUD, which is what we want to avoid.
            appState.pendingShowDungeonMap = true
            appState.mainPath = NavigationPath()
        } else {
            appState.mainPath.append(destination)
        }
    }

    // MARK: - Quest Card (B — art banner + one clear action)

    @ViewBuilder
    private func questCard(_ quest: Quest, vm: DailyQuestsViewModel) -> some View {
        let isClaiming = vm.claimingQuestId == quest.id
        let destination = destinationRoute(for: quest)

        VStack(spacing: 0) {
            questBanner(quest)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
                if quest.canClaim {
                    rewardTiles(quest)

                    Button {
                        HapticManager.success()
                        SFXManager.shared.play(.uiQuestComplete)
                        showQuestBurst = true
                        burstQuestId = quest.id
                        Task { await vm.claimQuest(quest) }
                    } label: {
                        if isClaiming {
                            HexPulseLoader.onGold()
                        } else {
                            Text("CLAIM REWARD")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(isClaiming)
                } else {
                    if !quest.rewardClaimed {
                        progressRow(quest)
                    }

                    HStack(spacing: LayoutConstants.spaceSM) {
                        rewardChips(quest)
                        Spacer(minLength: 0)
                        if quest.rewardClaimed {
                            HStack(spacing: LayoutConstants.spaceXS) {
                                Image(systemName: "checkmark")
                                    .font(DarkFantasyTheme.body.bold())
                                Text("Claimed")
                                    .font(DarkFantasyTheme.body)
                            }
                            .foregroundStyle(DarkFantasyTheme.success)
                        } else if let destination {
                            Button {
                                navigate(to: destination)
                            } label: {
                                HStack(spacing: LayoutConstants.spaceXS) {
                                    Text(destinationLabel(for: quest))
                                    Image("ui-arrow-right")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                                }
                                .frame(minHeight: Self.goButtonMinHeight)
                            }
                            .buttonStyle(.compactOutline(color: DarkFantasyTheme.gold))
                        }
                    }
                }
            }
            .padding(LayoutConstants.spaceMS)
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    quest.canClaim ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle,
                    lineWidth: quest.canClaim ? 1.5 : 1
                )
        )
        .cardShadow()
        .opacity(quest.rewardClaimed ? 0.6 : 1)
        .overlay {
            if showQuestBurst && burstQuestId == quest.id {
                GeometryReader { geo in
                    RewardBurstView(style: .claim, isActive: $showQuestBurst)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .allowsHitTesting(false)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Title, task and (when finished) a "Done" pill over the building art.
    private func questBanner(_ quest: Quest) -> some View {
        ZStack {
            DarkFantasyTheme.bgTertiary

            HStack {
                Spacer(minLength: 0)
                Image(questIconAsset(for: quest.type))
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.bannerArtSize, height: Self.bannerArtSize)
                    .offset(x: LayoutConstants.spaceMS)
                    .accessibilityHidden(true)
            }

            HStack {
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(quest.title.uppercased())
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(quest.description)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(2)

                    if quest.canClaim {
                        Text("Done \(quest.target) / \(quest.target)")
                            .font(DarkFantasyTheme.body.bold())
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .badgeCapsule(color: DarkFantasyTheme.gold)
                            .padding(.top, LayoutConstants.space2XS)
                    }
                }
                .frame(maxWidth: Self.bannerTextWidth, alignment: .leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, LayoutConstants.spaceMS)
        }
        .frame(height: Self.bannerHeight)
        .clipped()
    }

    /// Segmented bar plus the count it stands for — "1 / 4", never a bare bar.
    private func progressRow(_ quest: Quest) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            SegmentedProgressBar(progress: quest.progress, target: quest.target)
            Text("\(min(quest.progress, quest.target)) / \(quest.target)")
                .font(DarkFantasyTheme.body.bold())
                .foregroundStyle(DarkFantasyTheme.cyan)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress \(min(quest.progress, quest.target)) of \(quest.target)")
    }

    /// Inline rewards for an unfinished / claimed quest.
    private func rewardChips(_ quest: Quest) -> some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            if quest.rewardGold > 0 {
                rewardChip(asset: "icon-gold", value: quest.rewardGold, color: DarkFantasyTheme.goldBright, label: "gold")
            }
            if quest.rewardXp > 0 {
                rewardChip(asset: "icon-xp", value: quest.rewardXp, color: DarkFantasyTheme.xpRing, label: "XP")
            }
            if let gems = quest.rewardGems, gems > 0 {
                rewardChip(asset: "icon-gems", value: gems, color: DarkFantasyTheme.cyan, label: "gems")
            }
        }
    }

    private func rewardChip(asset: String, value: Int, color: Color, label: String) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
            Text("\(value)")
                .font(DarkFantasyTheme.body.bold())
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    /// Equal-width reward tiles for a quest that is ready to claim.
    private func rewardTiles(_ quest: Quest) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if quest.rewardGold > 0 {
                rewardTile(asset: "icon-gold", value: quest.rewardGold, color: DarkFantasyTheme.goldBright, label: "gold")
            }
            if quest.rewardXp > 0 {
                rewardTile(asset: "icon-xp", value: quest.rewardXp, color: DarkFantasyTheme.xpRing, label: "XP")
            }
            if let gems = quest.rewardGems, gems > 0 {
                rewardTile(asset: "icon-gems", value: gems, color: DarkFantasyTheme.cyan, label: "gems")
            }
        }
    }

    private func rewardTile(asset: String, value: Int, color: Color, label: String) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
            Text("\(value)")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.rewardTileHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(color.opacity(DarkFantasyTheme.opacityMedium), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Daily Chest (pinned)

    @ViewBuilder
    private func chestBar(vm: DailyQuestsViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Image("rush-node-treasure")
                .resizable()
                .scaledToFit()
                .frame(width: Self.chestArtSize, height: Self.chestArtSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                HStack {
                    Text("DAILY CHEST")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .tracking(1)
                    Spacer(minLength: 0)
                    Text("\(vm.claimedCount) / \(vm.quests.count)")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .monospacedDigit()
                }

                SegmentedProgressBar(
                    progress: vm.claimedCount,
                    target: vm.quests.count,
                    isBonus: true
                )

                if vm.bonusClaimedToday {
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text("Claimed · next chest in \(timeUntilReset())")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                } else {
                    // Real chest amounts from GET /api/quests/daily
                    // (`daily_bonus_reward`); the old hard-coded 500 / 10
                    // left out the 300 XP the server also grants.
                    let chest = vm.bonusReward
                    HStack(spacing: LayoutConstants.spaceMS) {
                        if chest.gold > 0 {
                            rewardChip(asset: "icon-gold", value: chest.gold, color: DarkFantasyTheme.goldBright, label: "gold")
                        }
                        if chest.xp > 0 {
                            rewardChip(asset: "icon-xp", value: chest.xp, color: DarkFantasyTheme.xpRing, label: "XP")
                        }
                        if chest.gems > 0 {
                            rewardChip(asset: "icon-gems", value: chest.gems, color: DarkFantasyTheme.cyan, label: "gems")
                        }
                    }
                }
            }

            if vm.canClaimBonus {
                Button {
                    HapticManager.success()
                    SFXManager.shared.play(.uiQuestComplete)
                    Task { await vm.claimBonus() }
                } label: {
                    if vm.isClaimingBonus {
                        HexPulseLoader.onGold()
                    } else {
                        Text("CLAIM")
                    }
                }
                .buttonStyle(.compactPrimary)
                .disabled(vm.isClaimingBonus)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMS)
        .padding(.bottom, LayoutConstants.spaceMD)
        .background(
            DarkFantasyTheme.bgSecondary
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityStrong))
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Daily chest, \(vm.claimedCount) of \(vm.quests.count) quests claimed")
    }

    // MARK: - All Done Ceremony

    /// Celebratory state shown when every quest is claimed AND the daily bonus has been collected.
    /// Uses a large victory asset instead of a plain SF Symbol and reuses the ornamental card system.
    @ViewBuilder
    private func allDoneCeremony(vm: DailyQuestsViewModel) -> some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer(minLength: LayoutConstants.spaceXL)

                // Hero asset — large victory artwork
                Image("result-victory")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.35), radius: 24)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 12, y: 6)
                    .accessibilityLabel("All daily quests completed")

                // Ornamental title + subtitle
                OrnamentalTitle(
                    "ALL DONE!",
                    subtitle: "You've claimed every quest and today's bonus."
                )

                // Reset countdown card
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("New quests in")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text(timeUntilReset())
                            .font(DarkFantasyTheme.cardTitle)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, LayoutConstants.spaceMD)
                .padding(.horizontal, LayoutConstants.spaceLG)
                .background(
                    RadialGlowBackground(
                        baseColor: DarkFantasyTheme.bgSecondary,
                        glowColor: DarkFantasyTheme.bgTertiary,
                        glowIntensity: 0.4,
                        cornerRadius: LayoutConstants.cardRadius
                    )
                )
                .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
                .innerBorder(
                    cornerRadius: LayoutConstants.cardRadius - 2,
                    inset: 2,
                    color: DarkFantasyTheme.gold.opacity(0.08)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
                )
                .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
                .cardShadow()
                .padding(.horizontal, LayoutConstants.screenPadding)

                Spacer(minLength: LayoutConstants.spaceXL)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
