import Foundation

private struct SocialFriendActionRequest: Encodable {
    let characterId: String
    let targetId: String
    let action: String
}

private struct SocialReportRequest: Encodable {
    let characterId: String
    let targetId: String
    let category: String
    let reason: String?
    let contextType: String
    let contextId: String?
}

private struct SocialReportResponse: Decodable {
    let reported: Bool
    let duplicate: Bool
}

/// Report categories — must match `REPORT_CATEGORIES` in backend/src/lib/moderation.ts.
enum ReportCategory: String, CaseIterable, Identifiable {
    case harassment, hate, spam, cheating, inappropriateName = "inappropriate_name", other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .harassment: return "Harassment or bullying"
        case .hate: return "Hate speech"
        case .spam: return "Spam"
        case .cheating: return "Cheating or exploits"
        case .inappropriateName: return "Inappropriate name"
        case .other: return "Something else"
        }
    }
}

enum ReportContext: String {
    case profile, message, challenge, leaderboard
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

    // MARK: - Report (UGC moderation — App Store 1.2)

    /// Files a report against `targetId`. Returns true when accepted
    /// (including the "already reported today" case — the player should not
    /// be told their report was ignored).
    func report(
        characterId: String,
        targetId: String,
        category: ReportCategory,
        context: ReportContext = .profile,
        contextId: String? = nil,
        reason: String? = nil
    ) async -> Bool {
        do {
            let response: SocialReportResponse = try await APIClient.shared.post(
                APIEndpoints.socialReport,
                body: SocialReportRequest(
                    characterId: characterId,
                    targetId: targetId,
                    category: category.rawValue,
                    reason: reason,
                    contextType: context.rawValue,
                    contextId: contextId
                )
            )
            return response.reported
        } catch {
            #if DEBUG
            print("[SocialService] report error: \(error)")
            #endif
            return false
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


// MARK: - Report dialog (SwiftUI)

import SwiftUI

/// `confirmationDialog` listing report categories; on pick → `SocialService.report`
/// → toast. Use via `.reportPlayerDialog(isPresented:targetId:targetName:context:contextId:)`.
/// Lives here (not its own file) so it needs no project.pbxproj entry.
struct ReportPlayerDialogModifier: ViewModifier {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool
    let targetId: String
    let targetName: String
    let context: ReportContext
    let contextId: String?

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Report \(targetName)",
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            ForEach(ReportCategory.allCases) { category in
                Button(category.label) { submit(category) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Reports are reviewed by the Hexbound team. Abuse of reporting may be actioned.")
        }
    }

    private func submit(_ category: ReportCategory) {
        guard let charId = appState.currentCharacter?.id else { return }
        HapticManager.light()
        Task { @MainActor in
            let ok = await SocialService.shared.report(
                characterId: charId,
                targetId: targetId,
                category: category,
                context: context,
                contextId: contextId
            )
            if ok {
                appState.showToast("Report sent", subtitle: "Thanks — we'll take a look.", type: .info)
            } else {
                appState.showToast("Couldn't send report", subtitle: "Check connection and try again", type: .error)
            }
        }
    }
}

extension View {
    func reportPlayerDialog(
        isPresented: Binding<Bool>,
        targetId: String,
        targetName: String,
        context: ReportContext = .profile,
        contextId: String? = nil
    ) -> some View {
        modifier(ReportPlayerDialogModifier(
            isPresented: isPresented,
            targetId: targetId,
            targetName: targetName,
            context: context,
            contextId: contextId
        ))
    }
}
