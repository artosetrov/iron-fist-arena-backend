import SwiftUI

struct ArenaDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: ArenaViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    staminaBar(vm)

                ScrollView {
                    VStack(spacing: LayoutConstants.spaceLG) {
                        // Active quest banner
                        ActiveQuestBanner(questTypes: ["pvp_wins"])
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Arena Header
                        arenaHeader(vm)

                        // Combat Stance
                        if let char = appState.currentCharacter {
                            stanceSummaryCard(char)
                        }

                        GoldDivider()
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Tab Switcher
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
                } // VStack
            }
        }
        .navigationBarBackButtonHidden(true)
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.stamina)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DarkFantasyTheme.bgTertiary)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DarkFantasyTheme.staminaGradient)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 14)

                Text("\(current)/\(max)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.stamina)
                    .monospacedDigit()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
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
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceSM)
    }

    // MARK: - Arena Header

    @ViewBuilder
    private func arenaHeader(_ vm: ArenaViewModel) -> some View {
        HStack(spacing: 0) {
            arenaPvpStat("Rating", value: "\(vm.pvpRating)", color: DarkFantasyTheme.rankColor(for: vm.pvpRating))
            arenaPvpStat("Record", value: "\(vm.character?.pvpWins ?? 0)W / \(vm.character?.pvpLosses ?? 0)L", color: DarkFantasyTheme.textPrimary)
            arenaPvpStat("Rank", value: vm.character?.rankName ?? vm.rank.rawValue, color: DarkFantasyTheme.rankColor(for: vm.pvpRating))
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func arenaPvpStat(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Opponents Tab

    @ViewBuilder
    private func opponentsTab(_ vm: ArenaViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if vm.isLoadingOpponents && vm.opponents.isEmpty {
                // Skeleton loading state — 3 shimmer cards
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonOpponentCard()
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }
            } else if vm.opponents.isEmpty {
                emptyState(icon: "⚔️", message: "No opponents available.\nPull down to refresh.")
            } else {
                // Refresh button
                HStack {
                    Spacer()
                    Button {
                        Task { await vm.refreshOpponents() }
                    } label: {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "arrow.clockwise")
                            Text("REFRESH")
                        }
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.gold)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)

                ForEach(vm.opponents) { opponent in
                    OpponentCardView(
                        opponent: opponent,
                        isFighting: vm.fightingOpponentId == opponent.id,
                        canFight: vm.canFight,
                        staminaCost: vm.staminaCost,
                        onFight: {
                            Task { await vm.fight(opponentId: opponent.id) }
                        },
                        playerRating: vm.pvpRating
                    )
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }
            }
        }
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
                .font(.system(size: 24))
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

            // Revenge button
            Button {
                Task { await vm.revenge(revengeId: entry.id) }
            } label: {
                HStack(spacing: 4) {
                    if vm.fightingOpponentId == entry.id {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                            .scaleEffect(0.8)
                    } else {
                        Text("⚔️")
                            .font(.system(size: 14))
                        Text("REVENGE")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    }
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(DarkFantasyTheme.danger.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.danger.opacity(0.5), lineWidth: 1)
                )
            }
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
                .font(.system(size: 20))

            // Opponent info
            VStack(alignment: .leading, spacing: 2) {
                Text(match.opponentName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(match.opponentClass.icon)
                        .font(.system(size: 12))
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

    // MARK: - Stance Summary Card

    @ViewBuilder
    private func stanceSummaryCard(_ char: Character) -> some View {
        let stance = char.combatStance ?? .default

        Button {
            appState.mainPath.append(AppRoute.stanceSelector)
        } label: {
            HStack(spacing: LayoutConstants.spaceLG) {
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("⚔️ ATTACK")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold())
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text(stance.attack.uppercased())
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                        .foregroundStyle(StanceSelectorViewModel.zoneColor(for: stance.attack))
                }

                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(width: 1, height: 40)

                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("🛡️ DEFENSE")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold())
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text(stance.defense.uppercased())
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                        .foregroundStyle(StanceSelectorViewModel.zoneColor(for: stance.defense))
                }
            }
            .frame(maxWidth: .infinity)
            .panelCard(highlight: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text(icon)
                .font(.system(size: 40))
            Text(message)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, LayoutConstants.spaceXL)
    }
}
