import SwiftUI

@MainActor @Observable
final class DungeonSelectViewModel {
    private let appState: AppState
    private let service: DungeonService

    var dungeons: [DungeonInfo] = []
    var isLoading = false
    var errorMessage: String? = nil

    // Progress: dungeonId → number of bosses defeated
    var dungeonProgress: [String: Int] = [:]

    // Active run (if any)
    var currentRun: [String: Any]?

    private let cache: GameDataCache

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = DungeonService(appState: appState)
    }

    var playerLevel: Int { appState.currentCharacter?.level ?? 1 }
    var stamina: Int { appState.currentCharacter?.currentStamina ?? 0 }
    var maxStamina: Int { appState.currentCharacter?.maxStamina ?? 120 }

    // MARK: - Dungeon State

    func stateFor(_ dungeon: DungeonInfo) -> DungeonState {
        // Check level lock
        if playerLevel < dungeon.minLevel {
            // Find the previous dungeon
            if let idx = dungeons.firstIndex(where: { $0.id == dungeon.id }), idx > 0 {
                let prev = dungeons[idx - 1]
                return .locked(requirement: "Complete \(prev.name) first")
            }
            return .locked(requirement: "Reach Level \(dungeon.minLevel)")
        }

        // Check if previous dungeon is completed (sequential unlock)
        if let idx = dungeons.firstIndex(where: { $0.id == dungeon.id }), idx > 0 {
            let prev = dungeons[idx - 1]
            let prevDefeated = dungeonProgress[prev.id] ?? 0
            if prevDefeated < prev.totalBosses {
                return .locked(requirement: "Complete \(prev.name) first")
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
<<<<<<< HEAD
        errorMessage = nil

=======
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
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
        if let rawDungeons = await serverDungeons {
            let parsed = rawDungeons.compactMap { DungeonInfo.from(serverData: $0) }
            if !parsed.isEmpty {
                // Merge: prefer server data, but keep rich client data for known dungeons
                dungeons = parsed.map { serverDungeon in
                    // If we have a hardcoded version with richer data (loot, portraits), use it
                    if let local = DungeonInfo.fallback.first(where: { $0.id == serverDungeon.id }) {
                        return local
                    }
                    return serverDungeon
                }
                cache.cacheDungeonList(dungeons)
            }
        }

        // Process progress
        let data = await progressData
        if let progress = data?["progress"] as? [String: Any] {
            for (key, value) in progress {
                if let defeated = value as? Int {
                    dungeonProgress[key] = defeated
                } else if let info = value as? [String: Any] {
                    dungeonProgress[key] = info["defeated"] as? Int ?? 0
                }
            }
        }

        if let run = data?["activeRun"] as? [String: Any] {
            currentRun = run
        }

        cache.cacheDungeonProgress(dungeonProgress)
        isLoading = false
    }

    // MARK: - Enter Dungeon

    func enterDungeon(_ dungeon: DungeonInfo) {
        appState.selectedDungeonId = dungeon.id
        appState.mainPath.append(AppRoute.dungeonRoom)
    }

    func goToShop() {
        appState.shopInitialTab = 3
        appState.mainPath.append(AppRoute.shop)
    }

    func goBack() {
        if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
    }
}
