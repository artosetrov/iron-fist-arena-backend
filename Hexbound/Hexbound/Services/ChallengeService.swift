import Foundation

// MARK: - Request Bodies

private struct SendChallengeBody: Encodable {
    let characterId: String
    let targetId: String
    let action: String
    let message: String?
    let goldWager: Int?

    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case targetId = "target_id"
        case action, message
        case goldWager = "gold_wager"
    }
}

private struct ChallengeActionBody: Encodable {
    let characterId: String
    let challengeId: String
    let action: String

    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case challengeId = "challenge_id"
        case action
    }
}

@MainActor
final class ChallengeService {
    static let shared = ChallengeService()
    private init() {}

    // MARK: - Get All Challenges

    /// Fetches incoming, outgoing, and completed challenges for a character.
    /// - Parameter characterId: The character ID
    /// - Returns: ChallengesResponse with three challenge lists
    func getChallenges(characterId: String) async throws -> ChallengesResponse {
        do {
            let response: ChallengesResponse = try await APIClient.shared.get(
                APIEndpoints.socialChallenges,
                params: ["character_id": characterId]
            )
            return response
        } catch {
            #if DEBUG
            print("[ChallengeService] getChallenges error: \(error)")
            #endif
            throw error
        }
    }

    // MARK: - Send Challenge

    /// Sends a new challenge to another player.
    /// - Parameters:
    ///   - characterId: The challenger's character ID
    ///   - targetId: The defender's character ID
    ///   - message: Optional challenge message
    ///   - goldWager: Optional gold amount to wager
    /// - Returns: SentChallengeInfo with challenge details
    func sendChallenge(
        characterId: String,
        targetId: String,
        message: String?,
        goldWager: Int? = nil
    ) async throws -> SentChallengeInfo {
        do {
            let body = SendChallengeBody(
                characterId: characterId,
                targetId: targetId,
                action: "send",
                message: message,
                goldWager: goldWager
            )
            let response: SendChallengeResponse = try await APIClient.shared.post(
                APIEndpoints.socialChallenges,
                body: body
            )
            return response.challenge
        } catch {
            #if DEBUG
            print("[ChallengeService] sendChallenge error: \(error)")
            #endif
            throw error
        }
    }

    // MARK: - Accept Challenge

    /// Accepts an incoming challenge and triggers the duel.
    /// - Parameters:
    ///   - characterId: The defender's character ID
    ///   - challengeId: The challenge ID to accept
    /// - Returns: DuelResult with match outcome
    func acceptChallenge(
        characterId: String,
        challengeId: String
    ) async throws -> DuelResult {
        do {
            let body = ChallengeActionBody(
                characterId: characterId,
                challengeId: challengeId,
                action: "accept"
            )
            let response: DuelResultResponse = try await APIClient.shared.post(
                APIEndpoints.socialChallenges,
                body: body
            )
            return response.result
        } catch {
            #if DEBUG
            print("[ChallengeService] acceptChallenge error: \(error)")
            #endif
            throw error
        }
    }

    // MARK: - Decline Challenge

    /// Declines an incoming challenge.
    /// - Parameters:
    ///   - characterId: The defender's character ID
    ///   - challengeId: The challenge ID to decline
    func declineChallenge(
        characterId: String,
        challengeId: String
    ) async throws {
        do {
            let body: [String: Any] = [
                "character_id": characterId,
                "challenge_id": challengeId,
                "action": "decline"
            ]
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.socialChallenges,
                body: body
            )
        } catch {
            #if DEBUG
            print("[ChallengeService] declineChallenge error: \(error)")
            #endif
            throw error
        }
    }

    // MARK: - Cancel Challenge

    /// Cancels an outgoing challenge that hasn't been accepted yet.
    /// - Parameters:
    ///   - characterId: The challenger's character ID
    ///   - challengeId: The challenge ID to cancel
    func cancelChallenge(
        characterId: String,
        challengeId: String
    ) async throws {
        do {
            let body: [String: Any] = [
                "character_id": characterId,
                "challenge_id": challengeId,
                "action": "cancel"
            ]
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.socialChallenges,
                body: body
            )
        } catch {
            #if DEBUG
            print("[ChallengeService] cancelChallenge error: \(error)")
            #endif
            throw error
        }
    }
}
