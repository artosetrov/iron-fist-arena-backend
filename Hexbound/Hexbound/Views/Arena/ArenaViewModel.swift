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

    // Loading
    var isLoadingOpponents = false
    var isLoadingRevenge = false
    var isLoadingHistory = false
    var fightingOpponentId: String?

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

    var canFight: Bool {
        hasFreePvp || currentStamina >= AppConstants.pvpStaminaCost
    }

    var staminaCost: Int {
        hasFreePvp ? 0 : AppConstants.pvpStaminaCost
    }

    // MARK: - Load Data

    func loadOpponents() async {
        // Serve cached opponents instantly, then refresh in background
        if let cached = cache.cachedOpponents() {
            opponents = cached
        } else {
            isLoadingOpponents = true
        }
        let result = await pvpService.getOpponents()
        opponents = result
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
                _ = await battlePreloader.prepare(opponentId: opponent.id)
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

        // 1. Navigate to combat screen INSTANTLY (shows preparation animation)
        appState.combatData = nil
        appState.combatResult = nil
        appState.resolveResult = nil
        appState.pendingLoot = []
        fightingOpponentId = nil
        appState.mainPath.append(AppRoute.combat)

        // 2. Prepare battle (get seed + stats from server)
        guard let prepareData = await battlePreloader.prepare(opponentId: opponentId) else {
            // Prepare failed — pop combat screen
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
            }
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

    /// Apply resolve data to character immediately so UI reflects server-verified state
    private func applyResolveToCharacter(_ result: ResolveResult?) {
        guard let result else { return }

        // Update stamina
        appState.currentCharacter?.currentStamina = result.staminaCurrent
        appState.currentCharacter?.maxStamina = result.staminaMax

        // Update gold and XP from server-verified rewards
        if let currentGold = appState.currentCharacter?.gold {
            appState.currentCharacter?.gold = currentGold + result.goldReward
        }
        if let currentXp = appState.currentCharacter?.experience {
            appState.currentCharacter?.experience = currentXp + result.xpReward
        }

        // Update PvP rating
        if let currentRating = appState.currentCharacter?.pvpRating {
            appState.currentCharacter?.pvpRating = currentRating + result.ratingChange
        }

        // Update win/loss counters
        let isWin = result.serverWinnerId == appState.currentCharacter?.id
        if isWin {
            appState.currentCharacter?.pvpWins = (appState.currentCharacter?.pvpWins ?? 0) + 1
            appState.currentCharacter?.pvpWinStreak = (appState.currentCharacter?.pvpWinStreak ?? 0) + 1
            appState.currentCharacter?.pvpLossStreak = 0
        } else {
            appState.currentCharacter?.pvpLosses = (appState.currentCharacter?.pvpLosses ?? 0) + 1
            appState.currentCharacter?.pvpLossStreak = (appState.currentCharacter?.pvpLossStreak ?? 0) + 1
            appState.currentCharacter?.pvpWinStreak = 0
        }

        // Store loot for display
        if !result.loot.isEmpty {
            appState.pendingLoot = result.loot
        }

        // Level-up modal is triggered from CombatResultDetailView.onAppear
        // to avoid showing it during combat animation

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
        cache.invalidateOpponents()
        await battlePreloader.invalidateCache()
        // Load opponents + character in parallel
        async let opponentRefresh: Void = loadOpponents()
        async let charRefresh: Void = characterService.loadCharacter()
        _ = await (opponentRefresh, charRefresh)
    }
}
