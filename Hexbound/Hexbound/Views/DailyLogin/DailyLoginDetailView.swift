import SwiftUI

struct DailyLoginDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
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
                Group {
                if vm.isLoading {
                    ProgressView()
                        .tint(DarkFantasyTheme.gold)
                } else if let data = vm.loginData {
                    ScrollView {
                        VStack(spacing: 0) {
                            // ── Modal Header with close button ──
                            modalHeader()

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
                            .padding(.top, LayoutConstants.spaceSM)

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
                .transaction { $0.animation = nil }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DarkFantasyTheme.bgPrimary)
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

    // MARK: - Modal Header

    @ViewBuilder
    private func modalHeader() -> some View {
        HStack {
            Spacer()

            Text("DAILY LOGIN")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMD)
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
                    RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                        .fill(DarkFantasyTheme.bgTertiary)

                    RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
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
                        rewardIcon(reward, size: isBonus ? 28 : 24)
                            .opacity(0.4)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                } else {
                    rewardIcon(reward, size: isBonus ? 32 : 26)
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
                        rewardIcon(reward, size: 28)
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
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderSubtle.opacity(0.4), lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 12, thickness: 1.5)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
        }
    }

    // MARK: - Claim Section

    @ViewBuilder
    private func claimSection(vm: DailyLoginPopupViewModel) -> some View {
        if vm.hasClaimed {
            Button {
                dismiss()
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
                    HStack(spacing: 4) {
                        rewardIcon(nextReward, size: 16)
                        Text(nextReward.label)
                    }
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody).weight(.bold))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            } else {
                HStack(spacing: 4) {
                    Text("Tomorrow:")
                    rewardIcon(nextReward, size: 14)
                    Text(nextReward.label)
                }
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }

    // MARK: - Reward Icon (asset-first, emoji fallback)

    @ViewBuilder
    private func rewardIcon(_ reward: DailyReward, size: CGFloat) -> some View {
        if let assetName = reward.assetIcon, UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(reward.icon)
                .font(.system(size: size))
        }
    }
}
