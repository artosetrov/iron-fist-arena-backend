import Foundation
import SwiftUI

@MainActor @Observable
class GuildHallViewModel {
    enum Tab: String, CaseIterable {
        case allies = "ALLIES"
        case scrolls = "SCROLLS"
        case duels = "DUELS"
    }

    enum LoadState {
        case idle, loading, loaded, error
    }

    var selectedTab: Tab = .allies
    var loadState: LoadState = .idle

    // Allies tab
    var friends: [FriendEntry] = []
    var incomingRequests: [FriendRequest] = []
    var outgoingRequests: [FriendRequest] = []
    var friendCount: Int = 0
    var maxFriends: Int = 50

    // Scrolls tab
    var conversations: [Conversation] = []
    var scrollsLoadState: LoadState = .idle
    var activeThread: [DirectMessageItem] = []
    var activeThreadCharacterId: String?
    var activeThreadCharacterName: String?
    var activeThreadCharacterAvatar: String?
    var activeThreadCharacterClass: String?
    var threadLoadState: LoadState = .idle
    var isSendingMessage = false
    var isLoadingThreadMessages = false
    var composedMessage = ""

    // Duels tab
    var incomingChallenges: [IncomingChallenge] = []
    var outgoingChallenges: [OutgoingChallenge] = []
    var completedChallenges: [CompletedChallenge] = []
    var duelsLoadState: LoadState = .idle
    var duelResult: DuelResult?
    var showDuelResult = false

    // Processing states
    var processingRequestId: String?
    var processingFriendId: String?
    var processingChallengeId: String?
    var sendMessageError: String?
    var actionError: String?

    // Thread polling
    private var isPollingActive = false

    private let socialService = SocialService.shared
    private let challengeService = ChallengeService.shared
    private let messageService = MessageService.shared
    private var characterId: String

    init(characterId: String) {
        self.characterId = characterId
    }

    // MARK: - Thread Polling (auto-refresh incoming messages)

    func startThreadPolling() {
        guard !isPollingActive else { return }
        isPollingActive = true
        Task { [weak self] in
            while let self, self.isPollingActive, self.activeThreadCharacterId != nil {
                try? await Task.sleep(for: .seconds(5))
                guard self.isPollingActive, let targetId = self.activeThreadCharacterId else { break }
                // Silent refresh — don't reset loading state
                if let messages = try? await self.messageService.getThread(
                    characterId: self.characterId,
                    withCharacterId: targetId
                ) {
                    // Only update if new messages arrived (avoid UI flicker)
                    // Backend returns ASC order — last element is newest
                    if messages.count != self.activeThread.count ||
                       messages.last?.id != self.activeThread.last?.id {
                        self.activeThread = messages
                    }
                }
            }
        }
    }

    func stopThreadPolling() {
        isPollingActive = false
    }

    // MARK: - Load Data

    func loadFriends() async {
        loadState = .loading
        guard let response = await socialService.getFriends(characterId: characterId) else {
            loadState = .error
            return
        }

        friends = response.friends.sorted { f1, f2 in
            // Online first, then by name
            let s1 = f1.onlineStatus
            let s2 = f2.onlineStatus
            if s1 != s2 {
                return onlineOrder(s1) < onlineOrder(s2)
            }
            return f1.characterName < f2.characterName
        }
        incomingRequests = response.incomingRequests
        outgoingRequests = response.outgoingRequests
        friendCount = response.count
        maxFriends = response.maxFriends
        loadState = .loaded
    }

    private func onlineOrder(_ status: OnlineStatus) -> Int {
        switch status {
        case .online: return 0
        case .away: return 1
        case .offline: return 2
        }
    }

    // MARK: - Friend Actions (Optimistic UI)

    /// Result of an optimistic action — caller shows toast based on this
    enum ActionResult {
        case success
        case failed(String)
    }

    func acceptRequest(_ request: FriendRequest) -> ActionResult {
        // Optimistic: remove from requests, add to friends
        let savedRequests = incomingRequests
        let savedFriends = friends
        let savedCount = friendCount
        incomingRequests.removeAll { $0.friendshipId == request.friendshipId }
        let newFriend = FriendEntry(
            id: request.id,
            friendshipId: request.friendshipId,
            characterName: request.characterName,
            characterClass: request.characterClass,
            origin: request.origin,
            level: request.level,
            pvpRating: request.pvpRating,
            avatar: request.avatar,
            lastActiveAt: nil
        )
        friends.append(newFriend)
        friendCount = friends.count
        HapticManager.light()

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            let success = await self.socialService.acceptFriendRequest(
                characterId: self.characterId,
                requesterId: request.id
            )
            if !success {
                self.incomingRequests = savedRequests
                self.friends = savedFriends
                self.friendCount = savedCount
                self.actionError = "Failed to accept request"
            } else {
                // Silently refresh to get accurate data
                await self.loadFriends()
            }
        }
        return .success
    }

    func declineRequest(_ request: FriendRequest) -> ActionResult {
        let savedRequests = incomingRequests
        incomingRequests.removeAll { $0.friendshipId == request.friendshipId }
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            let success = await self.socialService.declineFriendRequest(
                characterId: self.characterId,
                requesterId: request.id
            )
            if !success {
                self.incomingRequests = savedRequests
                self.actionError = "Failed to decline request"
            }
        }
        return .success
    }

    func removeFriend(_ friend: FriendEntry) -> ActionResult {
        let savedFriends = friends
        let savedCount = friendCount
        friends.removeAll { $0.id == friend.id }
        friendCount = friends.count
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            let success = await self.socialService.removeFriend(
                characterId: self.characterId,
                friendId: friend.id
            )
            if !success {
                self.friends = savedFriends
                self.friendCount = savedCount
                self.actionError = "Failed to remove ally"
            }
        }
        return .success
    }

    func blockUser(_ targetId: String) -> ActionResult {
        let savedFriends = friends
        let savedRequests = incomingRequests
        let savedCount = friendCount
        friends.removeAll { $0.id == targetId }
        incomingRequests.removeAll { $0.id == targetId }
        friendCount = friends.count
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            let success = await self.socialService.blockUser(
                characterId: self.characterId,
                targetId: targetId
            )
            if !success {
                self.friends = savedFriends
                self.incomingRequests = savedRequests
                self.friendCount = savedCount
                self.actionError = "Failed to block user"
            }
        }
        return .success
    }

    // MARK: - Computed

    var onlineFriends: [FriendEntry] {
        friends.filter { $0.onlineStatus == .online || $0.onlineStatus == .away }
    }

    var offlineFriends: [FriendEntry] {
        friends.filter { $0.onlineStatus == .offline }
    }

    var alliesBadgeCount: Int {
        incomingRequests.count
    }

    var duelsBadgeCount: Int {
        incomingChallenges.count
    }

    var scrollsBadgeCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Scrolls (Messages)

    func loadConversations() async {
        // Cache-first: only show skeleton if no cached conversations
        if conversations.isEmpty {
            scrollsLoadState = .loading
        }
        do {
            let response = try await messageService.getConversations(characterId: characterId)
            conversations = response
            scrollsLoadState = .loaded
        } catch {
            if conversations.isEmpty {
                scrollsLoadState = .error
            }
        }
    }

    func openThread(characterId targetId: String, characterName: String, avatar: String? = nil, characterClass: String? = nil) async {
        activeThreadCharacterId = targetId
        activeThreadCharacterName = characterName
        activeThreadCharacterAvatar = avatar ?? conversations.first(where: { $0.otherCharacter.id == targetId })?.otherCharacter.avatar
        activeThreadCharacterClass = characterClass ?? conversations.first(where: { $0.otherCharacter.id == targetId })?.otherCharacter.characterClass
        // Show thread UI instantly — messages load in background
        threadLoadState = .loaded
        composedMessage = ""
        activeThread = []
        isLoadingThreadMessages = true
        do {
            let messages = try await messageService.getThread(
                characterId: characterId,
                withCharacterId: targetId
            )
            withAnimation(.easeOut(duration: 0.2)) {
                activeThread = messages
            }
            isLoadingThreadMessages = false
            // Background: refresh conversations to update read status
            Task { [weak self] in
                await self?.loadConversations()
            }
        } catch {
            isLoadingThreadMessages = false
            if activeThread.isEmpty {
                threadLoadState = .error
            }
        }
    }

    func sendMessage() async {
        guard let targetId = activeThreadCharacterId else { return }
        let content = composedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, content.count <= 200 else { return }

        // Optimistic: show message immediately
        let tempId = "temp-\(UUID().uuidString)"
        let optimisticMsg = DirectMessageItem(
            id: tempId,
            senderId: characterId,
            content: content,
            isQuick: false,
            quickId: nil,
            isRead: false,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        withAnimation(.easeOut(duration: 0.25)) {
            activeThread.append(optimisticMsg)
        }
        composedMessage = ""
        HapticManager.light()

        // Background: actual API call
        sendMessageError = nil
        do {
            let sent = try await messageService.sendMessage(
                characterId: characterId,
                targetId: targetId,
                content: content
            )
            // Replace temp message with real one (animated status change)
            withAnimation(.easeInOut(duration: 0.2)) {
                if let idx = activeThread.firstIndex(where: { $0.id == tempId }) {
                    activeThread[idx] = DirectMessageItem(
                        id: sent.id,
                        senderId: characterId,
                        content: sent.content,
                        isQuick: false,
                        quickId: nil,
                        isRead: false,
                        createdAt: sent.createdAt
                    )
                }
            }
        } catch {
            // Remove optimistic message on failure
            withAnimation(.easeOut(duration: 0.2)) {
                activeThread.removeAll(where: { $0.id == tempId })
            }
            sendMessageError = "Failed to send message"
        }
    }

    func sendQuickMessage(_ quickId: String) async {
        guard let targetId = activeThreadCharacterId else { return }

        // Optimistic: show quick message immediately
        let quick = QuickMessage(rawValue: quickId)
        let tempId = "temp-quick-\(UUID().uuidString)"
        let optimisticMsg = DirectMessageItem(
            id: tempId,
            senderId: characterId,
            content: quick?.displayText ?? quickId,
            isQuick: true,
            quickId: quickId,
            isRead: false,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        withAnimation(.easeOut(duration: 0.25)) {
            activeThread.append(optimisticMsg)
        }
        HapticManager.light()

        // Background: actual API call
        do {
            let sent = try await messageService.sendQuickMessage(
                characterId: characterId,
                targetId: targetId,
                quickId: quickId
            )
            // Replace temp with real message (animated status change)
            withAnimation(.easeInOut(duration: 0.2)) {
                if let idx = activeThread.firstIndex(where: { $0.id == tempId }) {
                    activeThread[idx] = DirectMessageItem(
                        id: sent.id,
                        senderId: characterId,
                        content: sent.content,
                        isQuick: true,
                        quickId: quickId,
                        isRead: false,
                        createdAt: sent.createdAt
                    )
                }
            }
        } catch {
            // Remove optimistic on failure
            withAnimation(.easeOut(duration: 0.2)) {
                activeThread.removeAll(where: { $0.id == tempId })
            }
        }
    }

    func closeThread() {
        stopThreadPolling()
        activeThreadCharacterId = nil
        activeThreadCharacterName = nil
        activeThreadCharacterAvatar = nil
        activeThreadCharacterClass = nil
        activeThread = []
        threadLoadState = .idle
    }

    // MARK: - Duels

    func loadChallenges() async {
        duelsLoadState = .loading
        do {
            let response = try await challengeService.getChallenges(characterId: characterId)
            incomingChallenges = response.incoming
            outgoingChallenges = response.outgoing
            completedChallenges = response.completed
            duelsLoadState = .loaded
        } catch {
            duelsLoadState = .error
        }
    }

    func acceptChallenge(_ challenge: IncomingChallenge) async {
        processingChallengeId = challenge.id
        do {
            let result = try await challengeService.acceptChallenge(
                characterId: characterId,
                challengeId: challenge.id
            )
            duelResult = result
            showDuelResult = true
            incomingChallenges.removeAll { $0.id == challenge.id }
        } catch {
            // Error handled by service
        }
        processingChallengeId = nil
    }

    func declineChallenge(_ challenge: IncomingChallenge) -> ActionResult {
        let savedChallenges = incomingChallenges
        incomingChallenges.removeAll { $0.id == challenge.id }
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.challengeService.declineChallenge(
                    characterId: self.characterId,
                    challengeId: challenge.id
                )
            } catch {
                self.incomingChallenges = savedChallenges
                self.actionError = "Failed to decline challenge"
            }
        }
        return .success
    }

    func cancelOutgoingChallenge(_ challenge: OutgoingChallenge) -> ActionResult {
        let savedChallenges = outgoingChallenges
        outgoingChallenges.removeAll { $0.id == challenge.id }
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.challengeService.cancelChallenge(
                    characterId: self.characterId,
                    challengeId: challenge.id
                )
            } catch {
                self.outgoingChallenges = savedChallenges
                self.actionError = "Failed to cancel challenge"
            }
        }
        return .success
    }

    func sendChallenge(targetId: String, message: String? = nil) -> ActionResult {
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.challengeService.sendChallenge(
                    characterId: self.characterId,
                    targetId: targetId,
                    message: message
                )
            } catch {
                self.actionError = "Failed to send challenge"
            }
        }
        return .success
    }

    /// Count of pending outgoing challenges (for daily limit display)
    var pendingOutgoingCount: Int {
        outgoingChallenges.filter { $0.status == "pending" }.count
    }
}
