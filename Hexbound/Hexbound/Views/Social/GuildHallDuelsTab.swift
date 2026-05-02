import SwiftUI

extension GuildHallDetailView {
    // MARK: - Duels Tab

    @ViewBuilder
    func duelsTab(_ vm: GuildHallViewModel) -> some View {
        switch vm.duelsLoadState {
        case .idle, .loading:
            VStack(spacing: LayoutConstants.spaceMD) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                        .frame(height: 100)
                        .shimmer()
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

        case .error(let msg):
            VStack(spacing: LayoutConstants.spaceMD) {
                ErrorStateView(
                    message: msg,
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
    func duelsContent(_ vm: GuildHallViewModel) -> some View {
        // Incoming challenges (urgent — shown first)
        if !vm.incomingChallenges.isEmpty {
            duelsSectionLabel("INCOMING CHALLENGES", count: vm.incomingChallenges.count)
                .padding(.horizontal, LayoutConstants.screenPadding)

            ForEach(vm.incomingChallenges) { challenge in
                incomingChallengeCard(challenge, vm: vm)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }

        // Outgoing challenges
        if !vm.outgoingChallenges.isEmpty {
            duelsSectionLabel("SENT CHALLENGES", count: vm.outgoingChallenges.count)
                .padding(.horizontal, LayoutConstants.screenPadding)

            // Daily limit counter
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("Pending:")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text("\(vm.pendingOutgoingCount) / 5")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(vm.pendingOutgoingCount >= 5 ? DarkFantasyTheme.danger : DarkFantasyTheme.stamina)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, LayoutConstants.spaceXS)

            ForEach(vm.outgoingChallenges) { challenge in
                outgoingChallengeCard(challenge, vm: vm)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }

        // Completed duels
        if !vm.completedChallenges.isEmpty {
            GoldDivider()
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceSM)

            duelsSectionLabel("RECENT DUELS", count: vm.completedChallenges.count)
                .padding(.horizontal, LayoutConstants.screenPadding)

            ForEach(vm.completedChallenges) { challenge in
                completedChallengeCard(challenge)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    func duelsSectionLabel(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)
            Spacer()
            Text("\(count)")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.goldDim)
        }
    }

    // MARK: - Incoming Challenge Card (full-width buttons + expiry timer)

    func incomingChallengeCard(_ challenge: IncomingChallenge, vm: GuildHallViewModel) -> some View {
        let isProcessing = vm.processingChallengeId == challenge.id
        let expiryText = Self.duelTimeRemaining(from: challenge.expiresAt)

        return VStack(spacing: LayoutConstants.spaceSM) {
            // Top row: avatar + info + expiry badge
            HStack(spacing: LayoutConstants.spaceSM) {
                characterAvatar(
                    name: challenge.challenger.characterName,
                    className: challenge.challenger.characterClass,
                    avatar: challenge.challenger.avatar
                )

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(challenge.challenger.characterName)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)

                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("Lv.\(challenge.challenger.level)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        let rank = PvPRank.fromRating(challenge.challenger.pvpRating)
                        Image(systemName: rank.icon)
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(rank.color)
                        Text("\(challenge.challenger.pvpRating)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(rank.color)
                    }

                    if let msg = challenge.message {
                        Text("\"\(msg)\"")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldDim)
                            .italic()
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                // Expiry timer badge
                if !expiryText.isEmpty {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Circle()
                            .fill(DarkFantasyTheme.stamina)
                            .frame(width: 6, height: 6)
                        Text(expiryText)
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.stamina)
                    }
                }
            }

            // Full-width action buttons
            HStack(spacing: LayoutConstants.spaceSM) {
                Button {
                    Task {
                        if let error = await vm.acceptChallenge(challenge) {
                            appState.showToast(
                                "Duel failed",
                                subtitle: error,
                                type: .error,
                                actionLabel: "Retry"
                            ) {
                                Task { [weak vm] in
                                    if let error = await vm?.acceptChallenge(challenge) {
                                        appState.showToast("Duel failed", subtitle: error, type: .error)
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        if isProcessing {
                            HexPulseLoader(.compact)
                                .tint(DarkFantasyTheme.textOnGold)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "swords")
                            Text("FIGHT")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 36)
                }
                .buttonStyle(.compactPrimary)
                .disabled(isProcessing)

                Button {
                    _ = vm.declineChallenge(challenge)
                } label: {
                    Text("DECLINE")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 36)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(DarkFantasyTheme.danger.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                .stroke(DarkFantasyTheme.danger.opacity(0.12), lineWidth: 1)
                        )
                )
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
        .compositingGroup()
        .cardShadow()
    }

    // MARK: - Outgoing Challenge Card (cancel button + status pill + expiry timer)

    func outgoingChallengeCard(_ challenge: OutgoingChallenge, vm: GuildHallViewModel) -> some View {
        let isPending = challenge.status == "pending"
        let isProcessing = vm.processingChallengeId == challenge.id
        let isDimmed = challenge.status == "declined" || challenge.status == "expired"

        return VStack(spacing: 0) {
            // Main row: avatar + info + status pill
            HStack(spacing: LayoutConstants.spaceSM) {
                characterAvatar(
                    name: challenge.defender.characterName,
                    className: challenge.defender.characterClass,
                    avatar: challenge.defender.avatar
                )
                .opacity(isDimmed ? 0.5 : 1.0)

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(challenge.defender.characterName)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(isDimmed ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textPrimary)

                    Text("Lv.\(challenge.defender.level)")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                Spacer()

                // Status pill
                outgoingStatusPill(challenge.status)
            }

            // Bottom row for pending: timer + cancel button
            if isPending {
                HStack {
                    // Expiry timer (24h from creation)
                    let expiryText = Self.duelTimeRemaining(from: challenge.createdAt, addingHours: 24)
                    if !expiryText.isEmpty {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "clock")
                                .font(DarkFantasyTheme.body.weight(.semibold))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                            Text("Expires in \(expiryText)")
                                .font(DarkFantasyTheme.body.weight(.semibold))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }

                    Spacer()

                    // Cancel button
                    Button {
                        _ = vm.cancelOutgoingChallenge(challenge)
                    } label: {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            if isProcessing {
                                HexPulseLoader(.compact)
                                    .tint(DarkFantasyTheme.danger)
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: "xmark")
                                    .font(DarkFantasyTheme.body.weight(.semibold))
                                Text("CANCEL")
                                    .font(DarkFantasyTheme.body.weight(.semibold))
                                    .tracking(0.5)
                            }
                        }
                        .foregroundStyle(DarkFantasyTheme.danger)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.spaceSM)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .fill(DarkFantasyTheme.danger.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                        .stroke(DarkFantasyTheme.danger.opacity(0.12), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }
                .padding(.top, LayoutConstants.spaceSM)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .opacity(isDimmed ? 0.7 : 1.0)
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
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    /// Status pill for outgoing challenges
    func outgoingStatusPill(_ status: String) -> some View {
        let color = statusColor(status)
        let icon = statusIcon(status)
        let label = status.capitalized

        return HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: icon)
                .font(DarkFantasyTheme.body.weight(.semibold))
            Text(label)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .tracking(0.5)
        }
        .foregroundStyle(color)
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Completed Duel Card (timestamp + circle result icon)

    func completedChallengeCard(_ challenge: CompletedChallenge) -> some View {
        let myId = appState.currentCharacter?.id
        let didWin = challenge.winnerId == myId
        let opponentName = challenge.challenger.id == myId
            ? challenge.defender.characterName
            : challenge.challenger.characterName
        let accentColor = didWin ? DarkFantasyTheme.gold : DarkFantasyTheme.danger

        return HStack(spacing: LayoutConstants.spaceSM) {
            // Circle result icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    )
                Image(systemName: didWin ? "trophy.fill" : "xmark.shield.fill")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(didWin ? "Victory vs \(opponentName)" : "Defeat vs \(opponentName)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: LayoutConstants.spaceSM) {
                    HStack(spacing: LayoutConstants.space2XS) {
                        Image("icon-gold")
                            .resizable()
                            .frame(width: LayoutConstants.iconXS, height: LayoutConstants.iconXS)
                        Text("+\(challenge.goldReward)")
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }
                    HStack(spacing: LayoutConstants.space2XS) {
                        Text("+\(challenge.xpReward) XP")
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.cyan)
                    }
                }

                // Timestamp
                if let completedAt = challenge.completedAt {
                    Text(Self.duelTimeAgo(from: completedAt))
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textDisabled)
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
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    var duelsEmptyState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "swords")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text("No Duels Yet")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Challenge opponents from the Arena or Leaderboard.")
                .font(DarkFantasyTheme.body)
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

    func statusColor(_ status: String) -> Color {
        switch status {
        case "pending": return DarkFantasyTheme.stamina
        case "accepted", "completed": return DarkFantasyTheme.success
        case "declined": return DarkFantasyTheme.danger
        case "expired": return DarkFantasyTheme.textDisabled
        default: return DarkFantasyTheme.textTertiary
        }
    }

    func statusIcon(_ status: String) -> String {
        switch status {
        case "pending": return "hourglass"
        case "accepted", "completed": return "checkmark.circle.fill"
        case "declined": return "xmark.circle.fill"
        case "expired": return "clock.badge.xmark"
        default: return "questionmark.circle"
        }
    }

    // MARK: - Duels Time Helpers

    /// Returns time remaining until expiry, e.g. "18h" or "45m"
    private static func duelTimeRemaining(from isoString: String, addingHours: Int? = nil) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var targetDate: Date?
        targetDate = formatter.date(from: isoString)
        if targetDate == nil {
            formatter.formatOptions = [.withInternetDateTime]
            targetDate = formatter.date(from: isoString)
        }
        guard var date = targetDate else { return "" }
        if let hours = addingHours {
            date = date.addingTimeInterval(TimeInterval(hours * 3600))
        }
        let remaining = Int(date.timeIntervalSinceNow)
        if remaining <= 0 { return "expired" }
        if remaining < 3600 { return "\(remaining / 60)m" }
        return "\(remaining / 3600)h"
    }

    /// Returns time ago string, e.g. "2h ago" or "1d ago"
    private static func duelTimeAgo(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var parsedDate: Date?
        parsedDate = formatter.date(from: isoString)
        if parsedDate == nil {
            formatter.formatOptions = [.withInternetDateTime]
            parsedDate = formatter.date(from: isoString)
        }
        guard let date = parsedDate else { return "" }
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }

    // Duel result sheet removed — challenge fights now use CombatDetailView → CombatResultDetailView flow.

}
