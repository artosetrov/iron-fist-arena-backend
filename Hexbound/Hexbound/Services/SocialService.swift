import Foundation

@MainActor
class SocialService {
    static let shared = SocialService()

    // MARK: - Friends List

    func getFriends(characterId: String) async -> FriendsListResponse? {
        do {
            let response: FriendsListResponse = try await APIClient.shared.get(
                APIEndpoints.socialFriends,
                params: ["character_id": characterId]
            )
            return response
        } catch {
            #if DEBUG
            print("[SocialService] getFriends error: \(error)")
            #endif
            return nil
        }
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
            let body: [String: Any] = [
                "character_id": characterId,
                "target_id": targetId,
                "action": action,
            ]
            _ = try await APIClient.shared.postRaw(
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
            let body: [String: Any] = [
                "character_id": characterId,
                "target_id": targetId,
                "action": action,
            ]
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.socialFriends,
                body: body
            )
            return nil  // success
        } catch let apiError as APIError {
            switch apiError {
            case .serverError(_, let message):
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
            let body: [String: Any] = [
                "character_id": characterId,
                "target_id": targetId,
            ]
            let raw = try await APIClient.shared.postRaw(
                APIEndpoints.socialStatus,
                body: body
            )
            guard let status = raw["status"] as? String else { return .none }
            switch status {
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
