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
                    .padding(.vertical, LayoutConstants.tabSwitcherPaddingV)
                    .accessibilityLabel("Leaderboard tabs: \(LeaderboardViewModel.tabs.joined(separator: ", "))")
                    .accessibilityValue("Current tab: \(LeaderboardViewModel.tabs[vm.selectedTab])")

                    // Your rank
                    HStack {
                        Text("Your Position:")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .accessibilityLabel("Your leaderboard position")
                        if let rank = vm.myRank {
                            HStack(spacing: 0) {
                                Text("#")
                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                    .foregroundStyle(DarkFantasyTheme.goldBright)
                                NumberTickUpText(
                                    value: rank,
                                    color: DarkFantasyTheme.goldBright,
                                    font: DarkFantasyTheme.section(size: LayoutConstants.textLabel)
                                )
                                .accessibilityLabel("Rank \(rank)")
                            }
                        } else {
                            Text("Not ranked")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                                .accessibilityLabel("You are not currently ranked")
                        }
                        Spacer()
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.spaceSM)
                    .accessibilityElement(children: .combine)
                    .background(DarkFantasyTheme.bgSecondary)
                    .overlay(
                        Rectangle()
                            .fill(DarkFantasyTheme.gold.opacity(0.2))
                            .frame(height: 1),
                        alignment: .bottom
                    )

                    // Content
                    if vm.errorMessage != nil {
                        ErrorStateView.loadFailed { Task { await vm.loadLeaderboard() } }
                    } else if vm.isLoading && vm.currentEntries.isEmpty {
                        LazyVStack(spacing: LayoutConstants.spaceXS) {
                            ForEach(0..<8, id: \.self) { index in
                                SkeletonLeaderboardRow()
                                    .staggeredAppear(index: index)
                            }
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.vertical, LayoutConstants.spaceSM)
                    } else if vm.currentEntries.isEmpty {
                        // TODO: Add error property to LeaderboardViewModel
                        EmptyStateView.leaderboard
                    } else {
                        let tabKey = LeaderboardViewModel.tabKeys[vm.selectedTab]
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: LayoutConstants.spaceXS) {
                                    ForEach(Array(vm.currentEntries.enumerated()), id: \.element.id) { index, entry in
                                        let isMe = entry.characterId == vm.myCharacterId
                                        LeaderboardRowView(
                                            entry: entry,
                                            isSelf: isMe,
                                            valueLabel: tabKey
                                        )
                                        .id(entry.characterId)
                                        .staggeredAppear(index: index)
                                        .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.3, isActive: isMe)
                                    }
                                }
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.vertical, LayoutConstants.spaceSM)
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
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
