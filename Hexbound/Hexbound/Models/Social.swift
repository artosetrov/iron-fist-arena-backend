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

    // CodingKeys needed only for "class" → characterClass mapping.
    // All other keys are camelCase from backend — match Swift property names directly.
    // APIClient's .convertFromSnakeCase is overridden when CodingKeys exist,
    // so raw values must match the actual JSON keys (camelCase).
    enum CodingKeys: String, CodingKey {
        case id, friendshipId, characterName
        case characterClass = "class"
        case origin, level, pvpRating, avatar, lastActiveAt
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

    // CodingKeys needed only for "class" → characterClass mapping.
    // Backend sends camelCase — raw values must match JSON keys.
    enum CodingKeys: String, CodingKey {
        case friendshipId, id, characterName
        case characterClass = "class"
        case origin, level, pvpRating, avatar, requestedAt
    }
}

// MARK: - Social Status (badge counts)

struct SocialStatus: Codable {
    let pendingRequests: Int
    let unreadMessages: Int
    let pendingRevenges: Int
    let pendingChallenges: Int
    let totalBadge: Int
    // No CodingKeys — APIClient's .convertFromSnakeCase handles camelCase passthrough.
    // Backend sends camelCase (pendingRequests, etc.) which passes through unchanged.
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
    // No CodingKeys — all keys match camelCase from backend.
    // APIClient's .convertFromSnakeCase passes camelCase through unchanged.
}
