import SwiftUI

struct ArenaDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: ArenaViewModel?
    @State private var refreshRotation: Double = 0
    // confirmation dialog removed — revenge triggers directly
    // Opponent card refresh animation
    @State private var opponentCardsVisible = true
    @State private var opponentCardPhase: RefreshPhase = .idle
    @State private var cardShineActive = false
    // NPC guide widget state — persisted so guide only shows on first visit
    @AppStorage(AppConstants.udNPCArenaGuideDismissed) private var arenaGuideDismissed = false
    @State private var showArenaGuide = false
    @State private var showArenaGuideMini = false
    // Low HP NPC widget — shown when character HP < 30%
    @State private var showLowHPGuide = false

    var body: some View {
        ZStack {
            // Background image with dark overlay
            GeometryReader { geo in
                Image("bg-arena")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()

            Group {
            if let vm {
                ZStack {
                    VStack(spacing: 0) {
                        // Screen title — sticky above tabs
                        OrnamentalTitle("ARENA", accentColor: DarkFantasyTheme.danger)
                            .padding(.top, LayoutConstants.spaceXS)
                            .padding(.bottom, LayoutConstants.spaceXS)

                        // Tab Switcher — sticky
                        TabSwitcher(
                            tabs: ["OPPONENTS", "REVENGE", "HISTORY"],
                            selectedIndex: Binding(
                                get: { vm.selectedTab },
                                set: { newValue in
                                    vm.selectedTab = newValue
                                    Task { await vm.loadTabData() }
                                }
                            )
                        )
                        .accessibilityLabel("Arena tabs")
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)

                        // Scrollable content
                        ScrollView {
                            VStack(spacing: LayoutConstants.sectionGap) {
                                // Active quest banner
                                ActiveQuestBanner(questTypes: ["pvp_wins"])
                                    .padding(.horizontal, LayoutConstants.screenPadding)

                                // Unified Hero Widget
                                if let char = appState.currentCharacter {
                                    UnifiedHeroWidget(
                                        character: char,
                                        context: .arena,
                                        onTap: { appState.mainPath.append(AppRoute.hero) }
                                    )
                                    .padding(.horizontal, LayoutConstants.screenPadding)

                                    // PvP Stats Bar — rating, streak, first win
                                    arenaPvpStatsBar(char)
                                        .padding(.horizontal, LayoutConstants.screenPadding)
                                }

                                // Low HP potion banner — shown when HP < 30%
                                if let currentChar = appState.currentCharacter,
                                   LowHPPotionBanner.shouldShow(character: currentChar) {
                                    LowHPPotionBanner(
                                        character: currentChar,
                                        hasHealthPotion: hasHealthPotion,
                                        onDrinkPotion: {
                                            Task { await useHealthPotion() }
                                        },
                                        onGoToShop: {
                                            appState.shopInitialTab = 3 // Potions tab
                                            appState.mainPath.append(AppRoute.shop)
                                        }
                                    )
                                    .padding(.horizontal, LayoutConstants.screenPadding)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                // Current stance indicator
                                if let stance = appState.currentCharacter?.combatStance {
                                    stancePreview(stance)
                                        .tutorialAnchor(.arenaStance)
                                }

                                // Tab Content
                                switch vm.selectedTab {
                                case 0: opponentsTab(vm)
                                case 1: revengeTab(vm)
                                case 2: historyTab(vm)
                                default: EmptyView()
                                }

                                Spacer().frame(height: LayoutConstants.spaceLG)
                            }
                        }

                        // Refresh button pinned to bottom
                        if vm.selectedTab == 0 && !vm.opponents.isEmpty {
                            refreshButton(vm)
                                .padding(.bottom, LayoutConstants.spaceSM)
                        }
                    } // VStack

                    // Low HP NPC Widget — overrides arena guide when HP < 30%
                    if showLowHPGuide && isLowHP, let char = appState.currentCharacter {
                        VStack {
                            Spacer()
                            NPCGuideWidget(
                                npcTitle: "Field Medic",
                                onDismiss: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showLowHPGuide = false
                                    }
                                },
                                avatarSkinKey: char.avatar,
                                avatarClass: char.characterClass,
                                plainMessage: "You're critically wounded! Restore your HP before heading into battle.",
                                onTapCard: {
                                    appState.shopInitialTab = 3
                                    appState.mainPath.append(AppRoute.shop)
                                }
                            )
                            .padding(.horizontal, LayoutConstants.npcOuterPadding)
                            .padding(.bottom, LayoutConstants.npcOuterPadding)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // NPC Guide Widget — player's own avatar as arena coach (hidden when HP is critical)
                    if showArenaGuide && !isLowHP, let char = appState.currentCharacter {
                        VStack {
                            Spacer()
                            NPCGuideWidget(
                                npcTitle: "Arena Master",
                                onDismiss: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showArenaGuide = false
                                    }
                                    arenaGuideDismissed = true
                                },
                                avatarSkinKey: char.avatar,
                                avatarClass: char.characterClass,
                                plainMessage: "Your stance affects attack and defense zones. Tap to change it before battle.",
                                onTapCard: {
                                    appState.mainPath.append(AppRoute.stanceSelector)
                                }
                            )
                            .padding(.horizontal, LayoutConstants.npcOuterPadding)
                            .padding(.bottom, LayoutConstants.npcOuterPadding)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Collapsed NPC mini avatar (hidden when HP is critical)
                    if showArenaGuideMini && !isLowHP, let char = appState.currentCharacter {
                        VStack {
                            Spacer()
                            HStack {
                                NPCMiniButton(
                                    avatarSkinKey: char.avatar,
                                    avatarClass: char.characterClass,
                                    onTap: {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            showArenaGuideMini = false
                                            showArenaGuide = true
                                        }
                                    }
                                )
                                .padding(.leading, LayoutConstants.screenPadding)
                                .padding(.bottom, LayoutConstants.spaceMD)
                                Spacer()
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                } // ZStack
                .sheet(isPresented: Binding(
                    get: { vm.showComparison },
                    set: { vm.showComparison = $0 }
                )) {
                    if let opponent = vm.selectedOpponent, let char = vm.character {
                        ArenaComparisonSheet(
                            opponent: opponent,
                            character: char,
                            isFighting: vm.fightingOpponentId == opponent.id,
                            canFight: vm.canFight,
                            staminaCost: vm.staminaCost,
                            onFight: {
                                Task { await vm.fight(opponentId: opponent.id) }
                            }
                        )
                    }
                }
            } else {
                // Skeleton placeholder — shown only while vm is nil
                VStack(spacing: 0) {
                    OrnamentalTitle("ARENA", accentColor: DarkFantasyTheme.danger)
                        .padding(.top, LayoutConstants.spaceXS)
                        .padding(.bottom, LayoutConstants.spaceXS)

                    ScrollView {
                        VStack(spacing: LayoutConstants.sectionGap) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonOpponentCard()
                            }
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.top, LayoutConstants.spaceMD)
                    }
                }
            }
            } // Group
            .transaction { $0.animation = nil }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .npcHint(.arena, isReady: vm != nil)
        .tutorialOverlay(steps: [.arenaStance, .arenaOpponent])
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
        }
        // confirmation dialog removed — revenge triggers directly from button
        .onAppear {
            AudioManager.shared.playBGM("arena-pvp.mp3")
        }
        .onDisappear {
            AudioManager.shared.playBGM("stray-city.mp3")
        }
        .onChange(of: isLowHP) { _, lowHP in
            if lowHP {
                withAnimation(.easeIn(duration: 0.25)) {
                    showLowHPGuide = true
                }
            } else {
                // HP recovered — hide the guide
                withAnimation(.easeOut(duration: 0.2)) {
                    showLowHPGuide = false
                }
            }
        }
        .task {
            // Show low HP guide if critically wounded
            if isLowHP {
                showLowHPGuide = true
            }
            // Show arena guide NPC only on first visit (not yet dismissed)
            if !arenaGuideDismissed {
                showArenaGuide = true
            }
            if vm == nil {
                vm = ArenaViewModel(appState: appState, cache: cache)
            }

            // Ensure inventory is cached so LowHP banner can check for potions
            if appState.cachedInventory == nil {
                let service = InventoryService(appState: appState)
                _ = await service.loadInventory()
            }

            await vm?.loadAll()
        }
    }

    // MARK: - HP Helpers

    /// True when character HP is critically low (< 30%) and fighting should be blocked
    private var isLowHP: Bool {
        guard let char = appState.currentCharacter else { return false }
        return LowHPPotionBanner.shouldShow(character: char)
    }

    // MARK: - Potion Helpers

    /// Whether the player has at least one health potion in cached inventory
    private var hasHealthPotion: Bool {
        appState.cachedInventory?.contains(where: {
            $0.consumableType?.contains("health_potion") == true && ($0.quantity ?? 0) > 0
        }) ?? false
    }

    // MARK: - Health Potion Handler

    private func useHealthPotion() async {
        // Find the first available health potion from cached inventory
        guard let items = appState.cachedInventory else {
            appState.showToast("No potions found", subtitle: "Visit the shop", type: .info)
            return
        }

        guard let potion = items.first(where: {
            $0.consumableType?.contains("health_potion") == true && ($0.quantity ?? 0) > 0
        }) else {
            appState.showToast("No health potions", subtitle: "Buy potions at the shop", type: .error)
            return
        }

        // Optimistic UI — update inventory cache immediately
        let previousItems = items
        if let qty = potion.quantity, qty > 1 {
            appState.cachedInventory = items.map { existing in
                guard existing.id == potion.id else { return existing }
                var updated = existing
                updated.quantity = qty - 1
                return updated
            }
        } else {
            appState.cachedInventory = items.filter { $0.id != potion.id }
        }

        // Optimistic HP update — estimate healing amount (30% of maxHP)
        let maxHp = appState.currentCharacter?.maxHp ?? 1
        let currentHp = appState.currentCharacter?.currentHp ?? 0
        let estimatedHeal = max(Int(Double(maxHp) * 0.3), 50)
        let newHp = min(currentHp + estimatedHeal, maxHp)
        appState.currentCharacter?.currentHp = newHp

        HapticManager.success()
        appState.showToast("Healed! HP: \(newHp)/\(maxHp)", type: .reward)

        // Fire API in background — server returns actual values
        let potionId = potion.id
        let consumableType = potion.consumableType
        let previousHp = currentHp
        let service = InventoryService(appState: appState)
        Task {
            let success = await service.useItem(
                inventoryId: potionId,
                consumableType: consumableType
            )
            if !success {
                // Revert on failure
                await MainActor.run {
                    appState.cachedInventory = previousItems
                    appState.currentCharacter?.currentHp = previousHp
                    appState.showToast("Failed to use potion", type: .error)
                }
            }
        }
    }

    // MARK: - PvP Stats Bar

    @ViewBuilder
    private func arenaPvpStatsBar(_ char: Character) -> some View {
        HStack(spacing: 0) {
            // Rating
            pvpStatItem(
                imageAsset: "icon-pvp-rating",
                value: "\(char.pvpRating)",
                label: "Rating",
                accentColor: DarkFantasyTheme.gold
            )

            // Divider
            Rectangle()
                .fill(DarkFantasyTheme.borderMedium.opacity(0.3))
                .frame(width: 1, height: 28)

            // Win Streak
            pvpStatItem(
                imageAsset: "icon-wins",
                value: "\(char.pvpWinStreak ?? 0)",
                label: "Streak",
                accentColor: DarkFantasyTheme.danger
            )

            // First Win bonus
            if char.firstWinToday == true {
                Rectangle()
                    .fill(DarkFantasyTheme.borderMedium.opacity(0.3))
                    .frame(width: 1, height: 28)

                pvpStatItem(
                    imageAsset: "reward-first-win",
                    value: "2×",
                    label: "First Win",
                    accentColor: DarkFantasyTheme.success
                )
            }
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceMD)
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
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    @ViewBuilder
    private func pvpStatItem(imageAsset: String, value: String, label: String, accentColor: Color) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(imageAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stance Preview

    @ViewBuilder
    private func stancePreview(_ stance: CombatStance) -> some View {
        StanceDisplayView(
            stance: stance,
            isInteractive: true,
            onTap: { appState.mainPath.append(AppRoute.stanceSelector) }
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Opponents Tab

    @ViewBuilder
    private func opponentsTab(_ vm: ArenaViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if vm.isLoadingOpponents && vm.opponents.isEmpty {
                // Skeleton loading state
                HStack(spacing: LayoutConstants.arenaCardGap) {
                    ForEach(0..<2, id: \.self) { _ in
                        SkeletonOpponentCard()
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            } else if vm.opponents.isEmpty {
                emptyState(icon: "swords", message: "No opponents available.") {
                    Button {
                        Task { await vm.refreshOpponents() }
                    } label: {
                        Text("FIND OPPONENTS")
                    }
                    .buttonStyle(.secondary)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }
            } else {
                // Two opponent cards side by side — animated
                HStack(spacing: LayoutConstants.arenaCardGap) {
                    ForEach(Array(vm.displayedOpponents.enumerated()), id: \.element.id) { index, opponent in
                        ArenaOpponentCard(
                            opponent: opponent,
                            playerRating: vm.pvpRating,
                            onTap: { vm.selectOpponent(opponent) }
                        )
                        .frame(maxWidth: .infinity)
                        .opacity(opponentCardsVisible ? 1 : 0)
                        .offset(y: opponentCardsVisible ? 0 : 12)
                        .animation(
                            .spring(response: 0.35, dampingFraction: 0.72)
                            .delay(opponentCardsVisible ? Double(index) * 0.08 : 0),
                            value: opponentCardsVisible
                        )
                    }
                }
                .tutorialAnchor(.arenaOpponent)
                .padding(.horizontal, LayoutConstants.screenPadding)
                .onAppear {
                    // Initial entrance animation
                    if opponentCardPhase == .idle {
                        opponentCardsVisible = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            opponentCardsVisible = true
                            opponentCardPhase = .shown
                        }
                    }
                }
            }
        }
    }

    // MARK: - Refresh Button

    @ViewBuilder
    private func refreshButton(_ vm: ArenaViewModel) -> some View {
        Button {
            withAnimation(.linear(duration: 0.5)) {
                refreshRotation += 360
            }
            Task { await animatedRefresh(vm) }
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(refreshRotation))
                Text("New Opponents")
            }
        }
        .buttonStyle(.compactPrimary)
        .disabled(vm.isRefreshing || opponentCardPhase == .animatingOut)
        .accessibilityLabel("Find new opponents")
    }

    /// Animated opponent refresh: cards slide out → data refreshes → cards slide back in.
    private func animatedRefresh(_ vm: ArenaViewModel) async {
        guard opponentCardPhase != .animatingOut else { return }
        opponentCardPhase = .animatingOut

        // 1. Animate current cards OUT
        withAnimation(.easeIn(duration: 0.2)) {
            opponentCardsVisible = false
        }

        // 2. Wait for exit animation
        try? await Task.sleep(nanoseconds: 220_000_000) // 220ms

        // 3. Fetch new opponents
        await vm.refreshOpponents()

        // 4. Small beat before entrance
        try? await Task.sleep(nanoseconds: 60_000_000) // 60ms

        // 5. Animate new cards IN with stagger
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            opponentCardsVisible = true
        }

        opponentCardPhase = .shown
    }

    // MARK: - Revenge Tab

    @ViewBuilder
    private func revengeTab(_ vm: ArenaViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if vm.isLoadingRevenge && vm.revengeList.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonRevengeCard()
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }
            } else if vm.revengeList.isEmpty {
                emptyState(icon: "shield", message: "No one has attacked you yet.\nYou're safe... for now.")
            } else {
                ForEach(vm.revengeList) { entry in
                    revengeCard(entry, vm: vm)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }
            }
        }
    }

    @ViewBuilder
    private func revengeCard(_ entry: RevengeEntry, vm: ArenaViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Attacker info
            Text(entry.attackerClass.icon)
                .font(.system(size: 24)) // emoji — keep
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .fill(DarkFantasyTheme.danger.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.attackerName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Lv.\(entry.attackerLevel)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text("-\(entry.ratingLost) rating")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.danger)
                    Text(entry.timeAgo)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }

            Spacer()

            // Revenge button — triggers fight directly
            Button {
                Task { await vm.revenge(revengeId: entry.id) }
            } label: {
                HStack(spacing: 4) {
                    if vm.fightingOpponentId == entry.id {
                        ProgressView()
                            .tint(.textPrimary)
                            .scaleEffect(0.8)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "swords")
                                .font(.system(size: 12))
                            Text("REVENGE")
                        }
                    }
                }
            }
            .buttonStyle(.dangerCompact)
            .disabled(vm.fightingOpponentId == entry.id || !vm.canFight)
            .accessibilityLabel("Fight \(entry.attackerName) for revenge")
        }
        .panelCard()
    }

    // MARK: - History Tab

    @ViewBuilder
    private func historyTab(_ vm: ArenaViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if vm.isLoadingHistory && vm.history.isEmpty {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonHistoryRow()
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }
            } else if vm.history.isEmpty {
                emptyState(icon: "doc.text", message: "No match history yet.\nFight to see your results!")
            } else {
                ForEach(vm.history) { match in
                    historyRow(match)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }
            }
        }
    }

    @ViewBuilder
    private func historyRow(_ match: MatchHistory) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Win/Loss indicator
            Text(match.isWin ? "✅" : "❌")
                .font(.system(size: 20)) // emoji — keep

            // Opponent info
            VStack(alignment: .leading, spacing: 2) {
                Text(match.opponentName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(match.opponentClass.icon)
                        .font(.system(size: 12)) // emoji — keep
                    Text("Lv.\(match.opponentLevel)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text(match.timeAgo)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }

            Spacer()

            // Rating change + rewards
            VStack(alignment: .trailing, spacing: 2) {
                let ratingText = match.ratingChange > 0 ? "+\(match.ratingChange)" : "\(match.ratingChange)"
                Text(ratingText)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(match.ratingChange > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)

                if let gold = match.goldReward, gold > 0 {
                    Text("+\(gold) 💰")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: match.isWin ? DarkFantasyTheme.success.opacity(0.06) : DarkFantasyTheme.danger.opacity(0.06),
                glowColor: match.isWin ? DarkFantasyTheme.success.opacity(0.03) : DarkFantasyTheme.danger.opacity(0.03),
                glowIntensity: 0.2,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.panelRadius - 1,
            inset: 1,
            color: (match.isWin ? DarkFantasyTheme.success : DarkFantasyTheme.danger).opacity(0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(
                    match.isWin ? DarkFantasyTheme.success.opacity(0.2) : DarkFantasyTheme.danger.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState<CTA: View>(icon: String, message: String, @ViewBuilder cta: () -> CTA = { EmptyView() }) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Text(icon)
                .font(.system(size: 40)) // emoji — keep
            Text(message)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
            cta()
        }
        .padding(.top, LayoutConstants.spaceXL)
    }
}

// MARK: - Refresh Animation Phase

private enum RefreshPhase {
    case idle         // Initial state — first entrance not yet triggered
    case shown        // Cards are visible
    case animatingOut // Cards are leaving before refresh
}
