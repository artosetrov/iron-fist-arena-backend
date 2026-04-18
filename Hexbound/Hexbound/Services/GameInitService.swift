import Foundation

/// Calls /api/game/init and populates AppState + GameDataCache with all hub data.
/// Replaces 5+ individual API calls the client would otherwise make on startup.
@MainActor
final class GameInitService {
    private let appState: AppState
    private let cache: GameDataCache

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
    }

    /// Load all game data in a single request.
    /// Falls back to individual CharacterService if game/init fails.
    func loadGameData() async {
        guard let charId = appState.currentCharacter?.id else { return }

        // Load cached layouts from disk immediately (before network)
        cache.loadHubLayoutFromDisk()
        cache.loadDungeonMapLayoutFromDisk()

        do {
            let response: GameInitResponse = try await APIClient.shared.get(
                APIEndpoints.gameInit,
                params: ["character_id": charId]
            )

            appState.currentCharacter = response.character
            appState.currentUser = response.user
            appState.cachedInventory = response.inventoryItems
            appState.cachedTypedQuests = response.quests
            appState.cachedDailyLogin = response.dailyLogin

            // BUG-53: auto-open the Daily Login modal at most once per local
            // calendar day. Decision happens here — the exact moment we know
            // fresh server state — so subsequent NavigationStack pop-backs,
            // re-entries, or `.task` re-fires can never retrigger the popup.
            // `maybeEnqueueDailyLogin` also syncs `dailyLoginCanClaim` for the
            // hub badge, so HubView no longer needs its own daily-login probe.
            appState.maybeEnqueueDailyLogin()

            cache.gameConfig = GameConfig(config: response.config)
            Item.fallbackUpgradeStatBonusPerLevel = response.config.upgradeStatBonusPerLevel
            cache.cacheFeatureFlags(response.featureFlags.compactMapValues(\.boolValue))
            cache.cacheHubLayout(mapLayout(response.hubLayout))
            cache.cacheDungeonMapLayout(mapLayout(response.dungeonMapLayout))

            // Calculate server time delta for client-side stamina calculation
            if let serverDate = Self.parseServerDate(response.serverTime) {
                cache.serverTimeDelta = Date().timeIntervalSince(serverDate)
            }

            cache.isInitLoaded = true

            // Load skins catalog (fire-and-forget, non-blocking)
            if cache.skins.isEmpty {
                await loadSkins()
            }
        } catch {
            #if DEBUG
            print("[GameInitService] game/init failed: \(error). Falling back to individual loads.")
            #endif
            // Fallback — load character individually
            let charService = CharacterService(appState: appState)
            await charService.loadCharacter()
        }
    }

    // MARK: - Skins Loader

    private func loadSkins() async {
        do {
            let response: AppearancesResponse = try await APIClient.shared.get(APIEndpoints.appearances)
            cache.cacheSkins(response.skins)
        } catch {
            // Non-critical — avatar images will show placeholder
        }
    }

    // MARK: - Helpers

    private func mapLayout(
        _ layout: [String: LayoutOverridePayload]
    ) -> [String: GameDataCache.BuildingOverride] {
        layout.mapValues {
            GameDataCache.BuildingOverride(
                x: CGFloat($0.x),
                y: CGFloat($0.y),
                size: $0.size.map { CGFloat($0) }
            )
        }
    }

    private static func parseServerDate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) {
            return date
        }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }
}

private struct GameInitResponse: Decodable {
    let user: CurrentUserSnapshot?
    let character: Character
    let equipment: [GameInitEquipmentInventoryEntry]
    let consumables: [GameInitConsumableInventoryEntry]
    let quests: [Quest]
    let dailyLogin: DailyLoginData
    let config: GameInitConfigPayload
    let featureFlags: [String: JSONValue]
    let hubLayout: [String: LayoutOverridePayload]
    let dungeonMapLayout: [String: LayoutOverridePayload]
    let serverTime: String

    var inventoryItems: [Item] {
        equipment.map(\.toItem) + consumables.compactMap(\.toItem)
    }
}

private struct GameInitEquipmentInventoryEntry: Decodable {
    let id: String
    let upgradeLevel: Int
    let durability: Int
    let maxDurability: Int
    let isEquipped: Bool
    let equippedSlot: String?
    let rolledStats: [String: Int]?
    let effectiveStats: [String: Int]?
    let item: GameInitItemRecord

    var toItem: Item {
        Item(
            id: id,
            itemName: item.itemName,
            itemType: item.itemType,
            rarity: item.rarity,
            itemLevel: item.itemLevel,
            upgradeLevel: upgradeLevel,
            isEquipped: isEquipped,
            equippedSlot: equippedSlot,
            baseStats: item.baseStats,
            rolledStats: rolledStats,
            buyPrice: item.buyPrice,
            sellPrice: item.sellPrice,
            setName: item.setName,
            specialEffect: item.specialEffect,
            uniquePassive: item.uniquePassive,
            durability: durability,
            maxDurability: maxDurability,
            description: item.description,
            catalogId: item.catalogId,
            classRestriction: item.classRestriction,
            imageUrl: item.imageUrl,
            imageKey: item.imageKey,
            quantity: nil,
            consumableType: nil,
            authoritativeEffectiveStats: effectiveStats
        )
    }
}

private struct GameInitItemRecord: Decodable {
    let catalogId: String?
    let itemName: String
    let itemType: ItemType
    let rarity: ItemRarity
    let itemLevel: Int
    let baseStats: [String: Int]?
    let setName: String?
    let specialEffect: String?
    let uniquePassive: String?
    let imageUrl: String?
    let imageKey: String?
    let classRestriction: String?
    let description: String?
    let buyPrice: Int?
    let sellPrice: Int?
}

private struct GameInitConsumableInventoryEntry: Decodable {
    let id: String
    let consumableType: String
    let quantity: Int

    var toItem: Item? {
        guard quantity > 0 else { return nil }

        let canonicalID = ConsumableCatalog.canonicalID(
            consumableType: consumableType,
            catalogId: consumableType,
            imageKey: nil
        )
        let displayName = canonicalID.map(ConsumableCatalog.displayName(for:))
            ?? ConsumableCatalog.displayName(forKnownOrRaw: consumableType)
        let imageKey = ConsumableCatalog.resolvedImageKey(
            consumableType: consumableType,
            catalogId: consumableType,
            imageKey: nil
        )
        let rarity = canonicalID.flatMap(ConsumableCatalog.rarity(for:)) ?? .common

        return Item(
            id: id,
            itemName: displayName,
            itemType: .consumable,
            rarity: rarity,
            itemLevel: 1,
            upgradeLevel: nil,
            isEquipped: false,
            equippedSlot: nil,
            baseStats: nil,
            rolledStats: nil,
            buyPrice: nil,
            sellPrice: nil,
            setName: nil,
            specialEffect: nil,
            uniquePassive: nil,
            durability: nil,
            maxDurability: nil,
            description: nil,
            catalogId: consumableType,
            classRestriction: nil,
            imageUrl: nil,
            imageKey: imageKey,
            quantity: quantity,
            consumableType: consumableType
        )
    }
}

private struct LayoutOverridePayload: Decodable {
    let x: Double
    let y: Double
    let size: Double?
}

private struct GameInitConfigPayload: Decodable {
    let staminaMax: Int
    let staminaRegenMinutes: Int
    let pvpStaminaCost: Int
    let freePvpPerDay: Int
    let upgradeChances: [Int]
    let upgradeStatBonusPerLevel: Int
    let maxLevel: Int
    let statPointsPerLevel: Int
    let pvpWinGold: Int
    let pvpLossGold: Int
    let pvpWinXp: Int
    let pvpLossXp: Int
    let critMultiplier: Double
    let maxCritChance: Int
    let maxDodgeChance: Int
    let dailyLoginRewards: [DailyLoginRewardDef]
    let gemCosts: GameInitGemCosts
    let interactiveCombatEnabled: Bool
}

private struct GameInitGemCosts: Decodable {
    let goldMineSlotCost: Int
    let goldMineBoost: Int
    let staminaRefill: Int
    let extraPvpCombat: Int
}

private extension GameConfig {
    init(config: GameInitConfigPayload) {
        staminaMax = config.staminaMax
        staminaRegenMinutes = config.staminaRegenMinutes
        pvpStaminaCost = config.pvpStaminaCost
        freePvpPerDay = config.freePvpPerDay
        upgradeChances = config.upgradeChances
        upgradeStatBonusPerLevel = config.upgradeStatBonusPerLevel
        maxLevel = config.maxLevel
        statPointsPerLevel = config.statPointsPerLevel
        pvpWinGold = config.pvpWinGold
        pvpLossGold = config.pvpLossGold
        pvpWinXp = config.pvpWinXp
        pvpLossXp = config.pvpLossXp
        critMultiplier = config.critMultiplier
        maxCritChance = config.maxCritChance
        maxDodgeChance = config.maxDodgeChance
        dailyLoginRewards = config.dailyLoginRewards
        goldMineSlotCostGems = config.gemCosts.goldMineSlotCost
        goldMineBoostGems = config.gemCosts.goldMineBoost
        staminaRefillGems = config.gemCosts.staminaRefill
        extraPvpCombatGems = config.gemCosts.extraPvpCombat
        interactiveCombatEnabled = config.interactiveCombatEnabled
    }
}

private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value in game/init payload"
            )
        }
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let value):
            return value
        case .null:
            return nil
        default:
            return nil
        }
    }
}
