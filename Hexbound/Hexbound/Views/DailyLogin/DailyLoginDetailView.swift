import SwiftUI

/// Daily Tribute — "A · chests of the week" (canvas 2026-11-04).
///
/// Composition, top to bottom, over the Descent's treasure vault at night:
///   DAILY TRIBUTE · DAY N OF 7 · streak pill (close ✕ top-right)
///     → today's chest on the floor (`TributeChestStage`): tap or the CTA opens
///       it, the reward rises out, then the tribute reward card follows
///     → THIS WEEK'S CHESTS: seven chests, wood → iron → gold, day 7 violet
///     → OPEN THE CHEST / TO THE CASTLE · "Tomorrow: … · wooden chest"
///
/// Day numbers all come from `vm.displayDay` (BUG-23) — the title, the chest,
/// the week and the reward card always agree. Rewards are server-authored
/// (`GameConfig.dailyLoginRewards`); the chest tiers are presentation only.
struct DailyLoginDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: DailyLoginPopupViewModel?

    // BUG-53: single dismissal path. Routes through AppState's modal queue so
    // any queued modal (e.g. pending .levelUp) gets its turn after close, and
    // so pop-back paths can never resurrect the popup — the state lives on
    // AppState.showDailyLoginPopup, not on a local sheet binding.
    private func close() {
        appState.dismissDailyLoginPopup()
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            vault

            if let vm {
                if vm.isLoading {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.gold)
                        .transaction { $0.animation = nil }
                } else if let data = vm.loginData {
                    content(data: data, vm: vm)
                } else {
                    ErrorStateView.loadFailed {
                        Task { await vm.loadData() }
                    }
                    .transaction { $0.animation = nil }
                }
            }
        }
        .claimRewardModal(config: Binding(
            get: { vm?.claimRewardConfig },
            set: { vm?.claimRewardConfig = $0 }
        ))
        .task {
            if vm == nil {
                let viewModel = DailyLoginPopupViewModel(appState: appState, cache: cache)
                vm = viewModel
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Backdrop

    /// The treasure vault under the Descent's night grade, a pool of warm
    /// light where the chest stands, the bottom fading into the panel.
    private var vault: some View {
        ZStack {
            DescentBackdrop(
                asset: "rush2-bg-treasure",
                dim: 0.05,
                focusY: 0.55,
                lights: [DescentLight(center: CGPoint(x: 0.5, y: 0.62), radius: 0.62, strength: 0.55)]
            )
            DescentVignette(strength: 0.55)
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [DarkFantasyTheme.bgAbyss.opacity(0.85), DarkFantasyTheme.bgAbyss.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [DarkFantasyTheme.bgPrimary.opacity(0), DarkFantasyTheme.bgPrimary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 360)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        let rewards = DailyReward.rewards(from: cache)
        let today = rewards.first(where: { $0.day == vm.displayDay })

        VStack(spacing: 0) {
            header(data: data, vm: vm)
                .padding(.top, LayoutConstants.spaceSM)
                .transaction { $0.animation = nil }

            TributeChestStage(
                day: vm.displayDay,
                reward: today,
                isOpen: vm.hasClaimed,
                isBusy: vm.isClaiming,
                onOpen: { Task { await vm.claimReward() } }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            weekPanel(rewards: rewards, vm: vm)
                .transaction { $0.animation = nil }
        }
    }

    // MARK: - Header

    private func header(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("DAILY TRIBUTE")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(4)
                .foregroundStyle(DarkFantasyTheme.gold)

            Text("DAY \(vm.displayDay) OF 7")
                .font(DarkFantasyTheme.cinematicTitle)
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 8, y: 2)
                .accessibilityAddTraits(.isHeader)

            TributeStreakPill(text: streakLine(data: data, vm: vm), isLost: vm.streakIsLost)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, LayoutConstants.spaceLG)
        .overlay(alignment: .topTrailing) {
            Button {
                close()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.closeButton)
            .accessibilityLabel("Close daily tribute")
            .padding(.trailing, LayoutConstants.screenPadding)
        }
    }

    /// One line, one meaning: how long the streak is and what keeps it.
    private func streakLine(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> String {
        if vm.hasClaimed {
            return data.streak <= 1
                ? "Streak started · come back tomorrow"
                : "\(data.streak)-day streak · come back tomorrow"
        }
        if vm.streakIsLost {
            return "Streak lost · a new one starts today"
        }
        if data.streak == 0 || DailyLoginPopupViewModel.streakResets(data) {
            return "Open today's chest to start a streak"
        }
        return "\(data.streak)-day streak · keep it lit"
    }

    // MARK: - Week panel

    private func weekPanel(rewards: [DailyReward], vm: DailyLoginPopupViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            HStack(alignment: .firstTextBaseline) {
                Text("THIS WEEK'S CHESTS")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer()
                Text("\(vm.claimedCount)/7 opened")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            .accessibilityElement(children: .combine)

            TributeWeekStrip(rewards: rewards, displayDay: vm.displayDay, hasClaimed: vm.hasClaimed)

            cta(vm: vm)
                .padding(.top, LayoutConstants.space2XS)

            tomorrowLine(vm: vm)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMS)
        .padding(.bottom, LayoutConstants.spaceMD)
        .background(alignment: .top) {
            DarkFantasyTheme.bgPrimary
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [DarkFantasyTheme.gold.opacity(0), DarkFantasyTheme.goldDim.opacity(0.6), DarkFantasyTheme.gold.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private func cta(vm: DailyLoginPopupViewModel) -> some View {
        if vm.hasClaimed {
            Button {
                close()
            } label: {
                Text("TO THE CASTLE")
            }
            .buttonStyle(.secondary)
        } else {
            Button {
                Task { await vm.claimReward() }
            } label: {
                if vm.isClaiming {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.textOnGold)
                } else {
                    Text("OPEN THE CHEST")
                }
            }
            .buttonStyle(.primary)
            .disabled(vm.isClaiming)
        }
    }

    @ViewBuilder
    private func tomorrowLine(vm: DailyLoginPopupViewModel) -> some View {
        if let next = vm.nextDayReward {
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("Tomorrow:")
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                TributeRewardIcon(reward: next, size: LayoutConstants.iconSM + 2)
                Text(next.label)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text("· \(TributeChestTier(day: next.day).adjective) chest")
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
            }
            .font(DarkFantasyTheme.body)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .accessibilityElement(children: .combine)
        }
    }
}
