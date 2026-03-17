import Foundation

/// Central client-side cache for game data.
/// Stores data from /game/init and screen-specific caches with TTLs.
/// Serves screens instantly without network requests.
@MainActor @Observable
final class GameDataCache {

    // MARK: - Skins catalog (loaded once, rarely changes)

    private(set) var skins: [AppearanceSkin] = []
    private var skinsByKey: [String: AppearanceSkin] = [:]

    func skinImageURL(for skinKey: String?) -> URL? {
        guard let key = skinKey else { return nil }
        return skinsByKey[key]?.resolvedImageURL
    }

    /// Returns the local asset key for a skin, preferring imageKey, falling back to skinKey.
    func skinImageKey(for skinKey: String?) -> String? {
        guard let key = skinKey else { return nil }
        return skinsByKey[key]?.resolvedImageKey ?? key
    }

    func cacheSkins(_ data: [AppearanceSkin]) {
        skins = data
        skinsByKey = Dictionary(data.map { ($0.skinKey, $0) }, uniquingKeysWith: { _, last in last })
    }

    // MARK: - Screen-specific caches with timestamps

    private(set) var opponents: [Opponent] = []
    private var opponentsFetchedAt: Date?

    private(set) var leaderboardEntries: [String: [LeaderboardEntry]] = [:]
    private var leaderboardFetchedAt: Date?

    private(set) var shopItems: [ShopItem] = []
    private var shopFetchedAt: Date?

    private(set) var achievements: [Achievement] = []
    private var achievementsFetchedAt: Date?

    private(set) var battlePassData: BattlePassData?
    private var battlePassFetchedAt: Date?

    private(set) var dungeonProgress: [String: Int] = [:]
    private var dungeonProgressFetchedAt: Date?

    private(set) var goldMineSlots: [[String: Any]] = []
    var goldMineMaxSlots: Int = 3
    private var goldMineFetchedAt: Date?

    private(set) var revengeList: [RevengeEntry] = []
    private var revengeFetchedAt: Date?

    private(set) var matchHistory: [MatchHistory] = []
    private var historyFetchedAt: Date?

    // MARK: - Feature Flags (resolved server-side, keyed by flag key)

    private(set) var featureFlags: [String: Any] = [:]

    func isFeatureEnabled(_ key: String) -> Bool {
        featureFlags[key] as? Bool ?? false
    }

    func featureFlagValue<T>(_ key: String, default defaultValue: T) -> T {
        featureFlags[key] as? T ?? defaultValue
    }

    func cacheFeatureFlags(_ flags: [String: Any]) {
        featureFlags = flags
    }

    // MARK: - Game config from server

    var gameConfig: GameConfig?
    var serverTimeDelta: TimeInterval = 0 // localTime - serverTime

    // MARK: - TTLs

    private let opponentsTTL: TimeInterval = 30
    private let leaderboardTTL: TimeInterval = 60
    private let shopTTL: TimeInterval = 300
    private let achievementsTTL: TimeInterval = 120
    private let battlePassTTL: TimeInterval = 120
    private let dungeonTTL: TimeInterval = 60
    private let goldMineTTL: TimeInterval = 15
    private let revengeTTL: TimeInterval = 30
    private let historyTTL: TimeInterval = 60

    // MARK: - Init data loaded flag

    var isInitLoaded = false

    // MARK: - Opponents Cache

    func cachedOpponents() -> [Opponent]? {
        guard let fetchedAt = opponentsFetchedAt,
              Date().timeIntervalSince(fetchedAt) < opponentsTTL,
              !opponents.isEmpty else { return nil }
        return opponents
    }

    func cacheOpponents(_ data: [Opponent]) {
        opponents = data
        opponentsFetchedAt = Date()
    }

    func invalidateOpponents() {
        opponentsFetchedAt = nil
    }

    // MARK: - Leaderboard Cache

    func cachedLeaderboard() -> [String: [LeaderboardEntry]]? {
        guard let fetchedAt = leaderboardFetchedAt,
              Date().timeIntervalSince(fetchedAt) < leaderboardTTL,
              !leaderboardEntries.isEmpty else { return nil }
        return leaderboardEntries
    }

    func cacheLeaderboard(_ data: [String: [LeaderboardEntry]]) {
        leaderboardEntries = data
        leaderboardFetchedAt = Date()
    }

    // MARK: - Shop Cache

    func cachedShop() -> [ShopItem]? {
        guard let fetchedAt = shopFetchedAt,
              Date().timeIntervalSince(fetchedAt) < shopTTL,
              !shopItems.isEmpty else { return nil }
        return shopItems
    }

    func cacheShop(_ data: [ShopItem]) {
        shopItems = data
        shopFetchedAt = Date()
    }

    func invalidateShop() {
        shopFetchedAt = nil
    }

    // MARK: - Achievements Cache

    func cachedAchievements() -> [Achievement]? {
        guard let fetchedAt = achievementsFetchedAt,
              Date().timeIntervalSince(fetchedAt) < achievementsTTL,
              !achievements.isEmpty else { return nil }
        return achievements
    }

    func cacheAchievements(_ data: [Achievement]) {
        achievements = data
        achievementsFetchedAt = Date()
    }

    func invalidateAchievements() {
        achievementsFetchedAt = nil
    }

    // MARK: - Battle Pass Cache

    func cachedBattlePass() -> BattlePassData? {
        guard let fetchedAt = battlePassFetchedAt,
              Date().timeIntervalSince(fetchedAt) < battlePassTTL,
              battlePassData != nil else { return nil }
        return battlePassData
    }

    func cacheBattlePass(_ data: BattlePassData) {
        battlePassData = data
        battlePassFetchedAt = Date()
    }

    func invalidateBattlePass() {
        battlePassFetchedAt = nil
    }

    // MARK: - Dungeon Progress Cache

    func cachedDungeonProgress() -> [String: Int]? {
        guard let fetchedAt = dungeonProgressFetchedAt,
              Date().timeIntervalSince(fetchedAt) < dungeonTTL else { return nil }
        return dungeonProgress
    }

    func cacheDungeonProgress(_ data: [String: Int]) {
        dungeonProgress = data
        dungeonProgressFetchedAt = Date()
    }

    func invalidateDungeonProgress() {
        dungeonProgressFetchedAt = nil
    }

    // MARK: - Gold Mine Cache

    func cachedGoldMine() -> (slots: [[String: Any]], maxSlots: Int)? {
        guard let fetchedAt = goldMineFetchedAt,
              Date().timeIntervalSince(fetchedAt) < goldMineTTL else { return nil }
        return (goldMineSlots, goldMineMaxSlots)
    }

    func cacheGoldMine(slots: [[String: Any]], maxSlots: Int) {
        goldMineSlots = slots
        goldMineMaxSlots = maxSlots
        goldMineFetchedAt = Date()
    }

    func invalidateGoldMine() {
        goldMineFetchedAt = nil
    }

    // MARK: - Revenge Cache

    func cachedRevenge() -> [RevengeEntry]? {
        guard let fetchedAt = revengeFetchedAt,
              Date().timeIntervalSince(fetchedAt) < revengeTTL else { return nil }
        return revengeList
    }

    func cacheRevenge(_ data: [RevengeEntry]) {
        revengeList = data
        revengeFetchedAt = Date()
    }

    func invalidateRevenge() {
        revengeFetchedAt = nil
    }

    // MARK: - Match History Cache

    func cachedHistory() -> [MatchHistory]? {
        guard let fetchedAt = historyFetchedAt,
              Date().timeIntervalSince(fetchedAt) < historyTTL else { return nil }
        return matchHistory
    }

    func cacheHistory(_ data: [MatchHistory]) {
        matchHistory = data
        historyFetchedAt = Date()
    }

    // MARK: - Reset

    func invalidateAll() {
        skins = []
        skinsByKey = [:]
        opponents = []
        opponentsFetchedAt = nil
        leaderboardEntries = [:]
        leaderboardFetchedAt = nil
        shopItems = []
        shopFetchedAt = nil
        achievements = []
        achievementsFetchedAt = nil
        battlePassData = nil
        battlePassFetchedAt = nil
        dungeonProgress = [:]
        dungeonProgressFetchedAt = nil
        goldMineSlots = []
        goldMineFetchedAt = nil
        revengeList = []
        revengeFetchedAt = nil
        matchHistory = []
        historyFetchedAt = nil
        featureFlags = [:]
        gameConfig = nil
        isInitLoaded = false
    }
}

// MARK: - Game Config Model

struct GameConfig {
    let staminaMax: Int
    let staminaRegenMinutes: Int
    let pvpStaminaCost: Int
    let freePvpPerDay: Int
    let upgradeChances: [Int]
    let maxLevel: Int
    let statPointsPerLevel: Int
    let pvpWinGold: Int
    let pvpLossGold: Int
    let pvpWinXp: Int
    let pvpLossXp: Int
    let critMultiplier: Double
    let maxCritChance: Int
    let maxDodgeChance: Int

    init(from dict: [String: Any]) {
        staminaMax = dict["staminaMax"] as? Int ?? 120
        staminaRegenMinutes = dict["staminaRegenMinutes"] as? Int ?? 8
        pvpStaminaCost = dict["pvpStaminaCost"] as? Int ?? 10
        freePvpPerDay = dict["freePvpPerDay"] as? Int ?? 3
        upgradeChances = dict["upgradeChances"] as? [Int] ?? [100, 100, 100, 100, 100, 80, 60, 40, 25, 15]
        maxLevel = dict["maxLevel"] as? Int ?? 50
        statPointsPerLevel = dict["statPointsPerLevel"] as? Int ?? 3
        pvpWinGold = dict["pvpWinGold"] as? Int ?? 100
        pvpLossGold = dict["pvpLossGold"] as? Int ?? 30
        pvpWinXp = dict["pvpWinXp"] as? Int ?? 80
        pvpLossXp = dict["pvpLossXp"] as? Int ?? 20
        critMultiplier = dict["critMultiplier"] as? Double ?? 1.5
        maxCritChance = dict["maxCritChance"] as? Int ?? 50
        maxDodgeChance = dict["maxDodgeChance"] as? Int ?? 30
    }
}
