import SwiftUI

extension GuildHallDetailView {
    // MARK: - Allies Tab

    @ViewBuilder
    func alliesTab(_ vm: GuildHallViewModel) -> some View {
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
            emptyAllies(vm)

        case .loaded, .idle:
            // Allies as hero cards — online first (the view model sorts).
            VStack(spacing: LayoutConstants.spaceSM) {
                GuildSectionLabel(title: "YOUR ALLIES", trailing: "\(vm.friendCount) / \(vm.maxFriends)")
                LazyVGrid(columns: Self.allyColumns, spacing: LayoutConstants.spaceMD) {
                    ForEach(vm.friends) { friend in
                        allyCard(friend, vm: vm)
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Rivals from the Arena, one tap from a banner.
            if !vm.allySuggestions.isEmpty {
                VStack(spacing: LayoutConstants.spaceSM) {
                    GuildSectionLabel(title: "WARRIORS YOU'VE FOUGHT", trailing: "from the arena", trailingColor: DarkFantasyTheme.textTertiaryAA)
                    ForEach(vm.allySuggestions) { warrior in
                        metWarriorRow(
                            warrior,
                            actionLabel: "Raise banner",
                            isSent: vm.allyRequestSentIds.contains(warrior.id),
                            action: { vm.sendAllyRequest(to: warrior) }
                        )
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }
        }
    }

    static var allyColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.spaceSM, alignment: .top), count: 3)
    }

    // MARK: - Ally Card

    /// The card opens the same actions the old row's ••• menu had.
    @ViewBuilder
    func allyCard(_ friend: FriendEntry, vm: GuildHallViewModel) -> some View {
        if vm.processingFriendId == friend.id {
            AllyHeroCard(friend: friend)
                .opacity(0.5)
                .overlay { HexPulseLoader(.compact).tint(DarkFantasyTheme.gold) }
        } else {
            Menu {
                Button {
                    appState.mainPath.append(
                        AppRoute.characterProfile(characterId: friend.id, characterName: friend.characterName)
                    )
                } label: {
                    Label("View Profile", systemImage: "person.text.rectangle")
                }

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
                    appState.mainPath.append(
                        AppRoute.guildHallMessage(
                            characterId: friend.id,
                            characterName: friend.characterName,
                            avatar: friend.avatar,
                            characterClass: friend.characterClass
                        )
                    )
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
                AllyHeroCard(friend: friend)
            }
            .menuStyle(.button)
            .buttonStyle(GuildPressStyle())
            .menuIndicator(.hidden)
            .accessibilityHint("Opens actions: profile, challenge, scroll, remove")
        }
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

    // MARK: - Empty & Error States

    /// Empty Allies: warriors you've fought, one tap to ask them — or, before
    /// your first Arena fight, the full scene pointing at the Leaderboard.
    @ViewBuilder
    func emptyAllies(_ vm: GuildHallViewModel) -> some View {
        let suggestions = vm.allySuggestions
        if !vm.metWarriorsLoaded {
            alliesSkeletons
                .padding(.horizontal, LayoutConstants.screenPadding)
        } else if suggestions.isEmpty {
            EmptyStateScene(
                art: "empty-allies",
                title: "No allies yet",
                message: "Allies show up here with their online status — write to them or call them to a duel right from this list.",
                actionLabel: "Find Warriors",
                action: { appState.mainPath.append(AppRoute.leaderboard) }
            )
        } else {
            VStack(spacing: LayoutConstants.spaceMD) {
                EmptyStateHeader(
                    art: "empty-allies",
                    title: "No allies yet",
                    message: "Raise a banner with warriors you've fought — you'll see when they're online."
                )

                GuildSectionLabel(title: "WARRIORS YOU'VE FOUGHT", trailing: "from the arena", trailingColor: DarkFantasyTheme.textTertiaryAA)

                ForEach(suggestions) { warrior in
                    metWarriorRow(
                        warrior,
                        actionLabel: "Raise banner",
                        isSent: vm.allyRequestSentIds.contains(warrior.id),
                        action: { vm.sendAllyRequest(to: warrior) }
                    )
                }

                Button {
                    appState.mainPath.append(AppRoute.leaderboard)
                } label: {
                    Text("Find More on the Leaderboard")
                }
                .buttonStyle(.secondary)
                .padding(.top, LayoutConstants.spaceSM)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceSM)
        }
    }

    /// A warrior from your recent fights. The row opens their profile; the
    /// button does the one thing this tab is about (add / challenge).
    func metWarriorRow(
        _ warrior: MetWarrior,
        actionLabel: String,
        isSent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Button {
                appState.mainPath.append(
                    AppRoute.characterProfile(characterId: warrior.id, characterName: warrior.name)
                )
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    HeroFramedPortrait(
                        level: warrior.level,
                        avatar: warrior.avatar,
                        characterClass: warrior.characterClass,
                        showsLevel: false
                    )
                    .frame(width: 42)

                    VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                        Text(warrior.name)
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .lineLimit(1)

                        Text("Lv.\(warrior.level) · \(warrior.lastFight)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(warrior.name), level \(warrior.level), \(warrior.lastFight)")
            .accessibilityHint("Opens their profile")

            Button(action: action) {
                Text(isSent ? "Sent" : actionLabel)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .frame(minWidth: 64, minHeight: LayoutConstants.touchMin - LayoutConstants.spaceSM * 2)
            }
            .buttonStyle(.compactOutline(color: isSent ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.goldBright))
            .disabled(isSent)
            .accessibilityLabel(isSent ? "\(actionLabel) sent to \(warrior.name)" : "\(actionLabel) \(warrior.name)")
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
        .compositingGroup()
        .cardShadow()
    }

    func errorPanel(_ vm: GuildHallViewModel, message: String = "Failed to load allies") -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            EmptyStateArt(asset: "empty-allies", size: 96)
                .opacity(0.7)

            Text(message)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .multilineTextAlignment(.center)

            Button {
                Task { await vm.loadFriends() }
            } label: {
                Text("Retry")
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

    /// Three card-shaped placeholders, the size of the hero cards to come.
    var alliesSkeletons: some View {
        LazyVGrid(columns: Self.allyColumns, spacing: LayoutConstants.spaceMD) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: LayoutConstants.spaceXS) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.bgSecondary)
                        .aspectRatio(HeroFramedPortrait.aspect, contentMode: .fit)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: 72, height: 14)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: 48, height: 12)
                }
                .shimmer()
            }
        }
    }

}
