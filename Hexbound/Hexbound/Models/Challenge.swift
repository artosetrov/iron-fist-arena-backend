import Foundation

// MARK: - Challenge Character Info

struct ChallengeCharacterInfo: Codable, Identifiable {
    let id: String
    let characterName: String
    let characterClass: String  // raw string from API, e.g. "warrior"
    let level: Int
    let pvpRating: Int
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case characterName = "character_name"
        case characterClass = "class"  // "class" is a Swift keyword
        case level
        case pvpRating = "pvp_rating"
        case avatar
    }

    var classEnum: CharacterClass {
        CharacterClass(rawValue: characterClass) ?? .warrior
    }

    var rankName: String {
        PvPRank.fromRating(pvpRating).rawValue
    }
}

// MARK: - Incoming Challenge

struct IncomingChallenge: Codable, Identifiable {
    let id: String
    let challenger: ChallengeCharacterInfo
    let message: String?
    let goldWager: Int
    let createdAt: String  // ISO date string
    let expiresAt: String  // ISO date string

    enum CodingKeys: String, CodingKey {
        case id
        case challenger
        case message
        case goldWager = "gold_wager"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

// MARK: - Outgoing Challenge

struct OutgoingChallenge: Codable, Identifiable {
    let id: String
    let defender: ChallengeCharacterInfo
    let status: String  // "pending", "accepted", "declined", "expired", "completed"
    let message: String?
    let goldWager: Int
    let createdAt: String  // ISO date string
    let respondedAt: String?  // ISO date string, nil if not yet responded

    enum CodingKeys: String, CodingKey {
        case id
        case defender
        case status
        case message
        case goldWager = "gold_wager"
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }
}

// MARK: - Completed Challenge

struct CompletedChallenge: Codable, Identifiable {
    let id: String
    let challenger: ChallengeCharacterInfo
    let defender: ChallengeCharacterInfo
    let winnerId: String?  // nil if draw/tie
    let goldReward: Int
    let xpReward: Int
    let completedAt: String?  // ISO date string

    enum CodingKeys: String, CodingKey {
        case id
        case challenger
        case defender
        case winnerId = "winner_id"
        case goldReward = "gold_reward"
        case xpReward = "xp_reward"
        case completedAt = "completed_at"
    }
}

// MARK: - Challenges List Response

struct ChallengesResponse: Codable {
    let incoming: [IncomingChallenge]
    let outgoing: [OutgoingChallenge]
    let completed: [CompletedChallenge]
}

// MARK: - Send Challenge Request & Response

struct SendChallengeRequest: Encodable {
    let characterId: String
    let targetId: String
    let message: String?
    let goldWager: Int?

    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case targetId = "target_id"
        case message
        case goldWager = "gold_wager"
    }
}

struct SendChallengeResponse: Codable {
    let challenge: SentChallengeInfo
}

struct SentChallengeInfo: Codable {
    let id: String
    let defenderId: String
    let defenderName: String
    let status: String
    let message: String?
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case defenderId = "defender_id"
        case defenderName = "defender_name"
        case status
        case message
        case expiresAt = "expires_at"
    }
}

// MARK: - Duel Result Response

struct DuelResultResponse: Codable {
    let result: DuelResult
}

struct DuelResult: Codable {
    let matchId: String
    let challengeId: String
    let won: Bool
    let winnerId: String
    let loserId: String
    let turns: Int?
    let ratingBefore: Int
    let ratingAfter: Int
    let ratingChange: Int
    let goldReward: Int
    let xpReward: Int
    let challengerName: String
    let defenderName: String

    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case challengeId = "challenge_id"
        case won
        case winnerId = "winner_id"
        case loserId = "loser_id"
        case turns
        case ratingBefore = "rating_before"
        case ratingAfter = "rating_after"
        case ratingChange = "rating_change"
        case goldReward = "gold_reward"
        case xpReward = "xp_reward"
        case challengerName = "challenger_name"
        case defenderName = "defender_name"
    }
}

// MARK: - Challenge Actions

enum ChallengeAction: String {
    case send
    case accept
    case decline
    case cancel
}

// MARK: - Challenge Status

enum ChallengeStatus: String {
    case pending
    case accepted
    case declined
    case expired
    case completed
}
