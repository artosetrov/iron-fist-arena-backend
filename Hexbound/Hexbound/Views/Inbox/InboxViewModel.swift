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

    // MARK: - Last-known snapshot (latency pass 2026-10-15)
    //
    // The inbox had no cache at all: every open showed skeletons for a full
    // round trip. The last feed is kept for the session (per hero) and shown
    // instantly on the next open while `fetchAll` revalidates.
    private struct Snapshot {
        let characterId: String
        let messages: [MailMessage]
        let conversations: [Conversation]
        let mailUnread: Int
        let scrollsUnread: Int
    }
    private static var lastSnapshot: Snapshot?
    private var characterId: String?

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
        // Every mutation ends here, so the snapshot never lags a claim/read.
        if let characterId {
            Self.lastSnapshot = Snapshot(
                characterId: characterId,
                messages: messages,
                conversations: conversations,
                mailUnread: mailUnreadCount,
                scrollsUnread: scrollsUnreadCount
            )
        }
    }

    // MARK: - Fetch All

    func fetchAll(characterId: String) async {
        if self.characterId != characterId {
            self.characterId = characterId
            if messages.isEmpty, conversations.isEmpty,
               let snapshot = Self.lastSnapshot, snapshot.characterId == characterId {
                messages = snapshot.messages
                conversations = snapshot.conversations
                mailUnreadCount = snapshot.mailUnread
                scrollsUnreadCount = snapshot.scrollsUnread
                rebuildUnifiedFeed()
            }
        }
        async let mailTask: () = fetchInbox(characterId: characterId)
        async let scrollsTask: () = loadConversations(characterId: characterId)
        _ = await (mailTask, scrollsTask)
        rebuildUnifiedFeed()
    }

    // MARK: - Fetch Mail

    func fetchInbox(characterId: String, page: Int = 1) async {
        // Skeleton only when there is nothing on screen.
        isLoading = messages.isEmpty
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
                // Revert only the affected message
                if let idx = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[idx] = messages[idx].withUnread()
                    mailUnreadCount += 1
                    rebuildUnifiedFeed()
                }
            }
        }
    }

    private var claimingMessageIds: Set<String> = []

    func claimAttachments(messageId: String, characterId: String, appState: AppState) {
        guard !claimingMessageIds.contains(messageId) else { return }
        claimingMessageIds.insert(messageId)

        // Save for revert
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else {
            claimingMessageIds.remove(messageId)
            return
        }
        let savedMessage = messages[idx]

        // Optimistic: mark claimed instantly
        messages[idx] = messages[idx].withClaimed()
        rebuildUnifiedFeed()

        // Latency pass (2026-10-15): the attachments say exactly what the
        // server will grant, so the CLAIMED modal (root queue) and the
        // gold/gems/xp credit land on the tap. This also fixes the modal
        // showing ACCOUNT TOTALS ("+12,345 gold"): it used `response.gold`,
        // which is the post-claim balance, not the amount claimed.
        let attachments = savedMessage.attachments ?? []
        let credit = appState.creditRewardOptimistically(
            gold: Self.sum(attachments, type: "gold"),
            gems: Self.sum(attachments, type: "gems"),
            xp: Self.sum(attachments, type: "xp")
        )
        let config = buildClaimRewardConfig(message: savedMessage, attachments: attachments)
        appState.claimRewardConfig = config
        let previousLevel = appState.currentCharacter?.level

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            defer { claimingMessageIds.remove(messageId) }
            do {
                let response: MailClaimResponse = try await apiClient.post(
                    "/api/mail/\(messageId)/claim",
                    body: ["character_id": characterId]
                )

                appState.applyAuthoritativeRewardState(
                    gold: response.gold,
                    gems: response.gems,
                    xp: response.xp,
                    leveledUp: response.leveledUp,
                    newLevel: response.newLevel,
                    statPointsAwarded: response.statPointsAwarded,
                    passivePointsAwarded: response.passivePointsAwarded,
                    previousLevel: previousLevel
                )
                if response.claimed?.contains(where: { $0.type == "item" || $0.type == "consumable" }) == true {
                    appState.cachedInventory = nil
                }
            } catch {
                // Revert on failure
                appState.revertRewardCredit(credit)
                appState.withdrawClaimReward(config)
                if let revertIdx = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[revertIdx] = savedMessage
                }
                rebuildUnifiedFeed()
                appState.showToast("Failed to claim rewards", subtitle: "Please try again", type: .error)
            }
        }
    }

    private static func sum(_ attachments: [MailAttachment], type: String) -> Int {
        attachments.filter { $0.type == type }.reduce(0) { $0 + $1.amount }
    }

    private func buildClaimRewardConfig(
        message: MailMessage,
        attachments: [MailAttachment]
    ) -> ClaimRewardConfig {
        ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: message.subject,
            goldReward: Self.sum(attachments, type: "gold"),
            gemsReward: Self.sum(attachments, type: "gems"),
            xpReward: Self.sum(attachments, type: "xp"),
            lootItems: attachments.compactMap(buildLootItem)
        )
    }

    private func buildLootItem(from attachment: MailAttachment) -> ClaimLootItem? {
        switch attachment.type {
        case "consumable":
            return ClaimLootItem(
                id: attachment.itemId ?? UUID().uuidString,
                name: consumableName(attachment.itemId),
                quantity: attachment.amount,
                imageKey: attachment.itemId,
                fallbackIcon: "cross.vial",
                rarity: .uncommon,
                rarityColor: DarkFantasyTheme.rarityUncommon
            )
        case "item":
            return ClaimLootItem(
                id: attachment.itemId ?? UUID().uuidString,
                name: attachment.itemId ?? "Item",
                quantity: attachment.amount,
                imageKey: attachment.itemId,
                fallbackIcon: "shippingbox",
                rarity: .rare,
                rarityColor: DarkFantasyTheme.rarityRare
            )
        default:
            return nil
        }
    }

    private func consumableName(_ id: String?) -> String {
        guard let id else { return "Potion" }
        return id
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
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
