import SwiftUI

struct AchievementsDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: AchievementsViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    // Count + unclaimed indicator
                    HStack {
                        Text("\(vm.completedCount) / \(vm.totalCount)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .accessibilityLabel("Achievements: \(vm.completedCount) of \(vm.totalCount) completed")
                        if vm.unclaimedCount > 0 {
                            Text("(\(vm.unclaimedCount) unclaimed!)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                                .accessibilityLabel("\(vm.unclaimedCount) unclaimed achievements available")
                        }
                        Spacer()
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.spaceXS)

                    // Tab switcher with badge overlays (H4 fix)
                    tabSwitcherWithBadges(vm: vm)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.vertical, LayoutConstants.tabSwitcherPaddingV)

                    // Content
                    if vm.isLoading && vm.achievements.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                ForEach(0..<5, id: \.self) { _ in
                                    SkeletonAchievementCard()
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                    } else if vm.errorMessage != nil {
                        ErrorStateView.loadFailed { Task { await vm.loadAchievements() } }
                    } else if vm.filteredAchievements.isEmpty {
                        EmptyStateView.noAchievements
                    } else {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                ForEach(Array(vm.filteredAchievements.enumerated()), id: \.element.id) { index, achievement in
                                    AchievementCardView(
                                        achievement: achievement,
                                        isClaiming: vm.claimingKey == achievement.key,
                                        onClaim: {
                                            HapticManager.success()
                                            SFXManager.shared.play(.uiRewardClaim)
                                            Task { await vm.claim(achievement) }
                                        }
                                    )
                                    .staggeredAppear(index: index)
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.top, LayoutConstants.spaceSM)
                            .padding(.bottom, LayoutConstants.safeAreaBottom + LayoutConstants.spaceSM) // M3 fix: safe area
                        }
                        .transition(.opacity) // M2 fix: was .opacity.combined(with: .scale(0.98))
                    }
                }
                .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("ACHIEVEMENTS")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil { vm = AchievementsViewModel(appState: appState, cache: cache) }
            await vm?.loadAchievements()
        }
    }

    // MARK: - Tab Switcher with Badge Overlays (H4 fix)

    @ViewBuilder
    private func tabSwitcherWithBadges(vm: AchievementsViewModel) -> some View {
        ZStack {
            TabSwitcher(
                tabs: AchievementsViewModel.tabs,
                selectedIndex: Binding(
                    get: { vm.selectedTab },
                    set: { vm.selectedTab = $0 }
                )
            )
            .accessibilityLabel("Achievement tabs: \(AchievementsViewModel.tabs.joined(separator: ", "))")
            .accessibilityValue("Current tab: \(AchievementsViewModel.tabs[vm.selectedTab])")

            // Badge overlays for unclaimed counts per tab
            GeometryReader { geo in
                let tabWidth = geo.size.width / CGFloat(AchievementsViewModel.tabs.count)
                ForEach(AchievementsViewModel.tabs.indices, id: \.self) { index in
                    let count = vm.unclaimedCountForTab(index)
                    if count > 0 && index != vm.selectedTab {
                        Text("\(count)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textOnGold)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(DarkFantasyTheme.gold)
                            )
                            .position(
                                x: tabWidth * CGFloat(index) + tabWidth - 14,
                                y: 6
                            )
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }
}
