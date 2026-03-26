import SwiftUI

struct InboxRowView: View {
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
        default: return DarkFantasyTheme.goldDim
        }
    }

    private var isSystem: Bool {
        message.senderType == "system" || message.senderType == "admin"
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
                            Task {
                                await viewModel.markAsRead(
                                    messageId: message.id, characterId: characterId)
                            }
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

                    // Attachment pills preview
                    if let attachments = message.attachments, !attachments.isEmpty,
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

            // Message body
            Text(message.body)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(nil)
                .padding(.horizontal, LayoutConstants.spaceMD)

            // Attachments card
            if let attachments = message.attachments, !attachments.isEmpty {
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
        isClaiming = true
        Task {
            await viewModel.claimAttachments(messageId: message.id, characterId: characterId)
            isClaiming = false
        }
    }

    private func deleteMail() {
        isDeleting = true
        Task {
            await viewModel.deleteMail(messageId: message.id, characterId: characterId)
            withAnimation {
                isExpanded = false
            }
            isDeleting = false
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
