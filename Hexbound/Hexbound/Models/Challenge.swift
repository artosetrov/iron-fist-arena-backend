import Foundation

// MARK: - Challenge Character Info

struct ChallengeCharacterInfo: Codable, Identifiable {
    let id: String
    let characterName: String
    let characterClass: String  // raw string from API, e.g. "warrior"
    let level: Int
    let pvpRating: Int
    let avatar: String?

    // CodingKeys needed only for "class" → characterClass.
    // Backend sends camelCase — raw values must match JSON keys.
    enum CodingKeys: String, CodingKey {
        case id, characterName
        case characterClass = "class"
        case level, pvpRating, avatar
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
    // No CodingKeys — all keys are camelCase from backend, matching Swift property names.
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
    // No CodingKeys — all keys are camelCase from backend.
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
    // No CodingKeys — all keys are camelCase from backend.
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
    // No CodingKeys — all keys are camelCase from backend.
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
    // No CodingKeys — all keys are camelCase from backend.
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
