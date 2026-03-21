import SwiftUI

struct DailyLoginPopupView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DailyLoginPopupViewModel?
    @State private var appear = false
    @State private var glowRotation: Double = 0

    var body: some View {
        ZStack {
            // Backdrop
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .opacity(appear ? 1 : 0)
                .onTapGesture {
                    dismissPopup()
                }

            if let vm = viewModel, !vm.isLoading, let data = vm.loginData {
                VStack(spacing: 0) {
                    // ── Header ──
                    headerSection(data: data)

                    // ── Progress Bar ──
                    progressBar(data: data)
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.top, LayoutConstants.spaceSM)

                    // ── Day Grid ──
                    dayGrid(data: data, vm: vm)
                        .padding(.top, LayoutConstants.spaceMD)

                    // ── Today's Reward Card ──
                    todayRewardCard(data: data, vm: vm)
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.top, LayoutConstants.spaceMD)

                    // ── Claim Button ──
                    claimButton(vm: vm)
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.top, LayoutConstants.spaceMD)

                    // ── Tomorrow hint ──
                    tomorrowHint(vm: vm)
                        .padding(.top, LayoutConstants.spaceSM)
                        .padding(.bottom, LayoutConstants.spaceLG)
                }
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                        .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1.5)
                )
                .padding(.horizontal, LayoutConstants.spaceLG)
                .opacity(appear ? 1 : 0)
                .transition(.identity)
            }
        }
        .onAppear {
            let vm = DailyLoginPopupViewModel(appState: appState)
            viewModel = vm
            Task {
                await vm.loadData()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    appear = true
                }
            }
            // Continuous glow rotation
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(data: DailyLoginData) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("DAILY LOGIN")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .padding(.top, LayoutConstants.spaceLG)

            Text("Day \(data.streak) Streak")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Keep your streak for bonus rewards!")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private func progressBar(data: DailyLoginData) -> some View {
        let progress = max(0, min(1, Double(data.currentDay - 1) / 6.0))

        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("Weekly Progress")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer()
                Text("\(data.currentDay)/7")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).weight(.bold))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DarkFantasyTheme.bgTertiary)

                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * max(0, min(1, progress)))
                        .shadow(color: DarkFantasyTheme.goldGlow, radius: 6, x: 0, y: 0)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Day Grid

    @ViewBuilder
    private func dayGrid(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Row 1: Days 1-3
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(DailyReward.rewards.prefix(3), id: \.day) { reward in
                    dayCell(reward: reward, data: data, vm: vm)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceMD)

            // Row 2: Days 4-6
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(DailyReward.rewards.dropFirst(3).prefix(3), id: \.day) { reward in
                    dayCell(reward: reward, data: data, vm: vm)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceMD)

            // Row 3: Day 7 bonus
            if let day7 = DailyReward.rewards.last, day7.day == 7 {
                dayCell(reward: day7, data: data, vm: vm, isBonus: true)
                    .padding(.horizontal, LayoutConstants.spaceMD)
            }
        }
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(
        reward: DailyReward,
        data: DailyLoginData,
        vm: DailyLoginPopupViewModel,
        isBonus: Bool = false
    ) -> some View {
        let isCurrentDay = reward.day == data.currentDay && data.canClaim
        let isClaimed = reward.day < data.currentDay || (reward.day == data.currentDay && !data.canClaim)
        let isLocked = !isClaimed && !isCurrentDay
        let _ = vm.claimedDayBounce == reward.day

        ZStack {
            // Background
            if isClaimed {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
            } else if isCurrentDay {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.dailyGradientTopGold, DarkFantasyTheme.dailyGradientBottomGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.4))
            }

            // Border
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                .stroke(
                    isClaimed ? DarkFantasyTheme.goldDim.opacity(0.4) :
                    isCurrentDay ? DarkFantasyTheme.goldBright :
                    DarkFantasyTheme.borderSubtle.opacity(0.3),
                    lineWidth: isCurrentDay ? 2 : 1
                )

            // Animated glow ring for current day
            if isCurrentDay {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                DarkFantasyTheme.goldBright,
                                DarkFantasyTheme.goldBright.opacity(0.2),
                                DarkFantasyTheme.gold.opacity(0.1),
                                DarkFantasyTheme.goldBright
                            ]),
                            center: .center,
                            angle: .degrees(glowRotation)
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 8, x: 0, y: 0)
            }

            // Content
            VStack(spacing: 4) {
                // Claimed checkmark
                if isClaimed {
                    ZStack {
                        Text(reward.icon)
                            .font(.system(size: isBonus ? 24 : 20))
                            .opacity(0.4)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                } else {
                    Text(reward.icon)
                        .font(.system(size: isBonus ? 28 : 22))
                        .opacity(isLocked ? 0.3 : 1)
                }

                Text(reward.label)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).weight(.bold))
                    .foregroundStyle(
                        isClaimed ? DarkFantasyTheme.textDisabled :
                        isCurrentDay ? DarkFantasyTheme.goldBright :
                        DarkFantasyTheme.textSecondary.opacity(isLocked ? 0.4 : 1)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Day \(reward.day)")
                    .font(DarkFantasyTheme.body(size: 10).weight(.semibold))
                    .foregroundStyle(
                        isCurrentDay ? DarkFantasyTheme.gold.opacity(0.8) :
                        DarkFantasyTheme.textTertiary.opacity(isLocked ? 0.3 : 0.6)
                    )
            }
        }
        .frame(height: isBonus ? 80 : 88)
        .opacity(isLocked ? 0.5 : 1)
    }

    // MARK: - Today's Reward Card

    @ViewBuilder
    private func todayRewardCard(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        if let reward = DailyReward.rewards.first(where: { $0.day == data.currentDay }) {
            HStack(spacing: LayoutConstants.spaceMD) {
                // Reward icon box
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 2)
                        .fill(
                            LinearGradient(
                                colors: vm.hasClaimed
                                    ? [DarkFantasyTheme.dailyGradientTopGreen, DarkFantasyTheme.dailyGradientBottomGreen]
                                    : [DarkFantasyTheme.dailyGradientTopGold, DarkFantasyTheme.dailyGradientBottomGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 2)
                        .stroke(
                            vm.hasClaimed ? DarkFantasyTheme.success : DarkFantasyTheme.goldBright,
                            lineWidth: 1.5
                        )
                        .frame(width: 52, height: 52)

                    if vm.hasClaimed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.success)
                    } else {
                        Text(reward.icon)
                            .font(.system(size: 26))
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S REWARD")
                        .font(DarkFantasyTheme.body(size: 10).weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text(vm.hasClaimed ? "Claimed!" : reward.label.uppercased())
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCard).weight(.heavy))
                        .foregroundStyle(
                            vm.hasClaimed ? DarkFantasyTheme.success : DarkFantasyTheme.goldBright
                        )
                }

                Spacer()

                Text("Day \(data.currentDay)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .padding(LayoutConstants.spaceMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                    .stroke(DarkFantasyTheme.borderSubtle.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Claim Button

    @ViewBuilder
    private func claimButton(vm: DailyLoginPopupViewModel) -> some View {
        Button {
            Task { await vm.claimReward() }
        } label: {
            Group {
                if vm.isClaiming {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                } else if vm.hasClaimed {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("REWARD CLAIMED")
                    }
                } else {
                    Text("CLAIM REWARD")
                }
            }
        }
        .buttonStyle(.primary)
        .disabled(vm.hasClaimed || vm.isClaiming)
    }

    // MARK: - Tomorrow Hint

    @ViewBuilder
    private func tomorrowHint(vm: DailyLoginPopupViewModel) -> some View {
        if let nextReward = vm.nextDayReward {
            if vm.hasClaimed {
                VStack(spacing: 2) {
                    Text("Come back tomorrow for")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("\(nextReward.icon) \(nextReward.label)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).weight(.bold))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            } else {
                Text("Tomorrow: \(nextReward.icon) \(nextReward.label)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }

    private func dismissPopup() {
        withAnimation(.easeOut(duration: 0.2)) {
            appear = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            viewModel?.dismiss()
        }
    }
}
