import SwiftUI

@MainActor @Observable
final class LeaderboardViewModel {
    private let appState: AppState
    private let cache: GameDataCache
    private let service: LeaderboardService

    var data: [String: [LeaderboardEntry]] = [:]
    var isLoading = false
    var selectedTab = 0
    var errorMessage: String? = nil

    static let tabs = ["Rating", "Level", "Gold"]
    static let tabKeys = ["rating", "level", "gold"]

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = LeaderboardService(appState: appState)
    }

    var currentEntries: [LeaderboardEntry] {
        data[Self.tabKeys[selectedTab]] ?? []
    }

    var myCharacterId: String? {
        appState.currentCharacter?.id
    }

    var myRank: Int? {
        currentEntries.first { $0.characterId == myCharacterId }?.rank
    }

    // MARK: - Load

    func loadLeaderboard() async {
        // Serve cached data instantly
        if let cached = cache.cachedLeaderboard() {
            data = cached
        } else {
            isLoading = true
        }
        errorMessage = nil
        let result = await service.loadLeaderboard()
        data = result
        cache.cacheLeaderboard(result)
        isLoading = false
    }
}
