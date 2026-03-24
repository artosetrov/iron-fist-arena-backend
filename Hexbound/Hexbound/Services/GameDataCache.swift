import Foundation
import CoreGraphics

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

    private(set) var dungeonList: [DungeonInfo] = []
    private var dungeonListFetchedAt: Date?

    private(set) var goldMineSlots: [[String: Any]] = []
    var goldMineMaxSlots: Int = 3
    private var goldMineFetchedAt: Date?

    private(set) var revengeList: [RevengeEntry] = []
    private var revengeFetchedAt: Date?

    private(set) var matchHistory: [MatchHistory] = []
    private var historyFetchedAt: Date?

    private(set) var socialStatus: SocialStatus?
    private var socialStatusFetchedAt: Date?

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

    // MARK: - Hub Layout (admin-defined building positions + sizes)

    struct BuildingOverride {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat? // nil = use default
    }

    private static let hubLayoutKey = "hub_layout_cache"

    private(set) var hubLayout: [String: BuildingOverride] = GameDataCache.loadFromDisk() {
        didSet { persistHubLayout() }
    }

    private static func loadFromDisk() -> [String: BuildingOverride] {
        guard let dict = UserDefaults.standard.dictionary(forKey: hubLayoutKey) as? [String: [String: Double]] else {
            return [:]
        }
        var result: [String: BuildingOverride] = [:]
        for (id, coords) in dict {
            if let x = coords["x"], let y = coords["y"] {
                result[id] = BuildingOverride(x: CGFloat(x), y: CGFloat(y), size: coords["size"].map { CGFloat($0) })
            }
        }
        return result
    }

    func cacheHubLayout(_ layout: [String: BuildingOverride]) {
        hubLayout = layout
    }

    func cacheHubLayout(from dict: [String: Any]) {
        var result: [String: BuildingOverride] = [:]
        for (buildingId, value) in dict {
            if let coords = value as? [String: Any],
               let x = coords["x"] as? Double,
               let y = coords["y"] as? Double {
                let size = coords["size"] as? Double
                result[buildingId] = BuildingOverride(x: CGFloat(x), y: CGFloat(y), size: size.map { CGFloat($0) })
            }
        }
        hubLayout = result
    }

    func loadHubLayoutFromDisk() {
        guard hubLayout.isEmpty,
              let dict = UserDefaults.standard.dictionary(forKey: Self.hubLayoutKey) as? [String: [String: Double]]
        else { return }
        var result: [String: BuildingOverride] = [:]
        for (id, coords) in dict {
            if let x = coords["x"], let y = coords["y"] {
                result[id] = BuildingOverride(x: CGFloat(x), y: CGFloat(y), size: coords["size"].map { CGFloat($0) })
            }
        }
        hubLayout = result
    }

    private func persistHubLayout() {
        guard !hubLayout.isEmpty else { return }
        var dict: [String: [String: Double]] = [:]
        for (id, o) in hubLayout {
            var entry: [String: Double] = ["x": Double(o.x), "y": Double(o.y)]
            if let s = o.size { entry["size"] = Double(s) }
            dict[id] = entry
        }
        UserDefaults.standard.set(dict, forKey: Self.hubLayoutKey)
    }

    // MARK: - Dungeon Map Layout (admin-defined dungeon node positions + sizes)

    private static let dungeonMapLayoutKey = "dungeon_map_layout_cache"

    private(set) var dungeonMapLayout: [String: BuildingOverride] = GameDataCache.loadDungeonMapFromDisk() {
        didSet { persistDungeonMapLayout() }
    }

    private static func loadDungeonMapFromDisk() -> [String: BuildingOverride] {
        guard let dict = UserDefaults.standard.dictionary(forKey: dungeonMapLayoutKey) as? [String: [String: Double]] else {
            return [:]
        }
        var result: [String: BuildingOverride] = [:]
        for (id, coords) in dict {
            if let x = coords["x"], let y = coords["y"] {
                result[id] = BuildingOverride(x: CGFloat(x), y: CGFloat(y), size: coords["size"].map { CGFloat($0) })
            }
        }
        return result
    }

    func cacheDungeonMapLayout(_ layout: [String: BuildingOverride]) {
        dungeonMapLayout = layout
    }

    func cacheDungeonMapLayout(from dict: [String: Any]) {
        var result: [String: BuildingOverride] = [:]
        for (buildingId, value) in dict {
            if let coords = value as? [String: Any],
               let x = coords["x"] as? Double,
               let y = coords["y"] as? Double {
                let size = coords["size"] as? Double
                result[buildingId] = BuildingOverride(x: CGFloat(x), y: CGFloat(y), size: size.map { CGFloat($0) })
            }
        }
        dungeonMapLayout = result
    }

    func loadDungeonMapLayoutFromDisk() {
        guard dungeonMapLayout.isEmpty,
              let dict = UserDefaults.standard.dictionary(forKey: Self.dungeonMapLayoutKey) as? [String: [String: Double]]
        else { return }
        var result: [String: BuildingOverride] = [:]
        for (id, coords) in dict {
            if let x = coords["x"], let y = coords["y"] {
                result[id] = BuildingOverride(x: CGFloat(x), y: CGFloat(y), size: coords["size"].map { CGFloat($0) })
            }
        }
        dungeonMapLayout = result
    }

    private func persistDungeonMapLayout() {
        guard !dungeonMapLayout.isEmpty else { return }
        var dict: [String: [String: Double]] = [:]
        for (id, o) in dungeonMapLayout {
            var entry: [String: Double] = ["x": Double(o.x), "y": Double(o.y)]
            if let s = o.size { entry["size"] = Double(s) }
            dict[id] = entry
        }
        UserDefaults.standard.set(dict, forKey: Self.dungeonMapLayoutKey)
    }

    // MARK: - Sky Layout (admin-defined sky object positions + sizes)

    private static let skyLayoutKey = "sky_layout_cache"

    private(set) var skyLayout: [String: BuildingOverride] = GameDataCache.loadSkyFromDisk() {
        didSet { persistSkyLayout() }
    }

    private static func loadSkyFromDisk() -> [String: BuildingOverride] {
        guard let dict = UserDefaults.standard.dictionary(forKey: skyLayoutKey) as? [String: [String: Double]] else {
            return [:]
        }
        var result: [String: BuildingOverride] = [:]
        for (id, coords) in dict {
            if let x = coords["x"], let y = coords["y"] {
                result[id] = BuildingOverride(x: CGFloat(x), y: CGFloat(y), size: coords["size"].map { CGFloat($0) })
            }
        }
        return result
    }

    func cacheSkyLayout(_ layout: [String: BuildingOverride]) {
        skyLayout = layout
    }

    private func persistSkyLayout() {
        guard !skyLayout.isEmpty else { return }
        var dict: [String: [String: Double]] = [:]
        for (id, o) in skyLayout {
            var entry: [String: Double] = ["x": Double(o.x), "y": Double(o.y)]
            if let s = o.size { entry["size"] = Double(s) }
            dict[id] = entry
        }
        UserDefaults.standard.set(dict, forKey: Self.skyLayoutKey)
    }

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

    // MARK: - Dungeon List Cache

    private let dungeonListTTL: TimeInterval = 300 // 5 minutes

    func cachedDungeonList() -> [DungeonInfo]? {
        guard let fetchedAt = dungeonListFetchedAt,
              Date().timeIntervalSince(fetchedAt) < dungeonListTTL,
              !dungeonList.isEmpty else { return nil }
        return dungeonList
    }

    func cacheDungeonList(_ data: [DungeonInfo]) {
        dungeonList = data
        dungeonListFetchedAt = Date()
    }

    func invalidateDungeonList() {
        dungeonListFetchedAt = nil
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

    // Social Status TTL: 2 minutes (badge counts refresh frequently)
    private let socialStatusTTL: TimeInterval = 120

    func cachedSocialStatus() -> SocialStatus? {
        guard let fetchedAt = socialStatusFetchedAt,
              Date().timeIntervalSince(fetchedAt) < socialStatusTTL else { return nil }
        return socialStatus
    }

    func cacheSocialStatus(_ data: SocialStatus) {
        socialStatus = data
        socialStatusFetchedAt = Date()
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
        dungeonList = []
        dungeonListFetchedAt = nil
        goldMineSlots = []
        goldMineFetchedAt = nil
        revengeList = []
        revengeFetchedAt = nil
        matchHistory = []
        historyFetchedAt = nil
        socialStatus = nil
        socialStatusFetchedAt = nil
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
