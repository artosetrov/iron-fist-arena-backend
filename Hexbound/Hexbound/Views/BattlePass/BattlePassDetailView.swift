import SwiftUI

struct BattlePassDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: BattlePassViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

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
                    Text("No battle pass data")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
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

            HStack {
                Text("Level \(vm.currentLevel)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
                Text("\(vm.currentXp) / \(vm.xpToNext) XP")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
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
            }
        }
        .frame(height: 10)
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
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            }
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(vm.isBuyingPremium ? AnyShapeStyle(DarkFantasyTheme.goldDim) : AnyShapeStyle(DarkFantasyTheme.goldGradient))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
        }
        .disabled(vm.isBuyingPremium)
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
                        ForEach(rewards) { reward in
                            BPRewardNodeView(
                                reward: reward,
                                state: vm.rewardState(reward),
                                isClaiming: vm.claimingLevel == reward.level
                            ) {
                                Task { await vm.claimReward(reward) }
                            }
                            .id(reward.level)
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
