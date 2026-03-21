import SwiftUI

struct DailyLoginDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DailyLoginPopupViewModel?
    @State private var glowRotation: Double = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DarkFantasyTheme.gold.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(y: -60)

            if let vm {
                if vm.isLoading {
                    ProgressView()
                        .tint(DarkFantasyTheme.gold)
                } else if let data = vm.loginData {
                    ScrollView {
                        VStack(spacing: 0) {
                            // ── Streak Header ──
                            VStack(spacing: LayoutConstants.spaceXS) {
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
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                            }
                            .padding(.top, LayoutConstants.spaceMD)

                            // ── Progress Bar ──
                            progressBar(data: data)
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.top, LayoutConstants.spaceLG)

                            // ── Day Grid ──
                            dayGrid(data: data, vm: vm)
                                .padding(.top, LayoutConstants.spaceLG)

                            // ── Today's Reward Card ──
                            todayRewardCard(data: data, vm: vm)
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.top, LayoutConstants.spaceLG)

                            // ── Claim / Claimed ──
                            claimSection(vm: vm)
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.top, LayoutConstants.spaceLG)

                            // ── Tomorrow Hint ──
                            tomorrowHint(vm: vm)
                                .padding(.top, LayoutConstants.spaceMD)
                                .padding(.bottom, LayoutConstants.space2XL)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DAILY LOGIN")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil {
                let viewModel = DailyLoginPopupViewModel(appState: appState)
                vm = viewModel
                await viewModel.loadData()
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private func progressBar(data: DailyLoginData) -> some View {
        let progress = max(0, min(1, Double(data.currentDay - 1) / 6.0))

        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("Weekly Progress")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer()
                Text("\(data.currentDay)/7")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).weight(.bold))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.bgTertiary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * max(0, min(1, progress)))
                        .shadow(color: DarkFantasyTheme.goldGlow, radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 8)
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
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Row 2: Days 4-6
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(DailyReward.rewards.dropFirst(3).prefix(3), id: \.day) { reward in
                    dayCell(reward: reward, data: data, vm: vm)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Row 3: Day 7 bonus
            if let day7 = DailyReward.rewards.last, day7.day == 7 {
                dayCell(reward: day7, data: data, vm: vm, isBonus: true)
                    .padding(.horizontal, LayoutConstants.screenPadding)
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
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
            } else if isCurrentDay {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.dailyGradientTopGold, DarkFantasyTheme.dailyGradientBottomGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.4))
            }

            // Border
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    isClaimed ? DarkFantasyTheme.goldDim.opacity(0.4) :
                    isCurrentDay ? DarkFantasyTheme.goldBright :
                    DarkFantasyTheme.borderSubtle.opacity(0.3),
                    lineWidth: isCurrentDay ? 2 : 1
                )

            // Animated glow for current day
            if isCurrentDay {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
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
            VStack(spacing: 6) {
                if isClaimed {
                    ZStack {
                        Text(reward.icon)
                            .font(.system(size: isBonus ? 28 : 24))
                            .opacity(0.4)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                } else {
                    Text(reward.icon)
                        .font(.system(size: isBonus ? 32 : 26))
                        .opacity(isLocked ? 0.3 : 1)
                }

                Text(reward.label)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).weight(.bold))
                    .foregroundStyle(
                        isClaimed ? DarkFantasyTheme.textDisabled :
                        isCurrentDay ? DarkFantasyTheme.goldBright :
                        DarkFantasyTheme.textSecondary.opacity(isLocked ? 0.4 : 1)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Day \(reward.day)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).weight(.semibold))
                    .foregroundStyle(
                        isCurrentDay ? DarkFantasyTheme.gold.opacity(0.8) :
                        DarkFantasyTheme.textTertiary.opacity(isLocked ? 0.3 : 0.6)
                    )
            }
        }
        .frame(height: isBonus ? 90 : 100)
        .opacity(isLocked ? 0.5 : 1)
    }

    // MARK: - Today's Reward Card

    @ViewBuilder
    private func todayRewardCard(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        if let reward = DailyReward.rewards.first(where: { $0.day == data.currentDay }) {
            HStack(spacing: LayoutConstants.spaceMD) {
                // Reward icon
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(
                            LinearGradient(
                                colors: vm.hasClaimed
                                    ? [DarkFantasyTheme.dailyGradientTopGreen, DarkFantasyTheme.dailyGradientBottomGreen]
                                    : [DarkFantasyTheme.dailyGradientTopGold, DarkFantasyTheme.dailyGradientBottomGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(
                            vm.hasClaimed ? DarkFantasyTheme.success : DarkFantasyTheme.goldBright,
                            lineWidth: 1.5
                        )
                        .frame(width: 56, height: 56)

                    if vm.hasClaimed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.success)
                    } else {
                        Text(reward.icon)
                            .font(.system(size: 28))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S REWARD")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).weight(.bold))
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
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .padding(LayoutConstants.spaceMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderSubtle.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Claim Section

    @ViewBuilder
    private func claimSection(vm: DailyLoginPopupViewModel) -> some View {
        if vm.hasClaimed {
            Button {
                appState.mainPath.removeLast()
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("REWARD CLAIMED")
                }
            }
            .buttonStyle(.primary)
        } else {
            Button {
                HapticManager.success()
                Task { await vm.claimReward() }
            } label: {
                if vm.isClaiming {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                } else {
                    Text("CLAIM REWARD")
                }
            }
            .buttonStyle(.primary)
            .disabled(vm.isClaiming)
        }
    }

    // MARK: - Tomorrow Hint

    @ViewBuilder
    private func tomorrowHint(vm: DailyLoginPopupViewModel) -> some View {
        if let nextReward = vm.nextDayReward {
            if vm.hasClaimed {
                VStack(spacing: 4) {
                    Text("Come back tomorrow for")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("\(nextReward.icon) \(nextReward.label)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody).weight(.bold))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            } else {
                Text("Tomorrow: \(nextReward.icon) \(nextReward.label)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }
}
