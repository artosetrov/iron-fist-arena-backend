import SwiftUI

struct ArenaDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: ArenaViewModel?
    @State private var refreshRotation: Double = 0
    @State private var revengeConfirmEntry: RevengeEntry?

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

            if let vm {
                VStack(spacing: 0) {
                    staminaBar(vm)

                ScrollView {
                    VStack(spacing: LayoutConstants.spaceLG) {
                        // Active quest banner
                        ActiveQuestBanner(questTypes: ["pvp_wins"])
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Arena Header (Rating, Record, Rank)
                        arenaHeader(vm)

                        // Current stance indicator
                        if let stance = appState.currentCharacter?.combatStance {
                            stancePreview(stance)
                                .tutorialAnchor(.arenaStance)
                        }

                        // Character card (from Hub)
                        if let char = appState.currentCharacter {
                            HubCharacterCardWrapper(character: char)
                                .padding(.horizontal, LayoutConstants.screenPadding)
                        }

                        GoldDivider()
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Tab Switcher
                        TabSwitcher(
                            tabs: ["⚔ OPPONENTS", "🔄 REVENGE", "📜 HISTORY"],
                            selectedIndex: Binding(
                                get: { vm.selectedTab },
                                set: { newValue in
                                    vm.selectedTab = newValue
                                    Task { await vm.loadTabData() }
                                }
                            )
                        )
                        .padding(.horizontal, LayoutConstants.screenPadding)

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
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)
                }
                } // VStack
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
            }
        }
        .navigationBarBackButtonHidden(true)
        .tutorialOverlay(steps: [.arenaStance, .arenaOpponent])
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("ARENA")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .confirmationDialog(
            "REVENGE",
            isPresented: Binding(
                get: { revengeConfirmEntry != nil },
                set: { if !$0 { revengeConfirmEntry = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let entry = revengeConfirmEntry {
                Button("Fight \(entry.attackerName) (\(vm?.staminaCost ?? 0) STA)") {
                    Task { await vm?.revenge(revengeId: entry.id) }
                    revengeConfirmEntry = nil
                }
                Button("Cancel", role: .cancel) {
                    revengeConfirmEntry = nil
                }
            }
        } message: {
            if let entry = revengeConfirmEntry {
                Text("\(entry.attackerName) took \(entry.ratingLost) rating from you. Spend stamina to fight back?")
            }
        }
        .onAppear {
            AudioManager.shared.playBGM("Arena : PvP.mp3")
        }
        .onDisappear {
            AudioManager.shared.playBGM("Stray City.mp3")
        }
        .task {
            if vm == nil {
                vm = ArenaViewModel(appState: appState, cache: cache)
            }
            await vm?.loadAll()
        }
    }

    // MARK: - Stamina Bar

    @ViewBuilder
    private func staminaBar(_ vm: ArenaViewModel) -> some View {
        let current = vm.currentStamina
        let max = vm.maxStamina
        let fraction = max > 0 ? Double(current) / Double(max) : 0

        Button {
            vm.goToShop()
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold)) // SF Symbol icon — keep
                    .foregroundStyle(DarkFantasyTheme.stamina)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DarkFantasyTheme.bgDarkPanel)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DarkFantasyTheme.staminaGradient)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 6)

                Text("\(current)/\(max)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.stamina)
                    .monospacedDigit()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16)) // SF Symbol icon — keep
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.stamina.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.scalePress(0.97))
        .contentShape(Rectangle())
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceSM)
    }

    // MARK: - Arena Header

    @ViewBuilder
    private func arenaHeader(_ vm: ArenaViewModel) -> some View {
        HStack(spacing: 0) {
            arenaPvpStat("RATING", value: "\(vm.pvpRating)", color: DarkFantasyTheme.xpRing)
            arenaPvpStat("RECORD", value: "\(vm.character?.pvpWins ?? 0)W / \(vm.character?.pvpLosses ?? 0)L", color: DarkFantasyTheme.textPrimary)
            arenaPvpStat("RANK", value: vm.character?.rankName ?? vm.rank.rawValue, color: DarkFantasyTheme.arenaRankGold)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DarkFantasyTheme.bgDarkPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DarkFantasyTheme.bgDarkPanelBorder, lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func arenaPvpStat(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(value)
                .font(DarkFantasyTheme.section(size: 14))
                .foregroundStyle(color)
            Text(label)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textDimLabel)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stance Preview

    @ViewBuilder
    private func stancePreview(_ stance: CombatStance) -> some View {
        Button {
            appState.mainPath.append(AppRoute.stanceSelector)
        } label: {
            HStack(spacing: LayoutConstants.spaceMD) {
                // Attack zone
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("⚔️")
                    Text(stance.attack.uppercased())
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(StanceSelectorViewModel.zoneColor(for: stance.attack))
                }

                Spacer()

                Text("STANCE")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textDimLabel)

                Spacer()

                // Defense zone
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(stance.defense.uppercased())
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(StanceSelectorViewModel.zoneColor(for: stance.defense))
                    Text("🛡️")
                }
            }
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.scalePress(0.97))
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Opponents Tab

    @ViewBuilder
    private func opponentsTab(_ vm: ArenaViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if vm.isLoadingOpponents && vm.opponents.isEmpty {
                // Skeleton loading state
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(0..<2, id: \.self) { _ in
                        SkeletonOpponentCard()
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            } else if vm.opponents.isEmpty {
                emptyState(icon: "⚔️", message: "No opponents available.") {
                    Button {
                        Task { await vm.refreshOpponents() }
                    } label: {
                        Text("FIND OPPONENTS")
                    }
                    .buttonStyle(.secondary)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }
            } else {
                // Two opponent cards side by side
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(vm.displayedOpponents) { opponent in
                        ArenaOpponentCard(
                            opponent: opponent,
                            playerRating: vm.pvpRating,
                            onTap: { vm.selectOpponent(opponent) }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .tutorialAnchor(.arenaOpponent)
                .padding(.horizontal, LayoutConstants.screenPadding)
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
            Task { await vm.refreshOpponents() }
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(refreshRotation))
                Text("NEW OPPONENTS")
            }
        }
        .buttonStyle(.primary)
        .disabled(vm.isRefreshing)
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
                emptyState(icon: "🛡️", message: "No one has attacked you yet.\nYou're safe... for now.")
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

            // Revenge button — opens confirmation
            Button {
                revengeConfirmEntry = entry
            } label: {
                HStack(spacing: 4) {
                    if vm.fightingOpponentId == entry.id {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Text("⚔️")
                            .font(.system(size: 14)) // emoji — keep
                        Text("REVENGE")
                    }
                }
            }
            .buttonStyle(.dangerCompact)
            .disabled(vm.fightingOpponentId == entry.id || !vm.canFight)
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
                emptyState(icon: "📜", message: "No match history yet.\nFight to see your results!")
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
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(match.isWin ? DarkFantasyTheme.success.opacity(0.05) : DarkFantasyTheme.danger.opacity(0.05))
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
