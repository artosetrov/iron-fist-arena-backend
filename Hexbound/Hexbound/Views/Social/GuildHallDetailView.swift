import SwiftUI

struct GuildHallDetailView: View {
    /// Deep-link: if set, auto-opens SCROLLS tab with this character's thread
    var openMessageTo: String?
    var messageName: String?
    var messageAvatar: String?
    var messageCharacterClass: String?

    @Environment(AppState.self) var appState
    @Environment(GameDataCache.self) var cache
    @State var vm: GuildHallViewModel?
    /// Received message picked from the context menu for reporting.
    @State var reportedMessage: DirectMessageItem?
    @FocusState var isComposeFieldFocused: Bool

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                // Thread view is full-screen, replaces the tabs entirely
                if vm.selectedTab == .scrolls, vm.activeThreadCharacterId != nil {
                    threadView(vm)
                        .transaction { $0.animation = nil }
                } else if openMessageTo != nil, vm.activeThreadCharacterId == nil {
                    // Deep-link mode: show loading while thread opens (don't flash Guild Hall UI)
                    VStack {
                        Spacer()
                        HexPulseLoader(.compact)
                            .tint(DarkFantasyTheme.gold)
                        Text("Opening conversation...")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .padding(.top, LayoutConstants.spaceSM)
                        Spacer()
                    }
                } else {
                    // The hall scrolls away; the banner tabs pin under the
                    // nav bar (2026-11-04, canvas "A · Зал гильдии").
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            GuildHallHeader()

                            Section {
                                VStack(spacing: LayoutConstants.sectionGap) {
                                    chroniclerLine(vm)
                                        .padding(.horizontal, LayoutConstants.screenPadding)

                                    switch vm.selectedTab {
                                    case .allies: alliesTab(vm)
                                    case .scrolls: scrollsTab(vm)
                                    case .duels: duelsTab(vm)
                                    }

                                    Spacer().frame(height: LayoutConstants.spaceLG)
                                }
                                .padding(.top, LayoutConstants.spaceSM)
                            } header: {
                                bannerTabs(vm)
                                    .padding(.horizontal, LayoutConstants.screenPadding)
                                    .padding(.vertical, LayoutConstants.tabSwitcherPaddingV)
                                    .background(DarkFantasyTheme.bgPrimary)
                            }
                        }
                    }
                    .transaction { $0.animation = nil }
                }
            } else {
                HexPulseLoader(.compact)
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .navigationBarBackButtonHidden(true)
        // Opaque, in the screen's own colour: the hall header scrolls up
        // beneath the bar, and nothing should show through behind the back button.
        .toolbarBackground(DarkFantasyTheme.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(vm?.activeThreadCharacterId != nil ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
        }
        .task {
            guard let charId = appState.currentCharacter?.id else { return }
            // Reuse the view model on re-appear (back from a profile, a duel…)
            // instead of rebuilding it — a fresh VM reset every tab to its
            // loading state and refetched all three lists (latency pass
            // 2026-10-15). The loads below now revalidate in place.
            let viewModel: GuildHallViewModel
            if let existing = vm {
                viewModel = existing
            } else {
                viewModel = GuildHallViewModel(characterId: charId, appState: appState)
                vm = viewModel
            }

            // Deep-link: open message thread instantly (conversations load in background)
            if let targetId = openMessageTo, let targetName = messageName {
                viewModel.selectedTab = .scrolls
                // Open thread immediately — don't wait for conversations to load
                await viewModel.openThread(characterId: targetId, characterName: targetName, avatar: messageAvatar, characterClass: messageCharacterClass)
            } else {
                // Parallel prefetch all tabs for instant switching
                async let friendsTask: () = viewModel.loadFriends()
                async let challengesTask: () = viewModel.loadChallenges()
                async let scrollsTask: () = viewModel.loadConversations()
                async let metTask: () = viewModel.loadMetWarriors(cache: cache)
                _ = await (friendsTask, challengesTask, scrollsTask, metTask)
            }
        }
        .onChange(of: vm?.selectedTab) { _, newTab in
            guard let vm else { return }
            if newTab == .duels, vm.duelsLoadState == .idle {
                Task { await vm.loadChallenges() }
            }
            if newTab == .scrolls, vm.scrollsLoadState == .idle {
                Task { await vm.loadConversations() }
            }
        }
        .onChange(of: vm?.sendMessageError) { _, error in
            if let error {
                appState.showToast(error, type: .error)
                vm?.sendMessageError = nil
            }
        }
        .onChange(of: vm?.actionError) { _, error in
            if let error {
                appState.showToast(error, type: .error)
                vm?.actionError = nil
            }
        }
        // Duel result sheet removed — challenge fights now navigate to CombatDetailView
        // for full combat playback, then CombatResultDetailView shows the outcome.
    }


    // MARK: - Banner tabs & the Chronicler

    func bannerTabs(_ vm: GuildHallViewModel) -> some View {
        let tabs = GuildHallViewModel.Tab.allCases
        return GuildBannerTabs(
            items: tabs.enumerated().map { index, tab in
                GuildBannerTabs.Item(id: index, title: tab.rawValue, emblem: tab.emblem, badge: vm.badgeCount(for: tab))
            },
            selectedIndex: Binding(
                get: { tabs.firstIndex(of: vm.selectedTab) ?? 0 },
                set: { newValue in
                    if tabs.indices.contains(newValue) {
                        vm.selectedTab = tabs[newValue]
                    }
                }
            )
        )
    }

    /// The keeper of the guild roll says one thing about the open tab.
    func chroniclerLine(_ vm: GuildHallViewModel) -> some View {
        NPCSpeechBubble(
            npcName: "The Chronicler",
            message: chroniclerMessage(vm),
            npcImageName: NPCSpeaker.chronicler.face,
            messageId: vm.selectedTab.rawValue,
            typewriterEnabled: false
        )
    }

    func chroniclerMessage(_ vm: GuildHallViewModel) -> String {
        switch vm.selectedTab {
        case .allies:
            let asking = vm.incomingRequests.count
            if asking > 0 {
                return asking == 1
                    ? "A warrior asks to raise a banner with you. Answer below."
                    : "\(asking) warriors ask to raise a banner with you. Answer below."
            }
            if vm.friends.isEmpty {
                if case .error = vm.loadState { return "The roll of banners is lost for a moment. Try again below." }
                if vm.loadState != .loaded { return "Let me find the roll of banners…" }
            }
            let foughtWait = vm.allySuggestions.isEmpty ? "" : " Warriors you fought wait below."
            if vm.friends.isEmpty {
                return vm.allySuggestions.isEmpty
                    ? "No banners in this hall yet. Rivals from the Arena make the best allies."
                    : "No banners in this hall yet.\(foughtWait)"
            }
            return "\(vm.friendCount) of \(vm.maxFriends) banners raised.\(foughtWait)"
        case .scrolls:
            let unread = vm.scrollsBadgeCount
            if unread > 0 {
                return unread == 1 ? "One scroll still sealed. The wax is warm." : "\(unread) scrolls still sealed. The wax is warm."
            }
            return vm.conversations.isEmpty
                ? "No scrolls yet. Any warrior can be written to — ally or rival."
                : "Every letter you have traded, kept under seal."
        case .duels:
            let calls = vm.duelsBadgeCount
            if calls > 0 {
                return calls == 1
                    ? "A challenge is nailed to the door. You have a day to answer."
                    : "\(calls) challenges are nailed to the door. You have a day to answer."
            }
            return "Call out an ally or a rival. The winner takes the rating."
        }
    }

    // MARK: - Helpers

    func characterAvatar(name: String, className: String? = nil, avatar: String? = nil) -> some View {
        Group {
            if let avatar, !avatar.isEmpty {
                AvatarImageView(
                    skinKey: avatar,
                    characterClass: CharacterClass(rawValue: className ?? "warrior") ?? .warrior,
                    size: 40
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: 40, height: 40)

                    Text(String(name.prefix(1)).uppercased())
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
            }
        }
        .frame(width: 40, height: 40)
    }

    func onlineStatusColor(_ status: OnlineStatus) -> Color {
        switch status {
        case .online: DarkFantasyTheme.success
        case .away: DarkFantasyTheme.stamina
        case .offline: DarkFantasyTheme.textTertiary
        }
    }
}

extension GuildHallViewModel.Tab {
    /// The empty-state emblem that rides on the tab's banner.
    var emblem: String {
        switch self {
        case .allies: "empty-allies"
        case .scrolls: "empty-scrolls"
        case .duels: "empty-duels"
        }
    }
}

extension GuildHallViewModel {
    func badgeCount(for tab: Tab) -> Int {
        switch tab {
        case .allies: alliesBadgeCount
        case .scrolls: scrollsBadgeCount
        case .duels: duelsBadgeCount
        }
    }
}
