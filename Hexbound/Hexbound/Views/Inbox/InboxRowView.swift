import SwiftUI

struct InboxRowView: View {
    let message: MailMessage
    let viewModel: InboxViewModel
    let characterId: String
    
    @State private var isExpanded = false
    @State private var isClaiming = false
    @State private var isDeleting = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Row header
            HStack(spacing: LayoutConstants.spaceMD) {
                // Unread indicator
                if !message.isRead {
                    Circle()
                        .fill(DarkFantasyTheme.gold)
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }
                
                VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text(message.subject)
                            .font(.system(size: 16, weight: message.isRead ? .regular : .semibold))
                            .foregroundColor(DarkFantasyTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        // Attachment icons
                        HStack(spacing: LayoutConstants.spaceXS) {
                            if let attachments = message.attachments, !attachments.isEmpty {
                                ForEach(attachments.prefix(3), id: \.type) { attachment in
                                    AttachmentIcon(type: attachment.type, amount: attachment.amount)
                                }
                                
                                if attachments.count > 3 {
                                    Text("+\(attachments.count - 3)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(DarkFantasyTheme.textSecondary)
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text(message.senderName)
                            .font(.system(size: 14))
                            .foregroundColor(DarkFantasyTheme.textSecondary)
                        
                        Spacer()
                        
                        Text(formatDate(message.createdAt))
                            .font(.system(size: 13))
                            .foregroundColor(DarkFantasyTheme.textSecondary)
                    }
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(DarkFantasyTheme.textSecondary)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(LayoutConstants.spaceMD)
            .background(DarkFantasyTheme.bgSecondary)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                    
                    if isExpanded && !message.isRead {
                        Task {
                            await viewModel.markAsRead(messageId: message.id, characterId: characterId)
                        }
                    }
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: LayoutConstants.spaceMD) {
                    Divider()
                        .foregroundColor(DarkFantasyTheme.bgTertiary)
                    
                    // Message body
                    Text(message.body)
                        .font(.system(size: 16))
                        .foregroundColor(DarkFantasyTheme.textPrimary)
                        .lineLimit(nil)
                    
                    // Attachments details
                    if let attachments = message.attachments, !attachments.isEmpty {
                        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                            Text("Attachments")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DarkFantasyTheme.textSecondary)
                            
                            ForEach(attachments, id: \.type) { attachment in
                                HStack(spacing: LayoutConstants.spaceSM) {
                                    AttachmentIcon(type: attachment.type, amount: attachment.amount)
                                    
                                    Text(formatAttachment(attachment))
                                        .font(.system(size: 14))
                                        .foregroundColor(DarkFantasyTheme.textPrimary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(LayoutConstants.spaceMD)
                        .background(DarkFantasyTheme.bgTertiary)
                        .cornerRadius(LayoutConstants.radiusSM)
                    }
                    
                    // Actions
                    HStack(spacing: LayoutConstants.spaceMD) {
                        if !message.isClaimed && message.attachments != nil {
                            Button(action: claimAttachments) {
                                HStack {
                                    Image(systemName: "gift.fill")
                                    Text("Claim")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.primary)
                            .disabled(isClaiming)
                        }
                        
                        Button(action: deleteMail) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.secondary)
                        .disabled(isDeleting)
                    }
                }
                .padding(LayoutConstants.spaceMD)
                .background(DarkFantasyTheme.bgSecondary)
            }
        }
        .background(DarkFantasyTheme.bgSecondary)
        .cornerRadius(LayoutConstants.radiusMD)
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
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
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            return dateFormatter.string(from: date)
        }
    }
    
    private func formatAttachment(_ attachment: MailAttachment) -> String {
        switch attachment.type {
        case "gold":
            return "\(attachment.amount) Gold"
        case "gems":
            return "\(attachment.amount) Gems"
        case "xp":
            return "\(attachment.amount) XP"
        case "item":
            return "Item: \(attachment.itemId ?? "Unknown")"
        default:
            return attachment.type
        }
    }
}

// MARK: - Attachment Icon
private struct AttachmentIcon: View {
    let type: String
    let amount: Int
    
    var body: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(iconColor)

            Text("\(amount)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DarkFantasyTheme.textSecondary)
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(DarkFantasyTheme.bgTertiary)
        .cornerRadius(LayoutConstants.radiusXS)
    }
    
    private var iconName: String {
        switch type {
        case "gold":
            return "dollarsign.circle.fill"
        case "gems":
            return "diamond.fill"
        case "xp":
            return "star.fill"
        case "item":
            return "bag.fill"
        default:
            return "envelope.fill"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case "gold":
            return DarkFantasyTheme.gold
        case "gems":
            return DarkFantasyTheme.purple
        case "xp":
            return DarkFantasyTheme.gold
        case "item":
            return DarkFantasyTheme.gold
        default:
            return DarkFantasyTheme.textSecondary
        }
    }
}

#Preview {
    InboxRowView(
        message: MailMessage(
            id: "mail-1",
            subject: "Daily Reward",
            body: "Congratulations! You've earned your daily reward.",
            senderType: "system",
            senderName: "System",
            attachments: [
                MailAttachment(type: "gold", amount: 500, itemId: nil),
                MailAttachment(type: "gems", amount: 10, itemId: nil)
            ],
            isRead: false,
            isClaimed: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            expiresAt: nil
        ),
        viewModel: InboxViewModel(),
        characterId: "char-123"
    )
    .background(DarkFantasyTheme.bgPrimary)
}
