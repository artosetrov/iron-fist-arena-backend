import SwiftUI

@MainActor @Observable
final class DungeonRoomViewModel {
    private let appState: AppState
    private let service: DungeonService
    private let characterService: CharacterService

    // Dungeon data
    var dungeon: DungeonInfo?
    var defeatedCount = 0      // How many bosses beaten (0–10)
    var selectedBossIndex = 0  // Which boss detail card is shown

    // Run state
    var runId = ""
    var isFighting = false
    var isLoading = false
    var errorMessage: String?

    // Victory overlay
    var showVictory = false
    var victoryGold = 0
    var victoryXP = 0
    var victoryItems: [[String: Any]] = []
    /// HP fraction after battle (0.0–1.0) for star rating. nil if unknown.
    var hpFractionAfterBattle: Double?

    private let cache: GameDataCache

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = DungeonService(appState: appState)
        self.characterService = CharacterService(appState: appState)
    }

    /// Resolve dungeon list: cached server data → fallback hardcoded
    private var allDungeons: [DungeonInfo] {
        guard let cached = cache.cachedDungeonList(), !cached.isEmpty else {
            return DungeonInfo.fallback
        }
        return cached
    }

    // MARK: - Computed

    var currentBossIndex: Int {
        min(defeatedCount, (dungeon?.totalBosses ?? 10) - 1)
    }

    var currentBoss: BossInfo? {
        guard let dungeon, currentBossIndex < dungeon.bosses.count else { return nil }
        return dungeon.bosses[currentBossIndex]
    }

    var selectedBoss: BossInfo? {
        guard let dungeon, selectedBossIndex < dungeon.bosses.count else { return nil }
        return dungeon.bosses[selectedBossIndex]
    }

    var isDungeonComplete: Bool {
        guard let dungeon else { return false }
        return defeatedCount >= dungeon.totalBosses
    }

    var stamina: Int { appState.currentCharacter?.currentStamina ?? 0 }
    var maxStamina: Int { appState.currentCharacter?.maxStamina ?? 120 }

    func bossState(at index: Int) -> BossState {
        if index < defeatedCount { return .defeated }
        if index == defeatedCount { return .current }
        return .locked
    }

    var canFightSelectedBoss: Bool {
        guard let dungeon else { return false }
        let state = bossState(at: selectedBossIndex)
        return state == .current && stamina >= dungeon.energyCost
    }

    var progressFraction: Double {
        guard let dungeon, dungeon.totalBosses > 0 else { return 0 }
        return Double(defeatedCount) / Double(dungeon.totalBosses)
    }

    // MARK: - Load State

    func loadState() async {
        isLoading = true
        errorMessage = nil

        // Resolve which dungeon to show from appState or active run
        let selectedId = appState.selectedDungeonId

        let data = await service.getProgress()
        isLoading = false

        guard data != nil else {
            errorMessage = "Failed to load dungeon data. Check your connection and try again."
            return
        }

        // Try to find dungeon from selected ID first
        if let selectedId {
            dungeon = allDungeons.first { $0.id == selectedId }
        }

        // Check for active run
        if let run = data?["activeRun"] as? [String: Any] {
            let runDungeonId = run["dungeon_id"] as? String ?? run["dungeonId"] as? String ?? ""
            runId = run["id"] as? String ?? ""
            let floor = run["current_floor"] as? Int ?? run["currentFloor"] as? Int ?? 1

            // If we didn't have a selected dungeon, use the run's dungeon
            if dungeon == nil, !runDungeonId.isEmpty {
                dungeon = allDungeons.first { $0.id == runDungeonId }
            }

            // If run's dungeon matches our selected dungeon, use its floor
            if runDungeonId == dungeon?.id {
                defeatedCount = max(floor - 1, 0)
            } else {
                // Run is for a different dungeon — ignore it
                runId = ""
            }
        }

        // Load saved progress for our dungeon
        if let progress = data?["progress"] as? [String: Any],
           let d = dungeon {
            if let defeated = progress[d.id] as? Int {
                // Use saved progress if greater than what active run says
                defeatedCount = max(defeatedCount, defeated)
            }
        }

        // Default dungeon if nothing resolved
        if dungeon == nil {
            dungeon = DungeonInfo.trainingCamp
            defeatedCount = 0
        }

        // Auto-select current boss
        selectedBossIndex = currentBossIndex
    }

    // MARK: - Fight

    func fight() async {
        guard canFightSelectedBoss else { return }
        isFighting = true

        // Start a run if we don't have one
        if runId.isEmpty {
            let startResult = await service.start(dungeonId: dungeon?.id ?? "", difficulty: "normal")
            if let result = startResult {
                // The start response returns run_id at top level
                runId = result["run_id"] as? String
                    ?? result["id"] as? String
                    ?? (result["run"] as? [String: Any])?["id"] as? String
                    ?? ""
            }
        }

        guard !runId.isEmpty else {
            isFighting = false
            appState.showToast("Failed to start dungeon run", subtitle: "Check energy and connection", type: .error)
            return
        }

        let result = await service.fight(runId: runId)
        isFighting = false
        guard let result else { return }

        // Store loot
        let lootItems = result["loot"] as? [[String: Any]] ?? []
        appState.pendingLoot = lootItems

        // Try to navigate to combat animation
        if let combatData = parseCombatData(from: result) {
            appState.combatData = combatData
            // Store pending result to apply after combat animation
            pendingFightResult = result
            appState.mainPath.append(AppRoute.combat)
        } else {
            // No animation — apply directly
            applyFightResult(result)
        }
    }

    var pendingFightResult: [String: Any]?

    func applyPendingResult() {
        guard let result = pendingFightResult else { return }
        pendingFightResult = nil
        applyFightResult(result)
    }

    private func applyFightResult(_ result: [String: Any]) {
        let won = result["victory"] as? Bool ?? false

        if won {
            // Extract gold/xp from rewards or result
            victoryGold = (result["rewards"] as? [String: Any])?["gold"] as? Int
                ?? (result["result"] as? [String: Any])?["gold_reward"] as? Int
                ?? 0
            victoryXP = (result["rewards"] as? [String: Any])?["xp"] as? Int
                ?? (result["result"] as? [String: Any])?["xp_reward"] as? Int
                ?? 0
            victoryItems = result["loot"] as? [[String: Any]] ?? []

            // HP fraction for star rating (server sends playerHpPercent or we compute from character)
            if let hpPct = result["playerHpPercent"] as? Double {
                hpFractionAfterBattle = hpPct
            } else if let rewards = result["rewards"] as? [String: Any],
                      let hpPct = rewards["hpPercent"] as? Double {
                hpFractionAfterBattle = hpPct
            } else {
                // Fallback: use current character HP if available
                if let char = appState.currentCharacter {
                    hpFractionAfterBattle = Double(char.currentHp) / Double(max(char.maxHp, 1))
                }
            }

            defeatedCount += 1
            showVictory = true

            // Notify loot
            if !victoryItems.isEmpty {
                let first = victoryItems[0]
                let name = first["name"] as? String ?? "Item"
                let rarity = first["rarity"] as? String ?? "common"
                if victoryItems.count > 1 {
                    appState.showToast("\(rarity.capitalized) \(name) +\(victoryItems.count - 1) more!", type: .reward)
                } else {
                    appState.showToast("\(rarity.capitalized) \(name) dropped!", type: .reward)
                }
            }

            // Check if dungeon is now complete
            let serverDungeonComplete = result["dungeonComplete"] as? Bool ?? false
            if isDungeonComplete || serverDungeonComplete {
                runId = ""
                // FTUE: mark explore dungeon complete
                TutorialManager.shared.completeFTUEObjective(.exploreDungeon)
            }

            // Refresh character data (gold, xp, level may have changed)
            Task { [characterService] in
                await characterService.loadCharacter()
            }
            let resultData = result["result"] as? [String: Any]
            if let leveledUp = resultData?["leveled_up"] as? Bool, leveledUp,
               let newLevel = resultData?["new_level"] as? Int {
                let statPoints = resultData?["stat_points_awarded"] as? Int ?? 3
                appState.triggerLevelUpModal(newLevel: newLevel, statPoints: statPoints)
            }
        } else {
            // Defeat — run is deleted server-side
            runId = ""
            appState.showToast("Defeated!", subtitle: "Heal up and try again", type: .error)
        }
    }

    private func parseCombatData(from response: [String: Any]) -> CombatData? {
        guard response["player"] != nil, response["combat_log"] != nil else { return nil }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(CombatData.self, from: jsonData)
        } catch {
            return nil
        }
    }

    // MARK: - Victory Actions

    func dismissVictory() {
        showVictory = false
        if isDungeonComplete {
            // Go back to dungeon select
            appState.showToast("Dungeon Complete!", type: .achievement)
            appState.invalidateCache("quests")
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
        } else {
            // Select next boss
            selectedBossIndex = currentBossIndex
        }
    }

    func proceedToNextBoss() {
        showVictory = false
        selectedBossIndex = currentBossIndex
    }

    // MARK: - Navigation

    func goBack() {
        if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
    }

    func selectBoss(at index: Int) {
        selectedBossIndex = index
    }
}
