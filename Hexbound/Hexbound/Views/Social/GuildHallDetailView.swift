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
    @FocusState var isComposeFieldFocused: Bool

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()

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
                    VStack(spacing: 0) {
                        // Screen title — sticky
                        OrnamentalTitle("GUILD HALL", subtitle: "Bonds forged in battle", accentColor: DarkFantasyTheme.gold)
                            .padding(.top, LayoutConstants.spaceXS)
                            .padding(.bottom, LayoutConstants.spaceXS)

                        // Tab Switcher — sticky
                        TabSwitcher(
                            tabs: GuildHallViewModel.Tab.allCases.map(\.rawValue),
                            selectedIndex: Binding(
                                get: { GuildHallViewModel.Tab.allCases.firstIndex(of: vm.selectedTab) ?? 0 },
                                set: { newValue in
                                    vm.selectedTab = GuildHallViewModel.Tab.allCases[newValue]
                                }
                            )
                        )
                        .accessibilityLabel("Guild Hall tabs")
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)

                        // Scrollable content
                        ScrollView {
                            VStack(spacing: LayoutConstants.sectionGap) {
                                switch vm.selectedTab {
                                case .allies: alliesTab(vm)
                                case .scrolls: scrollsTab(vm)
                                case .duels: duelsTab(vm)
                                }

                                Spacer().frame(height: LayoutConstants.spaceLG)
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(vm?.activeThreadCharacterId != nil ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
        }
        .task {
            guard let charId = appState.currentCharacter?.id else { return }
            let viewModel = GuildHallViewModel(characterId: charId, appState: appState)
            vm = viewModel

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
                _ = await (friendsTask, challengesTask, scrollsTask)
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
