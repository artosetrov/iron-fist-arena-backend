import Foundation

// MARK: - Conversation List Item (from GET /api/social/messages)

struct Conversation: Codable, Identifiable {
    let otherCharacter: ConversationCharacterInfo
    let lastMessage: ConversationLastMessage
    let unreadCount: Int

    var id: String {
        otherCharacter.id
    }

    enum CodingKeys: String, CodingKey {
        case otherCharacter = "otherCharacter"
        case lastMessage = "lastMessage"
        case unreadCount = "unreadCount"
    }
}

// MARK: - Conversation Character Info (nested in Conversation)

struct ConversationCharacterInfo: Codable, Identifiable {
    let id: String
    let characterName: String
    let characterClass: String  // raw string from API, e.g. "warrior"
    let level: Int
    let pvpRating: Int
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case characterName = "characterName"
        case characterClass = "class"  // "class" is a Swift keyword
        case level
        case pvpRating = "pvpRating"
        case avatar
    }

    var classEnum: CharacterClass {
        CharacterClass(rawValue: characterClass) ?? .warrior
    }

    var rankName: String {
        PvPRank.fromRating(pvpRating).rawValue
    }
}

// MARK: - Conversation Last Message (nested in Conversation)

struct ConversationLastMessage: Codable {
    let content: String
    let createdAt: String  // ISO date
    let isRead: Bool
    let senderId: String

    enum CodingKeys: String, CodingKey {
        case content
        case createdAt = "createdAt"
        case isRead = "isRead"
        case senderId = "senderId"
    }
}

// MARK: - Direct Message Item (in thread)

struct DirectMessageItem: Codable, Identifiable {
    let id: String
    let senderId: String
    let content: String
    let isQuick: Bool
    let quickId: String?
    let isRead: Bool
    let createdAt: String  // ISO date

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "senderId"
        case content
        case isQuick = "isQuick"
        case quickId = "quickId"
        case isRead = "isRead"
        case createdAt = "createdAt"
    }
}

// MARK: - Quick Message Presets

enum QuickMessage: String, CaseIterable {
    case gg = "gg"
    case rematch = "rematch"
    case thanks = "thanks"
    case niceFight = "nice_fight"
    case wellPlayed = "well_played"
    case haha = "haha"
    case wow = "wow"
    case oops = "oops"

    var displayText: String {
        switch self {
        case .gg: "Good game!"
        case .rematch: "Rematch?"
        case .thanks: "Thanks!"
        case .niceFight: "Nice fight!"
        case .wellPlayed: "Well played!"
        case .haha: "Haha!"
        case .wow: "Wow!"
        case .oops: "Oops!"
        }
    }

    var icon: String {
        switch self {
        case .gg: "hand.thumbsup.fill"
        case .rematch: "arrow.triangle.2.circlepath"
        case .thanks: "heart.fill"
        case .niceFight: "flame.fill"
        case .wellPlayed: "star.fill"
        case .haha: "face.smiling.fill"
        case .wow: "exclamationmark.circle.fill"
        case .oops: "hand.wave.fill"
        }
    }
}

// MARK: - API Responses

struct ConversationsResponse: Codable {
    let conversations: [Conversation]
}

struct MessagesResponse: Codable {
    let messages: [DirectMessageItem]
}

struct SendMessageResponse: Codable {
    let message: SentMessageInfo
}

struct SentMessageInfo: Codable {
    let id: String
    let content: String
    let createdAt: String
    let quickId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt = "createdAt"
        case quickId = "quickId"
    }
}
