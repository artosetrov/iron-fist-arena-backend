import Foundation

enum APIEndpoints {
    // MARK: - Auth
    static let authLogin = "/api/auth/login"
    static let authRegister = "/api/auth/register"
    static let authGuestLogin = "/api/auth/guest-login"
    static let authForgotPassword = "/api/auth/forgot-password"
    static let authApple = "/api/auth/apple"
    static let authGoogle = "/api/auth/google"
    static let authUpgradeGuest = "/api/auth/upgrade-guest"

    // MARK: - Characters
    static let characters = "/api/characters"
    static let checkName = "/api/characters/check-name"
    static func character(_ id: String) -> String { "/api/characters/\(id)" }
    static func characterProfile(_ id: String) -> String { "/api/characters/\(id)/profile" }
    static func allocateStats(_ id: String) -> String { "/api/characters/\(id)/allocate-stats" }
    static func respecStats(_ id: String) -> String { "/api/characters/\(id)/respec-stats" }
    static func setStance(_ id: String) -> String { "/api/characters/\(id)/stance" }
    static func changeOrigin(_ id: String) -> String { "/api/characters/\(id)/origin" }
    static func changeAppearance(_ id: String) -> String { "/api/characters/\(id)/appearance" }

    // MARK: - Combat
    static let combatSimulate = "/api/combat/simulate"
    static let combatStatus = "/api/combat/status"
    static let combatBuyExtra = "/api/combat/buy-extra"

    // MARK: - PvP
    static let pvpFight = "/api/pvp/fight"
    static let pvpPrepare = "/api/pvp/prepare"
    static let pvpResolve = "/api/pvp/resolve"
    static let pvpOpponents = "/api/pvp/opponents"
    static let pvpRevenge = "/api/pvp/revenge"
    static func pvpRevengeMatch(_ matchId: String) -> String { "/api/pvp/revenge/\(matchId)" }
    static let pvpHistory = "/api/pvp/history"

    // MARK: - Inventory
    static let inventory = "/api/inventory"
    static let inventoryEquip = "/api/inventory/equip"
    static let inventoryUnequip = "/api/inventory/unequip"
    static let inventorySell = "/api/inventory/sell"
    static let inventoryUse = "/api/inventory/use"
    static let consumablesUse = "/api/consumables/use"
    static let inventoryExpand = "/api/inventory/expand"

    // MARK: - Shop
    static let shopItems = "/api/shop/items"
    static let shopBuy = "/api/shop/buy"
    static let shopBuyPotion = "/api/shop/buy-potion"
    static let shopBuyConsumable = "/api/shop/buy-consumable"
    static let shopBuyGold = "/api/shop/buy-gold"
    static let shopBuyGems = "/api/shop/buy-gems"
    static let shopOffers = "/api/shop/offers"
    static let shopRepair = "/api/shop/repair"
    static let shopUpgrade = "/api/shop/upgrade"

    // MARK: - Quests
    static let questsDaily = "/api/quests/daily"
    static let questsDailyBonus = "/api/quests/daily/bonus"

    // MARK: - Achievements
    static let achievements = "/api/achievements"
    static let achievementsClaim = "/api/achievements/claim"

    // MARK: - Battle Pass
    static let battlePass = "/api/battle-pass"
    static func battlePassClaim(_ level: Int) -> String { "/api/battle-pass/claim/\(level)" }
    static let battlePassBuyPremium = "/api/battle-pass/buy-premium"

    // MARK: - Dungeons
    static let dungeons = "/api/dungeons"
    static let dungeonsList = "/api/dungeons/list"
    static let dungeonsStart = "/api/dungeons/start"
    static let dungeonsFight = "/api/dungeons/fight"

    // MARK: - Push Notifications
    static let pushRegister = "/api/push/register"
    static let pushUnregister = "/api/push/unregister"

    // MARK: - Dungeon Rush
    static let dungeonRushStart = "/api/dungeon-rush/start"
    static let dungeonRushFight = "/api/dungeon-rush/fight"
    static let dungeonRushStatus = "/api/dungeon-rush/status"
    static let dungeonRushAbandon = "/api/dungeon-rush/abandon"
    static let dungeonRushResolve = "/api/dungeon-rush/resolve"
    static let dungeonRushShopBuy = "/api/dungeon-rush/shop-buy"

    // MARK: - Shell Game
    static let shellGameStart = "/api/minigames/shell-game/start"
    static let shellGameGuess = "/api/minigames/shell-game/guess"

    // MARK: - Gold Mine
    static let goldMineStatus = "/api/minigames/gold-mine/status"
    static let goldMineStart = "/api/minigames/gold-mine/start"
    static let goldMineCollect = "/api/minigames/gold-mine/collect"
    static let goldMineBoost = "/api/minigames/gold-mine/boost"
    static let goldMineBuySlot = "/api/minigames/gold-mine/buy-slot"

    // MARK: - Daily Login
    static let dailyLogin = "/api/daily-login"
    static let dailyLoginClaim = "/api/daily-login/claim"

    // MARK: - Leaderboard
    static let leaderboard = "/api/leaderboard"

    // MARK: - Game Init
    static let gameInit = "/api/game/init"

    // MARK: - Appearances
    static let appearances = "/api/appearances"

    // MARK: - Events
    static let eventsActive = "/api/events/active"

    // MARK: - IAP
    static let iapVerify = "/api/iap/verify"
    static let iapRestore = "/api/iap/restore"
    static let iapProducts = "/api/iap/products"

    // MARK: - Social
    static let socialFriends = "/api/social/friends"
    static let socialStatus = "/api/social/status"
    static let socialChallenges = "/api/social/challenges"

    // MARK: - Admin
    static let adminHubLayout = "/api/admin/hub-layout"
    static let adminDungeonMapLayout = "/api/admin/dungeon-map-layout"
}
