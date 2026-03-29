import SwiftUI

struct InboxRowView: View {
    @Environment(AppState.self) private var appState

    let message: MailMessage
    let viewModel: InboxViewModel
    let characterId: String

    @State private var isExpanded = false
    @State private var isClaiming = false
    @State private var isDeleting = false
    @State private var isPressed = false

    // MARK: - Accent color by sender type

    private var accentColor: Color {
        switch message.senderType {
        case "system": return DarkFantasyTheme.gold
        case "admin": return DarkFantasyTheme.purple
        case "arena_result":
            if let bd = message.battleData {
                return bd.isWin ? DarkFantasyTheme.gold : DarkFantasyTheme.danger
            }
            return DarkFantasyTheme.gold
        case "battle_invite":
            if let inv = message.inviteData {
                if inv.isAccepted { return DarkFantasyTheme.success }
                if inv.isDeclined || inv.isExpired { return DarkFantasyTheme.textTertiary }
            }
            return DarkFantasyTheme.orange
        default: return DarkFantasyTheme.goldDim
        }
    }

    private var isSystem: Bool {
        message.senderType == "system" || message.senderType == "admin"
            || message.senderType == "arena_result" || message.senderType == "battle_invite"
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Mail Row Header
            mailHeader
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()

                        if isExpanded && !message.isRead {
                            viewModel.markAsRead(
                                messageId: message.id, characterId: characterId)
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                    isPressed = pressing
                }, perform: {})

            // MARK: - Expanded Content
            if isExpanded {
                expandedContent
            }
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: isExpanded
                    ? accentColor.opacity(0.06) : DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(
            cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2, inset: 2,
            color: message.isRead
                ? DarkFantasyTheme.borderMedium.opacity(0.15)
                : accentColor.opacity(0.12)
        )
        .cornerBrackets(
            color: (message.isRead ? DarkFantasyTheme.borderMedium : accentColor).opacity(0.3),
            length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        .brightness(isPressed ? -0.06 : 0)
    }

    // MARK: - Mail Header

    private var mailHeader: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Sender icon
            senderIcon

            // Title + sender + timestamp
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                // Subject line
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(message.subject)
                        .font(
                            DarkFantasyTheme.section(
                                size: message.isRead
                                    ? LayoutConstants.textBody : LayoutConstants.textCard)
                        )
                        .foregroundStyle(
                            message.isRead
                                ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    // Battle result: rating change badge
                    if let battle = message.battleData {
                        Text("\(battle.ratingChange > 0 ? "+" : "")\(battle.ratingChange)")
                            .font(DarkFantasyTheme.section(size: 11))
                            .foregroundStyle(battle.ratingChange >= 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(DarkFantasyTheme.bgTertiary)
                                    .overlay(
                                        Capsule()
                                            .stroke((battle.ratingChange >= 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger).opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                    }

                    // Battle invite: status badge
                    if let invite = message.inviteData {
                        Text(invite.status.uppercased())
                            .font(DarkFantasyTheme.section(size: 11))
                            .foregroundStyle(inviteStatusColor(invite.status))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(DarkFantasyTheme.bgTertiary)
                                    .overlay(
                                        Capsule()
                                            .stroke(inviteStatusColor(invite.status).opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                    }

                    // Attachment pills preview (non-battle mails)
                    if !message.isBattleResult && !message.isBattleInvite,
                        let attachments = message.attachments, !attachments.isEmpty,
                        !message.isClaimed
                    {
                        attachmentPills(attachments)
                    }
                }

                // Sender + date row
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(message.senderName)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text("·")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text(formatDate(message.createdAt))
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Spacer()
                }
            }

            // Expand chevron
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, 14)
    }

    // MARK: - Sender Icon

    private var senderIcon: some View {
        ZStack {
            // Icon background
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(
                    isSystem
                        ? LinearGradient(
                            colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgTertiary,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .frame(width: 40, height: 40)

            // Icon
            Image(systemName: senderSFSymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSystem ? accentColor : DarkFantasyTheme.textSecondary)

            // Unread dot
            if !message.isRead {
                Circle()
                    .fill(DarkFantasyTheme.gold)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(DarkFantasyTheme.bgSecondary, lineWidth: 2)
                    )
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 4)
                    .offset(x: 16, y: -16)
            }
        }
    }

    private var senderSFSymbol: String {
        switch message.senderType {
        case "system": return "scroll.fill"
        case "admin": return "megaphone.fill"
        case "arena_result":
            if let bd = message.battleData {
                return bd.isWin ? "trophy.fill" : "xmark.shield.fill"
            }
            return "swords"
        case "battle_invite":
            if let inv = message.inviteData {
                if inv.isAccepted { return "checkmark.circle.fill" }
                if inv.isDeclined { return "xmark.circle.fill" }
                if inv.isExpired { return "clock.badge.xmark" }
            }
            return "swords"
        case "player": return "person.fill"
        default: return "envelope.fill"
        }
    }

    // MARK: - Attachment Pills

    private func attachmentPills(_ attachments: [MailAttachment]) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(Array(attachments.prefix(3).enumerated()), id: \.offset) { _, attachment in
                HStack(spacing: 3) {
                    attachmentIcon(for: attachment.type)
                        .frame(width: 12, height: 12)

                    Text(formatAmount(attachment.amount))
                        .font(DarkFantasyTheme.section(size: 11))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay(
                            Capsule()
                                .stroke(DarkFantasyTheme.goldDim.opacity(0.3), lineWidth: 0.5)
                        )
                )
            }

            if attachments.count > 3 {
                Text("+\(attachments.count - 3)")
                    .font(DarkFantasyTheme.section(size: 11))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMD) {
            // Gold divider
            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)

            // Structured content by type
            if message.isBattleResult, let battle = message.battleData {
                battleResultContent(battle)
                    .padding(.horizontal, LayoutConstants.spaceMD)
            } else if message.isBattleInvite, let invite = message.inviteData {
                battleInviteContent(invite)
                    .padding(.horizontal, LayoutConstants.spaceMD)
            } else {
                // Regular mail: plain text body
                Text(message.body)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(nil)
                    .padding(.horizontal, LayoutConstants.spaceMD)
            }

            // Attachments card (only for regular mails with claimable rewards)
            if !message.isBattleResult && !message.isBattleInvite,
                let attachments = message.attachments, !attachments.isEmpty {
                attachmentsCard(attachments)
                    .padding(.horizontal, LayoutConstants.spaceMD)
            }

            // Action buttons
            actionButtons
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.bottom, LayoutConstants.spaceMD)
        }
        .padding(.top, LayoutConstants.spaceXS)
    }

    // MARK: - Battle Result Content

    private func battleResultContent(_ battle: BattleResultData) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Fight type label
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "swords")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                Text(battle.label)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                Spacer()

                Text("\(battle.totalTurns) turns")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            // Rating change row
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .frame(width: 20)

                Text("Rating")
                    .font(DarkFantasyTheme.body(size: 14))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                Text("\(battle.ratingBefore) → \(battle.ratingAfter)")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("(\(battle.ratingChange > 0 ? "+" : "")\(battle.ratingChange))")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(battle.ratingChange >= 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
            }

            // Gold reward row
            HStack(spacing: LayoutConstants.spaceSM) {
                Image("icon-gold")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .frame(width: 20)

                Text("Gold")
                    .font(DarkFantasyTheme.body(size: 14))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                Text("+\(battle.goldReward)")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(DarkFantasyTheme.gold)
            }

            // XP reward row
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DarkFantasyTheme.cyan)
                    .frame(width: 20)

                Text("XP")
                    .font(DarkFantasyTheme.body(size: 14))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                Text("+\(battle.xpReward)")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(DarkFantasyTheme.cyan)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgTertiary.opacity(0.6),
                glowColor: accentColor.opacity(0.04),
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.radiusSM
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.radiusSM - 1, inset: 1,
            color: accentColor.opacity(0.08))
        .compositingGroup()
    }

    // MARK: - Attachments Card

    private func attachmentsCard(_ attachments: [MailAttachment]) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            OrnamentalSectionHeader(title: "Rewards", accentColor: accentColor)

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(Array(attachments.enumerated()), id: \.offset) { _, attachment in
                    rewardPill(attachment)
                }
                Spacer()
            }
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgTertiary.opacity(0.6),
                glowColor: accentColor.opacity(0.04),
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.radiusSM
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.radiusSM - 1, inset: 1,
            color: accentColor.opacity(0.08))
        .compositingGroup()
    }

    // MARK: - Battle Invite Content

    private func battleInviteContent(_ invite: BattleInviteData) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Challenger info row
            HStack(spacing: LayoutConstants.spaceMD) {
                // Challenger avatar
                if let avatar = invite.challengerAvatar, !avatar.isEmpty {
                    AvatarImageView(
                        skinKey: avatar,
                        characterClass: invite.challengerClassEnum,
                        size: 44
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                } else {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        )
                }

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(invite.challengerName)
                        .font(DarkFantasyTheme.section(size: 16))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)

                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("Lv.\(invite.challengerLevel)")
                            .font(DarkFantasyTheme.body(size: 12))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text("·")
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Text(invite.challengerClass.capitalized)
                            .font(DarkFantasyTheme.body(size: 12))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text("·")
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Text("\(invite.challengerRating)")
                            .font(DarkFantasyTheme.section(size: 12))
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }
                }

                Spacer()
            }

            // Challenge message (if any)
            if let msg = invite.message, !msg.isEmpty {
                Text("\"\(msg)\"")
                    .font(DarkFantasyTheme.body(size: 14).italic())
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Action buttons (only for pending invites)
            if invite.isPending {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Button {
                        acceptInvite(invite)
                    } label: {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "swords")
                                .font(.system(size: 13))
                            Text("FIGHT")
                                .font(DarkFantasyTheme.section(size: 14))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)

                    Button {
                        declineInvite(invite)
                    } label: {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("DECLINE")
                                .font(DarkFantasyTheme.section(size: 14))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary)
                }
            } else {
                // Resolved status
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: invite.isAccepted ? "checkmark.circle.fill" : invite.isDeclined ? "xmark.circle.fill" : "clock")
                        .foregroundStyle(inviteStatusColor(invite.status))
                    Text(invite.status.capitalized)
                        .font(DarkFantasyTheme.body(size: 14))
                        .foregroundStyle(inviteStatusColor(invite.status))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, LayoutConstants.spaceXS)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgTertiary.opacity(0.6),
                glowColor: accentColor.opacity(0.04),
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.radiusSM
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.radiusSM - 1, inset: 1,
            color: accentColor.opacity(0.08))
        .compositingGroup()
    }

    private func inviteStatusColor(_ status: String) -> Color {
        switch status {
        case "accepted": return DarkFantasyTheme.success
        case "declined": return DarkFantasyTheme.danger
        case "expired": return DarkFantasyTheme.textTertiary
        default: return DarkFantasyTheme.orange
        }
    }

    private func acceptInvite(_ invite: BattleInviteData) {
        HapticManager.heavy()
        // Navigate to guild hall which handles challenge acceptance with combat playback
        appState.mainPath.append(AppRoute.guildHall)
    }

    private func declineInvite(_ invite: BattleInviteData) {
        HapticManager.light()
        Task {
            do {
                try await ChallengeService.shared.declineChallenge(
                    characterId: characterId,
                    challengeId: invite.challengeId
                )
                // Mark the mail as read since the action is done
                viewModel.markAsRead(messageId: message.id, characterId: characterId)
                appState.showToast("Challenge declined", type: .info)
            } catch {
                appState.showToast("Failed to decline", type: .error)
            }
        }
    }

    private func rewardPill(_ attachment: MailAttachment) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            attachmentIcon(for: attachment.type)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 0) {
                Text(formatAmount(attachment.amount))
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(attachment.type.capitalized)
                    .font(DarkFantasyTheme.body(size: 11))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(DarkFantasyTheme.goldDim.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            if !message.isClaimed, let attachments = message.attachments, !attachments.isEmpty {
                Button(action: claimAttachments) {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 14))
                        Text("Claim Rewards")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .disabled(isClaiming)
            } else if message.isClaimed {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                    Text("Claimed")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, LayoutConstants.spaceSM)
            }

            Button(action: deleteMail) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 13))
                    Text("Delete")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
            .disabled(isDeleting)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func attachmentIcon(for type: String) -> some View {
        switch type {
        case "gold":
            Image("icon-gold")
                .resizable()
                .scaledToFit()
        case "gems":
            Image("icon-gems")
                .resizable()
                .scaledToFit()
        case "xp":
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DarkFantasyTheme.gold)
        case "item":
            Image(systemName: "bag.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DarkFantasyTheme.gold)
        default:
            Image(systemName: "gift.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DarkFantasyTheme.gold)
        }
    }

    private func formatAmount(_ amount: Int) -> String {
        if amount >= 1000 {
            let k = Double(amount) / 1000.0
            if k == Double(Int(k)) {
                return "\(Int(k))K"
            }
            return String(format: "%.1fK", k)
        }
        return "\(amount)"
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        guard let date else { return dateString }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return dateFormatter.string(from: date)
        }
    }

    private func claimAttachments() {
        viewModel.claimAttachments(messageId: message.id, characterId: characterId, appState: appState)
        isClaiming = true
        // Reset after brief delay (optimistic already applied)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            isClaiming = false
        }
    }

    private func deleteMail() {
        viewModel.deleteMail(messageId: message.id, characterId: characterId, appState: appState)
        withAnimation {
            isExpanded = false
        }
    }
}

#Preview {
    ZStack {
        DarkFantasyTheme.bgPrimary.ignoresSafeArea()
        VStack(spacing: LayoutConstants.spaceSM) {
            InboxRowView(
                message: MailMessage(
                    id: "mail-1",
                    subject: "Daily Reward",
                    body: "Congratulations! You've earned your daily reward for logging in.",
                    senderType: "system",
                    senderName: "System",
                    attachments: [
                        MailAttachment(type: "gold", amount: 500, itemId: nil),
                        MailAttachment(type: "gems", amount: 10, itemId: nil),
                    ],
                    isRead: false,
                    isClaimed: false,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    expiresAt: nil
                ),
                viewModel: InboxViewModel(),
                characterId: "char-123"
            )

            InboxRowView(
                message: MailMessage(
                    id: "mail-2",
                    subject: "Arena Season Rewards",
                    body: "Season 3 has ended. Here are your ranking rewards!",
                    senderType: "admin",
                    senderName: "Arena Master",
                    attachments: [
                        MailAttachment(type: "gold", amount: 2500, itemId: nil)
                    ],
                    isRead: true,
                    isClaimed: true,
                    createdAt: ISO8601DateFormatter().string(
                        from: Date().addingTimeInterval(-86400)),
                    expiresAt: nil
                ),
                viewModel: InboxViewModel(),
                characterId: "char-123"
            )
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
    }
}
