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

                // Action Buttons — right under equipment
                actionButtons

                // PvP Section
                pvpSection(profile)

                GoldDivider()

                // Base Stats (grouped like hero page)
                baseStatsSection(profile)

                GoldDivider()

                // Derived Stats
                derivedStatsSection(profile)

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
            sectionHeader("PVP RECORD")

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
            .padding(LayoutConstants.spaceSM)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary.opacity(0.5),
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.2,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        }
    }

    private func pvpStatCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
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
            // Grouped stats — same layout as hero page STATUS tab
            ForEach(StatGroup.allCases, id: \.self) { group in
                VStack(spacing: LayoutConstants.spaceSM) {
                    statGroupHeader(group.rawValue)

                    ForEach(group.stats, id: \.self) { stat in
                        opponentStatCell(stat, value: profile.statValue(for: stat))
                    }
                }
            }
        }
    }

    /// Read-only stat cell matching HeroDetailView ornamental style (no +/- buttons, no tooltip)
    @ViewBuilder
    private func opponentStatCell(_ stat: StatType, value: Int) -> some View {
        let color = DarkFantasyTheme.statColor(for: stat.rawValue)

        HStack(spacing: LayoutConstants.spaceXS) {
            Image(stat.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            Text(stat.fullName)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text("\(value)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .frame(minWidth: 36, alignment: .trailing)
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(
            cornerRadius: LayoutConstants.panelRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.borderMedium.opacity(0.15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }

    /// Stat group header with ornamental diamond lines — matches HeroDetailView
    @ViewBuilder
    private func statGroupHeader(_ label: String) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, DarkFantasyTheme.goldDim.opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
            }

            Text(label)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.gold.opacity(0.6))
                .lineLimit(1)
                .fixedSize()

            HStack(spacing: 0) {
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.goldDim.opacity(0.4), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
        }
        .padding(.top, LayoutConstants.spaceXS)
    }

    // MARK: - Derived Stats

    private func derivedStatsSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("DERIVED STATS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: LayoutConstants.spaceSM
            ) {
                derivedRow("Atk Power", value: "\(profile.attackPower) \(profile.damageTypeName)", color: DarkFantasyTheme.statBarFill)
                derivedRow("Armor", value: "\(profile.armor ?? 0)", color: DarkFantasyTheme.statBarFill)
                derivedRow("Magic Resist", value: "\(profile.magicResist ?? 0)", color: DarkFantasyTheme.statBarFill)
                derivedRow("Crit Chance", value: String(format: "%.1f%%", profile.critChance), color: DarkFantasyTheme.statBarFill)
                derivedRow("Dodge", value: String(format: "%.1f%%", profile.dodgeChance), color: DarkFantasyTheme.statBarFill)
            }
        }
    }

    /// Derived stat row — matches HeroDetailView exactly
    @ViewBuilder
    private func derivedRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary.opacity(0.5),
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.2,
                cornerRadius: LayoutConstants.radiusSM
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.radiusSM - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
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
        let errorMsg = await SocialService.shared.sendFriendRequest(
            characterId: charId,
            targetId: entry.characterId
        )
        isFriendActionLoading = false
        if errorMsg == nil {
            friendshipState = .requestSent
            HapticManager.success()
            appState.showToast("Ally request sent!", type: .info)
        } else {
            HapticManager.error()
            let reason: String
            switch errorMsg {
            case "Already friends or request pending":
                reason = "Request already pending"
                friendshipState = .requestSent
            case "Friend list full":
                reason = "Your ally list is full (max 50)"
                friendshipState = .maxReached
            case "Cannot send request":
                reason = "This player is unavailable"
            case "Too many requests today":
                reason = "Daily request limit reached (20/day)"
            case "Cooldown active":
                reason = "Wait 24h before sending again"
            default:
                reason = errorMsg ?? "Something went wrong"
            }
            appState.showToast("Can't send request", subtitle: reason, type: .error)
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
        Text(title)
            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading)
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
