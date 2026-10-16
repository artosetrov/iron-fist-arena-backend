import SwiftUI

struct InboxRowView: View {
    @Environment(AppState.self) private var appState

    let message: MailMessage
    let viewModel: InboxViewModel
    let characterId: String

    @State private var isExpanded = false
    @State private var isClaiming = false
    @State private var isPressed = false

    /// Sender tile / avatar side — the minimum touch target, since the
    /// opponent avatar is a button.
    private var tileSize: CGFloat { LayoutConstants.touchMin }

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
            return DarkFantasyTheme.btnOrangePrimary
        default: return DarkFantasyTheme.goldDim
        }
    }

    /// Rewards still waiting in the letter.
    private var hasUnclaimedRewards: Bool {
        message.hasAttachments && !message.isClaimed
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Mail Row Header
            mailHeader
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(MotionConstants.snappy) {
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
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(isExpanded ? "Closes the letter" : "Opens the letter")

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
        .cardShadow()
        .brightness(isPressed ? -0.06 : 0)
    }

    // MARK: - Mail Header

    private var mailHeader: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            // Sender: painted crest, or the opponent's portrait for a battle report
            senderIcon

            // Title + sender + timestamp
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                // Subject line
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(message.subject)
                        .font(
                            message.isRead
                                ? DarkFantasyTheme.body : DarkFantasyTheme.cardTitle
                        )
                        .foregroundStyle(
                            message.isRead
                                ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: LayoutConstants.spaceXS)

                    headerBadge
                        .fixedSize()
                }

                // Sender + date row
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(message.senderName)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(1)

                    Text("·")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .accessibilityHidden(true)

                    Text(formatDate(message.createdAt))
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Spacer(minLength: LayoutConstants.spaceXS)

                    // Rewards still inside — on this line so the subject keeps its width
                    if let attachments = waitingRewards {
                        attachmentPills(attachments)
                            .fixedSize()
                    }
                }
            }

            // Expand arrow — painted, turns over when the letter is open
            Image("ui-arrow-down")
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .opacity(0.8)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceMS)
    }

    /// One glanceable fact on the subject line: rating swing or duel status.
    @ViewBuilder
    private var headerBadge: some View {
        if let battle = message.battleData {
            ratingChangeBadge(battle.ratingChange)
        } else if let invite = message.inviteData {
            statusCapsule(invite.status.uppercased(), color: inviteStatusColor(invite.status))
        }
    }

    /// Unclaimed attachments of a regular letter (battle mails carry none —
    /// their rewards are paid at fight time).
    private var waitingRewards: [MailAttachment]? {
        guard !message.isBattleResult, !message.isBattleInvite, !message.isClaimed,
              let attachments = message.attachments, !attachments.isEmpty else { return nil }
        return attachments
    }

    private func ratingChangeBadge(_ change: Int) -> some View {
        let color = change >= 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger
        let text = "\(change > 0 ? "+" : "")\(change)"
        return HStack(spacing: LayoutConstants.space2XS) {
            Image(change >= 0 ? "reward-rating-up" : "reward-rating-down")
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)

            Text(text)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            Capsule()
                .fill(DarkFantasyTheme.bgTertiary)
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating \(text)")
    }

    private func statusCapsule(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DarkFantasyTheme.body.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.bgTertiary)
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }

    // MARK: - Sender Icon

    private var senderIcon: some View {
        ZStack(alignment: .topTrailing) {
            if message.isBattleResult, let battle = message.battleData {
                // Battle result: opponent portrait (tappable → profile)
                Button {
                    HapticManager.light()
                    appState.mainPath.append(
                        AppRoute.characterProfile(
                            characterId: battle.opponentId,
                            characterName: battle.opponentName
                        )
                    )
                } label: {
                    battleOpponentAvatar(battle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(battle.opponentName), open profile")
            } else {
                artTile(senderAsset)
            }

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
                    .offset(x: 3, y: -3)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: tileSize, height: tileSize)
    }

    /// Painted crest for the sender (Hexbound/CLAUDE.md: project assets, not SF Symbols).
    private var senderAsset: String {
        if message.isBattleResult {
            guard let battle = message.battleData else { return "icon-fights" }
            return battle.isWin ? "icon-wins" : "icon-losses"
        }
        if message.isBattleInvite { return "icon-fights" }
        if hasUnclaimedRewards { return "hud-gift" }            // a chest while rewards wait
        return message.senderType == "admin" ? "hud-quests" : "hud-inbox"  // proclamation / letter
    }

    private func artTile(_ asset: String) -> some View {
        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
            .fill(
                LinearGradient(
                    colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: tileSize, height: tileSize)
            .overlay(
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .padding(LayoutConstants.spaceXS)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(accentColor.opacity(message.isRead ? 0.25 : 0.5), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }

    private func battleOpponentAvatar(_ battle: BattleResultData) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if let avatar = battle.opponentAvatar, !avatar.isEmpty {
                AvatarImageView(
                    skinKey: avatar,
                    characterClass: battle.opponentClassEnum,
                    size: tileSize
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
            } else {
                artTile(battle.opponentClassEnum.iconAsset)
            }

            // Win/loss ring
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(accentColor.opacity(0.6), lineWidth: 1.5)
                .frame(width: tileSize, height: tileSize)

            // Result crest — trophy for a win, broken shield for a loss
            Image(battle.isWin ? "icon-wins" : "icon-losses")
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                .offset(x: LayoutConstants.spaceXS, y: LayoutConstants.spaceXS)
                .accessibilityHidden(true)
        }
        .frame(width: tileSize, height: tileSize)
    }

    // MARK: - Attachment Pills

    /// Inline "icon amount" pairs — no capsules, so they fit beside the
    /// sender and date on a phone-width row.
    private func attachmentPills(_ attachments: [MailAttachment]) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(attachments.prefix(2).enumerated()), id: \.offset) { _, attachment in
                HStack(spacing: LayoutConstants.space2XS) {
                    Image(attachmentAsset(for: attachment.type))
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)

                    Text(formatAmount(attachment.amount))
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(attachment.amount) \(attachmentLabel(for: attachment.type))")
            }

            if attachments.count > 2 {
                Text("+\(attachments.count - 2)")
                    .font(DarkFantasyTheme.body)
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
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
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
                .padding(.bottom, LayoutConstants.spaceSM)
        }
        .padding(.top, LayoutConstants.spaceXS)
    }

    // MARK: - Battle Result Content

    private func battleResultContent(_ battle: BattleResultData) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Fight type label
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-fights")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                    .accessibilityHidden(true)

                Text(battle.label)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                Spacer()

                Text("\(battle.totalTurns) turns")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            // Rating change row
            HStack(spacing: LayoutConstants.spaceSM) {
                rowIcon("icon-pvp-rating")

                Text("Rating")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                Text("\(battle.ratingBefore) → \(battle.ratingAfter)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("(\(battle.ratingChange > 0 ? "+" : "")\(battle.ratingChange))")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(battle.ratingChange >= 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
            }

            // Gold reward row
            HStack(spacing: LayoutConstants.spaceSM) {
                rowIcon("icon-gold")

                Text("Gold")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                Text("+\(battle.goldReward)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.gold)
            }

            // XP reward row
            HStack(spacing: LayoutConstants.spaceSM) {
                rowIcon("icon-xp")

                Text("XP")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                Text("+\(battle.xpReward)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
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

    /// 20pt painted icon in a 24pt column, so the labels line up.
    private func rowIcon(_ asset: String) -> some View {
        Image(asset)
            .resizable()
            .scaledToFit()
            .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
            .frame(width: LayoutConstants.iconLG)
            .accessibilityHidden(true)
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
        .opacity(message.isClaimed ? 0.6 : 1)
    }

    // MARK: - Battle Invite Content

    private func battleInviteContent(_ invite: BattleInviteData) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Challenger info row
            HStack(spacing: LayoutConstants.spaceMD) {
                // Challenger avatar — portrait, or the class crest
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
                            Image(invite.challengerClassEnum.iconAsset)
                                .resizable()
                                .scaledToFit()
                                .padding(LayoutConstants.spaceXS)
                        )
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(invite.challengerName)
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)

                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("Lv.\(invite.challengerLevel)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text("·")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Text(invite.challengerClass.capitalized)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text("·")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Image("icon-pvp-rating")
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                            .accessibilityHidden(true)

                        Text("\(invite.challengerRating)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }
                }

                Spacer()
            }

            // Challenge message (if any)
            if let msg = invite.message, !msg.isEmpty {
                Text("\"\(msg)\"")
                    .font(DarkFantasyTheme.body.italic())
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Action buttons (only for pending invites)
            if invite.isPending {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Button {
                        acceptInvite(invite)
                    } label: {
                        Text("FIGHT")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)

                    Button {
                        declineInvite(invite)
                    } label: {
                        Text("DECLINE")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary)
                }
            } else {
                // Resolved status
                statusCapsule(invite.status.capitalized, color: inviteStatusColor(invite.status))
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
        default: return DarkFantasyTheme.btnOrangePrimary
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
                appState.showToast(
                    "Failed to decline",
                    type: .error,
                    actionLabel: "Retry",
                    action: { declineInvite(invite) }
                )
            }
        }
    }

    private func rewardPill(_ attachment: MailAttachment) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(attachmentAsset(for: attachment.type))
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)

            VStack(alignment: .leading, spacing: 0) {
                Text(formatAmount(attachment.amount))
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(attachmentLabel(for: attachment.type))
                    .font(DarkFantasyTheme.body)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(attachment.amount) \(attachmentLabel(for: attachment.type))")
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceMS) {
                if hasUnclaimedRewards {
                    Button(action: claimAttachments) {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Image("hud-gift")
                                .resizable()
                                .scaledToFit()
                                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                            Text("Claim Rewards")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .disabled(isClaiming)
                } else if message.isClaimed {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "checkmark")
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.goldDim)
                        Text("Rewards claimed")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutConstants.spaceSM)
                }

                // Write to the opponent from their battle report
                if message.isBattleResult, let battle = message.battleData {
                    Button {
                        HapticManager.light()
                        appState.mainPath.append(
                            AppRoute.guildHallMessage(
                                characterId: battle.opponentId,
                                characterName: battle.opponentName,
                                avatar: battle.opponentAvatar,
                                characterClass: battle.opponentClass
                            )
                        )
                    } label: {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Image("hud-inbox")
                                .resizable()
                                .scaledToFit()
                                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                            Text("Write to \(battle.opponentName)")
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary)
                }
            }

            // Rare and destructive — kept quiet so it is never hit instead of Claim.
            Button(role: .destructive, action: deleteMail) {
                Text("Delete letter")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                    .frame(maxWidth: .infinity, minHeight: LayoutConstants.touchMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    /// Painted icon per reward type (never SF Symbols for currency — CurrencyDisplay rule).
    private func attachmentAsset(for type: String) -> String {
        switch type {
        case "gold": return "icon-gold"
        case "gems": return "icon-gems"
        case "xp": return "icon-xp"
        case "item", "consumable": return "reward-loot"
        default: return "hud-gift"
        }
    }

    private func attachmentLabel(for type: String) -> String {
        switch type {
        case "gold": return "Gold"
        case "gems": return "Gems"
        case "xp": return "XP"
        case "item": return "Item"
        case "consumable": return "Supplies"
        default: return type.capitalized
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
