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

    // Defeat overlay
    var showDefeat = false
    var defeatTotalGold = 0
    var defeatTotalXP = 0
    var defeatFloorsCleared = 0

    // XP bar: snapshot taken just before fight to detect level-up
    var preFightLevel: Int = 0
    var preFightXPProgress: Double = 0

    /// XP bar config for the victory screen — built from current character state.
    var victoryXPBarConfig: XPBarConfig? {
        guard let char = appState.currentCharacter else { return nil }
        let leveledUp = char.level > preFightLevel
        return XPBarConfig(
            displayLevel: char.level,
            progress: CGFloat(char.xpPercentage),
            leveledUp: leveledUp
        )
    }

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
        errorMessage = nil

        // ── Cache-first: resolve dungeon immediately from local data ──
        // The dungeon list is already in GameDataCache / fallback. No need to wait for network.
        let selectedId = appState.selectedDungeonId
        if let selectedId {
            dungeon = allDungeons.first { $0.id == selectedId }
        }
        // Show default dungeon instantly if nothing selected yet
        if dungeon == nil {
            dungeon = DungeonInfo.trainingCamp
        }
        selectedBossIndex = currentBossIndex // snap to current boss immediately

        // ── Background refresh: fetch active run + saved progress from server ──
        // Only show spinner if we truly have zero dungeon data (first-ever open)
        isLoading = false // always keep UI interactive; API runs in background

        let data = await service.getProgress()

        guard data != nil else {
            // Non-blocking error — dungeon is already shown from cache
            if dungeon == nil {
                errorMessage = "Failed to load dungeon data. Check your connection and try again."
            }
            return
        }

        // Apply selected dungeon from server data if we didn't have one
        if let selectedId, dungeon?.id != selectedId {
            dungeon = allDungeons.first { $0.id == selectedId } ?? dungeon
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

        // Re-snap to current boss after fresh data arrives
        selectedBossIndex = currentBossIndex
    }

    // MARK: - Fight

    func fight() async {
        guard canFightSelectedBoss else { return }
        isFighting = true
        // Capture XP snapshot before fight to detect level-up on victory screen
        preFightLevel = appState.currentCharacter?.level ?? 0
        preFightXPProgress = appState.currentCharacter?.xpPercentage ?? 0

        #if DEBUG
        print("[DUNGEON-COMBAT] fight(): hp=\(appState.currentCharacter?.currentHp ?? -1)/\(appState.currentCharacter?.maxHp ?? -1), stamina=\(stamina), bossIdx=\(selectedBossIndex)")
        #endif

        // Start a run if we don't have one
        if runId.isEmpty {
            #if DEBUG
            print("[DUNGEON-COMBAT] fight(): no runId, starting new run for dungeon=\(dungeon?.id ?? "nil")")
            #endif
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

        #if DEBUG
        print("[DUNGEON-COMBAT] fight(): calling service.fight(runId: \(runId))")
        #endif

        let result = await service.fight(runId: runId)
        isFighting = false
        guard let result else {
            #if DEBUG
            print("[DUNGEON-COMBAT] fight(): service.fight returned nil")
            #endif
            return
        }

        #if DEBUG
        let hasPlayer = result["player"] != nil
        let hasCombatLog = result["combat_log"] != nil
        let victory = result["victory"] as? Bool
        print("[DUNGEON-COMBAT] fight(): response keys=\(Array(result.keys)), hasPlayer=\(hasPlayer), hasCombatLog=\(hasCombatLog), victory=\(String(describing: victory))")
        #endif

        // Store loot
        let lootItems = result["loot"] as? [[String: Any]] ?? []
        appState.pendingLoot = lootItems

        // Try to navigate to combat animation
        if let combatData = parseCombatData(from: result) {
            #if DEBUG
            print("[DUNGEON-COMBAT] fight(): parseCombatData OK — navigating to combat screen")
            #endif
            appState.combatData = combatData
            // Store pending result to apply after combat animation
            pendingFightResult = result
            appState.mainPath.append(AppRoute.combat)
        } else {
            #if DEBUG
            print("[DUNGEON-COMBAT] fight(): parseCombatData FAILED — applying result directly (no combat animation)")
            #endif
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

            // Notify rare+ drops as celebration, skip common/uncommon (shown in loot screen)
            if !victoryItems.isEmpty {
                let first = victoryItems[0]
                let name = first["name"] as? String ?? "Item"
                let rarity = first["rarity"] as? String ?? "common"
                let rarityEnum = ItemRarity(rawValue: rarity) ?? .common

                // Only celebrate epic+ drops
                if rarityEnum == .epic || rarityEnum == .legendary {
                    if victoryItems.count > 1 {
                        appState.showCelebration(.rareDrop, title: "\(rarity.capitalized) \(name)", subtitle: "+\(victoryItems.count - 1) more!")
                    } else {
                        appState.showCelebration(.rareDrop, title: "\(rarity.capitalized) \(name)", subtitle: "Rare drop!")
                    }
                }
                // Common/uncommon drops are shown in loot screen — no toast needed
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

            // Extract total progress earned during the run
            let rewards = result["rewards"] as? [String: Any]
            defeatTotalGold = rewards?["gold"] as? Int ?? 0
            defeatTotalXP = rewards?["xp"] as? Int ?? 0
            defeatFloorsCleared = rewards?["floorsCleared"] as? Int
                ?? rewards?["floors_cleared"] as? Int ?? 0

            showDefeat = true
            HapticManager.error()

            // Refresh character data (HP, stamina may have changed)
            Task { [characterService] in
                await characterService.loadCharacter()
            }
        }
    }

    private func parseCombatData(from response: [String: Any]) -> CombatData? {
        guard response["player"] != nil, response["combat_log"] != nil else {
            #if DEBUG
            print("[DUNGEON-COMBAT] parseCombatData: missing 'player' or 'combat_log' keys")
            #endif
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(CombatData.self, from: jsonData)
        } catch {
            #if DEBUG
            print("[DUNGEON-COMBAT] parseCombatData decode FAILED: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Victory Actions

    func dismissVictory() {
        showVictory = false
        if isDungeonComplete {
            // Go back to dungeon select
            appState.showCelebration(.dungeonClear, title: "Dungeon Complete!", subtitle: "All bosses defeated")
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

    func dismissDefeat() {
        showDefeat = false
        goBack()
    }

    // MARK: - Navigation

    func goBack() {
        if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
    }

    func selectBoss(at index: Int) {
        selectedBossIndex = index
    }
}
