import Foundation

private struct SocialFriendActionRequest: Encodable {
    let characterId: String
    let targetId: String
    let action: String
}

private struct SocialActionResponse: Decodable {
    let message: String?
}

private struct FriendshipStatusRequest: Encodable {
    let characterId: String
    let targetId: String
}

@MainActor
class SocialService {
    static let shared = SocialService()

    // MARK: - Friends List

    /// Fetches friends list. Throws on failure so caller can distinguish error types.
    func getFriends(characterId: String) async throws -> FriendsListResponse {
        let response: FriendsListResponse = try await APIClient.shared.get(
            APIEndpoints.socialFriends,
            params: ["character_id": characterId]
        )
        return response
    }

    // MARK: - Friend Actions

    /// Returns nil on success, or error message string on failure.
    func sendFriendRequest(characterId: String, targetId: String) async -> String? {
        return await performActionWithError(characterId: characterId, targetId: targetId, action: "request")
    }

    func acceptFriendRequest(characterId: String, requesterId: String) async -> Bool {
        return await performAction(characterId: characterId, targetId: requesterId, action: "accept")
    }

    func declineFriendRequest(characterId: String, requesterId: String) async -> Bool {
        return await performAction(characterId: characterId, targetId: requesterId, action: "decline")
    }

    func removeFriend(characterId: String, friendId: String) async -> Bool {
        return await performAction(characterId: characterId, targetId: friendId, action: "remove")
    }

    func blockUser(characterId: String, targetId: String) async -> Bool {
        return await performAction(characterId: characterId, targetId: targetId, action: "block")
    }

    func unblockUser(characterId: String, targetId: String) async -> Bool {
        return await performAction(characterId: characterId, targetId: targetId, action: "unblock")
    }

    private func performAction(characterId: String, targetId: String, action: String) async -> Bool {
        do {
            let body = SocialFriendActionRequest(
                characterId: characterId,
                targetId: targetId,
                action: action
            )
            let _: SocialActionResponse = try await APIClient.shared.post(
                APIEndpoints.socialFriends,
                body: body
            )
            return true
        } catch {
            #if DEBUG
            print("[SocialService] \(action) error: \(error)")
            #endif
            return false
        }
    }

    /// Like performAction but returns nil on success, or error message on failure.
    private func performActionWithError(characterId: String, targetId: String, action: String) async -> String? {
        do {
            let body = SocialFriendActionRequest(
                characterId: characterId,
                targetId: targetId,
                action: action
            )
            let _: SocialActionResponse = try await APIClient.shared.post(
                APIEndpoints.socialFriends,
                body: body
            )
            return nil
        } catch let apiError as APIError {
            switch apiError {
            case .serverError(_, let message):
                return message
            case .clientError(_, let message, _):
                return message
            default:
                return "Network error"
            }
        } catch {
            return "Network error"
        }
    }

    // MARK: - Social Status (Badge Counts)

    func getSocialStatus(characterId: String) async -> SocialStatus? {
        do {
            let response: SocialStatus = try await APIClient.shared.get(
                APIEndpoints.socialStatus,
                params: ["character_id": characterId]
            )
            return response
        } catch {
            #if DEBUG
            print("[SocialService] getSocialStatus error: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Friendship Status (for button states)

    func getFriendshipStatus(characterId: String, targetId: String) async -> FriendshipButtonState {
        do {
            let body = FriendshipStatusRequest(
                characterId: characterId,
                targetId: targetId
            )
            let response: FriendshipStatusResponse = try await APIClient.shared.post(
                APIEndpoints.socialStatus,
                body: body
            )
            switch response.status {
            case "friends": return .friends
            case "request_sent": return .requestSent
            case "request_received": return .requestReceived
            case "blocked": return .blocked
            case "blocked_by": return .blockedBy
            default: return .none
            }
        } catch {
            #if DEBUG
            print("[SocialService] getFriendshipStatus error: \(error)")
            #endif
            return .none
        }
    }
}
