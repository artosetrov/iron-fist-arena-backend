import SwiftUI

@MainActor @Observable
final class DungeonSelectViewModel {
    private let appState: AppState
    private let service: DungeonService

    var dungeons: [DungeonInfo] = []
    var isLoading = false
    var errorMessage: String? = nil

    /// True only when the last refresh failed AND there is nothing to show.
    ///
    /// A failed background refresh over warm cache must not replace a readable
    /// list with a full-screen error — the stale list is more useful. The error
    /// page is for the case where the screen would otherwise be blank.
    // `dungeons` is seeded from DungeonInfo.fallback before the fetch, so it is
    // never empty — including it here would make this screen's error state
    // unreachable all over again. Progress is the thing that is actually
    // missing when the load fails.
    var showsErrorState: Bool { errorMessage != nil && dungeonProgress.isEmpty }

    // Progress: dungeonId → number of bosses defeated
    var dungeonProgress: [String: Int] = [:]

    // Active run (if any)
    var currentRun: DungeonActiveRunSnapshot?

    private let cache: GameDataCache

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = DungeonService(appState: appState)
    }

    var playerLevel: Int { appState.currentCharacter?.level ?? 1 }
    var stamina: Int { appState.currentCharacter?.currentStamina ?? 0 }
    var maxStamina: Int { appState.currentCharacter?.maxStamina ?? 180 }

    // MARK: - Dungeon State

    func stateFor(_ dungeon: DungeonInfo) -> DungeonState {
        // Sequential unlock: previous dungeon must be completed
        // Completing the previous dungeon is the PRIMARY unlock condition.
        // Level requirement is only enforced for the very first dungeon (no predecessor).
        if let idx = dungeons.firstIndex(where: { $0.id == dungeon.id }), idx > 0 {
            let prev = dungeons[idx - 1]
            let prevDefeated = dungeonProgress[prev.id] ?? 0
            if prevDefeated < prev.totalBosses {
                return .locked(requirement: "Complete \(prev.name) first")
            }
            // Previous dungeon completed → this one is unlocked regardless of level
        } else {
            // First dungeon in the list — use level requirement as gate
            if playerLevel < dungeon.minLevel {
                return .locked(requirement: "Reach Level \(dungeon.minLevel)")
            }
        }

        let defeated = dungeonProgress[dungeon.id] ?? 0
        if defeated >= dungeon.totalBosses {
            return .completed
        }
        return .inProgress(defeated: defeated)
    }

    func defeatedCount(for dungeon: DungeonInfo) -> Int {
        dungeonProgress[dungeon.id] ?? 0
    }

    func isUnlocked(_ dungeon: DungeonInfo) -> Bool {
        switch stateFor(dungeon) {
        case .locked: return false
        default: return true
        }
    }

    // MARK: - Load Progress

    func loadProgress() async {
        errorMessage = nil

        // Serve cached dungeon list + progress instantly
        if let cachedList = cache.cachedDungeonList() {
            dungeons = cachedList
        }
        if let cached = cache.cachedDungeonProgress() {
            dungeonProgress = cached
        }

        // Show loading only if we have zero data
        if dungeons.isEmpty && dungeonProgress.isEmpty {
            isLoading = true
        }

        // If dungeons are empty (no cache), use fallback while loading
        if dungeons.isEmpty {
            dungeons = DungeonInfo.fallback
        }

        // Fetch dungeon list from server in parallel with progress
        async let serverDungeons = service.listDungeons()
        async let progressData = service.getProgress()

        // Process dungeon list
        if let serverDungeonList = await serverDungeons, !serverDungeonList.isEmpty {
                // Server list + the code-only starters (see `DungeonInfo.merged`).
                dungeons = DungeonInfo.merged(withServer: serverDungeonList)
                cache.cacheDungeonList(dungeons)
        }

        // Process progress
        let data = await progressData
        if let snapshot = data {
            dungeonProgress = snapshot.progress
            currentRun = snapshot.activeRun
            // Cache only a real result. Caching whatever is in memory after a
            // failed refresh is how an empty list became permanent.
            cache.cacheDungeonProgress(dungeonProgress)
        } else {
            // The screen has an ErrorStateView that was unreachable because
            // nothing ever assigned errorMessage. Keep any warm data visible
            // and say the refresh failed.
            errorMessage = "Couldn't load your dungeon progress. Check your connection."
        }

        isLoading = false
    }

    // MARK: - Enter Dungeon

    func enterDungeon(_ dungeon: DungeonInfo) {
        appState.selectedDungeonId = dungeon.id
        let route: AppRoute = DungeonTrailConfig.config(for: dungeon.id) != nil ? .dungeonTrail : .dungeonRoom
        appState.mainPath.append(route)
    }

    func goToShop() {
        appState.shopInitialTab = 3
        appState.mainPath.append(AppRoute.shop)
    }

    func goBack() {
        if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
    }
}
