import Foundation
import Observation

@MainActor
@Observable
final class InboxViewModel {
    // Unified feed
    var selectedFilter: InboxFilter = .all
    var unifiedItems: [UnifiedInboxItem] = []

    // Raw data sources
    var messages: [MailMessage] = []
    var conversations: [Conversation] = []

    // Loading / errors
    var isLoading: Bool = false
    var isLoadingScrolls: Bool = false
    var error: String?
    var scrollsError: String?

    // Pagination
    var currentPage: Int = 1
    var totalMessages: Int = 0

    // Unread
    var mailUnreadCount: Int = 0
    var scrollsUnreadCount: Int = 0

    /// Combined unread count for badge
    var totalUnreadCount: Int {
        mailUnreadCount + scrollsUnreadCount
    }

    /// Filtered items based on selected filter pill
    var filteredItems: [UnifiedInboxItem] {
        switch selectedFilter {
        case .all: return unifiedItems
        case .battles: return unifiedItems.filter { $0.category == .battles }
        case .messages: return unifiedItems.filter { $0.category == .messages }
        case .system: return unifiedItems.filter { $0.category == .system }
        }
    }

    private let apiClient = APIClient.shared
    private let messageService = MessageService.shared

    // MARK: - Unified Feed

    /// Merges mail + conversations into a single timeline sorted by date (newest first).
    /// Unread items float to the top within their date ordering.
    private func rebuildUnifiedFeed() {
        var items: [UnifiedInboxItem] = []
        for msg in messages {
            items.append(.mail(msg))
        }
        for conv in conversations {
            items.append(.conversation(conv))
        }
        // Sort: unread first, then by date descending
        items.sort { a, b in
            if a.isUnread != b.isUnread { return a.isUnread }
            return a.sortDate > b.sortDate
        }
        unifiedItems = items
    }

    // MARK: - Fetch All

    func fetchAll(characterId: String) async {
        async let mailTask: () = fetchInbox(characterId: characterId)
        async let scrollsTask: () = loadConversations(characterId: characterId)
        _ = await (mailTask, scrollsTask)
        rebuildUnifiedFeed()
    }

    // MARK: - Fetch Mail

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
            mailUnreadCount = response.unreadCount
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
        rebuildUnifiedFeed()
    }

    func fetchUnreadCount(characterId: String) async {
        do {
            let response: MailUnreadResponse = try await apiClient.get(
                "/api/mail/unread-count",
                params: ["character_id": characterId]
            )
            mailUnreadCount = response.unreadCount
        } catch {
            // silent — badge update only
        }
    }

    // MARK: - Fetch Conversations (Scrolls)

    func loadConversations(characterId: String) async {
        if conversations.isEmpty {
            isLoadingScrolls = true
        }
        scrollsError = nil
        do {
            let response = try await messageService.getConversations(characterId: characterId)
            conversations = response
            scrollsUnreadCount = response.reduce(0) { $0 + $1.unreadCount }
            isLoadingScrolls = false
        } catch {
            if conversations.isEmpty {
                scrollsError = error.localizedDescription
            }
            isLoadingScrolls = false
        }
        rebuildUnifiedFeed()
    }

    func fetchScrollsUnreadCount(characterId: String) async {
        do {
            let response = try await messageService.getConversations(characterId: characterId)
            scrollsUnreadCount = response.reduce(0) { $0 + $1.unreadCount }
        } catch {
            // silent — badge update only
        }
    }

    // MARK: - Mail Actions

    func markAsRead(messageId: String, characterId: String) {
        // Optimistic: mark read instantly
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx] = messages[idx].withRead()
        }
        mailUnreadCount = max(0, mailUnreadCount - 1)
        rebuildUnifiedFeed()

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
        rebuildUnifiedFeed()
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
                rebuildUnifiedFeed()
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
        rebuildUnifiedFeed()
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
                rebuildUnifiedFeed()
                appState.showToast("Failed to delete mail", subtitle: "Please try again", type: .error)
            }
        }
    }
}
