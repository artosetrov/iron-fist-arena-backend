import Foundation

struct MailMessage: Codable, Identifiable {
    let id: String
    let subject: String
    let body: String
    let senderType: String
    let senderName: String
    let attachments: [MailAttachment]?
    let isRead: Bool
    let isClaimed: Bool
    let createdAt: String
    let expiresAt: String?

    var hasAttachments: Bool {
        guard let att = attachments else { return false }
        return !att.isEmpty
    }

    /// Return a copy marked as read
    func withRead() -> MailMessage {
        MailMessage(
            id: id, subject: subject, body: body,
            senderType: senderType, senderName: senderName,
            attachments: attachments,
            isRead: true, isClaimed: isClaimed,
            createdAt: createdAt, expiresAt: expiresAt
        )
    }

    /// Return a copy marked as claimed (and read)
    func withClaimed() -> MailMessage {
        MailMessage(
            id: id, subject: subject, body: body,
            senderType: senderType, senderName: senderName,
            attachments: attachments,
            isRead: true, isClaimed: true,
            createdAt: createdAt, expiresAt: expiresAt
        )
    }
}

struct MailAttachment: Codable {
    let type: String   // gold, gems, xp, item
    let amount: Int
    let itemId: String?
}

struct MailInboxResponse: Codable {
    let messages: [MailMessage]
    let total: Int
    let page: Int
    let limit: Int
    let unreadCount: Int
}

struct MailUnreadResponse: Codable {
    let unreadCount: Int
}

struct MailClaimResponse: Codable {
    let success: Bool
    let claimed: [MailAttachment]?
}

/// Generic success response used across multiple endpoints
struct SuccessResponse: Codable {
    let success: Bool
}
