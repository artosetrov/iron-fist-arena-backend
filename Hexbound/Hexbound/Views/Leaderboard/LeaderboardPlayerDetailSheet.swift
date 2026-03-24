import SwiftUI

/// Full opponent profile sheet shown when tapping a leaderboard entry.
/// Fetches complete profile data (stats, equipment, PvP record) and displays
/// a rich card with action buttons (Challenge, Message, Add Friend).
struct LeaderboardPlayerDetailSheet: View {
    let entry: LeaderboardEntry
    let playerCharacter: Character
    let onMessage: () -> Void
    let onAddFriend: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(GameDataCache.self) private var cache
    @Environment(AppState.self) private var appState

    @State private var profile: OpponentProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var friendshipState: FriendshipButtonState = .none
    @State private var isFriendActionLoading = false
    @State private var isSendingChallenge = false
    @State private var challengeSent = false
    @State private var challengeError: String?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if isLoading {
                loadingState
            } else if let error = errorMessage {
                errorState(error)
            } else if let profile {
                profileContent(profile)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DarkFantasyTheme.bgPrimary)
        .presentationCornerRadius(20)
        .task {
            await loadProfile()
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            ProgressView()
                .tint(DarkFantasyTheme.gold)
                .scaleEffect(1.2)
            Text("Loading profile...")
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(DarkFantasyTheme.danger)

            Text(message)
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await loadProfile() }
            }
            .buttonStyle(.primary)
        }
        .padding(LayoutConstants.screenPadding)
    }

    // MARK: - Profile Content

    private func profileContent(_ profile: OpponentProfile) -> some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceMD) {
                // Integrated portrait + equipment card (same layout as hero page)
                OpponentIntegratedCard(profile: profile)

                // PvP Section
                pvpSection(profile)

                // Base Stats
                baseStatsSection(profile)

                // Derived Stats
                derivedStatsSection(profile)

                // Action Buttons
                actionButtons

                Spacer(minLength: LayoutConstants.spaceLG)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceMD)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    // MARK: - Portrait (now handled by OpponentIntegratedCard)

    // MARK: - PvP Section

    private func pvpSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("PVP")

            HStack(spacing: 0) {
                pvpStatCell(label: "Rating", value: "\(profile.pvpRating)", color: DarkFantasyTheme.gold)
                pvpDivider
                pvpStatCell(label: "Record", value: "\(profile.pvpWins)W / \(profile.pvpLosses)L", color: DarkFantasyTheme.textPrimary)
                pvpDivider
                pvpStatCell(
                    label: "Win Rate",
                    value: profile.pvpWins + profile.pvpLosses > 0
                        ? String(format: "%.0f%%", profile.winRate * 100)
                        : "—",
                    color: profile.winRate >= 0.5 ? DarkFantasyTheme.success : DarkFantasyTheme.danger
                )
            }
        }
        .padding(LayoutConstants.cardPadding)
        .panelCard()
    }

    private func pvpStatCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.body(size: 11))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(value)
                .font(DarkFantasyTheme.section(size: 15))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var pvpDivider: some View {
        Rectangle()
            .fill(DarkFantasyTheme.borderSubtle)
            .frame(width: 1, height: 36)
    }

    // MARK: - Equipment Section (now handled by OpponentIntegratedCard)

    // MARK: - Base Stats

    private func baseStatsSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("BASE STATS")

            let columns = [
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
            ]

            LazyVGrid(columns: columns, spacing: LayoutConstants.spaceXS) {
                baseStatRow(.strength, value: profile.strength ?? 0)
                baseStatRow(.agility, value: profile.agility ?? 0)
                baseStatRow(.vitality, value: profile.vitality ?? 0)
                baseStatRow(.endurance, value: profile.endurance ?? 0)
                baseStatRow(.intelligence, value: profile.intelligence ?? 0)
                baseStatRow(.wisdom, value: profile.wisdom ?? 0)
                baseStatRow(.luck, value: profile.luck ?? 0)
                baseStatRow(.charisma, value: profile.charisma ?? 0)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .panelCard()
    }

    private func baseStatRow(_ stat: StatType, value: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(stat.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text(stat.fullName)
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            Text("\(value)")
                .font(DarkFantasyTheme.section(size: 14))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
        )
    }

    // MARK: - Derived Stats

    private func derivedStatsSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("DERIVED STATS")

            let columns = [
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
            ]

            LazyVGrid(columns: columns, spacing: LayoutConstants.spaceXS) {
                derivedStatCell(
                    label: "Atk Power",
                    value: "\(profile.attackPower) \(profile.damageTypeName)",
                    color: damageTypeColor(profile.damageTypeName)
                )
                derivedStatCell(label: "Armor", value: "\(profile.armor ?? 0)", color: DarkFantasyTheme.textPrimary)
                derivedStatCell(label: "Magic Resist", value: "\(profile.magicResist ?? 0)", color: DarkFantasyTheme.purple)
                derivedStatCell(
                    label: "Crit Chance",
                    value: String(format: "%.1f%%", profile.critChance),
                    color: DarkFantasyTheme.danger
                )
                derivedStatCell(
                    label: "Dodge",
                    value: String(format: "%.1f%%", profile.dodgeChance),
                    color: DarkFantasyTheme.success
                )
            }
        }
        .padding(LayoutConstants.cardPadding)
        .panelCard()
    }

    private func derivedStatCell(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            Text(value)
                .font(DarkFantasyTheme.section(size: 13))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
        )
    }

    private func damageTypeColor(_ type: String) -> Color {
        switch type {
        case "Magical": DarkFantasyTheme.purple
        case "Poison": DarkFantasyTheme.success
        default: DarkFantasyTheme.danger
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            GoldDivider()

            Button {
                Task { await sendChallenge() }
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    if isSendingChallenge {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else if challengeSent {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Challenge Sent")
                    } else {
                        Image(systemName: "flame.fill")
                        Text("Challenge")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(isSendingChallenge || challengeSent)
            .accessibilityLabel(challengeSent ? "Challenge already sent" : "Challenge opponent to battle")

            HStack(spacing: LayoutConstants.spaceSM) {
                Button(action: onMessage) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "bubble.left.fill")
                        Text("Message")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
                .accessibilityLabel("Send message to opponent")

                friendshipButton
            }
        }
    }

    @ViewBuilder
    private var friendshipButton: some View {
        switch friendshipState {
        case .none:
            Button {
                Task { await sendFriendRequest() }
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    if isFriendActionLoading {
                        ProgressView().tint(DarkFantasyTheme.textPrimary)
                    } else {
                        Image(systemName: "person.badge.plus")
                    }
                    Text("Add Ally")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
            .disabled(isFriendActionLoading)
            .accessibilityLabel("Send ally request")

        case .requestSent:
            Button {} label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "hourglass")
                    Text("Pending")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.neutral)
            .disabled(true)
            .accessibilityLabel("Ally request pending")

        case .requestReceived:
            Button {
                Task { await acceptFriendRequest() }
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    if isFriendActionLoading {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Image(systemName: "checkmark")
                    }
                    Text("Accept")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(isFriendActionLoading)
            .accessibilityLabel("Accept ally request")

        case .friends:
            Button {} label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "person.2.fill")
                    Text("Allies")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.neutral)
            .disabled(true)
            .accessibilityLabel("Already allies")

        case .blocked, .blockedBy:
            Button {} label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "hand.raised.fill")
                    Text("Blocked")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.neutral)
            .disabled(true)

        case .maxReached:
            Button {} label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                    Text("List Full")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.neutral)
            .disabled(true)
        }
    }

    private func sendFriendRequest() async {
        guard let charId = appState.currentCharacter?.id else { return }
        isFriendActionLoading = true
        let success = await SocialService.shared.sendFriendRequest(
            characterId: charId,
            targetId: entry.characterId
        )
        isFriendActionLoading = false
        if success {
            friendshipState = .requestSent
        }
    }

    private func acceptFriendRequest() async {
        guard let charId = appState.currentCharacter?.id else { return }
        isFriendActionLoading = true
        let success = await SocialService.shared.acceptFriendRequest(
            characterId: charId,
            requesterId: entry.characterId
        )
        isFriendActionLoading = false
        if success {
            friendshipState = .friends
        }
    }

    // MARK: - Challenge Action

    private func sendChallenge() async {
        guard let charId = appState.currentCharacter?.id else { return }
        isSendingChallenge = true
        challengeError = nil

        do {
            _ = try await ChallengeService.shared.sendChallenge(
                characterId: charId,
                targetId: entry.characterId,
                message: nil
            )
            challengeSent = true
            SFXManager.shared.play(.uiConfirm)
            appState.showToast(
                "Challenge Sent",
                subtitle: "\(entry.characterName) has 24h to respond",
                type: .info
            )
        } catch {
            appState.showToast(
                "Challenge Failed",
                subtitle: "Could not send challenge. Try again later.",
                type: .error,
                actionLabel: "Retry",
                action: { Task { await sendChallenge() } }
            )
        }
        isSendingChallenge = false
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)
            Spacer()
        }
    }

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: OpponentProfileResponse = try await APIClient.shared.get(
                APIEndpoints.characterProfile(entry.characterId)
            )
            profile = response.profile
        } catch {
            errorMessage = "Failed to load profile"
        }

        isLoading = false

        // Fetch friendship status in background
        if let charId = appState.currentCharacter?.id {
            friendshipState = await SocialService.shared.getFriendshipStatus(
                characterId: charId,
                targetId: entry.characterId
            )
        }
    }
}
