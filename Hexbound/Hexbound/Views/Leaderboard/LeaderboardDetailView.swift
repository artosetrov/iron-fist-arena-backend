import SwiftUI

struct LeaderboardDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: LeaderboardViewModel?
    @State private var selectedPlayerForDetail: LeaderboardEntry?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    // Screen title
                    OrnamentalTitle("LEADERBOARD", titleSize: LayoutConstants.textSection)
                        .padding(.top, LayoutConstants.spaceSM)

                    // Search bar
                    searchBar(vm: vm)

                    // Tab switcher (hidden during active search)
                    if !vm.isSearchActive {
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

                    }

                    // Content
                    if vm.isSearchActive {
                        searchResultsContent(vm: vm)
                    } else if vm.errorMessage != nil {
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
                        EmptyStateView.leaderboard
                    } else {
                        leaderboardList(vm: vm)
                    }
                }
                .transaction { $0.animation = nil }
            }

        }
        .sheet(item: $selectedPlayerForDetail) { player in
            if let character = appState.currentCharacter {
                LeaderboardPlayerDetailSheet(
                    entry: player,
                    playerCharacter: character,
                    onMessage: {
                        selectedPlayerForDetail = nil
                        appState.mainPath.append(
                            AppRoute.guildHallMessage(
                                characterId: player.characterId,
                                characterName: player.characterName
                            )
                        )
                    },
                    onAddFriend: {
                        selectedPlayerForDetail = nil
                        // TODO: Send friend request
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
        }
        .task {
            if vm == nil { vm = LeaderboardViewModel(appState: appState, cache: cache) }
            await vm?.loadLeaderboard()
        }
    }

    // MARK: - Search Bar

    @ViewBuilder
    private func searchBar(vm: LeaderboardViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .frame(width: 20)

            TextField("", text: Binding(
                get: { vm.searchText },
                set: { vm.searchText = $0 }
            ), prompt: Text("Search by name...")
                .foregroundStyle(DarkFantasyTheme.textTertiary))
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .onChange(of: vm.searchText) {
                    vm.onSearchTextChanged()
                }
                .submitLabel(.search)

            if vm.isSearchActive {
                Button {
                    vm.clearSearch()
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: LayoutConstants.touchMin, height: LayoutConstants.touchMin)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .frame(height: LayoutConstants.inputHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                .stroke(
                    isSearchFocused ? DarkFantasyTheme.goldDim : DarkFantasyTheme.borderSubtle,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    // MARK: - Your Rank Banner

    @ViewBuilder
    private func yourRankBanner(vm: LeaderboardViewModel) -> some View {
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
    }

    // MARK: - Leaderboard List

    @ViewBuilder
    private func leaderboardList(vm: LeaderboardViewModel) -> some View {
        let tabKey = LeaderboardViewModel.tabKeys[vm.selectedTab]
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: LayoutConstants.spaceXS) {
                    ForEach(Array(vm.currentEntries.enumerated()), id: \.element.id) { index, entry in
                        let isMe = entry.characterId == vm.myCharacterId
                        LeaderboardRowView(
                            entry: entry,
                            isSelf: isMe,
                            valueLabel: tabKey,
                            onTap: {
                                selectedPlayerForDetail = entry
                            }
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

    // MARK: - Search Results

    @ViewBuilder
    private func searchResultsContent(vm: LeaderboardViewModel) -> some View {
        let trimmedCount = vm.searchText.trimmingCharacters(in: .whitespaces).count

        if vm.isSearching {
            VStack(spacing: LayoutConstants.spaceMD) {
                Spacer()
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
                Text("Searching...")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Spacer()
            }
        } else if vm.searchError {
            // Fix #4: Error state with retry
            VStack(spacing: LayoutConstants.spaceMD) {
                Spacer()
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(DarkFantasyTheme.danger)
                Text("Search failed")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Button {
                    vm.retrySearch()
                } label: {
                    Text("Retry")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .padding(.horizontal, LayoutConstants.spaceLG)
                        .padding(.vertical, LayoutConstants.spaceSM)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                .stroke(DarkFantasyTheme.gold, lineWidth: 1)
                        )
                }
                .accessibilityLabel("Retry search")
                Spacer()
            }
        } else if vm.searchResults.isEmpty && trimmedCount >= 2 {
            VStack(spacing: LayoutConstants.spaceMD) {
                Spacer()
                Image(systemName: "person.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text("No warriors found")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Text("Try a different name")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Spacer()
            }
        } else if trimmedCount < 2 {
            VStack(spacing: LayoutConstants.spaceMD) {
                Spacer()
                Text("Type at least 2 characters")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: LayoutConstants.spaceXS) {
                    ForEach(Array(vm.searchResults.enumerated()), id: \.element.id) { index, result in
                        searchResultRow(result: result, index: index)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceSM)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Search Result Row

    private let searchAvatarSize: CGFloat = 40

    @ViewBuilder
    private func searchResultRow(result: LeaderboardSearchResult, index: Int) -> some View {
        let isMe = result.characterId == vm?.myCharacterId
        let charClass = CharacterClass(rawValue: result.characterClass) ?? .warrior
        Button {
            guard !isMe else { return }
            selectedPlayerForDetail = result.toLeaderboardEntry()
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                // Portrait (Fix #1/#2 — avatar instead of emoji)
                AvatarImageView(
                    skinKey: result.avatar,
                    characterClass: charClass,
                    size: searchAvatarSize
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(
                            isMe ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle,
                            lineWidth: 1.5
                        )
                )

                // Name + class
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.characterName)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(isMe ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    Text("Lv.\(result.level) • \(result.characterClass.capitalized)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                Spacer()

                // Rating
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(result.rating)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.gold)
                    Text("Rating")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceMS)
            .background(
                RadialGlowBackground(
                    baseColor: isMe ? DarkFantasyTheme.gold.opacity(0.08) : DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .innerBorder(
                cornerRadius: LayoutConstants.cardRadius - 1,
                inset: 1,
                color: isMe ? DarkFantasyTheme.gold.opacity(0.2) : DarkFantasyTheme.borderSubtle.opacity(0.3)
            )
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isMe)
        .staggeredAppear(index: index)
        .accessibilityLabel("\(result.characterName), Level \(result.level) \(result.characterClass), Rating \(result.rating)")
        .accessibilityHint(isMe ? "This is you" : "Tap to view profile")
    }

    // MARK: - Helpers

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
