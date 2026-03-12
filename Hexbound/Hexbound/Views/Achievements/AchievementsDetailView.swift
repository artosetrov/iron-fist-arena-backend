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
                    // Count
                    HStack {
                        Text("\(vm.completedCount) / \(vm.totalCount)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                        if vm.unclaimedCount > 0 {
                            Text("(\(vm.unclaimedCount) unclaimed!)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.spaceXS)

                    // Tab switcher
                    TabSwitcher(
                        tabs: AchievementsViewModel.tabs,
                        selectedIndex: Binding(
                            get: { vm.selectedTab },
                            set: { vm.selectedTab = $0 }
                        )
                    )
                    .padding(.horizontal, LayoutConstants.screenPadding)

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
                    } else if vm.filteredAchievements.isEmpty {
                        Spacer()
                        Text("No achievements in this category")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                ForEach(vm.filteredAchievements) { achievement in
                                    AchievementCardView(
                                        achievement: achievement,
                                        isClaiming: vm.claimingKey == achievement.key,
                                        onClaim: {
                                            Task { await vm.claim(achievement) }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
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
}
