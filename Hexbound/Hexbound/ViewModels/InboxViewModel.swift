import Foundation
import Observation

@MainActor
@Observable
final class InboxViewModel {
    var messages: [MailMessage] = []
    var unreadCount: Int = 0
    var isLoading: Bool = false
    var error: String?
    var currentPage: Int = 1
    var totalMessages: Int = 0

    private let apiClient = APIClient.shared

    // MARK: - Fetch

    func fetchInbox(characterId: String, page: Int = 1) async {
        isLoading = true
        error = nil
        do {
            let response: MailInboxResponse = try await apiClient.get(
                "/api/mail",
                params: [
                    "character_id": characterId,
                    "page": String(page),
                    "limit": "50",
                ]
            )
            messages = response.messages
            totalMessages = response.total
            currentPage = response.page
            unreadCount = response.unreadCount
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func fetchUnreadCount(characterId: String) async {
        do {
            let response: MailUnreadResponse = try await apiClient.get(
                "/api/mail/unread-count",
                params: ["character_id": characterId]
            )
            unreadCount = response.unreadCount
        } catch {
            // silent — badge update only
        }
    }

    // MARK: - Actions

    func markAsRead(messageId: String, characterId: String) async {
        do {
            let _: SuccessResponse = try await apiClient.post(
                "/api/mail/\(messageId)/read",
                body: ["character_id": characterId]
            )
            if let idx = messages.firstIndex(where: { $0.id == messageId }) {
                messages[idx] = messages[idx].withRead()
            }
            unreadCount = max(0, unreadCount - 1)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func claimAttachments(messageId: String, characterId: String) async {
        do {
            let _: MailClaimResponse = try await apiClient.post(
                "/api/mail/\(messageId)/claim",
                body: ["character_id": characterId]
            )
            if let idx = messages.firstIndex(where: { $0.id == messageId }) {
                messages[idx] = messages[idx].withClaimed()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteMail(messageId: String, characterId: String) async {
        do {
            let _: SuccessResponse = try await apiClient.post(
                "/api/mail/\(messageId)/delete",
                body: ["character_id": characterId]
            )
            messages.removeAll { $0.id == messageId }
            totalMessages -= 1
        } catch {
            self.error = error.localizedDescription
        }
    }
}
