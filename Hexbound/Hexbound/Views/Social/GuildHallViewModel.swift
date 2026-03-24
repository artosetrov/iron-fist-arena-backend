import Foundation

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
    var threadLoadState: LoadState = .idle
    var isSendingMessage = false
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

    private let socialService = SocialService.shared
    private let challengeService = ChallengeService.shared
    private let messageService = MessageService.shared
    private var characterId: String

    init(characterId: String) {
        self.characterId = characterId
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

    // MARK: - Friend Actions

    func acceptRequest(_ request: FriendRequest) async {
        processingRequestId = request.friendshipId
        let success = await socialService.acceptFriendRequest(
            characterId: characterId,
            requesterId: request.id
        )
        processingRequestId = nil
        if success {
            await loadFriends()
        }
    }

    func declineRequest(_ request: FriendRequest) async {
        processingRequestId = request.friendshipId
        let success = await socialService.declineFriendRequest(
            characterId: characterId,
            requesterId: request.id
        )
        processingRequestId = nil
        if success {
            incomingRequests.removeAll { $0.friendshipId == request.friendshipId }
        }
    }

    func removeFriend(_ friend: FriendEntry) async {
        processingFriendId = friend.id
        let success = await socialService.removeFriend(
            characterId: characterId,
            friendId: friend.id
        )
        processingFriendId = nil
        if success {
            friends.removeAll { $0.id == friend.id }
            friendCount = friends.count
        }
    }

    func blockUser(_ targetId: String) async {
        let success = await socialService.blockUser(
            characterId: characterId,
            targetId: targetId
        )
        if success {
            friends.removeAll { $0.id == targetId }
            incomingRequests.removeAll { $0.id == targetId }
            friendCount = friends.count
        }
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
        scrollsLoadState = .loading
        do {
            let response = try await messageService.getConversations(characterId: characterId)
            conversations = response
            scrollsLoadState = .loaded
        } catch {
            scrollsLoadState = .error
        }
    }

    func openThread(characterId targetId: String, characterName: String) async {
        activeThreadCharacterId = targetId
        activeThreadCharacterName = characterName
        threadLoadState = .loading
        composedMessage = ""
        do {
            let messages = try await messageService.getThread(
                characterId: characterId,
                withCharacterId: targetId
            )
            activeThread = messages
            threadLoadState = .loaded
            // Reload conversations to reflect read status
            await loadConversations()
        } catch {
            threadLoadState = .error
        }
    }

    func sendMessage() async {
        guard let targetId = activeThreadCharacterId else { return }
        let content = composedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, content.count <= 200 else { return }

        isSendingMessage = true
        sendMessageError = nil
        do {
            let sent = try await messageService.sendMessage(
                characterId: characterId,
                targetId: targetId,
                content: content
            )
            // Add to thread (newest first)
            let newMsg = DirectMessageItem(
                id: sent.id,
                senderId: characterId,
                content: sent.content,
                isQuick: false,
                quickId: nil,
                isRead: false,
                createdAt: sent.createdAt
            )
            activeThread.insert(newMsg, at: 0)
            composedMessage = ""
        } catch {
            sendMessageError = "Failed to send message"
        }
        isSendingMessage = false
    }

    func sendQuickMessage(_ quickId: String) async {
        guard let targetId = activeThreadCharacterId else { return }
        isSendingMessage = true
        do {
            let sent = try await messageService.sendQuickMessage(
                characterId: characterId,
                targetId: targetId,
                quickId: quickId
            )
            let newMsg = DirectMessageItem(
                id: sent.id,
                senderId: characterId,
                content: sent.content,
                isQuick: true,
                quickId: quickId,
                isRead: false,
                createdAt: sent.createdAt
            )
            activeThread.insert(newMsg, at: 0)
        } catch {
            // Error handled by service
        }
        isSendingMessage = false
    }

    func closeThread() {
        activeThreadCharacterId = nil
        activeThreadCharacterName = nil
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

    func declineChallenge(_ challenge: IncomingChallenge) async {
        processingChallengeId = challenge.id
        do {
            try await challengeService.declineChallenge(
                characterId: characterId,
                challengeId: challenge.id
            )
            incomingChallenges.removeAll { $0.id == challenge.id }
        } catch {
            // Error handled by service
        }
        processingChallengeId = nil
    }

    func sendChallenge(targetId: String, message: String? = nil) async -> Bool {
        do {
            _ = try await challengeService.sendChallenge(
                characterId: characterId,
                targetId: targetId,
                message: message
            )
            return true
        } catch {
            return false
        }
    }
}
