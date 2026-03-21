import SwiftUI

struct BattlePassDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: BattlePassViewModel?

    var body: some View {
        ZStack {
            // Background image with dark overlay
            GeometryReader { geo in
                Image("bg-forge")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()

            if let vm {
                if vm.isLoading && vm.data == nil {
                    // Skeleton battle pass
                    ScrollView {
                        VStack(spacing: LayoutConstants.spaceMD) {
                            SkeletonRect(width: 120, height: 14)
                            SkeletonRect(height: 10)
                            SkeletonRect(height: 40, cornerRadius: 8)
                            HStack(spacing: LayoutConstants.spaceSM) {
                                ForEach(0..<6, id: \.self) { _ in
                                    SkeletonBPNode()
                                }
                            }
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.vertical, LayoutConstants.spaceSM)
                    }
                } else if vm.errorMessage != nil {
                    // TODO: Add error property to ViewModel
                    ErrorStateView.loadFailed { Task { await vm.loadBattlePass() } }
                } else if let _ = vm.data {
                    ScrollView {
                        VStack(spacing: LayoutConstants.spaceMD) {
                            // Season + Level
                            headerSection(vm: vm)

                            // XP Progress
                            xpProgressSection(vm: vm)

                            // Premium button
                            if !vm.hasPremium {
                                premiumButton(vm: vm)
                            }

                            // Free Rewards
                            rewardTrackSection(
                                title: "FREE REWARDS",
                                rewards: vm.freeRewards,
                                vm: vm
                            )

                            // Premium Rewards
                            rewardTrackSection(
                                title: "PREMIUM REWARDS",
                                rewards: vm.premiumRewards,
                                vm: vm
                            )
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.vertical, LayoutConstants.spaceSM)
                    }
                } else {
                    EmptyStateView.generic(title: "No Battle Pass", message: "The battle pass isn't available right now. Check back later!")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("BATTLE PASS")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil { vm = BattlePassViewModel(appState: appState, cache: cache) }
            await vm?.loadBattlePass()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(vm: BattlePassViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text(vm.seasonName)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .accessibilityLabel("Season: \(vm.seasonName)")

            HStack {
                Text("Level \(vm.currentLevel)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .accessibilityLabel("Battle Pass level \(vm.currentLevel)")
                Spacer()
                Text("\(vm.currentXp) / \(vm.xpToNext) XP")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .accessibilityLabel("Experience: \(vm.currentXp) of \(vm.xpToNext)")
            }
        }
    }

    // MARK: - XP Bar

    @ViewBuilder
    private func xpProgressSection(vm: BattlePassViewModel) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DarkFantasyTheme.bgTertiary)
                RoundedRectangle(cornerRadius: 4)
                    .fill(DarkFantasyTheme.progressGradient)
                    .frame(width: geo.size.width * vm.xpProgress)
                    .animation(
                        .easeOut(duration: MotionConstants.progressFillDuration(deltaPercent: vm.xpProgress * 100)),
                        value: vm.xpProgress
                    )
            }
        }
        .frame(height: 10)
        .accessibilityLabel("Experience progress")
        .accessibilityValue("\(Int(vm.xpProgress * 100))% complete")
    }

    // MARK: - Premium Button

    @ViewBuilder
    private func premiumButton(vm: BattlePassViewModel) -> some View {
        Button {
            Task { await vm.buyPremium() }
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                if vm.isBuyingPremium {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                } else {
                    Image(systemName: "star.fill")
                }
                Text("UPGRADE TO PREMIUM")
            }
        }
        .buttonStyle(.primary)
        .disabled(vm.isBuyingPremium)
        .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.5, isActive: !vm.isBuyingPremium)
        .shimmer(color: DarkFantasyTheme.gold, duration: 3)
    }

    // MARK: - Reward Track

    @ViewBuilder
    private func rewardTrackSection(title: String, rewards: [BPReward], vm: BattlePassViewModel) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text(title)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.gold)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(Array(rewards.enumerated()), id: \.element.id) { index, reward in
                            BPRewardNodeView(
                                reward: reward,
                                state: vm.rewardState(reward),
                                isClaiming: vm.claimingLevel == reward.level
                            ) {
                                HapticManager.medium()
                                SFXManager.shared.play(.uiRewardClaim)
                                Task { await vm.claimReward(reward) }
                            }
                            .id(reward.level)
                            .staggeredAppear(index: index)
                        }
                    }
                    .padding(.vertical, LayoutConstants.spaceXS)
                }
                .onAppear {
                    // Scroll to first claimable or current level
                    let target = rewards.first(where: { vm.rewardState($0) == .claimable })?.level
                        ?? rewards.first(where: { $0.level >= vm.currentLevel })?.level
                    if let target {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo(target, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}
