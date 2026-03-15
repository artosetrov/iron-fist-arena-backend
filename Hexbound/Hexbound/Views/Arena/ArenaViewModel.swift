import SwiftUI

@MainActor @Observable
final class ArenaViewModel {
    private let appState: AppState
    private let cache: GameDataCache
    private let pvpService: PvPService
    private let characterService: CharacterService
    private let battlePreloader: BattlePreloader

    // Tab
    var selectedTab = 0

    // Data
    var opponents: [Opponent] = []
    var revengeList: [RevengeEntry] = []
    var history: [MatchHistory] = []

    // Displayed pair (2 opponents shown at a time, refresh cycles through)
    var displayedOpponents: [Opponent] = []
    private var displayOffset: Int = 0

    // Comparison sheet
    var selectedOpponent: Opponent?
    var showComparison = false

    // Loading
    var isLoadingOpponents = false
    var isLoadingRevenge = false
    var isLoadingHistory = false
    var fightingOpponentId: String?
    var isRefreshing = false

    // Equipment / Loadout
    var equippedItems: [Item] = []

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.pvpService = PvPService(appState: appState)
        self.characterService = CharacterService(appState: appState)
        self.battlePreloader = BattlePreloader(appState: appState)
    }

    // MARK: - Character helpers

    var character: Character? { appState.currentCharacter }
    var pvpRating: Int { character?.pvpRating ?? 1000 }
    var rank: PvPRank { PvPRank.fromRating(pvpRating) }
    /// Number of free PvP fights USED today (0..3)
    var freePvpUsed: Int { character?.freePvpToday ?? 0 }
    /// Number of free PvP fights still REMAINING today
    var freePvpRemaining: Int { AppConstants.freePvpPerDay - freePvpUsed }
    var hasFreePvp: Bool { freePvpUsed < AppConstants.freePvpPerDay }
    var firstWinToday: Bool { character?.firstWinToday ?? false }
    var currentStamina: Int { character?.currentStamina ?? 0 }
    var maxStamina: Int { character?.maxStamina ?? 120 }

    func goToShop() {
        appState.shopInitialTab = 3
        appState.mainPath.append(AppRoute.shop)
    }

    func goToEquipment() {
        appState.mainPath.append(AppRoute.hero)
    }

    var canFight: Bool {
        hasFreePvp || currentStamina >= AppConstants.pvpStaminaCost
    }

    var staminaCost: Int {
        hasFreePvp ? 0 : AppConstants.pvpStaminaCost
    }

    // MARK: - Display helpers

    /// Shows the current pair of opponents based on displayOffset
    private func updateDisplayedOpponents() {
        guard !opponents.isEmpty else {
            displayedOpponents = []
            return
        }
        let start = displayOffset % opponents.count
        var pair: [Opponent] = []
        for i in 0..<2 {
            let idx = (start + i) % opponents.count
            pair.append(opponents[idx])
        }
        displayedOpponents = pair
    }

    /// Select opponent — opens comparison sheet
    func selectOpponent(_ opponent: Opponent) {
        selectedOpponent = opponent
        showComparison = true
    }

    // MARK: - Load Data

    func loadOpponents() async {
        // Serve cached opponents instantly, then refresh in background
        if let cached = cache.cachedOpponents() {
            opponents = cached
            updateDisplayedOpponents()
        } else {
            isLoadingOpponents = true
        }
        let result = await pvpService.getOpponents()
        opponents = result
        updateDisplayedOpponents()
        cache.cacheOpponents(result)
        isLoadingOpponents = false

        // Preload battle data for top opponents so Fight tap is instant
        preloadBattleData(for: result)
    }

    /// Preloads /pvp/prepare data for up to 3 opponents in background.
    /// When user taps Fight, BattlePreloader returns from cache instantly.
    private func preloadBattleData(for opponents: [Opponent]) {
        guard let _ = appState.currentCharacter?.id else { return }
        for opponent in opponents.prefix(3) {
            Task(priority: .background) {
                _ = await battlePreloader.prepare(opponentId: opponent.id, showErrors: false)
            }
        }
    }

    func loadRevenge() async {
        // Serve cached revenge instantly
        if let cached = cache.cachedRevenge() {
            revengeList = cached
        } else {
            isLoadingRevenge = true
        }
        let result = await pvpService.getRevengeList()
        revengeList = result
        cache.cacheRevenge(result)
        isLoadingRevenge = false
    }

    func loadHistory() async {
        // Serve cached history instantly
        if let cached = cache.cachedHistory() {
            history = cached
        } else {
            isLoadingHistory = true
        }
        let result = await pvpService.getHistory()
        history = result
        cache.cacheHistory(result)
        isLoadingHistory = false
    }

    func loadAll() async {
        await loadOpponents()
    }

    func loadTabData() async {
        switch selectedTab {
        case 0: await loadOpponents()
        case 1: await loadRevenge()
        case 2: await loadHistory()
        default: break
        }
    }

    // MARK: - Fight (Instant Battle Flow)

    func fight(opponentId: String) async {
        fightingOpponentId = opponentId
        showComparison = false

        // 1. Navigate to combat screen INSTANTLY (shows preparation animation)
        appState.combatData = nil
        appState.combatResult = nil
        appState.resolveResult = nil
        appState.pendingLoot = []
        fightingOpponentId = nil
        appState.mainPath.append(AppRoute.combat)

        // 2. Prepare battle (get seed + stats from server)
        //    If a background preload is already in-flight, this awaits it.
        guard let prepareData = await battlePreloader.prepare(opponentId: opponentId) else {
            // Prepare failed — pop combat screen
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
            }
            appState.showToast("Failed to start battle", subtitle: "Check stamina and connection", type: .error)
            return
        }
        await battlePreloader.invalidatePreparedBattle(opponentId: opponentId)

        // 3. Run client-side combat simulation (instant, deterministic)
        let combatData = battlePreloader.simulateCombat(prepareData: prepareData)

        // 4. Deliver combat data — CombatDetailView picks this up and starts playback
        appState.combatData = combatData

        // 5. Resolve on server asynchronously (fire-and-forget)
        let winnerId = combatData.result.winnerId ?? ""
        let seed = prepareData.battleSeed
        Task {
            let result = await battlePreloader.resolve(
                opponentId: opponentId,
                battleTicketId: prepareData.battleTicketId,
                battleSeed: seed,
                clientWinnerId: winnerId
            )
            appState.resolveResult = result
            applyResolveToCharacter(result)
        }
    }

    func revenge(revengeId: String) async {
        fightingOpponentId = revengeId

        // 1. Navigate to combat screen INSTANTLY (shows preparation animation)
        appState.combatData = nil
        appState.combatResult = nil
        appState.resolveResult = nil
        appState.pendingLoot = []
        fightingOpponentId = nil
        appState.mainPath.append(AppRoute.combat)

        // 2. Prepare battle (server validates revenge entry + returns seed + stats)
        guard let prepareData = await battlePreloader.prepare(revengeId: revengeId) else {
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
            }
            appState.showToast("Failed to start battle", subtitle: "Check stamina and connection", type: .error)
            return
        }
        await battlePreloader.invalidatePreparedBattle(revengeId: revengeId)

        // 3. Run client-side combat simulation (instant, deterministic)
        let combatData = battlePreloader.simulateCombat(prepareData: prepareData)

        // 4. Deliver combat data — CombatDetailView picks this up and starts playback
        appState.combatData = combatData

        // 5. Resolve on server asynchronously (fire-and-forget)
        let winnerId = combatData.result.winnerId ?? ""
        let seed = prepareData.battleSeed
        let opponentId = prepareData.enemyStats.id
        Task {
            let result = await battlePreloader.resolve(
                opponentId: opponentId,
                battleTicketId: prepareData.battleTicketId,
                battleSeed: seed,
                clientWinnerId: winnerId,
                revengeId: revengeId
            )
            appState.resolveResult = result
            applyResolveToCharacter(result)
        }
    }

    /// Apply resolve data to character immediately so UI reflects server-verified state.
    /// Uses a single write-back to avoid @Observable re-entrant exclusive-access violations
    /// (Character is a struct, so repeated `?.prop = value` creates overlapping modify accesses).
    private func applyResolveToCharacter(_ result: ResolveResult?) {
        guard let result else { return }
        guard var char = appState.currentCharacter else { return }

        // Stamina
        char.currentStamina = result.staminaCurrent
        char.maxStamina = result.staminaMax

        // Gold & XP
        char.gold += result.goldReward
        char.experience = (char.experience ?? 0) + result.xpReward

        // PvP rating
        char.pvpRating += result.ratingChange

        // Win/loss counters
        let isWin = result.serverWinnerId == char.id
        if isWin {
            char.pvpWins += 1
            char.pvpWinStreak = (char.pvpWinStreak ?? 0) + 1
            char.pvpLossStreak = 0
        } else {
            char.pvpLosses += 1
            char.pvpLossStreak = (char.pvpLossStreak ?? 0) + 1
            char.pvpWinStreak = 0
        }

        // Single write-back — triggers one @Observable notification
        appState.currentCharacter = char

        // Store loot for display
        if !result.loot.isEmpty {
            appState.pendingLoot = result.loot
        }

        // Notify about broken equipment
        let brokenItems = result.durabilityDegraded.filter {
            ($0["durabilityAfter"] as? Int) == 0 && ($0["durabilityBefore"] as? Int ?? 0) > 0
        }
        for item in brokenItems {
            if let name = item["name"] as? String {
                appState.showToast("\(name) broke!", subtitle: "Visit blacksmith to repair", type: .error)
            }
        }

        // Invalidate caches that depend on character state
        cache.invalidateOpponents()
    }

    // MARK: - Refresh

    func refreshOpponents() async {
        isRefreshing = true

        if opponents.count > 2 {
            // Cycle to next pair from the existing pool
            displayOffset += 2
            updateDisplayedOpponents()
            // Preload battle data for new pair
            preloadBattleData(for: displayedOpponents)
        } else {
            // Not enough opponents cached — fetch fresh from server
            cache.invalidateOpponents()
            await battlePreloader.invalidateCache()
            async let opponentRefresh: Void = loadOpponents()
            async let charRefresh: Void = characterService.loadCharacter()
            _ = await (opponentRefresh, charRefresh)
            displayOffset = 0
        }

        isRefreshing = false
    }
}
