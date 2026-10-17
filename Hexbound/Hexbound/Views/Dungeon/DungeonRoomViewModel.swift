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
    var victoryItems: [CombatLootItem] = []
    /// HP fraction after battle (0.0–1.0) for star rating. nil if unknown.
    var hpFractionAfterBattle: Double?
    /// Whether this fight levelled the hero up. Consumed by `DungeonVictoryView`
    /// to run the arena-style XP bar fill + LEVEL UP! flash animation and
    /// defer `triggerLevelUpModal` until the bar finishes filling.
    var victoryLeveledUp = false
    var victoryNewLevel: Int?
    var victoryStatPointsAwarded: Int = 0
    var victoryPassivePointsAwarded: Int = 0

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

    /// A run is open (or being opened). Energy is charged once, when the run
    /// starts — fights inside a run are free.
    var hasActiveRun: Bool { !runId.isEmpty || runStartTask != nil }

    var canFightSelectedBoss: Bool {
        guard let dungeon else { return false }
        let state = bossState(at: selectedBossIndex)
        return state == .current && (hasActiveRun || stamina >= dungeon.energyCost)
    }

    var progressFraction: Double {
        guard let dungeon, dungeon.totalBosses > 0 else { return 0 }
        return Double(defeatedCount) / Double(dungeon.totalBosses)
    }

    private static func pendingLootItem(_ item: CombatLootItem) -> PendingLootItem {
        PendingLootItem(item)
    }

    // MARK: - Load State

    func loadState() async {
        errorMessage = nil

        // The trail map can open the room on a specific boss; take the
        // request once so a later reload snaps back to the current boss.
        let requestedIndex = appState.requestedDungeonBossIndex
        appState.requestedDungeonBossIndex = nil

        // ── Cache-first: resolve dungeon immediately from local data ──
        // The dungeon list is already in GameDataCache / fallback. No need to wait for network.
        let selectedId = appState.selectedDungeonId
        if let selectedId, dungeon?.id != selectedId {
            dungeon = allDungeons.first { $0.id == selectedId }
            // Past the three starters, dungeons live only on the server. When
            // the list isn't warm yet, fetch it rather than fall back to
            // Training Camp (that put the wrong bosses on screen).
            if dungeon == nil {
                isLoading = true
                if let serverList = await service.listDungeons(), !serverList.isEmpty {
                    let merged = DungeonInfo.merged(withServer: serverList)
                    cache.cacheDungeonList(merged)
                    dungeon = merged.first { $0.id == selectedId }
                }
                isLoading = false
                guard dungeon != nil else {
                    errorMessage = "Couldn't load this dungeon. Check your connection and try again."
                    return
                }
            }
        }
        // Show default dungeon instantly if nothing selected yet
        if dungeon == nil {
            dungeon = DungeonInfo.trainingCamp
        }
        // Cache-first progress too: wins are written to the shared map, so
        // the right boss is up before the server answers.
        if let id = dungeon?.id, let cached = cache.dungeonProgress[id], cached > defeatedCount {
            defeatedCount = cached
        }
        snapSelection(requested: requestedIndex) // snap immediately

        // ── Background refresh: fetch active run + saved progress from server ──
        // Only show spinner if we truly have zero dungeon data (first-ever open)
        isLoading = false // always keep UI interactive; API runs in background

        let snapshot = await service.getProgress()

        guard snapshot != nil else {
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
        if let run = snapshot?.activeRun {
            let runDungeonId = run.dungeonId
            runId = run.id
            let floor = run.currentFloor

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
        if let progress = snapshot?.progress,
           let d = dungeon,
           let defeated = progress[d.id] {
            // Use saved progress if greater than what active run says
            defeatedCount = max(defeatedCount, defeated)
        }

        // Default dungeon if nothing resolved
        if dungeon == nil {
            dungeon = DungeonInfo.trainingCamp
            defeatedCount = 0
        }

        // Re-snap after fresh data arrives
        snapSelection(requested: requestedIndex)
        if let serverProgress = snapshot?.progress {
            storeProgress(serverProgress)
        }
    }

    /// Put the requested boss on the stage when it is open to the player,
    /// otherwise the current one.
    private func snapSelection(requested: Int?) {
        if let requested, let dungeon, dungeon.bosses.indices.contains(requested),
           requested <= currentBossIndex {
            selectedBossIndex = requested
        } else {
            selectedBossIndex = currentBossIndex
        }
    }

    /// After a fresh fetch: share the server's progress map, with this
    /// dungeon's count (which may include an open run) folded in, so the
    /// trail map and the overland map show it without another fetch.
    private func storeProgress(_ serverProgress: [String: Int]) {
        var progress = serverProgress
        if let id = dungeon?.id {
            progress[id] = max(progress[id] ?? 0, defeatedCount)
        }
        cache.cacheDungeonProgress(progress)
    }

    // MARK: - Fight

    /// In-flight run start kicked off by `prewarmRunIfNeeded()`.
    private var runStartTask: Task<Void, Never>?

    /// Latency pass (2026-10-15): start the dungeon run while the BOSS FIGHT
    /// slam plays, so `fight()` finds a `runId` instead of paying that round
    /// trip after the animation. Safe to call repeatedly.
    func prewarmRunIfNeeded() {
        guard runId.isEmpty, runStartTask == nil, canFightSelectedBoss else { return }
        runStartTask = Task { [weak self] in
            guard let self else { return }
            await self.startRunIfNeeded()
            self.runStartTask = nil
        }
    }

    private func startRunIfNeeded() async {
        guard runId.isEmpty else { return }
        #if DEBUG
        print("[DUNGEON-COMBAT] no runId, starting new run for dungeon=\(dungeon?.id ?? "nil")")
        #endif
        let startResult = await service.start(dungeonId: dungeon?.id ?? "", difficulty: "normal")
        if let result = startResult, runId.isEmpty {
            runId = result.runId
            AnalyticsService.shared.track(.dungeonRunStart, ["dungeon": .string(dungeon?.id ?? "")])
        }
    }

    func fight() async {
        guard !isFighting else { return } // prevent double-tap
        guard canFightSelectedBoss else {
            appState.showToast("Can't start this fight", subtitle: "Check your energy and try again", type: .error)
            return
        }
        isFighting = true
        // Capture XP snapshot before fight to detect level-up on victory screen
        preFightLevel = appState.currentCharacter?.level ?? 0
        preFightXP = appState.currentCharacter?.experience ?? 0
        preFightXPProgress = appState.currentCharacter?.xpPercentage ?? 0

        #if DEBUG
        print("[DUNGEON-COMBAT] fight(): hp=\(appState.currentCharacter?.currentHp ?? -1)/\(appState.currentCharacter?.maxHp ?? -1), stamina=\(stamina), bossIdx=\(selectedBossIndex)")
        #endif

        // Start a run if we don't have one — usually already done by
        // `prewarmRunIfNeeded()` during the slam; await it if still in flight.
        if let pending = runStartTask {
            await pending.value
        }
        if runId.isEmpty {
            await startRunIfNeeded()
        }

        guard !runId.isEmpty else {
            isFighting = false
            appState.showToast("Failed to start dungeon run", subtitle: "Check energy and connection", type: .error)
            return
        }

        // Interactive Combat v1 — when the feature is on, route the dungeon
        // boss through the match-lifecycle screen so the player picks stances
        // round by round. Server extends /pvp/match/start to load the boss
        // from the active DungeonRun and advance the floor on victory.
        if !appState.interactiveCombatLocallyDisabled,
           cache.gameConfig?.interactiveCombatEnabled == true,
           let char = appState.currentCharacter,
           let boss = selectedBoss {
            isFighting = false
            let bossMaxHp = boss.hp > 0 ? boss.hp : char.maxHp
            appState.mainPath.append(AppRoute.interactiveBattle(
                characterId: char.id,
                opponentId: EnemyPortraitResolver.opponentId(for: boss),
                attackerMaxHp: char.maxHp,
                defenderMaxHp: bossMaxHp,
                opponentType: .dungeonBoss,
                dungeonRunId: runId
            ))
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
        print("[DUNGEON-COMBAT] fight(): hasPlayer=true, turns=\(result.combatLog.count), victory=\(result.victory)")
        #endif

        // Store loot
        let lootItems = result.loot ?? []
        appState.pendingLoot = lootItems.map(Self.pendingLootItem)

        // Try to navigate to combat animation
        let combatData = result.combatData
        if !combatData.combatLog.isEmpty {
            #if DEBUG
            print("[DUNGEON-COMBAT] fight(): typed combatData OK — navigating to combat screen")
            #endif
            appState.combatData = combatData
            // Store pending result to apply after combat animation
            pendingFightResult = result
            appState.mainPath.append(AppRoute.combat)
        } else {
            #if DEBUG
            print("[DUNGEON-COMBAT] fight(): empty combat log — applying result directly (no combat animation)")
            #endif
            // No animation — apply directly
            applyFightResult(result)
        }
    }

    var pendingFightResult: DungeonFightResponse?

    func applyPendingResult() {
        // Dice combat hands its settled match over through AppState.
        if let data = appState.pendingDungeonBossResult {
            appState.pendingDungeonBossResult = nil
            applyDiceResult(data)
            return
        }
        guard let result = pendingFightResult else { return }
        pendingFightResult = nil
        applyFightResult(result)
    }

    /// Dice combat (`/pvp/match/complete` for a dungeon boss) → the same
    /// victory / defeat overlays as the classic dungeon fight.
    private func applyDiceResult(_ data: CombatData) {
        appState.fightsSinceSessionSummary += 1
        let res = data.result
        let postFightHp = data.postCombatHp?.player

        if res.isWin {
            let hpFraction: Double? = postFightHp.map {
                Double($0) / Double(max(data.player.maxHp, 1))
            }
            applyVictory(
                gold: data.rewards?.gold ?? res.goldReward ?? 0,
                xp: data.rewards?.xp ?? res.xpReward ?? 0,
                items: data.loot ?? [],
                leveledUp: res.leveledUp ?? false,
                newLevel: res.newLevel,
                statPoints: res.statPointsAwarded ?? 3,
                passivePoints: res.passivePointsAwarded ?? 0,
                hpFraction: hpFraction,
                postFightHp: postFightHp,
                serverFloorCleared: data.dungeon?.floorCleared,
                serverDungeonComplete: data.dungeon?.dungeonComplete ?? false
            )
        } else {
            // Defeat — the server deleted the run; saved progress stays.
            runId = ""
            if let postFightHp, var char = appState.currentCharacter {
                char.currentHp = postFightHp
                appState.currentCharacter = char
            }
            defeatTotalGold = 0
            defeatTotalXP = 0
            defeatFloorsCleared = defeatedCount
            showDefeat = true
            Task { [characterService] in
                await characterService.loadCharacter()
            }
        }
    }

    /// Shared by the classic and the dice fight: fill the victory overlay,
    /// update the hero optimistically, advance the dungeon.
    private func applyVictory(gold: Int,
                              xp: Int,
                              items: [CombatLootItem],
                              leveledUp: Bool,
                              newLevel: Int?,
                              statPoints: Int,
                              passivePoints: Int,
                              hpFraction: Double?,
                              postFightHp: Int? = nil,
                              serverFloorCleared: Int? = nil,
                              serverDungeonComplete: Bool) {
        victoryGold = gold
        victoryXP = xp
        victoryItems = items

        // Level-up metadata — consumed by DungeonVictoryView to animate the
        // XP bar and trigger the level-up modal in sync with the bar
        // finishing its fill (mirrors arena/pvp flow).
        victoryLeveledUp = leveledUp
        victoryNewLevel = newLevel
        victoryStatPointsAwarded = leveledUp ? statPoints : 0
        victoryPassivePointsAwarded = leveledUp ? passivePoints : 0

        // HP fraction for the star rating; fall back to the hero's HP.
        if let hpFraction {
            hpFractionAfterBattle = hpFraction
        } else if let char = appState.currentCharacter {
            hpFractionAfterBattle = Double(char.currentHp) / Double(max(char.maxHp, 1))
        }

        // Optimistic character update so DungeonVictoryView can snapshot
        // the XP transition. Single write-back (struct) to avoid @Observable
        // re-entrant exclusive-access violations. Background loadCharacter()
        // below reconciles against authoritative server state afterwards.
        if var char = appState.currentCharacter {
            if let postFightHp {
                char.currentHp = postFightHp
            }
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
                if passivePoints > 0 {
                    char.passivePointsAvailable = (char.passivePointsAvailable ?? 0) + passivePoints
                }
            }
            appState.currentCharacter = char
        }

        // The server's cleared floor is the new defeated count; fall back to
        // counting locally (classic fight responses don't carry it).
        if let serverFloorCleared, serverFloorCleared > 0 {
            defeatedCount = serverFloorCleared
        } else {
            defeatedCount += 1
        }
        // The trail map shows the win the moment the player walks back.
        if let id = dungeon?.id {
            cache.updateDungeonProgress(id, defeated: defeatedCount)
        }
        showVictory = true

        // Celebrate epic+ drops; common/uncommon show on the victory screen.
        if let first = victoryItems.first {
            let rarity = first.rarity ?? "common"
            let rarityEnum = ItemRarity(rawValue: rarity) ?? .common
            if rarityEnum == .epic || rarityEnum == .legendary {
                let subtitle = victoryItems.count > 1 ? "+\(victoryItems.count - 1) more!" : "Rare drop!"
                appState.showCelebration(.rareDrop, title: "\(rarity.capitalized) \(first.displayName)", subtitle: subtitle)
            }
        }

        if isDungeonComplete || serverDungeonComplete {
            runId = ""
            // FTUE: mark explore dungeon complete
            TutorialManager.shared.completeFTUEObjective(.exploreDungeon)
        }

        // Refresh character data (gold, xp, level may have changed).
        // The level-up modal waits for DungeonVictoryView's XP bar.
        Task { [characterService] in
            await characterService.loadCharacter()
        }
    }

    private func applyFightResult(_ result: DungeonFightResponse) {
        let won = result.victory

        if won {
            applyVictory(
                gold: result.rewards?.gold ?? result.result.goldReward ?? 0,
                xp: result.rewards?.xp ?? result.result.xpReward ?? 0,
                items: result.loot ?? [],
                leveledUp: result.result.leveledUp ?? false,
                newLevel: result.result.newLevel,
                statPoints: result.result.statPointsAwarded ?? 3,
                passivePoints: result.result.passivePointsAwarded ?? 0,
                hpFraction: result.playerHpPercent ?? result.rewards?.hpPercent,
                serverDungeonComplete: result.dungeonComplete ?? false
            )
        } else {
            // Defeat — run is deleted server-side
            runId = ""

            // Extract total progress earned during the run
            defeatTotalGold = result.rewards?.gold ?? 0
            defeatTotalXP = result.rewards?.xp ?? 0
            defeatFloorsCleared = result.rewards?.floorsCleared ?? 0

            showDefeat = true
            HapticManager.error()

            // Refresh character data (HP, stamina may have changed)
            Task { [characterService] in
                await characterService.loadCharacter()
            }
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

    /// Close the victory overlay and put the next boss on the stage.
    /// `ceremony: false` when the player goes straight into the next fight —
    /// the victory screen already revealed that boss.
    func proceedToNextBoss(ceremony: Bool = true) {
        showVictory = false
        selectedBossIndex = currentBossIndex
        if ceremony { queueBossUnlockIfAny() }
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

    /// TRY AGAIN: close the overlay and stay in the dungeon with the same
    /// boss on the stage (it used to leave the dungeon).
    func dismissDefeat() {
        showDefeat = false
        selectedBossIndex = currentBossIndex
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
        Character.xpToNextLevel(level)
    }
}
