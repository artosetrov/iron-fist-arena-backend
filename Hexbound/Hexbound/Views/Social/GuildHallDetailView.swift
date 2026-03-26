import SwiftUI

struct GuildHallDetailView: View {
    /// Deep-link: if set, auto-opens SCROLLS tab with this character's thread
    var openMessageTo: String?
    var messageName: String?

    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: GuildHallViewModel?
    @FocusState private var isComposeFieldFocused: Bool

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
                        ProgressView()
                            .tint(DarkFantasyTheme.gold)
                        Text("Opening conversation...")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
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
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(vm?.activeThreadCharacterId != nil ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
        }
        .task {
            guard let charId = appState.currentCharacter?.id else { return }
            let viewModel = GuildHallViewModel(characterId: charId)
            vm = viewModel

            // Deep-link: open message thread directly
            if let targetId = openMessageTo, let targetName = messageName {
                viewModel.selectedTab = .scrolls
                await viewModel.loadConversations()
                await viewModel.openThread(characterId: targetId, characterName: targetName)
            } else {
                // Parallel prefetch all tabs for instant switching
                async let friendsTask: () = viewModel.loadFriends()
                async let challengesTask: () = viewModel.loadChallenges()
                _ = await (friendsTask, challengesTask)
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
        .sheet(isPresented: Binding(
            get: { vm?.showDuelResult ?? false },
            set: { newValue in
                vm?.showDuelResult = newValue
                if !newValue { vm?.duelResult = nil }
            }
        )) {
            if let result = vm?.duelResult {
                duelResultSheet(result)
            }
        }
    }

    // MARK: - Allies Tab

    @ViewBuilder
    private func alliesTab(_ vm: GuildHallViewModel) -> some View {
        // Friend count header
        friendCountHeader(vm)
            .padding(.horizontal, LayoutConstants.screenPadding)

        // Incoming requests section
        if !vm.incomingRequests.isEmpty {
            requestsSection(vm)
                .padding(.horizontal, LayoutConstants.screenPadding)
        }

        // Outgoing requests (collapsed)
        if !vm.outgoingRequests.isEmpty {
            outgoingSection(vm)
                .padding(.horizontal, LayoutConstants.screenPadding)
        }

        // Loading / Error / Empty / Content
        switch vm.loadState {
        case .loading:
            alliesSkeletons
                .padding(.horizontal, LayoutConstants.screenPadding)

        case .error:
            errorPanel(vm)
                .padding(.horizontal, LayoutConstants.screenPadding)

        case .loaded where vm.friends.isEmpty:
            emptyAlliesPanel
                .padding(.horizontal, LayoutConstants.screenPadding)

        case .loaded, .idle:
            // Online friends
            if !vm.onlineFriends.isEmpty {
                OrnamentalSectionHeader(title: "Online", accentColor: DarkFantasyTheme.success)
                    .padding(.horizontal, LayoutConstants.screenPadding)

                ForEach(vm.onlineFriends) { friend in
                    friendRow(friend, vm: vm)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }
            }

            // Offline friends
            if !vm.offlineFriends.isEmpty {
                OrnamentalSectionHeader(title: "Offline", accentColor: DarkFantasyTheme.textTertiary)
                    .padding(.horizontal, LayoutConstants.screenPadding)

                ForEach(vm.offlineFriends) { friend in
                    friendRow(friend, vm: vm)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }
            }
        }
    }

    // MARK: - Friend Count Header

    private func friendCountHeader(_ vm: GuildHallViewModel) -> some View {
        HStack {
            Image(systemName: "person.2.fill")
                .font(.system(size: 14))
                .foregroundStyle(DarkFantasyTheme.gold)

            Text("Allies")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Spacer()

            Text("\(vm.friendCount)/\(vm.maxFriends)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    // MARK: - Incoming Requests

    private func requestsSection(_ vm: GuildHallViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            OrnamentalSectionHeader(title: "Friend Requests", accentColor: DarkFantasyTheme.gold)

            ForEach(vm.incomingRequests) { request in
                requestRow(request, vm: vm)
            }
        }
    }

    private func requestRow(_ request: FriendRequest, vm: GuildHallViewModel) -> some View {
        let isProcessing = vm.processingRequestId == request.friendshipId

        return HStack(spacing: LayoutConstants.spaceSM) {
            // Avatar placeholder
            characterAvatar(name: request.characterName, className: request.characterClass, avatar: request.avatar)

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(request.characterName)
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Lv.\(request.level)")
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text("·")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text(request.classEnum.rawValue.capitalized)
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }

            Spacer()

            // Action buttons
            if isProcessing {
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
            } else {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Button {
                        Task { await vm.acceptRequest(request) }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.textOnGold)
                            .frame(width: 36, height: 36)
                            .background(DarkFantasyTheme.success)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    }
                    .accessibilityLabel("Accept \(request.characterName)")

                    Button {
                        Task { await vm.declineRequest(request) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(DarkFantasyTheme.bgTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    }
                    .accessibilityLabel("Decline \(request.characterName)")
                }
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    // MARK: - Outgoing Requests

    private func outgoingSection(_ vm: GuildHallViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            OrnamentalSectionHeader(title: "Sent Requests", accentColor: DarkFantasyTheme.textTertiary)

            ForEach(vm.outgoingRequests) { request in
                HStack(spacing: LayoutConstants.spaceSM) {
                    characterAvatar(name: request.characterName, className: request.characterClass, avatar: request.avatar)

                    VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                        Text(request.characterName)
                            .font(DarkFantasyTheme.section(size: 14))
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .lineLimit(1)

                        Text("Pending...")
                            .font(DarkFantasyTheme.body(size: 12))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "hourglass")
                        .font(.system(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .padding(LayoutConstants.spaceSM)
                .background(
                    RadialGlowBackground(
                        baseColor: DarkFantasyTheme.bgSecondary,
                        glowColor: DarkFantasyTheme.bgTertiary,
                        glowIntensity: 0.3,
                        cornerRadius: LayoutConstants.cardRadius
                    )
                )
                .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
                .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.1))
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
            }
        }
    }

    // MARK: - Friend Row

    private func friendRow(_ friend: FriendEntry, vm: GuildHallViewModel) -> some View {
        let isProcessing = vm.processingFriendId == friend.id

        return HStack(spacing: LayoutConstants.spaceSM) {
            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                characterAvatar(name: friend.characterName, className: friend.characterClass, avatar: friend.avatar)

                // Online status dot
                Circle()
                    .fill(onlineStatusColor(friend.onlineStatus))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(DarkFantasyTheme.bgSecondary, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(friend.characterName)
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    Text(friend.rankName)
                        .font(DarkFantasyTheme.body(size: 10))
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                        .padding(.vertical, 2)
                        .background(DarkFantasyTheme.gold.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Lv.\(friend.level)")
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text("·")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text(friend.classEnum.rawValue.capitalized)
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    if let lastSeen = friend.lastSeenText, friend.onlineStatus == .offline {
                        Text("·")
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Text(lastSeen)
                            .font(DarkFantasyTheme.body(size: 11))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Actions
            if isProcessing {
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
            } else {
                Menu {
                    Button {
                        Task {
                            let success = await vm.sendChallenge(targetId: friend.id)
                            if success {
                                appState.showToast(
                                    "Challenge Sent",
                                    subtitle: "\(friend.characterName) has 24h to respond",
                                    type: .info
                                )
                            } else {
                                appState.showToast(
                                    "Challenge Failed",
                                    subtitle: "Could not send challenge",
                                    type: .error
                                )
                            }
                        }
                    } label: {
                        Label("Challenge", systemImage: "flame.fill")
                    }

                    Button {
                        // TODO: Message — Phase 2
                    } label: {
                        Label("Send Scroll", systemImage: "bubble.left.fill")
                    }

                    Divider()

                    Button(role: .destructive) {
                        Task { await vm.removeFriend(friend) }
                    } label: {
                        Label("Remove Ally", systemImage: "person.badge.minus")
                    }

                    Button(role: .destructive) {
                        Task { await vm.blockUser(friend.id) }
                    } label: {
                        Label("Block", systemImage: "hand.raised.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(DarkFantasyTheme.bgTertiary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                }
                .accessibilityLabel("Actions for \(friend.characterName)")
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    // MARK: - Empty & Error States

    private var emptyAlliesPanel: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text("No Allies Yet")
                .font(DarkFantasyTheme.section(size: 16))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Find warriors on the Leaderboard and send them an ally request.")
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutConstants.spaceLG)

            Button {
                appState.mainPath.append(AppRoute.leaderboard)
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "trophy.fill")
                    Text("Go to Leaderboard")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, LayoutConstants.spaceLG)
        }
        .padding(.vertical, LayoutConstants.spaceXL)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 14, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    private func errorPanel(_ vm: GuildHallViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(DarkFantasyTheme.danger)

            Text("Failed to load allies")
                .font(DarkFantasyTheme.section(size: 14))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Button {
                Task { await vm.loadFriends() }
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
            .padding(.horizontal, LayoutConstants.spaceLG)
        }
        .padding(.vertical, LayoutConstants.spaceLG)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.danger.opacity(0.08))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    // MARK: - Skeletons

    private var alliesSkeletons: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: LayoutConstants.spaceSM) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.bgTertiary)
                            .frame(width: 120, height: 14)
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.bgTertiary)
                            .frame(width: 80, height: 12)
                    }

                    Spacer()
                }
                .padding(LayoutConstants.spaceSM)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .shimmer()
            }
        }
    }

    // MARK: - Scrolls Tab (Messages)

    @ViewBuilder
    private func scrollsTab(_ vm: GuildHallViewModel) -> some View {
        if vm.activeThreadCharacterId != nil {
            threadView(vm)
        } else {
            conversationsList(vm)
        }
    }

    @ViewBuilder
    private func conversationsList(_ vm: GuildHallViewModel) -> some View {
        switch vm.scrollsLoadState {
        case .idle, .loading:
            VStack(spacing: LayoutConstants.spaceMD) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                        .frame(height: 70)
                        .shimmer()
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

        case .error:
            VStack(spacing: LayoutConstants.spaceMD) {
                ErrorStateView(
                    message: "Failed to load scrolls",
                    retryAction: { Task { await vm.loadConversations() } }
                )
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

        case .loaded:
            if vm.conversations.isEmpty {
                scrollsEmptyState
            } else {
                ForEach(vm.conversations) { convo in
                    conversationRow(convo, vm: vm)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }
            }
        }
    }

    private func conversationRow(_ convo: Conversation, vm: GuildHallViewModel) -> some View {
        let hasUnread = convo.unreadCount > 0

        return Button {
            Task {
                await vm.openThread(
                    characterId: convo.otherCharacter.id,
                    characterName: convo.otherCharacter.characterName
                )
            }
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                // Avatar
                characterAvatar(
                    name: convo.otherCharacter.characterName,
                    className: convo.otherCharacter.characterClass
                )

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(convo.otherCharacter.characterName)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        if hasUnread {
                            Text("\(convo.unreadCount)")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                                .foregroundStyle(DarkFantasyTheme.textOnGold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DarkFantasyTheme.gold)
                                .clipShape(Capsule())
                        }
                    }

                    Text(convo.lastMessage.content)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(hasUnread ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: hasUnread ? DarkFantasyTheme.gold.opacity(0.04) : DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: (hasUnread ? DarkFantasyTheme.gold : DarkFantasyTheme.borderMedium).opacity(hasUnread ? 0.1 : 0.15))
            .cornerBrackets(color: (hasUnread ? DarkFantasyTheme.gold : DarkFantasyTheme.borderMedium).opacity(0.3), length: 10, thickness: 1)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var scrollsEmptyState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "scroll.fill")
                .font(.system(size: 40))
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text("No Scrolls Yet")
                .font(DarkFantasyTheme.section(size: 16))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Send a message to an ally from their profile.")
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, LayoutConstants.space2XL)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Thread View (ChatGPT-style)

    @ViewBuilder
    private func threadView(_ vm: GuildHallViewModel) -> some View {
        VStack(spacing: 0) {
            // Thread header — sticky top bar
            threadHeader(vm)

            // Messages list — reversed scroll (newest at bottom)
            switch vm.threadLoadState {
            case .idle, .loading:
                Spacer()
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
                Spacer()

            case .error:
                Spacer()
                VStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(DarkFantasyTheme.danger)
                    Text("Failed to load messages")
                        .font(DarkFantasyTheme.body(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Button("Retry") {
                        if let targetId = vm.activeThreadCharacterId,
                           let name = vm.activeThreadCharacterName {
                            Task { await vm.openThread(characterId: targetId, characterName: name) }
                        }
                    }
                    .buttonStyle(.primary)
                }
                Spacer()

            case .loaded:
                if vm.activeThread.isEmpty {
                    Spacer()
                    threadEmptyState
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                // Date divider
                                dateDivider("Today")

                                ForEach(vm.activeThread.reversed()) { msg in
                                    messageBubble(msg, vm: vm)
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.top, LayoutConstants.spaceSM)
                            .padding(.bottom, LayoutConstants.spaceSM)
                        }
                        .defaultScrollAnchor(.bottom)
                    }
                }
            }

            // Quick replies — sticky above compose bar
            quickReplyChips(vm)

            // Compose bar — sticky bottom
            threadBottomBar(vm)
        }
        .onAppear {
            // Auto-focus compose field with short delay for keyboard animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isComposeFieldFocused = true
            }
            // Start polling for new incoming messages every 5 seconds
            vm.startThreadPolling()
        }
        .onDisappear {
            vm.stopThreadPolling()
        }
    }

    private func threadHeader(_ vm: GuildHallViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Back button — ornamental
            Button {
                if openMessageTo != nil {
                    if !appState.mainPath.isEmpty {
                        appState.mainPath.removeLast()
                    }
                } else {
                    vm.closeThread()
                }
            } label: {
                Image("ui-arrow-left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .fill(DarkFantasyTheme.bgTertiary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
            }

            // Character avatar — 44px with gold-dim border + online dot
            ZStack(alignment: .bottomTrailing) {
                if let avatar = vm.activeThreadCharacterAvatar {
                    AvatarImageView(
                        skinKey: avatar,
                        characterClass: CharacterClass(rawValue: vm.activeThreadCharacterClass ?? "warrior") ?? .warrior,
                        size: 44
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM + 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM + 2)
                            .stroke(DarkFantasyTheme.goldDim, lineWidth: 2)
                    )
                } else {
                    characterAvatar(
                        name: vm.activeThreadCharacterName ?? "?",
                        className: nil
                    )
                }

                // Online indicator
                Circle()
                    .fill(DarkFantasyTheme.success)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(DarkFantasyTheme.bgSecondary, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }

            // Name + status
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.activeThreadCharacterName ?? "Unknown")
                    .font(DarkFantasyTheme.section(size: 18))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            // Challenge action button
            if let targetId = vm.activeThreadCharacterId {
                Button {
                    Task {
                        HapticManager.medium()
                        _ = await vm.sendChallenge(targetId: targetId)
                    }
                } label: {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .fill(DarkFantasyTheme.bgTertiary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .stroke(DarkFantasyTheme.goldDim.opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            LinearGradient(
                colors: [DarkFantasyTheme.bgTertiary.opacity(0.95), DarkFantasyTheme.bgSecondary.opacity(0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            // Surface lighting — top highlight
            Rectangle()
                .fill(LinearGradient(colors: [Color.white.opacity(0.04), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 24)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            // Gold divider line
            Rectangle()
                .fill(LinearGradient(colors: [.clear, DarkFantasyTheme.goldDim, .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
        }
    }

    private var threadEmptyState: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.5))

            Text("Start the conversation")
                .font(DarkFantasyTheme.section(size: 15))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Text("Send a quick message or write your own scroll.")
                .font(DarkFantasyTheme.body(size: 13))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, LayoutConstants.space2XL)
    }

    private func messageBubble(_ msg: DirectMessageItem, vm: GuildHallViewModel) -> some View {
        let isMine = msg.senderId == appState.currentCharacter?.id

        return HStack(alignment: .bottom, spacing: LayoutConstants.spaceXS) {
            if isMine { Spacer(minLength: 48) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(msg.content)
                    .font(DarkFantasyTheme.body(size: 16))
                    .foregroundStyle(isMine ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textPrimary)

                // Timestamp + read status
                HStack(spacing: 4) {
                    Text(formatMessageTime(msg.createdAt))
                        .font(DarkFantasyTheme.body(size: 11))
                        .foregroundStyle(isMine
                            ? DarkFantasyTheme.textOnGold.opacity(0.5)
                            : DarkFantasyTheme.textTertiary
                        )

                    if isMine {
                        Image(systemName: msg.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(msg.isRead
                                ? DarkFantasyTheme.textOnGold.opacity(0.7)
                                : DarkFantasyTheme.textOnGold.opacity(0.4)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                if isMine {
                    ChatBubbleShape(isMine: true)
                        .fill(
                            LinearGradient(
                                colors: [DarkFantasyTheme.gold, DarkFantasyTheme.goldDim],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            // Surface lighting on gold bubble
                            ChatBubbleShape(isMine: true)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.08), .clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        }
                } else {
                    ChatBubbleShape(isMine: false)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay {
                            // Inner bevel on received bubble
                            ChatBubbleShape(isMine: false)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.03), .clear, Color.black.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .overlay {
                            ChatBubbleShape(isMine: false)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        }
                }
            }
            .shadow(color: isMine ? DarkFantasyTheme.gold.opacity(0.12) : Color.clear, radius: 6)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)

            if !isMine { Spacer(minLength: 48) }
        }
    }

    // MARK: - Date Divider

    private func dateDivider(_ text: String) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.borderSubtle],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text(text.uppercased())
                .font(DarkFantasyTheme.body(size: 11))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1.5)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.borderSubtle, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    // MARK: - Quick Reply Chips

    private func quickReplyChips(_ vm: GuildHallViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(QuickMessage.allCases, id: \.rawValue) { quick in
                    Button {
                        Task { await vm.sendQuickMessage(quick.rawValue) }
                    } label: {
                        Text(quick.displayText)
                            .font(DarkFantasyTheme.section(size: 13))
                            .foregroundStyle(DarkFantasyTheme.gold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(DarkFantasyTheme.bgTertiary)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(DarkFantasyTheme.goldDim, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isSendingMessage)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
        }
        .background(DarkFantasyTheme.bgSecondary)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle.opacity(0.3))
                .frame(height: 0.5)
        }
    }

    private func threadBottomBar(_ vm: GuildHallViewModel) -> some View {
        let isEmpty = vm.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return HStack(spacing: LayoutConstants.spaceSM) {
            TextField("Write a scroll...", text: Binding(
                get: { vm.composedMessage },
                set: { vm.composedMessage = $0 }
            ))
            .focused($isComposeFieldFocused)
            .font(DarkFantasyTheme.body(size: 16))
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.bgTertiary)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isComposeFieldFocused ? DarkFantasyTheme.goldDim.opacity(0.6) : DarkFantasyTheme.borderSubtle.opacity(0.5),
                        lineWidth: 1
                    )
            )

            Button {
                Task { await vm.sendMessage() }
            } label: {
                ZStack {
                    if vm.isSendingMessage {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(
                                isEmpty ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.textOnGold
                            )
                    }
                }
                .frame(width: 44, height: 44)
                .background {
                    if isEmpty {
                        Circle()
                            .fill(DarkFantasyTheme.bgTertiary)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DarkFantasyTheme.gold, DarkFantasyTheme.goldDim],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .shadow(color: isEmpty ? .clear : DarkFantasyTheme.gold.opacity(0.25), radius: 8)
            }
            .disabled(vm.isSendingMessage || isEmpty)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceLG)
        .background(DarkFantasyTheme.bgSecondary.opacity(0.95))
    }

    private func formatMessageTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString) else { return "" }
        let elapsed = Date().timeIntervalSince(date)
        if elapsed < 60 { return "Just now" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m ago" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))h ago" }
        return "\(Int(elapsed / 86400))d ago"
    }

    // MARK: - Duels Tab

    @ViewBuilder
    private func duelsTab(_ vm: GuildHallViewModel) -> some View {
        switch vm.duelsLoadState {
        case .idle, .loading:
            VStack(spacing: LayoutConstants.spaceMD) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                        .frame(height: 80)
                        .shimmer()
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

        case .error:
            VStack(spacing: LayoutConstants.spaceMD) {
                ErrorStateView(
                    message: "Failed to load duels",
                    retryAction: { Task { await vm.loadChallenges() } }
                )
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

        case .loaded:
            if vm.incomingChallenges.isEmpty && vm.outgoingChallenges.isEmpty && vm.completedChallenges.isEmpty {
                duelsEmptyState
            } else {
                duelsContent(vm)
            }
        }
    }

    @ViewBuilder
    private func duelsContent(_ vm: GuildHallViewModel) -> some View {
        // Incoming challenges
        if !vm.incomingChallenges.isEmpty {
            sectionLabel("INCOMING CHALLENGES", count: vm.incomingChallenges.count)
                .padding(.horizontal, LayoutConstants.screenPadding)

            ForEach(vm.incomingChallenges) { challenge in
                incomingChallengeCard(challenge, vm: vm)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }

        // Outgoing challenges
        if !vm.outgoingChallenges.isEmpty {
            sectionLabel("SENT CHALLENGES", count: vm.outgoingChallenges.count)
                .padding(.horizontal, LayoutConstants.screenPadding)

            ForEach(vm.outgoingChallenges) { challenge in
                outgoingChallengeCard(challenge)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }

        // Completed duels
        if !vm.completedChallenges.isEmpty {
            GoldDivider()
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceSM)

            sectionLabel("RECENT DUELS", count: vm.completedChallenges.count)
                .padding(.horizontal, LayoutConstants.screenPadding)

            ForEach(vm.completedChallenges) { challenge in
                completedChallengeCard(challenge)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    private func sectionLabel(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)
            Spacer()
            Text("\(count)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.goldDim)
        }
    }

    // MARK: - Challenge Cards

    private func incomingChallengeCard(_ challenge: IncomingChallenge, vm: GuildHallViewModel) -> some View {
        let isProcessing = vm.processingChallengeId == challenge.id

        return HStack(spacing: LayoutConstants.spaceSM) {
            // Challenger avatar
            characterAvatar(
                name: challenge.challenger.characterName,
                className: challenge.challenger.characterClass
            )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.challenger.characterName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Lv.\(challenge.challenger.level)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    let rank = PvPRank.fromRating(challenge.challenger.pvpRating)
                    Image(systemName: rank.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(rank.color)
                    Text("\(challenge.challenger.pvpRating)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(rank.color)
                }

                if let msg = challenge.message {
                    Text("\"\(msg)\"")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                        .italic()
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            // Accept / Decline buttons
            VStack(spacing: 4) {
                Button {
                    Task { await vm.acceptChallenge(challenge) }
                } label: {
                    if isProcessing {
                        ProgressView().tint(DarkFantasyTheme.textOnGold).scaleEffect(0.7)
                    } else {
                        Image(systemName: "swords")
                        Text("Fight")
                    }
                }
                .buttonStyle(.compactPrimary)
                .disabled(isProcessing)

                Button {
                    Task { await vm.declineChallenge(challenge) }
                } label: {
                    Text("Decline")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .disabled(isProcessing)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.danger.opacity(0.05),
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.danger.opacity(0.08))
        .cornerBrackets(color: DarkFantasyTheme.danger.opacity(0.3), length: 14, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    private func outgoingChallengeCard(_ challenge: OutgoingChallenge) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            characterAvatar(
                name: challenge.defender.characterName,
                className: challenge.defender.characterClass
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.defender.characterName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Lv.\(challenge.defender.level)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text(challenge.status.capitalized)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(statusColor(challenge.status))
                }
            }

            Spacer()

            // Status icon
            Image(systemName: statusIcon(challenge.status))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(statusColor(challenge.status))
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.1))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    private func completedChallengeCard(_ challenge: CompletedChallenge) -> some View {
        let myId = appState.currentCharacter?.id
        let didWin = challenge.winnerId == myId
        let opponentName = challenge.challenger.id == myId
            ? challenge.defender.characterName
            : challenge.challenger.characterName
        let accentColor = didWin ? DarkFantasyTheme.success : DarkFantasyTheme.danger

        return HStack(spacing: LayoutConstants.spaceSM) {
            // Win/Loss indicator
            Image(systemName: didWin ? "trophy.fill" : "xmark.shield.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(didWin ? "Victory vs \(opponentName)" : "Defeat vs \(opponentName)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: LayoutConstants.spaceSM) {
                    HStack(spacing: 2) {
                        Image("icon-gold")
                            .resizable()
                            .frame(width: 12, height: 12)
                        Text("+\(challenge.goldReward)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }
                    HStack(spacing: 2) {
                        Text("+\(challenge.xpReward) XP")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.cyan)
                    }
                }
            }

            Spacer()
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: accentColor.opacity(0.04),
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: accentColor.opacity(0.08))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    private var duelsEmptyState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "swords")
                .font(.system(size: 40))
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text("No Duels Yet")
                .font(DarkFantasyTheme.section(size: 16))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Challenge opponents from the Arena or Leaderboard.")
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                appState.mainPath.append(AppRoute.arena)
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "figure.fencing")
                    Text("Go to Arena")
                }
            }
            .buttonStyle(.secondary)
            .frame(width: 200)
        }
        .padding(.vertical, LayoutConstants.space2XL)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Challenge Status Helpers

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending": return DarkFantasyTheme.stamina
        case "accepted", "completed": return DarkFantasyTheme.success
        case "declined": return DarkFantasyTheme.danger
        case "expired": return DarkFantasyTheme.textDisabled
        default: return DarkFantasyTheme.textTertiary
        }
    }

    private func statusIcon(_ status: String) -> String {
        switch status {
        case "pending": return "hourglass"
        case "accepted", "completed": return "checkmark.circle.fill"
        case "declined": return "xmark.circle.fill"
        case "expired": return "clock.badge.xmark"
        default: return "questionmark.circle"
        }
    }

    private func comingSoonPlaceholder(_ feature: String) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "scroll.fill")
                .font(.system(size: 40))
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text("\(feature) — Coming Soon")
                .font(DarkFantasyTheme.section(size: 16))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("This feature is being forged in the depths.")
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, LayoutConstants.space2XL)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Duel Result Sheet

    private func duelResultSheet(_ result: DuelResult) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Spacer().frame(height: LayoutConstants.spaceLG)

            // Trophy / Skull icon
            Image(systemName: result.won ? "trophy.fill" : "xmark.shield.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(result.won ? DarkFantasyTheme.gold : DarkFantasyTheme.danger)
                .shadow(color: (result.won ? DarkFantasyTheme.gold : DarkFantasyTheme.danger).opacity(0.4), radius: 12)

            Text(result.won ? "VICTORY" : "DEFEAT")
                .font(DarkFantasyTheme.title(size: 28))
                .foregroundStyle(result.won ? DarkFantasyTheme.gold : DarkFantasyTheme.danger)
                .tracking(4)

            GoldDivider()

            // Opponent info
            Text("vs \(result.won ? result.defenderName : result.challengerName)")
                .font(DarkFantasyTheme.section(size: 16))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Rewards panel
            VStack(spacing: LayoutConstants.spaceSM) {
                // Rating change
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(DarkFantasyTheme.gold)
                    Text("Rating")
                        .font(DarkFantasyTheme.body(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Spacer()
                    Text("\(result.ratingBefore) → \(result.ratingAfter)")
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Text("(\(result.ratingChange > 0 ? "+" : "")\(result.ratingChange))")
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(result.ratingChange >= 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
                }

                // Gold reward
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image("icon-gold")
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("Gold")
                        .font(DarkFantasyTheme.body(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Spacer()
                    Text("+\(result.goldReward)")
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }

                // XP reward
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(DarkFantasyTheme.cyan)
                    Text("XP")
                        .font(DarkFantasyTheme.body(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Spacer()
                    Text("+\(result.xpReward)")
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
            }
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: (result.won ? DarkFantasyTheme.gold : DarkFantasyTheme.danger).opacity(0.1))
            .cornerBrackets(color: (result.won ? DarkFantasyTheme.gold : DarkFantasyTheme.danger).opacity(0.3), length: 14, thickness: 1.5)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
            .padding(.horizontal, LayoutConstants.screenPadding)

            Spacer()

            Button {
                vm?.showDuelResult = false
                vm?.duelResult = nil
                // Reload challenges to reflect new state
                Task { await vm?.loadChallenges() }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(DarkFantasyTheme.bgPrimary)
    }

    // MARK: - Helpers

    private func characterAvatar(name: String, className: String? = nil, avatar: String? = nil) -> some View {
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
                        .font(DarkFantasyTheme.section(size: 16))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
            }
        }
        .frame(width: 40, height: 40)
    }

    private func onlineStatusColor(_ status: OnlineStatus) -> Color {
        switch status {
        case .online: DarkFantasyTheme.success
        case .away: DarkFantasyTheme.stamina
        case .offline: DarkFantasyTheme.textTertiary
        }
    }
}

// MARK: - Chat Bubble Shape

/// A rounded rectangle with a small tail on the bottom-left or bottom-right,
/// similar to iMessage / ChatGPT message bubbles.
struct ChatBubbleShape: Shape {
    let isMine: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6

        var path = Path()

        if isMine {
            // Tail on bottom-right
            path.addRoundedRect(
                in: CGRect(x: rect.minX, y: rect.minY, width: rect.width - tailSize / 2, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
            // Tail
            path.move(to: CGPoint(x: rect.maxX - tailSize - radius / 2, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control1: CGPoint(x: rect.maxX - tailSize + 2, y: rect.maxY),
                control2: CGPoint(x: rect.maxX - 2, y: rect.maxY + tailSize / 2)
            )
            path.addCurve(
                to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - 4),
                control1: CGPoint(x: rect.maxX, y: rect.maxY - 2),
                control2: CGPoint(x: rect.maxX - tailSize + 2, y: rect.maxY - 2)
            )
        } else {
            // Tail on bottom-left
            path.addRoundedRect(
                in: CGRect(x: rect.minX + tailSize / 2, y: rect.minY, width: rect.width - tailSize / 2, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
            // Tail
            path.move(to: CGPoint(x: rect.minX + tailSize + radius / 2, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY),
                control1: CGPoint(x: rect.minX + tailSize - 2, y: rect.maxY),
                control2: CGPoint(x: rect.minX + 2, y: rect.maxY + tailSize / 2)
            )
            path.addCurve(
                to: CGPoint(x: rect.minX + tailSize, y: rect.maxY - 4),
                control1: CGPoint(x: rect.minX, y: rect.maxY - 2),
                control2: CGPoint(x: rect.minX + tailSize - 2, y: rect.maxY - 2)
            )
        }

        return path
    }
}
