import Foundation

// MARK: - Dungeon Rush v2 "The Descent" — wire models
//
// Mirror of `backend/src/lib/game/descent/view.ts` (DescentView) and the three
// `/api/dungeon-rush/v2/*` routes. The server is authoritative for everything:
// it rolls every die, picks every room and grants every reward. The client
// sends one action at a time (with the run's `seq`) and renders the snapshot
// it gets back.
//
// Keys inside `view` are camelCase (TS objects), so with APIClient's
// `.convertFromSnakeCase` they decode as is — no CodingKeys. Enum-like fields
// stay `String` on purpose: an unknown value from a newer server must never
// break decoding; the computed helpers below map them.

// MARK: Snapshot

struct DescentSnapshot: Decodable, Equatable {
    let runId: String
    let seq: Int
    let screen: String
    let depth: Int
    let depthKey: String
    let depthName: String
    let depthBlurb: String
    let guardianName: String
    let hero: DescentHero
    let relics: [DescentRelic]
    let bag: DescentBag
    let safe: DescentBag
    let xpEarned: Int
    let stats: DescentStats
    let progress: DescentProgress
    let tale: String?
    let fork: DescentFork?
    let combat: DescentCombat?
    let spoils: DescentSpoils?
    let chest: DescentChest?
    let event: DescentEvent?
    let camp: DescentCamp?
    let merchant: DescentMerchant?
    let relicChoice: DescentRelicChoice?
    let depthClear: DescentDepthClear?
    let result: DescentResult?
    let map: DescentMap
    let fx: [DescentFx]

    var screenKind: DescentScreenKind { DescentScreenKind(rawValue: screen) ?? .unknown }
    var depthRoman: String { DescentText.roman(depth + 1) }
    var isOver: Bool { screenKind == .result }
}

enum DescentScreenKind: String {
    case depthCard, fork, combat, spoils, chest, event, camp, merchant, relic, depthClear, result
    case unknown
}

/// Node / room types (`NodeType` on the server).
enum DescentRoomType: String {
    case combat, elite, treasure, event, camp, merchant, boss

    var displayName: String {
        switch self {
        case .combat: "Monster"
        case .elite: "Elite"
        case .treasure: "Treasure"
        case .event: "Mystery"
        case .camp: "Campfire"
        case .merchant: "Merchant"
        case .boss: "Guardian"
        }
    }

    /// Medallion used on the map and in the passage list.
    var iconAsset: String {
        switch self {
        case .combat: "rush2-node-combat"
        case .elite: "rush2-node-elite"
        case .treasure: "rush2-chest-wood-closed"
        case .event: "rush2-node-mystery"
        case .camp: "rush2-node-camp"
        case .merchant: "rush2-node-merchant"
        case .boss: "rush2-node-guardian"
        }
    }
}

struct DescentHero: Decodable, Equatable {
    let hp: Int
    let maxHp: Int
    let potions: Int
    let maxPotions: Int
    let torches: Int
    let maxTorches: Int
    let potionHeal: Int
    let dmgBonusPct: Int
    let cursedFights: Int

    var hpFraction: Double { maxHp > 0 ? Double(hp) / Double(maxHp) : 0 }
    var isLow: Bool { hpFraction < 0.35 }
}

struct DescentRelic: Decodable, Equatable, Identifiable {
    let key: String
    let name: String
    let desc: String
    let icon: String
    var id: String { key }
}

struct DescentBagItem: Decodable, Equatable {
    let kind: String
    let name: String
    let rarity: String
    let itemType: String?
    let itemLevel: Int?
    let imageKey: String?
    let imageUrl: String?
    let shardTier: String?
    let amount: Int

    var isShard: Bool { kind == "shard" }
    var itemRarity: ItemRarity { ItemRarity(rawValue: rarity) ?? .common }
}

struct DescentBag: Decodable, Equatable {
    let gold: Int
    let items: [DescentBagItem]
    var isEmpty: Bool { gold == 0 && items.isEmpty }
}

struct DescentStats: Decodable, Equatable {
    let kills: Int
    let rooms: Int
    let chests: Int
}

struct DescentProgress: Decodable, Equatable {
    let total: Int
    let current: Int
    let currentCleared: Bool
}

struct DescentLoot: Decodable, Equatable {
    /// gold | xp | potion | torch | relic | item
    let kind: String
    let amount: Int
    let relic: DescentRelic?
    let item: DescentBagItem?
}

// MARK: Fork & map

struct DescentFork: Decodable, Equatable {
    let lead: String
    let isBossGate: Bool
    let options: [DescentForkOption]
}

struct DescentForkOption: Decodable, Equatable, Identifiable {
    let id: String
    let lane: Int
    /// Ahead | Left | Middle | Right
    let side: String
    let known: Bool
    let type: String?
    let typeName: String?
    let cue: String
    let fled: Bool
    let revealed: Bool

    var roomType: DescentRoomType? { type.flatMap(DescentRoomType.init(rawValue:)) }
}

struct DescentMap: Decodable, Equatable {
    let rows: [[DescentMapNode]]
    let startNext: [String]
}

struct DescentMapNode: Decodable, Equatable, Identifiable {
    let id: String
    let r: Int
    let lane: Int
    let next: [String]
    /// Nil while the room is unknown (dark, or more than one row ahead).
    let type: String?
    let visited: Bool
    let cleared: Bool
    let reachable: Bool
    let current: Bool

    var roomType: DescentRoomType? { type.flatMap(DescentRoomType.init(rawValue:)) }
}

// MARK: Combat

struct DescentCombat: Decodable, Equatable {
    let key: String
    let name: String
    let art: String
    /// small | big | nil
    let size: String?
    /// combat | elite | boss
    let kind: String
    let level: Int
    let hp: Int
    let maxHp: Int
    let traits: [DescentTrait]
    let windup: Bool
    let enraged: Bool
    let bg: String
    let verdict: [DescentLine]
    let lastRound: DescentRound?
    let canFlee: Bool

    var isBoss: Bool { kind == "boss" }
    var isElite: Bool { kind == "elite" }
    var hpFraction: Double { maxHp > 0 ? Double(hp) / Double(maxHp) : 0 }
}

struct DescentTrait: Decodable, Equatable, Identifiable {
    let key: String
    let label: String
    var id: String { key }
}

struct DescentLine: Decodable, Equatable {
    let text: String
    /// good | bad | info | plain
    let tone: String
}

struct DescentRound: Decodable, Equatable {
    let action: String
    let pa: String
    let pg: String
    let ea: String
    let eg: String
    let pHit: Bool
    let eBlock: Bool
    let dodged: Bool
    let crit: Bool
    let dealt: Int
    let healed: Int
    let eHit: Bool
    let pBlock: Bool
    let taken: Int
    let crushing: Bool
    let mended: Int
}

// MARK: Rooms

struct DescentSpoils: Decodable, Equatable {
    let bg: String
    let loot: [DescentLoot]
}

struct DescentChest: Decodable, Equatable {
    /// wood | iron | gold
    let tier: String
    let name: String
    let inspected: Bool
    let opened: Bool
    let loot: [DescentLoot]
}

struct DescentEvent: Decodable, Equatable {
    let id: String
    let scene: String
    let text: String
    let done: Bool
    let resultText: String?
    let loot: [DescentLoot]
    /// take_loot | fight_now | continue | nil
    let then: String?
    let choices: [DescentEventChoice]
    let runes: [DescentRune]?
}

struct DescentEventChoice: Decodable, Equatable, Identifiable {
    let i: Int
    let label: String
    let hint: String
    let icon: String?
    let disabledReason: String?
    var id: Int { i }
}

struct DescentRune: Decodable, Equatable, Identifiable {
    let i: Int
    /// unknown | safe | trap
    let state: String
    var id: Int { i }
}

struct DescentCamp: Decodable, Equatable {
    let done: Bool
    let choice: String?
    let canStash: Bool
    let stashGold: Int
    let stashItems: Int
}

struct DescentMerchant: Decodable, Equatable {
    let wares: [DescentWare]
}

struct DescentWare: Decodable, Equatable, Identifiable {
    let i: Int
    /// potion | torch | relic
    let kind: String
    let name: String
    let desc: String
    let icon: String
    let price: Int
    let sold: Bool
    let available: Bool
    var id: Int { i }
}

struct DescentRelicChoice: Decodable, Equatable {
    let loot: [DescentLoot]
    let choices: [DescentRelic]
}

struct DescentDepthClear: Decodable, Equatable {
    let nextDepthName: String
    let bonusText: String
}

struct DescentResult: Decodable, Equatable {
    /// victory | escaped | dead | abandoned
    let outcome: String
    let keptGold: Int
    let keptItems: [DescentBagItem]
    let lostGold: Int
    let lostItems: [DescentBagItem]
    let xp: Int
    let depthReached: Int
    let rooms: Int
    let kills: Int
}

/// One visual beat the client plays after an action (numbers, reveals, coin rain).
struct DescentFx: Decodable, Equatable {
    /// hero | enemy | scene
    let target: String
    /// dmg | crit | hurt | heal | info | reveal | chest_open | mimic | slain | coins
    let kind: String
    let value: Int?
    let text: String?
}

// MARK: - Route responses

/// POST /api/dungeon-rush/v2/start — `{ resumed, stamina_cost, current_stamina, view }`
struct DescentStartResponse: Decodable {
    let resumed: Bool
    let staminaCost: Int
    let currentStamina: Int?
    let view: DescentSnapshot
}

/// GET /api/dungeon-rush/v2/state — `{ active, stamina_cost, view | null }`
struct DescentStateResponse: Decodable {
    let active: Bool
    let staminaCost: Int
    let view: DescentSnapshot?
}

/// POST /api/dungeon-rush/v2/act
struct DescentActResponse: Decodable {
    let view: DescentSnapshot
    let ended: Bool
    let granted: DescentGranted
    let character: DescentCharacterSync?
}

struct DescentGranted: Decodable {
    let gold: Int
    let xp: Int
    let items: [DescentGrantedItem]
}

/// `LootResponseItem` (snake_case on the wire).
struct DescentGrantedItem: Decodable {
    let id: String
    let name: String
    let rarity: String
    let imageKey: String?
    let imageUrl: String?
    let shard: DescentGrantedShard?
}

struct DescentGrantedShard: Decodable {
    let tier: String
    let amount: Int
}

/// Character values after the effects of this action were applied.
struct DescentCharacterSync: Decodable {
    let gold: Int
    let xp: Int
    let level: Int
    let leveledUp: Bool
    let newLevel: Int?
    let statPointsAwarded: Int
    let passivePointsAwarded: Int
}

// MARK: - Requests

struct DescentStartRequest: Encodable {
    let characterId: String
}

/// `{ character_id, run_id, seq, action, node_id?, i?, k? }` — nil fields are omitted.
struct DescentActRequest: Encodable {
    let characterId: String
    let runId: String
    let seq: Int
    let action: String
    let nodeId: String?
    let i: Int?
    let k: String?
}

/// Everything the player can do. Wire names match `ACTION_TYPES` on the server.
enum DescentAction: Equatable {
    case beginDepth
    case torch(nodeId: String)
    case move(nodeId: String)
    case strike
    case brace
    case potion
    case flee
    case drink
    case takeLoot
    case inspect
    case openChest
    case leave
    case choose(Int)
    case proceed
    case fightNow
    case camp(String)
    case buy(Int)
    case takeRelic(String?)
    case descend
    case escape
    case abandon

    var wireName: String {
        switch self {
        case .beginDepth: "begin_depth"
        case .torch: "torch"
        case .move: "move"
        case .strike: "strike"
        case .brace: "brace"
        case .potion: "potion"
        case .flee: "flee"
        case .drink: "drink"
        case .takeLoot: "take_loot"
        case .inspect: "inspect"
        case .openChest: "open_chest"
        case .leave: "leave"
        case .choose: "choose"
        case .proceed: "continue"
        case .fightNow: "fight_now"
        case .camp: "camp"
        case .buy: "buy"
        case .takeRelic: "take_relic"
        case .descend: "descend"
        case .escape: "escape"
        case .abandon: "abandon"
        }
    }

    func request(characterId: String, runId: String, seq: Int) -> DescentActRequest {
        var nodeId: String?
        var index: Int?
        var key: String?
        switch self {
        case .torch(let id), .move(let id): nodeId = id
        case .choose(let n), .buy(let n): index = n
        case .camp(let k): key = k
        case .takeRelic(let k): key = k
        default: break
        }
        return DescentActRequest(
            characterId: characterId, runId: runId, seq: seq,
            action: wireName, nodeId: nodeId, i: index, k: key
        )
    }
}
