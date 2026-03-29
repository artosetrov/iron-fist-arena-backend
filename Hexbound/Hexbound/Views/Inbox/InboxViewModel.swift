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

    func markAsRead(messageId: String, characterId: String) {
        // Optimistic: mark read instantly
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx] = messages[idx].withRead()
        }
        unreadCount = max(0, unreadCount - 1)

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            do {
                let _: SuccessResponse = try await apiClient.post(
                    "/api/mail/\(messageId)/read",
                    body: ["character_id": characterId]
                )
            } catch {
                // Revert — re-fetch to get accurate state
                await fetchInbox(characterId: characterId)
            }
        }
    }

    func claimAttachments(messageId: String, characterId: String, appState: AppState) {
        // Save for revert
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        let savedMessage = messages[idx]

        // Optimistic: mark claimed instantly
        messages[idx] = messages[idx].withClaimed()
        HapticManager.success()
        SFXManager.shared.play(.uiRewardClaim)

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            do {
                let _: MailClaimResponse = try await apiClient.post(
                    "/api/mail/\(messageId)/claim",
                    body: ["character_id": characterId]
                )
            } catch {
                // Revert on failure
                if let revertIdx = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[revertIdx] = savedMessage
                }
                appState.showToast("Failed to claim rewards", subtitle: "Please try again", type: .error)
            }
        }
    }

    func deleteMail(messageId: String, characterId: String, appState: AppState) {
        // Save for revert
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        let savedMessage = messages[idx]
        let savedIndex = idx

        // Optimistic: remove instantly
        messages.remove(at: idx)
        totalMessages -= 1
        HapticManager.light()

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            do {
                let _: SuccessResponse = try await apiClient.post(
                    "/api/mail/\(messageId)/delete",
                    body: ["character_id": characterId]
                )
            } catch {
                // Revert on failure
                let insertAt = min(savedIndex, messages.count)
                messages.insert(savedMessage, at: insertAt)
                totalMessages += 1
                appState.showToast("Failed to delete mail", subtitle: "Please try again", type: .error)
            }
        }
    }
}
