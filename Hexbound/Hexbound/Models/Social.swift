import Foundation

// MARK: - Friendship Status

enum FriendshipButtonState: String {
    case none           // Can send request
    case requestSent    // Waiting for them
    case requestReceived // They sent to me
    case friends        // Already friends
    case blocked        // I blocked them
    case blockedBy      // They blocked me
    case maxReached     // My friend list full
}

// MARK: - Friend Entry

struct FriendEntry: Codable, Identifiable {
    let id: String
    let friendshipId: String
    let characterName: String
    let characterClass: String
    let origin: String
    let level: Int
    let pvpRating: Int
    let avatar: String
    let lastActiveAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case friendshipId = "friendship_id"
        case characterName = "character_name"
        case characterClass = "class"
        case origin
        case level
        case pvpRating = "pvp_rating"
        case avatar
        case lastActiveAt = "last_active_at"
    }

    var onlineStatus: OnlineStatus {
        guard let lastActive = lastActiveAt else { return .offline }
        let elapsed = Date().timeIntervalSince(lastActive)
        if elapsed < 5 * 60 { return .online }
        if elapsed < 30 * 60 { return .away }
        return .offline
    }

    var lastSeenText: String? {
        guard let lastActive = lastActiveAt else { return nil }
        let elapsed = Date().timeIntervalSince(lastActive)
        if elapsed < 60 { return "Just now" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m ago" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))h ago" }
        let days = Int(elapsed / 86400)
        if days >= 7 { return "7d+ ago" }
        return "\(days)d ago"
    }

    var classEnum: CharacterClass {
        CharacterClass(rawValue: characterClass) ?? .warrior
    }

    var rankName: String {
        PvPRank.fromRating(pvpRating).rawValue
    }
}

enum OnlineStatus {
    case online, away, offline
}

// MARK: - Friend Request

struct FriendRequest: Codable, Identifiable {
    let friendshipId: String
    let id: String
    let characterName: String
    let characterClass: String
    let origin: String
    let level: Int
    let pvpRating: Int
    let avatar: String
    let requestedAt: Date

    var classEnum: CharacterClass {
        CharacterClass(rawValue: characterClass) ?? .warrior
    }

    var rankName: String {
        PvPRank.fromRating(pvpRating).rawValue
    }

    enum CodingKeys: String, CodingKey {
        case friendshipId = "friendship_id"
        case id
        case characterName = "character_name"
        case characterClass = "class"
        case origin
        case level
        case pvpRating = "pvp_rating"
        case avatar
        case requestedAt = "requested_at"
    }
}

// MARK: - Social Status (badge counts)

struct SocialStatus: Codable {
    let pendingRequests: Int
    let unreadMessages: Int
    let pendingRevenges: Int
    let totalBadge: Int

    enum CodingKeys: String, CodingKey {
        case pendingRequests = "pending_requests"
        case unreadMessages = "unread_messages"
        case pendingRevenges = "pending_revenges"
        case totalBadge = "total_badge"
    }
}

// MARK: - Friendship Status Response

struct FriendshipStatusResponse: Codable {
    let status: String
}

// MARK: - Friends List Response

struct FriendsListResponse: Codable {
    let friends: [FriendEntry]
    let incomingRequests: [FriendRequest]
    let outgoingRequests: [FriendRequest]
    let count: Int
    let maxFriends: Int

    enum CodingKeys: String, CodingKey {
        case friends
        case incomingRequests = "incoming_requests"
        case outgoingRequests = "outgoing_requests"
        case count
        case maxFriends = "max_friends"
    }
}
