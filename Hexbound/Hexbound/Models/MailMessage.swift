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

    /// Parse structured battle data from body JSON (arena_result mails only).
    ///
    /// Latency pass (2026-10-15): memoized. Inbox rows read this ~5× per
    /// render, and every read built a JSONDecoder and re-parsed the body on
    /// the main thread — for up to 50 rows on every list update.
    var battleData: BattleResultData? {
        guard isBattleResult else { return nil }
        return MailBodyDecodeCache.decode(BattleResultData.self, kind: "battle", id: id, body: body)
    }

    /// Parse battle invite data from body JSON (battle_invite mails only).
    /// Memoized like `battleData`.
    var inviteData: BattleInviteData? {
        guard isBattleInvite else { return nil }
        return MailBodyDecodeCache.decode(BattleInviteData.self, kind: "invite", id: id, body: body)
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

    /// Return a copy marked as unread (for rollback)
    func withUnread() -> MailMessage {
        MailMessage(
            id: id, subject: subject, body: body,
            senderType: senderType, senderName: senderName,
            attachments: attachments,
            isRead: false, isClaimed: isClaimed,
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
    let gold: Int?
    let gems: Int?
    let xp: Int?
    let leveledUp: Bool?
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
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
    let opponentAvatar: String?
    let opponentClass: String?
    let matchId: String
    let totalTurns: Int
    let ratingBefore: Int
    let ratingAfter: Int
    let ratingChange: Int
    let goldReward: Int
    let xpReward: Int

    var opponentClassEnum: CharacterClass {
        CharacterClass(rawValue: opponentClass ?? "warrior") ?? .warrior
    }
}

/// Generic success response used across multiple endpoints
struct SuccessResponse: Codable {
    let success: Bool
}

// MARK: - Body decode memo

/// Decoded mail bodies keyed by message id + body length (bodies never
/// change for a given id). Failures are cached too, so a malformed body is
/// parsed — and logged — once.
private enum MailBodyDecodeCache {
    private final class Box {
        let value: Any?
        init(_ value: Any?) { self.value = value }
    }

    private static let cache: NSCache<NSString, Box> = {
        let cache = NSCache<NSString, Box>()
        cache.countLimit = 300
        return cache
    }()

    static func decode<T: Decodable>(_ type: T.Type, kind: String, id: String, body: String) -> T? {
        let key = "\(kind):\(id):\(body.utf8.count)" as NSString
        if let box = cache.object(forKey: key) {
            return box.value as? T
        }
        var result: T?
        if let data = body.data(using: .utf8) {
            do {
                result = try JSONDecoder().decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("⚠️ [MailMessage] Failed to decode \(T.self): \(error)")
                #endif
            }
        }
        cache.setObject(Box(result), forKey: key)
        return result
    }
}
