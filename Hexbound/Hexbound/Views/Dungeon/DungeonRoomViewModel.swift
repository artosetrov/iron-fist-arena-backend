import SwiftUI

@MainActor @Observable
final class DungeonRoomViewModel {
    let appState: AppState
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
    /// Whether this fight levelled the hero up. Consumed by `DungeonVictoryView`
    /// to run the arena-style XP bar fill + LEVEL UP! flash animation and
    /// defer `triggerLevelUpModal` until the bar finishes filling.
    var victoryLeveledUp = false
    var victoryNewLevel: Int?
    var victoryStatPointsAwarded: Int = 0

    // Defeat overlay
    var showDefeat = false
    var defeatTotalGold = 0
    var defeatTotalXP = 0
    var defeatFloorsCleared = 0

    // Boss unlock ceremony — shown AFTER the victory screen is dismissed,
    // when defeating a boss unlocks the next one in the dungeon. Same
    // reveal animation as building unlocks on the hub.
    var pendingBossUnlock: BossInfo?

    // XP bar: snapshot taken just before fight to detect level-up
    var preFightLevel: Int = 0
    var preFightXP: Int = 0
    var preFightXPProgress: Double = 0

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
    var maxStamina: Int { appState.currentCharacter?.maxStamina ?? 180 }

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
        guard !isFighting else { return } // prevent double-tap
        guard canFightSelectedBoss else { return }
        isFighting = true
        // Capture XP snapshot before fight to detect level-up on victory screen
        preFightLevel = appState.currentCharacter?.level ?? 0
        preFightXP = appState.currentCharacter?.experience ?? 0
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

            // Extract level-up metadata — consumed by DungeonVictoryView to
            // animate the XP bar and trigger the level-up modal in sync with
            // the bar finishing its fill (mirrors arena/pvp flow).
            let resultData = result["result"] as? [String: Any]
            let leveledUp = (resultData?["leveled_up"] as? Bool) ?? false
            let newLevel = resultData?["new_level"] as? Int
            let statPoints = resultData?["stat_points_awarded"] as? Int ?? 3
            victoryLeveledUp = leveledUp
            victoryNewLevel = newLevel
            victoryStatPointsAwarded = leveledUp ? statPoints : 0

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

            // Optimistic character update so DungeonVictoryView can snapshot
            // the XP transition the same way CombatResultDetailView does for
            // arena/pvp. Single write-back (struct) to avoid @Observable
            // re-entrant exclusive-access violations. Background loadCharacter()
            // below reconciles against authoritative server state afterwards.
            if var char = appState.currentCharacter {
                if victoryXP > 0 {
                    char.experience = (char.experience ?? 0) + victoryXP
                }
                if victoryGold > 0 {
                    char.gold += victoryGold
                }
                if leveledUp, let newLvl = newLevel {
                    let prevXpNeeded = Self.xpNeededForLevel(newLvl - 1)
                    char.level = newLvl
                    let totalXp = char.experience ?? 0
                    if totalXp >= prevXpNeeded {
                        char.experience = totalXp - prevXpNeeded
                    }
                    if statPoints > 0 {
                        char.statPoints = (char.statPoints ?? 0) + statPoints
                    }
                }
                appState.currentCharacter = char
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
            // NOTE: level-up modal trigger is now deferred to
            // DungeonVictoryView.runXpBarAnimation() so it pops AFTER the
            // XP bar finishes filling (identical to arena/pvp flow).
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
            // Queue a "next dungeon unsealed" ceremony on the dungeon map,
            // if the player's clear unlocked the following dungeon in the
            // sequence. Played by `DungeonUnlockCeremonyHost` on mount.
            queueNextDungeonUnlockIfAny()
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
        } else {
            // Select next boss
            selectedBossIndex = currentBossIndex
            queueBossUnlockIfAny()
        }
    }

    func proceedToNextBoss() {
        showVictory = false
        selectedBossIndex = currentBossIndex
        queueBossUnlockIfAny()
    }

    /// Trigger the boss unlock ceremony if a new boss just became available.
    /// Called after the victory overlay closes so the player sees rewards
    /// first, then the "next challenger awakens" reveal.
    private func queueBossUnlockIfAny() {
        guard !isDungeonComplete, let boss = currentBoss else { return }
        pendingBossUnlock = boss
    }

    /// Enqueue a dungeon-map unlock ceremony when the player clears the
    /// current dungeon and the next one in the overland sort order becomes
    /// available. Consumed by `DungeonUnlockCeremonyHost` on `DungeonMapView`.
    private func queueNextDungeonUnlockIfAny() {
        guard let currentId = dungeon?.id else { return }
        let all = resolvedDungeonMapBuildings(from: cache)
            .sorted { $0.sortOrder < $1.sortOrder }
        guard let idx = all.firstIndex(where: { $0.id == currentId }),
              idx + 1 < all.count else { return }
        let nextId = all[idx + 1].id
        if !appState.pendingDungeonUnlocks.contains(nextId) {
            appState.pendingDungeonUnlocks.append(nextId)
        }
    }

    func dismissBossUnlock() {
        pendingBossUnlock = nil
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

    // MARK: - XP Curve

    /// XP required to finish `level` (i.e. reach `level + 1`). Mirrors the
    /// formula used by `CombatResultDetailView.xpNeededForLevel(_:)` and the
    /// backend `xpRequired()` helper. Kept in one place so the dungeon
    /// victory animation and the optimistic level-up update agree.
    static func xpNeededForLevel(_ level: Int) -> Int {
        let next = level + 1
        return 100 * next + 20 * next * next
    }
}
