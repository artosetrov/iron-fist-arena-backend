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

    /// Whether this mail is an arena/battle result notification
    var isBattleResult: Bool {
        senderType == "arena_result"
    }

    /// Whether this mail is a battle invite (challenge)
    var isBattleInvite: Bool {
        senderType == "battle_invite"
    }

    /// Parse structured battle data from body JSON (arena_result mails only)
    var battleData: BattleResultData? {
        guard isBattleResult else { return nil }
        guard let data = body.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(BattleResultData.self, from: data)
    }

    /// Parse battle invite data from body JSON (battle_invite mails only)
    var inviteData: BattleInviteData? {
        guard isBattleInvite else { return nil }
        guard let data = body.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(BattleInviteData.self, from: data)
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

/// Structured data parsed from battle_invite mail body (JSON)
struct BattleInviteData: Codable {
    let challengeId: String
    let challengerId: String
    let challengerName: String
    let challengerClass: String
    let challengerLevel: Int
    let challengerRating: Int
    let challengerAvatar: String?
    let message: String?
    let goldWager: Int
    let expiresAt: String         // ISO date string
    let status: String            // "pending", "accepted", "declined", "expired"

    var isPending: Bool { status == "pending" }
    var isExpired: Bool { status == "expired" }
    var isAccepted: Bool { status == "accepted" }
    var isDeclined: Bool { status == "declined" }

    var challengerClassEnum: CharacterClass {
        CharacterClass(rawValue: challengerClass) ?? .warrior
    }
}

// MARK: - Unified Inbox Item

/// Wraps different content types into a single feed item for the unified inbox.
enum UnifiedInboxItem: Identifiable {
    case mail(MailMessage)
    case conversation(Conversation)

    var id: String {
        switch self {
        case .mail(let m): return "mail-\(m.id)"
        case .conversation(let c): return "conv-\(c.otherCharacter.id)"
        }
    }

    var sortDate: Date {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        switch self {
        case .mail(let m):
            return iso.date(from: m.createdAt)
                ?? ISO8601DateFormatter().date(from: m.createdAt)
                ?? .distantPast
        case .conversation(let c):
            return iso.date(from: c.lastMessage.createdAt)
                ?? ISO8601DateFormatter().date(from: c.lastMessage.createdAt)
                ?? .distantPast
        }
    }

    var isUnread: Bool {
        switch self {
        case .mail(let m): return !m.isRead
        case .conversation(let c): return c.unreadCount > 0
        }
    }

    /// Category for filter pills
    var category: InboxFilter {
        switch self {
        case .mail(let m):
            if m.isBattleResult || m.isBattleInvite { return .battles }
            return .system
        case .conversation:
            return .messages
        }
    }
}

/// Filter options for the unified inbox
enum InboxFilter: String, CaseIterable {
    case all = "ALL"
    case battles = "BATTLES"
    case messages = "SCROLLS"
    case system = "SYSTEM"
}

/// Structured data parsed from arena_result mail body (JSON)
struct BattleResultData: Codable {
    let fightType: String      // "arena", "revenge", "challenge"
    let label: String           // "Arena Battle", "Revenge Battle", "Challenge Duel"
    let isWin: Bool
    let opponentName: String
    let opponentId: String
    let matchId: String
    let totalTurns: Int
    let ratingBefore: Int
    let ratingAfter: Int
    let ratingChange: Int
    let goldReward: Int
    let xpReward: Int
}

/// Generic success response used across multiple endpoints
struct SuccessResponse: Codable {
    let success: Bool
}
