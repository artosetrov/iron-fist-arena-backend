import SwiftUI

struct DailyLoginPopupView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DailyLoginPopupViewModel?

    // ── Entrance animation state ──
    @State private var backdropOpacity: Double = 0
    @State private var modalScale: CGFloat = 0.78
    @State private var modalOpacity: Double = 0
    @State private var modalOffsetY: CGFloat = 28

    // ── Idle animations (stopped on disappear per GPU rules) ──
    @State private var iconFloat: Bool = false
    @State private var glowPulse: Bool = false
    @State private var glowRotation: Double = 0

    var body: some View {
        ZStack {
            // Backdrop — fades in first, no tap-dismiss (modal is intentional)
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .opacity(backdropOpacity)

            if let vm = viewModel {
                if vm.isLoading {
                    skeletonView()
                        .padding(.horizontal, LayoutConstants.spaceLG)
                        .scaleEffect(modalScale)
                        .opacity(modalOpacity)
                        .offset(y: modalOffsetY)

                } else if let data = vm.loginData {
                    if vm.hasClaimed {
                        // ── Phase 2: Confirmation ──
                        confirmationModal(data: data, vm: vm)
                            .padding(.horizontal, LayoutConstants.spaceLG)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.86, anchor: .center).combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else {
                        // ── Phase 1: Pre-claim ──
                        preClaimModal(data: data, vm: vm)
                            .padding(.horizontal, LayoutConstants.spaceLG)
                            .scaleEffect(modalScale)
                            .opacity(modalOpacity)
                            .offset(y: modalOffsetY)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .scale(scale: 1.05, anchor: .center).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .onAppear {
            let vm = DailyLoginPopupViewModel(appState: appState)
            viewModel = vm

            // Backdrop fades in slightly ahead of the modal
            withAnimation(.easeOut(duration: 0.22)) {
                backdropOpacity = 1
            }
            // Modal springs in with satisfying bounce
            withAnimation(.spring(response: 0.50, dampingFraction: 0.68).delay(0.06)) {
                modalScale = 1.0
                modalOpacity = 1.0
                modalOffsetY = 0
            }
            // Start idle animations
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                iconFloat = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }

            Task { await vm.loadData() }
        }
        .onDisappear {
            // Stop all animations — NavigationStack keeps views in memory
            iconFloat = false
            glowPulse = false
            glowRotation = 0
        }
    }

    // MARK: - Phase 1: Pre-Claim Modal

    @ViewBuilder
    private func preClaimModal(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        VStack(spacing: 0) {

            // Day badge
            dayBadge(day: data.currentDay)
                .padding(.top, LayoutConstants.spaceLG)

            // Title
            Text("ЕЖЕДНЕВНАЯ\nНАГРАДА")
                .font(DarkFantasyTheme.section)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.top, LayoutConstants.spaceXS)

            // Big reward icon showcase
            if let reward = DailyReward.rewards.first(where: { $0.day == data.currentDay }) {
                bigRewardShowcase(reward: reward)
                    .padding(.top, LayoutConstants.spaceLG)

                // Amount label
                Text(reward.label.uppercased())
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 10)
                    .padding(.top, LayoutConstants.spaceSM)

                Text(reward.description)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .padding(.top, 2)
            }

            // 7-day streak dots
            streakDots(currentDay: data.currentDay)
                .padding(.top, LayoutConstants.spaceMD)

            // Divider
            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceMD)

            // Claim button
            claimButton(vm: vm)
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceMD)

            // Tomorrow hint
            tomorrowHint(vm: vm)
                .padding(.top, LayoutConstants.spaceSM)
                .padding(.bottom, LayoutConstants.spaceLG)
        }
        .modalCard()
    }

    // MARK: - Phase 2: Confirmation Modal

    @ViewBuilder
    private func confirmationModal(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        VStack(spacing: 0) {

            // Claimed badge
            claimedBadge()
                .padding(.top, LayoutConstants.spaceLG)

            // Title
            Text("НАГРАДА\nПОЛУЧЕНА")
                .font(DarkFantasyTheme.section)
                .multilineTextAlignment(.center)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.top, LayoutConstants.spaceXS)

            // Reward confirmation card
            if let reward = DailyReward.rewards.first(where: { $0.day == data.currentDay }) {
                rewardConfirmCard(reward: reward)
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.top, LayoutConstants.spaceMD)
            }

            // Streak progress
            streakRow(data: data)
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceSM)

            // Tomorrow
            tomorrowHint(vm: vm)
                .padding(.top, LayoutConstants.spaceSM)

            // Divider
            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceMD)

            // Continue button
            Button { dismissPopup() } label: { Text("ПРОДОЛЖИТЬ") }
                .buttonStyle(.neutral)
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceMD)
                .padding(.bottom, LayoutConstants.spaceLG)
        }
        .modalCard()
    }

    // MARK: - Sub-components

    @ViewBuilder
    private func dayBadge(day: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10))
                .foregroundStyle(DarkFantasyTheme.gold)
            Text("ДЕНЬ \(day) ИЗ 7")
                .font(DarkFantasyTheme.badge)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(DarkFantasyTheme.gold.opacity(0.10))
                .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.30), lineWidth: 1))
        )
    }

    @ViewBuilder
    private func claimedBadge() -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(DarkFantasyTheme.success)
                .frame(width: 6, height: 6)
                .shadow(color: DarkFantasyTheme.success.opacity(0.9), radius: 4)
            Text("ПОЛУЧЕНО!")
                .font(DarkFantasyTheme.badge)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.success)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(DarkFantasyTheme.success.opacity(0.10))
                .overlay(Capsule().stroke(DarkFantasyTheme.success.opacity(0.30), lineWidth: 1))
        )
    }

    @ViewBuilder
    private func bigRewardShowcase(reward: DailyReward) -> some View {
        ZStack {
            // Outer glow halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DarkFantasyTheme.gold.opacity(glowPulse ? 0.20 : 0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 72
                    )
                )
                .frame(width: 144, height: 144)

            // Rotating angular ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            DarkFantasyTheme.goldBright.opacity(0.7),
                            DarkFantasyTheme.gold.opacity(0.1),
                            DarkFantasyTheme.goldBright.opacity(0.7)
                        ],
                        center: .center,
                        angle: .degrees(glowRotation)
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 110, height: 110)

            // Icon box
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG + 4)
                .fill(
                    LinearGradient(
                        colors: [
                            DarkFantasyTheme.dailyGradientTopGold,
                            DarkFantasyTheme.dailyGradientBottomGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG + 4)
                        .stroke(DarkFantasyTheme.goldBright, lineWidth: 2)
                )
                .shadow(
                    color: DarkFantasyTheme.gold.opacity(glowPulse ? 0.55 : 0.25),
                    radius: glowPulse ? 18 : 8
                )

            // Asset or emoji
            if let assetIcon = reward.assetIcon, UIImage(named: assetIcon) != nil {
                Image(assetIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
            } else {
                Text(reward.icon)
                    .font(.system(size: 46))
            }
        }
        .offset(y: iconFloat ? -5 : 0)
    }

    @ViewBuilder
    private func streakDots(currentDay: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(1...7, id: \.self) { day in
                let isPast = day < currentDay
                let isCurrent = day == currentDay

                Capsule()
                    .fill(
                        isPast || isCurrent
                        ? LinearGradient(
                            colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                        : LinearGradient(
                            colors: [DarkFantasyTheme.gold.opacity(0.15), DarkFantasyTheme.gold.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
                    .frame(width: isCurrent ? 30 : 22, height: 4)
                    .shadow(
                        color: isCurrent ? DarkFantasyTheme.goldGlow : .clear,
                        radius: glowPulse ? 5 : 3
                    )
            }
        }
    }

    @ViewBuilder
    private func rewardConfirmCard(reward: DailyReward) -> some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD + 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                DarkFantasyTheme.dailyGradientTopGold,
                                DarkFantasyTheme.dailyGradientBottomGold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD + 2)
                            .stroke(DarkFantasyTheme.goldBright, lineWidth: 1.5)
                    )

                if let assetIcon = reward.assetIcon, UIImage(named: assetIcon) != nil {
                    Image(assetIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                } else {
                    Text(reward.icon)
                        .font(.system(size: 26))
                }
            }

            // Text info
            VStack(alignment: .leading, spacing: 2) {
                Text("СЕГОДНЯ")
                    .font(DarkFantasyTheme.badge)
                    .tracking(1)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("+")
                        .font(DarkFantasyTheme.uiLabel.bold())
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text(reward.label.uppercased())
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Text(reward.description)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            Spacer()

            // Added badge
            Text("Добавлено")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.success)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(DarkFantasyTheme.success.opacity(0.12))
                        .overlay(Capsule().stroke(DarkFantasyTheme.success.opacity(0.30), lineWidth: 1))
                )
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.50))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius + 4)
                        .stroke(DarkFantasyTheme.gold.opacity(0.20), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func streakRow(data: DailyLoginData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("СЕРИЯ ВХОДОВ")
                    .font(DarkFantasyTheme.badge)
                    .tracking(1)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text("\(data.streak) / 7")
                    .font(DarkFantasyTheme.uiLabel.bold())
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { day in
                    Capsule()
                        .fill(
                            day <= data.streak
                            ? LinearGradient(
                                colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [DarkFantasyTheme.gold.opacity(0.12), DarkFantasyTheme.gold.opacity(0.12)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                        )
                        .frame(width: 22, height: 3)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.borderSubtle.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Shared components

    @ViewBuilder
    private func claimButton(vm: DailyLoginPopupViewModel) -> some View {
        Button {
            Task { await vm.claimReward() }
        } label: {
            Group {
                if vm.isClaiming {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                } else {
                    Text("ПОЛУЧИТЬ НАГРАДУ")
                }
            }
        }
        .buttonStyle(.primary)
        .disabled(vm.isClaiming)
    }

    @ViewBuilder
    private func tomorrowHint(vm: DailyLoginPopupViewModel) -> some View {
        if let nextReward = vm.nextDayReward {
            HStack(spacing: 5) {
                Text("Завтра:")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text("\(nextReward.icon) \(nextReward.label)")
                    .font(DarkFantasyTheme.caption.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
    }

    // MARK: - Skeleton

    @ViewBuilder
    private func skeletonView() -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Badge placeholder
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(width: 100, height: 24)
                .padding(.top, LayoutConstants.spaceLG)

            // Title placeholder
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(width: 160, height: 28)

            // Icon placeholder
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG + 4)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
                .frame(width: 88, height: 88)

            // Label placeholder
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(width: 140, height: 36)

            // Streak dots placeholder
            RoundedRectangle(cornerRadius: 2)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.4))
                .frame(width: 200, height: 4)

            // Button placeholder
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(height: 52)
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.bottom, LayoutConstants.spaceLG)
        }
        .modalCard()
    }

    // MARK: - Dismiss

    private func dismissPopup() {
        withAnimation(.easeOut(duration: 0.20)) {
            backdropOpacity = 0
            modalScale = 0.93
            modalOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            viewModel?.dismiss()
        }
    }
}

// MARK: - Modal card style helper

private extension View {
    func modalCard() -> some View {
        self
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(
                cornerRadius: LayoutConstants.modalRadius,
                topHighlight: 0.10,
                bottomShadow: 0.16
            )
            .innerBorder(
                cornerRadius: LayoutConstants.modalRadius - 3,
                inset: 3,
                color: DarkFantasyTheme.gold.opacity(0.10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.50), lineWidth: 1.5)
            )
            .cornerBrackets(
                color: DarkFantasyTheme.goldBright.opacity(0.50),
                length: 18,
                thickness: 2.0
            )
            .cornerDiamonds(
                color: DarkFantasyTheme.gold.opacity(0.40),
                size: 6
            )
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 20)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.80), radius: 32, y: 8)
    }
}
