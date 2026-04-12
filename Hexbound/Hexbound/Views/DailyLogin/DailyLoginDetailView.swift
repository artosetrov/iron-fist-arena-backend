import SwiftUI

/// Daily Login — Variant B layout (shipped from Figma/HTML prototype 2026-04-10).
///
/// Composition:
///   modalHeader → streak header → weekly progress bar
///     → HERO `ItemCardView(.preview)` + title/subtitle
///     → horizontal 7-day BP-style strip (inline, no new component)
///     → CTA (`Button.primary` claim / `.neutral` claimed)
///     → footer caption ("Come back tomorrow…" + TO THE CASTLE)
///
/// The 3+3+1 grid and the old `todayRewardCard` HStack are gone.
/// ItemCardView is the **single** item-visual in this screen — the hero uses
/// its `.preview` context to get rarity border + corner accents for free.
struct DailyLoginDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: DailyLoginPopupViewModel?
    @State private var glowRotation: Double = 0

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
                        HexPulseLoader(.compact)
                            .tint(DarkFantasyTheme.gold)
                    } else if vm.loginData == nil {
                        ErrorStateView.loadFailed {
                            Task { await vm.loadData() }
                        }
                    } else if let data = vm.loginData {
                        content(data: data, vm: vm)
                    }
                }
                .transaction { $0.animation = nil }
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
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }
        }
        .onDisappear {
            glowRotation = 0
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func content(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                modalHeader()

                streakHeader(data: data)
                    .padding(.top, LayoutConstants.spaceSM)

                progressBar(vm: vm)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceLG)

                heroBlock(vm: vm)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceXL)

                dayStrip(data: data, vm: vm)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceLG)

                claimSection(vm: vm)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceLG)

                footerCaption(vm: vm)
                    .padding(.top, LayoutConstants.spaceMD)
                    .padding(.bottom, LayoutConstants.space2XL)
            }
        }
    }

    // MARK: - Modal Header

    @ViewBuilder
    private func modalHeader() -> some View {
        HStack {
            Spacer()
            Text("DAILY LOGIN")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.goldBright)
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                close()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(DarkFantasyTheme.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMD)
    }

    // MARK: - Streak Header

    @ViewBuilder
    private func streakHeader(data: DailyLoginData) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("Day \(data.streak) Streak")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Keep your streak for bonus rewards!")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private func progressBar(vm: DailyLoginPopupViewModel) -> some View {
        // BUG-23: progress and label both read from vm helpers — `claimedCount`
        // only advances after a successful claim, `displayDay` stays glued to
        // the cell being shown. Previously both derived from `data.currentDay`,
        // which flipped to tomorrow the instant the server advanced its pointer.
        let progress = max(0, min(1, Double(vm.claimedCount) / 7.0))

        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("Weekly Progress")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer()
                Text("\(vm.displayDay)/7")
                    .font(DarkFantasyTheme.body.bold())
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
            .frame(height: LayoutConstants.spaceSM)
        }
    }

    // MARK: - Hero Block (ItemCardView + labels)

    @ViewBuilder
    private func heroBlock(vm: DailyLoginPopupViewModel) -> some View {
        // BUG-23: hero lookup follows vm.displayDay. With the old
        // `data.currentDay` lookup, the instant the server advanced to the
        // next day, the hero card flipped to tomorrow's reward mid-animation.
        let rewards = DailyReward.rewards(from: cache)
        let today = rewards.first(where: { $0.day == vm.displayDay })

        VStack(spacing: LayoutConstants.spaceMD) {
            // HERO ItemCardView — single source of truth for item visuals
            if let reward = today {
                ItemCardView(
                    rarity: dayRarity(reward.day),
                    imageKey: reward.assetIcon,
                    imageUrl: nil,
                    fallbackIcon: "gift.fill",
                    context: .preview,
                    onTap: {}
                )
                .frame(width: 168, height: 168)
                .allowsHitTesting(false)
                .opacity(vm.hasClaimed ? 0.55 : 1)
                .overlay {
                    if vm.hasClaimed {
                        ZStack {
                            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                                .fill(DarkFantasyTheme.bgAbyss.opacity(0.35))
                            Image(systemName: "checkmark.seal.fill")
                                .font(DarkFantasyTheme.cinematicTitle)
                                .foregroundStyle(DarkFantasyTheme.success)
                                .shadow(color: DarkFantasyTheme.success.opacity(0.6), radius: 12)
                        }
                    }
                }
                .shadow(
                    color: DarkFantasyTheme.rarityGlow(for: dayRarity(reward.day)),
                    radius: 18
                )
            }

            // Hero label + title + subtitle (mirrors HTML prototype .hero-wrap)
            VStack(spacing: LayoutConstants.space2XS) {
                Text("TODAY'S REWARD")
                    .font(DarkFantasyTheme.body.bold())
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Text(vm.hasClaimed ? "Claimed!" : (today?.label ?? "Reward").uppercased())
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(
                        vm.hasClaimed ? DarkFantasyTheme.success : DarkFantasyTheme.goldBright
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Day \(vm.displayDay) · Next reward tomorrow")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Day Strip (horizontal 7-node BP-style)

    @ViewBuilder
    private func dayStrip(data: DailyLoginData, vm: DailyLoginPopupViewModel) -> some View {
        let rewards = DailyReward.rewards(from: cache)

        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(rewards, id: \.day) { reward in
                dayNode(reward: reward, data: data, vm: vm)
            }
        }
    }

    // MARK: - Day Node (single cell in horizontal strip)

    @ViewBuilder
    private func dayNode(
        reward: DailyReward,
        data: DailyLoginData,
        vm: DailyLoginPopupViewModel
    ) -> some View {
        // BUG-23: pivot the whole claimed/current/locked state machine on
        // vm.displayDay instead of data.currentDay. Previously, after claiming
        // day 1, data.currentDay jumped to 2, which made day 1 look like "past"
        // AND day 2 simultaneously look "already claimed" — the player saw
        // the strip skip two slots at once.
        let displayDay = vm.displayDay
        let effectiveCanClaim = data.canClaim && !vm.hasClaimed
        let isCurrentDay = reward.day == displayDay && effectiveCanClaim
        let isClaimed = reward.day < displayDay || (reward.day == displayDay && !effectiveCanClaim)
        let isLocked = !isClaimed && !isCurrentDay
        let isPremium = reward.day == 7
        let rarity = dayRarity(reward.day)
        let bounce = vm.claimedDayBounce == reward.day

        VStack(spacing: LayoutConstants.space2XS) {
            // Icon well
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(
                        isCurrentDay
                            ? LinearGradient(
                                colors: [
                                    DarkFantasyTheme.dailyGradientTopGold,
                                    DarkFantasyTheme.dailyGradientBottomGold
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    DarkFantasyTheme.bgTertiary.opacity(isLocked ? 0.3 : 0.5),
                                    DarkFantasyTheme.bgAbyss.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )

                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(
                        isClaimed ? DarkFantasyTheme.success.opacity(0.6) :
                        isCurrentDay ? DarkFantasyTheme.goldBright :
                        isPremium ? DarkFantasyTheme.rarityColor(for: rarity).opacity(0.6) :
                        DarkFantasyTheme.borderSubtle.opacity(0.4),
                        lineWidth: isCurrentDay ? 2 : 1
                    )

                // Animated glow ring for current day
                if isCurrentDay {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
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
                        .shadow(color: DarkFantasyTheme.goldGlow, radius: 6)
                }

                // Content
                if isClaimed {
                    Image(systemName: "checkmark")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.success)
                } else {
                    rewardIcon(reward, size: isPremium ? 28 : 24)
                        .opacity(isLocked ? 0.35 : 1)
                }
            }
            .frame(height: 48)
            .opacity(isLocked ? 0.55 : 1)
            .scaleEffect(bounce ? 1.08 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.55), value: bounce)

            // Day label
            Text("D\(reward.day)")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(
                    isCurrentDay ? DarkFantasyTheme.goldBright :
                    isClaimed ? DarkFantasyTheme.success.opacity(0.7) :
                    DarkFantasyTheme.textTertiary.opacity(isLocked ? 0.4 : 0.7)
                )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Claim Section

    @ViewBuilder
    private func claimSection(vm: DailyLoginPopupViewModel) -> some View {
        if vm.hasClaimed {
            Button {
                close()
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "checkmark")
                        .font(DarkFantasyTheme.body.bold())
                    Text("REWARD CLAIMED")
                }
            }
            .buttonStyle(.neutral)
            .disabled(true)
            .opacity(0.6)
        } else {
            Button {
                HapticManager.success()
                Task { await vm.claimReward() }
            } label: {
                if vm.isClaiming {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.textOnGold)
                } else {
                    Text("CLAIM REWARD")
                }
            }
            .buttonStyle(.primary)
            .disabled(vm.isClaiming)
        }
    }

    // MARK: - Footer Caption

    @ViewBuilder
    private func footerCaption(vm: DailyLoginPopupViewModel) -> some View {
        if let nextReward = vm.nextDayReward {
            if vm.hasClaimed {
                VStack(spacing: LayoutConstants.spaceMD) {
                    VStack(spacing: LayoutConstants.spaceXS) {
                        Text("Come back tomorrow for")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        HStack(spacing: LayoutConstants.spaceXS) {
                            rewardIcon(nextReward, size: 16)
                            Text(nextReward.label)
                        }
                        .font(DarkFantasyTheme.body.weight(.bold))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }

                    Button {
                        close()
                    } label: {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Image(systemName: "building.columns.fill")
                                .font(DarkFantasyTheme.body.bold())
                            Text("TO THE CASTLE")
                        }
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }
            } else {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Tomorrow:")
                    rewardIcon(nextReward, size: 14)
                    Text(nextReward.label)
                }
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }

    // MARK: - Reward Icon Helper (asset-first, placeholder fallback)

    @ViewBuilder
    private func rewardIcon(_ reward: DailyReward, size: CGFloat) -> some View {
        if let assetName = reward.assetIcon, UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            AssetPlaceholderView(systemIcon: "gift.fill")
                .frame(width: size, height: size)
        }
    }

    // MARK: - Day → Rarity mapping
    //
    // Visual progression across the 7-day week. Maps nicely to a bp-node
    // strip where the premium day 7 gets the legendary treatment via
    // `ItemCardView`'s rarityColor + rarityGlow shadow.
    //
    // This is purely presentational — the actual reward value comes from
    // `GameConfig.dailyLoginRewards` and is server-authored.
    private func dayRarity(_ day: Int) -> ItemRarity {
        switch day {
        case 1, 2:  return .common
        case 3:     return .uncommon
        case 4, 5:  return .rare
        case 6:     return .epic
        default:    return .legendary  // day 7 bonus
        }
    }
}
