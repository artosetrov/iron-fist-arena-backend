import SwiftUI

@MainActor @Observable
final class DungeonSelectViewModel {
    private let appState: AppState
    private let service: DungeonService

    var dungeons = DungeonInfo.all
    var isLoading = false

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
        // Serve cached progress instantly
        if let cached = cache.cachedDungeonProgress() {
            dungeonProgress = cached
        } else {
            isLoading = true
        }
        let data = await service.getProgress()
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
