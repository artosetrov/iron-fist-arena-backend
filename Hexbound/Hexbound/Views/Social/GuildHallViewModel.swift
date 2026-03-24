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

    // Processing states
    var processingRequestId: String?
    var processingFriendId: String?

    private let socialService = SocialService.shared
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
}
