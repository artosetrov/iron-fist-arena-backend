import SwiftUI

struct LeaderboardDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: LeaderboardViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    // Tab switcher
                    TabSwitcher(
                        tabs: LeaderboardViewModel.tabs,
                        selectedIndex: Binding(
                            get: { vm.selectedTab },
                            set: { vm.selectedTab = $0 }
                        )
                    )
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.spaceSM)

                    // Your rank
                    HStack {
                        Text("Your Position:")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                        if let rank = vm.myRank {
                            Text("#\(rank)")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                        } else {
                            Text("Not ranked")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.spaceSM)
                    .background(DarkFantasyTheme.bgSecondary)
                    .overlay(
                        Rectangle()
                            .fill(DarkFantasyTheme.gold.opacity(0.2))
                            .frame(height: 1),
                        alignment: .bottom
                    )

                    // Content
                    if vm.isLoading && vm.currentEntries.isEmpty {
                        LazyVStack(spacing: LayoutConstants.spaceXS) {
                            ForEach(0..<8, id: \.self) { _ in
                                SkeletonLeaderboardRow()
                            }
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.vertical, LayoutConstants.spaceSM)
                    } else if vm.currentEntries.isEmpty {
                        Spacer()
                        Text("No data available")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Spacer()
                    } else {
                        let tabKey = LeaderboardViewModel.tabKeys[vm.selectedTab]
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: LayoutConstants.spaceXS) {
                                    ForEach(vm.currentEntries) { entry in
                                        LeaderboardRowView(
                                            entry: entry,
                                            isSelf: entry.characterId == vm.myCharacterId,
                                            valueLabel: tabKey
                                        )
                                        .id(entry.characterId)
                                    }
                                }
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.vertical, LayoutConstants.spaceSM)
                            }
                            .onChange(of: vm.currentEntries.count) {
                                scrollToSelf(proxy: proxy, vm: vm)
                            }
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
                Text("LEADERBOARD")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil { vm = LeaderboardViewModel(appState: appState, cache: cache) }
            await vm?.loadLeaderboard()
        }
    }

    private func scrollToSelf(proxy: ScrollViewProxy, vm: LeaderboardViewModel) {
        guard let myId = vm.myCharacterId else { return }
        guard vm.currentEntries.contains(where: { $0.characterId == myId }) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                proxy.scrollTo(myId, anchor: .center)
            }
        }
    }
}
