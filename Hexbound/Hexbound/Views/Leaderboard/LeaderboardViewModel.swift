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

    // Search state
    var searchText = ""
    var searchResults: [LeaderboardSearchResult] = []
    var isSearching = false
    var searchError = false
    private var searchTask: Task<Void, Never>?

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

    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var myCharacterId: String? {
        appState.currentCharacter?.id
    }

    var myRank: Int? {
        currentEntries.first { $0.characterId == myCharacterId }?.rank
    }

    /// True only when the last refresh failed AND there is nothing to show.
    ///
    /// A failed background refresh over warm cache must not replace a readable
    /// list with a full-screen error — the stale list is more useful. The error
    /// page is for the case where the screen would otherwise be blank.
    var showsErrorState: Bool { errorMessage != nil && currentEntries.isEmpty }

    // MARK: - Load

    func loadLeaderboard() async {
        // Serve cached data instantly
        if let cached = cache.staleLeaderboard() {
            data = cached
        } else {
            isLoading = true
        }
        errorMessage = nil
        let outcome = await service.loadLeaderboard()
        outcome.apply(
            assign: { self.data = $0 },
            cache: { self.cache.cacheLeaderboard($0) },
            setError: { self.errorMessage = $0 }
        )
        isLoading = false
    }

    // MARK: - Search

    func onSearchTextChanged() {
        searchTask?.cancel()
        searchError = false

        let query = searchText.trimmingCharacters(in: .whitespaces)
        if query.count < 2 {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            // Debounce 400ms
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }

            do {
                let results = try await service.searchPlayers(query: query)
                guard !Task.isCancelled else { return }
                searchResults = results
                searchError = false
            } catch {
                guard !Task.isCancelled else { return }
                searchResults = []
                searchError = true
            }
            isSearching = false
        }
    }

    func retrySearch() {
        onSearchTextChanged()
    }

    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
        searchResults = []
        isSearching = false
        searchError = false
    }
}
