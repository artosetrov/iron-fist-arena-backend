import Foundation
import SwiftUI

struct DungeonActiveRunSnapshot: Decodable {
    let id: String
    let dungeonId: String
    let difficulty: String
    let currentFloor: Int
}

struct DungeonProgressSnapshot: Decodable {
    let progress: [String: Int]
    let activeRun: DungeonActiveRunSnapshot?
}

struct DungeonStartEnemySnapshot: Decodable {
    let id: String?
    let name: String?
    let level: Int?
    let maxHp: Int?
}

struct DungeonStartFloorSnapshot: Decodable {
    let number: Int
    let enemies: [DungeonStartEnemySnapshot]?
    let isBoss: Bool
}

struct DungeonStartResponse: Decodable {
    let runId: String
    let dungeonId: String?
    let currentFloor: Int
    let floor: DungeonStartFloorSnapshot?
}

struct DungeonFightRewardsSnapshot: Decodable {
    let gold: Int?
    let xp: Int?
    let totalGold: Int?
    let totalXp: Int?
    let floorsCleared: Int?
    let hpPercent: Double?
}

struct DungeonCombatResultEntry: Decodable {
    let enemyName: String
    let won: Bool
    let turns: Int
}

struct DungeonFightResponse: Decodable {
    let player: CombatFighter
    let enemy: CombatFighter
    let combatLog: [CombatLog]
    let result: CombatResultInfo
    let rewards: DungeonFightRewardsSnapshot?
    let loot: [CombatLootItem]?
    let source: String?
    let victory: Bool
    let message: String?
    let combatResults: [DungeonCombatResultEntry]?
    let floorCleared: Int?
    let dungeonComplete: Bool?
    let playerHpPercent: Double?
    let nextFloor: DungeonStartFloorSnapshot?

    var combatData: CombatData {
        CombatData(
            player: player,
            enemy: enemy,
            combatLog: combatLog,
            result: result,
            rewards: CombatRewards(gold: rewards?.gold, xp: rewards?.xp),
            loot: loot,
            source: source
        )
    }
}

struct RushEnemySnapshot: Decodable {
    let name: String
    let level: Int
}

struct RushRoomSnapshot: Decodable {
    let index: Int
    let type: String
    let resolved: Bool
    let seed: Int
}

struct RushBuffSnapshot: Decodable {
    let id: String
    let name: String
    let stat: String
    let value: Int
    let icon: String
}

struct RushArtifactSnapshot: Decodable {
    let id: String
    let name: String
    let description: String
    let icon: String
}

struct DungeonRushRewardsSnapshot: Decodable {
    let gold: Int?
    let xp: Int?
    let totalGold: Int?
    let totalXp: Int?
    let floorsCleared: Int?
}

struct DungeonRushStateResponse: Decodable {
    let active: Bool?
    let runId: String?
    let currentFloor: Int?
    let currentEnemy: RushEnemySnapshot?
    let message: String?
    let resumed: Bool?
    let rooms: [RushRoomSnapshot]?
    let currentRoomIndex: Int?
    let buffs: [RushBuffSnapshot]?
    let artifacts: [RushArtifactSnapshot]?
    let pendingArtifactChoices: [RushArtifactSnapshot]?
    let currentHpPercent: Int?
    let totalRooms: Int?
    let rewards: DungeonRushRewardsSnapshot?
}

struct DungeonRushNextRoomSnapshot: Decodable {
    let index: Int
    let type: String
    let seed: Int
}

struct DungeonRushFightResponse: Decodable {
    let player: CombatFighter
    let enemy: CombatFighter
    let combatLog: [CombatLog]
    let result: CombatResultInfo
    let rewards: DungeonRushRewardsSnapshot?
    let loot: [CombatLootItem]?
    let source: String?
    let victory: Bool
    let message: String?
    let roomIndex: Int?
    let roomType: String?
    let currentHpPercent: Int?
    let rushComplete: Bool?
    let currentXp: Int?
    let leveledUp: Bool?
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
    let nextRoom: DungeonRushNextRoomSnapshot?
    let nextEnemy: RushEnemySnapshot?
    let buffs: [RushBuffSnapshot]?
    let artifacts: [RushArtifactSnapshot]?
    let artifactChoices: [RushArtifactSnapshot]?

    var combatData: CombatData {
        CombatData(
            player: player,
            enemy: enemy,
            combatLog: combatLog,
            result: result,
            rewards: CombatRewards(gold: rewards?.gold, xp: rewards?.xp),
            loot: loot,
            source: source
        )
    }
}

struct RushShopItemSnapshot: Decodable {
    let slot: Int
    let type: String
    let name: String
    let icon: String
    let description: String
    let price: Int
    let purchased: Bool
}

struct RushShopPurchaseItemSnapshot: Decodable {
    let name: String
    let type: String
    let icon: String
}

struct DungeonRushResolveResponse: Decodable {
    let type: String?
    let action: String?
    let artifact: RushArtifactSnapshot?
    let artifacts: [RushArtifactSnapshot]?
    let currentRoomIndex: Int?
    let items: [RushShopItemSnapshot]?
    let playerGold: Int?
    let currentHpPercent: Int?
    let buffs: [RushBuffSnapshot]?
    let rewards: DungeonRushRewardsSnapshot?
    let currentXp: Int?
    let leveledUp: Bool?
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
    let rushComplete: Bool?
    let nextRoom: DungeonRushNextRoomSnapshot?
    let nextEnemy: RushEnemySnapshot?
    let gold: Int?
    let xp: Int?
    let hpChange: Int?
    let buffGranted: RushBuffSnapshot?
    let eventId: String?
    let eventName: String?
    let eventIcon: String?
    let description: String?
}

struct DungeonRushShopBuyResponse: Decodable {
    let purchased: Bool
    let slot: Int
    let item: RushShopPurchaseItemSnapshot?
    let currentHpPercent: Int
    let buffs: [RushBuffSnapshot]?
    let playerGold: Int?
    let shopPurchased: [Int]?
}

private struct DungeonStartRequest: Encodable {
    let characterId: String
    let dungeonId: String
    let difficulty: String
}

private struct DungeonFightRequest: Encodable {
    let characterId: String
    let runId: String
}

private struct DungeonRushStartRequest: Encodable {
    let characterId: String
}

private struct DungeonRushFightRequest: Encodable {
    let characterId: String
    let runId: String
}

private struct DungeonRushResolveRequest: Encodable {
    let characterId: String
    let runId: String
    let action: String?
    let artifactId: String?
}

private struct DungeonRushShopBuyRequest: Encodable {
    let characterId: String
    let runId: String
    let slot: Int
}

private struct DungeonRushAbandonRequest: Encodable {
    let characterId: String
}

private struct DungeonRushAbandonResponse: Decodable {
    let abandoned: Bool
    let finalFloor: Int?
    let message: String?
}

private struct DungeonListResponse: Decodable {
    let dungeons: [DungeonCatalogEntry]
}

private struct DungeonCatalogEntry: Decodable {
    let slug: String
    let name: String
    let description: String
    let levelReq: Int
    let energyCost: Int
    let sortOrder: Int
    let bosses: [DungeonCatalogBoss]
    let drops: [DungeonCatalogDrop]
}

private struct DungeonCatalogBoss: Decodable {
    let name: String
    let level: Int
    let hp: Int
    let tagline: String?
    let description: String
    let imageUrl: String?
}

private struct DungeonCatalogDrop: Decodable {
    let dropChance: Double
    let item: DungeonCatalogDropItem
}

private struct DungeonCatalogDropItem: Decodable {
    let name: String
    let type: String
    let rarity: String
    let imageUrl: String?
    let imageKey: String?
}

private extension DungeonCatalogEntry {
    func toDungeonInfo() -> DungeonInfo {
        let dungeonLoot: [LootPreview] = drops.map { drop in
            let rarity = ItemRarity(rawValue: drop.item.rarity) ?? .common
            return LootPreview(
                icon: iconForItemType(drop.item.type),
                name: drop.item.name,
                detail: "\(rarity.displayName) (\(Int(drop.dropChance))%)",
                imageUrl: drop.item.imageUrl,
                imageKey: drop.item.imageKey,
                rarity: rarity,
                itemTypeRaw: drop.item.type
            )
        }

        let baseLoot: [LootPreview] = [
            LootPreview(icon: "coloncurrencysign.circle.fill", name: "Gold", detail: "Varies", imageKey: "loot-gold"),
            LootPreview(icon: "star.fill", name: "XP", detail: "Varies", imageKey: "loot-xp"),
        ]
        let combinedLoot = baseLoot + dungeonLoot

        let parsedBosses: [BossInfo] = bosses.enumerated().map { idx, boss in
            let portrait = {
                guard let imageUrl = boss.imageUrl, !imageUrl.isEmpty else {
                    return "boss-generic-portrait"
                }
                return imageUrl
            }()

            return BossInfo(
                id: idx + 1,
                name: boss.name,
                level: boss.level,
                hp: boss.hp,
                description: boss.description,
                portraitImage: portrait,
                fullImage: portrait,
                loot: combinedLoot,
                tagline: boss.tagline
            )
        }

        let rewardIcons: [String] = {
            var icons = ["coloncurrencysign.circle.fill"]
            let uniqueIcons = Array(Set(dungeonLoot.map(\.icon))).prefix(3)
            icons.append(contentsOf: uniqueIcons)
            if icons.count < 4 { icons.append("scroll.fill") }
            return Array(icons.prefix(4))
        }()

        let icon: String = {
            if slug.contains("training") { return "swords" }
            if slug.contains("catacomb") { return "skull.fill" }
            if slug.contains("volcanic") || slug.contains("forge") { return "flame.fill" }
            if slug.contains("fungal") || slug.contains("grotto") { return "leaf.fill" }
            if slug.contains("scorched") || slug.contains("mine") { return "hammer.fill" }
            if slug.contains("frozen") || slug.contains("abyss") { return "snowflake" }
            if slug.contains("light") || slug.contains("realm") { return "sparkles" }
            if slug.contains("shadow") { return "moon.fill" }
            if slug.contains("clockwork") || slug.contains("citadel") { return "gearshape.fill" }
            if slug.contains("abyssal") || slug.contains("depth") { return "drop.fill" }
            if slug.contains("infernal") || slug.contains("throne") { return "crown.fill" }
            return "building.2.fill"
        }()

        let themeColor: Color = {
            switch sortOrder {
            case 0: return DarkFantasyTheme.glowArena
            case 1: return DarkFantasyTheme.glowMystic
            case 2: return DarkFantasyTheme.glowForge
            case 3: return DarkFantasyTheme.glowNature
            case 4: return DarkFantasyTheme.glowVolcanic
            case 5: return DarkFantasyTheme.glowIce
            case 6: return DarkFantasyTheme.glowTreasure
            case 7: return DarkFantasyTheme.glowShadow
            case 8: return DarkFantasyTheme.glowStone
            case 9: return DarkFantasyTheme.bgDungeonDeep
            default: return DarkFantasyTheme.glowBlood
            }
        }()

        return DungeonInfo(
            id: slug,
            name: name,
            icon: icon,
            description: description,
            minLevel: levelReq,
            maxLevel: parsedBosses.last?.level ?? (levelReq + 10),
            energyCost: energyCost,
            bosses: parsedBosses,
            themeColor: themeColor,
            rewardIcons: rewardIcons
        )
    }

    private func iconForItemType(_ type: String) -> String {
        switch type {
        case "weapon": return "sword"
        case "helmet": return "shield.checkered"
        case "chest": return "shield.fill"
        case "gloves": return "hand.raised.fill"
        case "legs": return "figure.walk"
        case "boots": return "shoe.fill"
        case "accessory": return "ring.circle.fill"
        case "amulet": return "seal.fill"
        case "belt": return "circle.grid.cross.fill"
        case "relic": return "sparkles"
        case "necklace": return "seal.fill"
        case "ring": return "diamond.fill"
        case "consumable": return "flask.fill"
        default: return "shippingbox.fill"
        }
    }
}

@MainActor
final class DungeonService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - List Dungeons (Dynamic)

    /// Fetches all active dungeons from the server as typed models.
    func listDungeons() async -> [DungeonInfo]? {
        guard let result: DungeonListResponse = try? await APIClient.shared.get(
            APIEndpoints.dungeonsList
        ) else { return nil }
        return result.dungeons.map { $0.toDungeonInfo() }
    }

    // MARK: - Dungeon Progress

    func getProgress() async -> DungeonProgressSnapshot? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        return try? await APIClient.shared.get(
            APIEndpoints.dungeons,
            params: ["character_id": charId]
        )
    }

    // MARK: - Start Dungeon

    func start(dungeonId: String, difficulty: String) async -> DungeonStartResponse? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.post(
                APIEndpoints.dungeonsStart,
                body: DungeonStartRequest(
                    characterId: charId,
                    dungeonId: dungeonId,
                    difficulty: difficulty
                )
            )
        } catch let error as APIError {
            switch error {
            case .clientError(409, _, _):
                appState.showToast("Active run exists — continue or abandon first", type: .error)
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to enter dungeon", subtitle: "Check connection and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Failed to enter dungeon", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    // MARK: - Fight Room

    func fight(runId: String) async -> DungeonFightResponse? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.post(
                APIEndpoints.dungeonsFight,
                body: DungeonFightRequest(characterId: charId, runId: runId)
            )
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Fight failed", subtitle: "Check connection and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Fight failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    // MARK: - Dungeon Rush

    func rushStatus() async -> DungeonRushStateResponse? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        return try? await APIClient.shared.get(
            APIEndpoints.dungeonRushStatus,
            params: ["character_id": charId]
        )
    }

    func rushStart() async -> DungeonRushStateResponse? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.post(
                APIEndpoints.dungeonRushStart,
                body: DungeonRushStartRequest(characterId: charId)
            )
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to start rush", subtitle: "Check connection and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Failed to start rush", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    func rushFight(runId: String) async -> DungeonRushFightResponse? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.post(
                APIEndpoints.dungeonRushFight,
                body: DungeonRushFightRequest(characterId: charId, runId: runId)
            )
        } catch {
            return nil
        }
    }

    func rushAbandon() async {
        guard let charId = appState.currentCharacter?.id else { return }
        let _: DungeonRushAbandonResponse? = try? await APIClient.shared.post(
            APIEndpoints.dungeonRushAbandon,
            body: DungeonRushAbandonRequest(characterId: charId)
        )
    }

    func rushResolve(runId: String, action: String? = nil, artifactId: String? = nil) async -> DungeonRushResolveResponse? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.post(
                APIEndpoints.dungeonRushResolve,
                body: DungeonRushResolveRequest(
                    characterId: charId,
                    runId: runId,
                    action: action,
                    artifactId: artifactId
                )
            )
        } catch {
            return nil
        }
    }

    func rushShopBuy(runId: String, slot: Int) async -> DungeonRushShopBuyResponse? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.post(
                APIEndpoints.dungeonRushShopBuy,
                body: DungeonRushShopBuyRequest(
                    characterId: charId,
                    runId: runId,
                    slot: slot
                )
            )
        } catch {
            return nil
        }
    }
}
