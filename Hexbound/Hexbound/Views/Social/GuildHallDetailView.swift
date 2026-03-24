import SwiftUI

struct GuildHallDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: GuildHallViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()

            if let vm {
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
                            case .scrolls: comingSoonPlaceholder("Scrolls")
                            case .duels: comingSoonPlaceholder("Duels")
                            }

                            Spacer().frame(height: LayoutConstants.spaceLG)
                        }
                    }
                }
                .transaction { $0.animation = nil }
            } else {
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if !appState.mainPath.isEmpty {
                        appState.mainPath.removeLast()
                    }
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(DarkFantasyTheme.gold)
                }
            }
        }
        .task {
            guard let charId = appState.currentCharacter?.id else { return }
            let viewModel = GuildHallViewModel(characterId: charId)
            vm = viewModel
            await viewModel.loadFriends()
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
            characterAvatar(name: request.characterName, className: request.characterClass)

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
                    characterAvatar(name: request.characterName, className: request.characterClass)

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
                characterAvatar(name: friend.characterName, className: friend.characterClass)

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
                        // TODO: Challenge — Phase 3
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

    // MARK: - Coming Soon Placeholder

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

    // MARK: - Helpers

    private func characterAvatar(name: String, className: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(width: 40, height: 40)

            Text(String(name.prefix(1)).uppercased())
                .font(DarkFantasyTheme.section(size: 16))
                .foregroundStyle(DarkFantasyTheme.gold)
        }
    }

    private func onlineStatusColor(_ status: OnlineStatus) -> Color {
        switch status {
        case .online: DarkFantasyTheme.success
        case .away: DarkFantasyTheme.stamina
        case .offline: DarkFantasyTheme.textTertiary
        }
    }
}
