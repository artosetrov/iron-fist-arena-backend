import SwiftUI

extension GuildHallDetailView {
    // MARK: - Allies Tab

    @ViewBuilder
    func alliesTab(_ vm: GuildHallViewModel) -> some View {
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

        case .error(let msg):
            errorPanel(vm, message: msg)
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

    func friendCountHeader(_ vm: GuildHallViewModel) -> some View {
        HStack {
            Image(systemName: "person.2.fill")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.gold)

            Text("Allies")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Spacer()

            Text("\(vm.friendCount)/\(vm.maxFriends)")
                .font(DarkFantasyTheme.body)
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
        .cardShadow()
    }

    // MARK: - Incoming Requests

    func requestsSection(_ vm: GuildHallViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            OrnamentalSectionHeader(title: "Friend Requests", accentColor: DarkFantasyTheme.gold)

            ForEach(vm.incomingRequests) { request in
                requestRow(request, vm: vm)
            }
        }
    }

    func requestRow(_ request: FriendRequest, vm: GuildHallViewModel) -> some View {
        let isProcessing = vm.processingRequestId == request.friendshipId

        return HStack(spacing: LayoutConstants.spaceSM) {
            // Avatar placeholder
            characterAvatar(name: request.characterName, className: request.characterClass, avatar: request.avatar)

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(request.characterName)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Lv.\(request.level)")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text("·")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text(request.classEnum.rawValue.capitalized)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }

            Spacer()

            // Action buttons
            if isProcessing {
                HexPulseLoader(.compact)
                    .tint(DarkFantasyTheme.gold)
            } else {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Button {
                        _ = vm.acceptRequest(request)
                    } label: {
                        Image(systemName: "checkmark")
                            .font(DarkFantasyTheme.body.bold())
                            .foregroundStyle(DarkFantasyTheme.textOnGold)
                            .frame(width: 36, height: 36)
                            .background(DarkFantasyTheme.success)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Accept \(request.characterName)")

                    Button {
                        _ = vm.declineRequest(request)
                    } label: {
                        Image(systemName: "xmark")
                            .font(DarkFantasyTheme.body.bold())
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(DarkFantasyTheme.bgTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    }
                    .buttonStyle(.plain)
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
        .cardShadow()
    }

    // MARK: - Outgoing Requests

    func outgoingSection(_ vm: GuildHallViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            OrnamentalSectionHeader(title: "Sent Requests", accentColor: DarkFantasyTheme.textTertiary)

            ForEach(vm.outgoingRequests) { request in
                HStack(spacing: LayoutConstants.spaceSM) {
                    characterAvatar(name: request.characterName, className: request.characterClass, avatar: request.avatar)

                    VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                        Text(request.characterName)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .lineLimit(1)

                        Text("Pending...")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "hourglass")
                        .font(DarkFantasyTheme.body)
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

    func friendRow(_ friend: FriendEntry, vm: GuildHallViewModel) -> some View {
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
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    Text(friend.rankName)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(DarkFantasyTheme.gold.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Lv.\(friend.level)")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text("·")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text(friend.classEnum.rawValue.capitalized)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    if let lastSeen = friend.lastSeenText, friend.onlineStatus == .offline {
                        Text("·")
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Text(lastSeen)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Actions
            if isProcessing {
                HexPulseLoader(.compact)
                    .tint(DarkFantasyTheme.gold)
            } else {
                Menu {
                    Button {
                        _ = vm.sendChallenge(targetId: friend.id)
                        appState.showToast(
                            "Challenge Sent",
                            subtitle: "\(friend.characterName) has 24h to respond",
                            type: .info
                        )
                    } label: {
                        Label("Challenge", systemImage: "flame.fill")
                    }

                    Button {
                        // TODO: Message — Phase 2
                    } label: {
                        Label("Send Scroll", systemImage: "bubble.left.fill")
                    }

                    Divider() // System menu separator — keep native

                    Button(role: .destructive) {
                        _ = vm.removeFriend(friend)
                    } label: {
                        Label("Remove Ally", systemImage: "person.badge.minus")
                    }

                    Button(role: .destructive) {
                        _ = vm.blockUser(friend.id)
                    } label: {
                        Label("Block", systemImage: "hand.raised.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(DarkFantasyTheme.body.weight(.medium))
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
        .cardShadow()
    }

    // MARK: - Empty & Error States

    var emptyAlliesPanel: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "person.2.slash")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text("No Allies Yet")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Find warriors on the Leaderboard and send them an ally request.")
                .font(DarkFantasyTheme.body)
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
        .cardShadow()
    }

    func errorPanel(_ vm: GuildHallViewModel, message: String = "Failed to load allies") -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "exclamationmark.triangle")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.danger)

            Text(message)
                .font(DarkFantasyTheme.body)
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
        .cardShadow()
    }

    // MARK: - Skeletons

    var alliesSkeletons: some View {
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

}
