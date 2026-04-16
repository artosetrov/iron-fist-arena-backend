import Foundation

// =============================================================================
// BattlePreloader.swift — Manages instant battle flow
//
// Flow:
// 1. When arena loads, opponents are fetched (already cached)
// 2. When "Fight" is pressed:
//    a. Open battle screen INSTANTLY with opponent preview data
//    b. Call /pvp/prepare in background to get seed + full stats
//    c. Run client-side combat engine with seed
//    d. Play battle animation
//    e. Show rewards optimistically
//    f. Call /pvp/resolve async to finalize server state
// =============================================================================

/// Holds all data needed to start a battle instantly
struct BattlePrepareData {
    let battleTicketId: String
    let battleSeed: Int
    let playerStats: FighterStats
    let enemyStats: FighterStats
    let combatConfig: CombatConfig
    let staminaInfo: StaminaInfo
    /// Server-authoritative HP at prepare time — fixes stale client cache display
    let serverCurrentHp: Int?
    let serverMaxHp: Int?

    struct StaminaInfo {
        let current: Int
        let cost: Int
        let hasFreePvp: Bool
        let freePvpRemaining: Int
    }
}

private struct PvpPrepareRequest: Encodable {
    let characterId: String
    let opponentId: String?
    let revengeId: String?
}

private struct BattleCombatStancePayload: Decodable {
    let attack: String?
    let defense: String?

    func toParsedZoneStance() -> ParsedZoneStance? {
        guard let attack, let defense else {
            return nil
        }
        return ParsedZoneStance(validatedAttack: attack, defense: defense)
    }
}

private struct BattlePassiveBonusesPayload: Decodable {
    let flatDamage: Double?
    let percentDamage: Double?
    let flatCritChance: Double?
    let flatDodgeChance: Double?
    let lifesteal: Double?
    let damageReduction: Double?

    func toPassiveBonus() -> PassiveBonus {
        PassiveBonus(
            flatDamage: flatDamage ?? 0,
            percentDamage: percentDamage ?? 0,
            flatCritChance: flatCritChance ?? 0,
            flatDodgeChance: flatDodgeChance ?? 0,
            lifesteal: lifesteal ?? 0,
            damageReduction: damageReduction ?? 0
        )
    }
}

private struct BattleSkillEffectPayload: Decodable {
    let heal: Int?
}

private struct BattleEquippedSkillPayload: Decodable {
    let id: String
    let skillKey: String?
    let name: String?
    let damageBase: Int?
    let damageScaling: [String: Double]?
    let damageType: String?
    let targetType: String?
    let cooldown: Int?
    let effectJson: BattleSkillEffectPayload?
    let rank: Int?
    let rankScaling: Double?

    func toCombatSkill() -> CombatSkill {
        CombatSkill(
            id: id,
            skillKey: skillKey,
            name: name,
            damageBase: damageBase.map(Double.init),
            damageScaling: damageScaling ?? [:],
            damageType: damageType,
            targetType: targetType,
            cooldown: cooldown ?? 0,
            effect: CombatSkillEffect(heal: effectJson?.heal),
            rank: rank ?? 1,
            rankScaling: rankScaling ?? 0.1
        )
    }
}

private struct BattleFighterStatsPayload: Decodable {
    let id: String
    let name: String
    let characterClass: String
    let level: Int
    let str: Int
    let agi: Int
    let vit: Int
    let end: Int
    let int: Int
    let wis: Int
    let luk: Int
    let cha: Int
    let maxHp: Int
    let armor: Int
    let magicResist: Int
    let avatar: String?
    let combatStance: BattleCombatStancePayload?
    let equippedSkills: [BattleEquippedSkillPayload]?
    let passiveBonuses: BattlePassiveBonusesPayload?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case characterClass = "class"
        case level
        case str
        case agi
        case vit
        case end
        case int
        case wis
        case luk
        case cha
        case maxHp
        case armor
        case magicResist
        case avatar
        case combatStance
        case equippedSkills
        case passiveBonuses
    }

    func toFighterStats() -> FighterStats {
        FighterStats(
            id: id,
            name: name,
            characterClass: characterClass,
            level: level,
            str: str,
            agi: agi,
            vit: vit,
            end: end,
            int: int,
            wis: wis,
            luk: luk,
            cha: cha,
            maxHp: maxHp,
            armor: armor,
            magicResist: magicResist,
            avatar: avatar,
            combatStance: combatStance?.toParsedZoneStance(),
            equippedSkills: (equippedSkills ?? []).map { $0.toCombatSkill() },
            passiveBonuses: passiveBonuses?.toPassiveBonus() ?? PassiveBonus()
        )
    }
}

private struct BattleCombatConfigPayload: Decodable {
    let maxTurns: Int?
    let minDamage: Int?
    let critMultiplier: Double?
    let maxCritChance: Double?
    let maxDodgeChance: Double?
    let rogueDodgeBonus: Double?
    let tankDamageReduction: Double?
    let damageVariance: Double?
    let poisonArmorPenetration: Double?
    let critPerLuk: Double?
    let critPerAgi: Double?
    let dodgePerAgi: Double?
    let dodgePerLuk: Double?
    let chaMissPerPoint: Double?
    let chaMissCap: Double?
    let rogueExecuteHpThreshold: Double?
    let rogueExecuteDamageBonus: Double?

    func toCombatConfig() -> CombatConfig {
        let defaults = CombatConfig.default
        return CombatConfig(
            maxTurns: maxTurns ?? defaults.maxTurns,
            minDamage: minDamage ?? defaults.minDamage,
            critMultiplier: critMultiplier ?? defaults.critMultiplier,
            maxCritChance: maxCritChance ?? defaults.maxCritChance,
            maxDodgeChance: maxDodgeChance ?? defaults.maxDodgeChance,
            rogueDodgeBonus: rogueDodgeBonus ?? defaults.rogueDodgeBonus,
            tankDamageReduction: tankDamageReduction ?? defaults.tankDamageReduction,
            damageVariance: damageVariance ?? defaults.damageVariance,
            poisonArmorPenetration: poisonArmorPenetration ?? defaults.poisonArmorPenetration,
            critPerLuk: critPerLuk ?? defaults.critPerLuk,
            critPerAgi: critPerAgi ?? defaults.critPerAgi,
            dodgePerAgi: dodgePerAgi ?? defaults.dodgePerAgi,
            dodgePerLuk: dodgePerLuk ?? defaults.dodgePerLuk,
            chaMissPerPoint: chaMissPerPoint ?? defaults.chaMissPerPoint,
            chaMissCap: chaMissCap ?? defaults.chaMissCap,
            rogueExecuteHpThreshold: rogueExecuteHpThreshold ?? defaults.rogueExecuteHpThreshold,
            rogueExecuteDamageBonus: rogueExecuteDamageBonus ?? defaults.rogueExecuteDamageBonus
        )
    }
}

private struct BattlePrepareStaminaPayload: Decodable {
    let current: Int
    let cost: Int
    let hasFreePvp: Bool
    let freePvpRemaining: Int
}

private struct PvpPrepareResponse: Decodable {
    let battleTicketId: String
    let battleSeed: Int
    let playerStats: BattleFighterStatsPayload
    let enemyStats: BattleFighterStatsPayload
    let combatConfig: BattleCombatConfigPayload
    let stamina: BattlePrepareStaminaPayload
    let currentHp: Int?
    let maxHp: Int?

    func toPrepareData() -> BattlePrepareData {
        BattlePrepareData(
            battleTicketId: battleTicketId,
            battleSeed: battleSeed,
            playerStats: playerStats.toFighterStats(),
            enemyStats: enemyStats.toFighterStats(),
            combatConfig: combatConfig.toCombatConfig(),
            staminaInfo: BattlePrepareData.StaminaInfo(
                current: stamina.current,
                cost: stamina.cost,
                hasFreePvp: stamina.hasFreePvp,
                freePvpRemaining: stamina.freePvpRemaining
            ),
            serverCurrentHp: currentHp,
            serverMaxHp: maxHp
        )
    }
}

private struct PvpResolveRequest: Encodable {
    let characterId: String
    let opponentId: String
    let battleTicketId: String
    let battleSeed: Int
    let clientWinnerId: String
    let revengeId: String?
}

struct DurabilityChangeSnapshot: Codable {
    let id: String
    let name: String
    let durabilityBefore: Int
    let durabilityAfter: Int
}

private struct PvpResolveResultPayload: Decodable {
    let goldReward: Int
    let xpReward: Int
    let ratingChange: Int
    let firstWinBonus: Bool
    let leveledUp: Bool
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
}

private struct PvpResolveStaminaPayload: Decodable {
    let current: Int
    let max: Int
}

private struct PvpResolvePostCombatHpPayload: Decodable {
    let player: Int?
    let enemy: Int?
    let max: Int?
}

private struct PvpResolveResponse: Decodable {
    let verified: Bool
    let clientMatches: Bool?
    let serverWinnerId: String
    let result: PvpResolveResultPayload
    let loot: [PendingLootItem]?
    let stamina: PvpResolveStaminaPayload
    let durabilityChanges: [DurabilityChangeSnapshot]?
    let matchId: String?
    let postCombatHp: PvpResolvePostCombatHpPayload?
}

/// Thread-safe cache for concurrent prepare calls
private actor PrepareCacheStore {
    private var cache: [String: BattlePrepareData] = [:]
    private var inFlight: [String: Task<BattlePrepareData?, Never>] = [:]

    func get(_ key: String) -> BattlePrepareData? { cache[key] }
    func set(_ key: String, _ data: BattlePrepareData) { cache[key] = data }
    func clear() {
        cache.removeAll()
        inFlight.removeAll()
    }
    func remove(_ key: String) {
        cache.removeValue(forKey: key)
        inFlight.removeValue(forKey: key)
    }
    func getInFlight(_ key: String) -> Task<BattlePrepareData?, Never>? { inFlight[key] }
    func setInFlight(_ key: String, _ task: Task<BattlePrepareData?, Never>) { inFlight[key] = task }
    func removeInFlight(_ key: String) { inFlight.removeValue(forKey: key) }
}

@MainActor @Observable
final class BattlePreloader {
    private let appState: AppState
    // Phase 2 (2026-04-13): shared cache across all BattlePreloader instances.
    // Previously each instance had its own PrepareCacheStore, which meant a
    // Hub-time prefetch couldn't warm the Arena's (and Combat's) cache — they
    // were talking to different dictionaries. Now every instance sees the
    // same inFlight + cache tables so a `prepare()` call from any caller
    // (Hub prefetch, Arena auto-preload, Fight button, revenge) dedups and
    // reuses results.
    private let cacheStore = BattlePreloader.sharedCacheStore
    private static let sharedCacheStore = PrepareCacheStore()

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Prepare Battle (called on Fight tap)

    /// Fetches battle data from server. Returns prepare data or nil on failure.
    /// Pass revengeId for revenge fights — the server resolves the opponent from the revenge entry.
    func prepare(opponentId: String? = nil, revengeId: String? = nil, showErrors: Bool = true) async -> BattlePrepareData? {
        let cacheKey = revengeId ?? opponentId ?? ""

        // Return cached if available
        if let cached = await cacheStore.get(cacheKey) {
            return cached
        }

        // If another call is already preparing this key, await it instead of returning nil
        if let existingTask = await cacheStore.getInFlight(cacheKey) {
            return await existingTask.value
        }

        guard let charId = appState.currentCharacter?.id else { return nil }

        let task = Task<BattlePrepareData?, Never> { [weak self] in
            guard let self else { return nil }
            do {
                let response: PvpPrepareResponse = try await APIClient.shared.post(
                    APIEndpoints.pvpPrepare,
                    body: PvpPrepareRequest(
                        characterId: charId,
                        opponentId: opponentId,
                        revengeId: revengeId
                    )
                )
                let data = response.toPrepareData()

                await cacheStore.set(cacheKey, data)
                await cacheStore.removeInFlight(cacheKey)
                return data

            } catch let error as APIError {
                await cacheStore.removeInFlight(cacheKey)
                if showErrors {
                    await MainActor.run { [weak self] in
                        switch error {
                        case .clientError(_, let message, _):
                            // Server returned specific error (e.g. "Not enough stamina", "Not enough HP")
                            self?.appState.showToast(message, type: .error)
                        case .serverError(_, let message):
                            self?.appState.showToast("Server error", subtitle: message, type: .error)
                        default:
                            self?.appState.showToast("Connection error", subtitle: "Check your internet and try again", type: .error)
                        }
                    }
                }
                return nil
            } catch {
                await cacheStore.removeInFlight(cacheKey)
                if showErrors {
                    await MainActor.run { [weak self] in
                        self?.appState.showToast("Connection error", subtitle: "Check your internet and try again", type: .error)
                    }
                }
                return nil
            }
        }

        await cacheStore.setInFlight(cacheKey, task)
        return await task.value
    }

    // MARK: - Simulate Combat (client-side, instant)

    func simulateCombat(prepareData: BattlePrepareData) -> CombatData {
        let engine = CombatEngine(
            seed: prepareData.battleSeed,
            config: prepareData.combatConfig
        )
        return engine.simulate(
            player: prepareData.playerStats,
            enemy: prepareData.enemyStats
        )
    }

    // MARK: - Resolve Battle (async, after animation)

    /// Sends battle result to server for verification and reward persistence.
    /// Does NOT block the UI — called fire-and-forget after combat animation.
    func resolve(
        opponentId: String,
        battleTicketId: String,
        battleSeed: Int,
        clientWinnerId: String,
        revengeId: String? = nil
    ) async -> ResolveResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }

        do {
            let response: PvpResolveResponse = try await APIClient.shared.post(
                APIEndpoints.pvpResolve,
                body: PvpResolveRequest(
                    characterId: charId,
                    opponentId: opponentId,
                    battleTicketId: battleTicketId,
                    battleSeed: battleSeed,
                    clientWinnerId: clientWinnerId,
                    revengeId: revengeId
                )
            )

            return ResolveResult(
                verified: response.verified,
                clientMatches: response.clientMatches ?? true,
                serverWinnerId: response.serverWinnerId,
                goldReward: response.result.goldReward,
                xpReward: response.result.xpReward,
                ratingChange: response.result.ratingChange,
                firstWinBonus: response.result.firstWinBonus,
                leveledUp: response.result.leveledUp,
                newLevel: response.result.newLevel,
                statPointsAwarded: response.result.statPointsAwarded,
                passivePointsAwarded: response.result.passivePointsAwarded,
                loot: response.loot ?? [],
                staminaCurrent: response.stamina.current,
                staminaMax: response.stamina.max,
                matchId: response.matchId,
                durabilityDegraded: response.durabilityChanges ?? [],
                hpCurrent: response.postCombatHp?.player,
                hpMax: response.postCombatHp?.max
            )
        } catch {
            // Resolve failure is non-fatal — server will reconcile
            #if DEBUG
            print("PvP resolve error: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Cache Management

    func invalidateCache() async {
        await cacheStore.clear()
    }

    func invalidatePreparedBattle(opponentId: String? = nil, revengeId: String? = nil) async {
        let key = revengeId ?? opponentId ?? ""
        guard !key.isEmpty else { return }
        await cacheStore.remove(key)
    }

    func isPreparing(_ opponentId: String) async -> Bool {
        await cacheStore.getInFlight(opponentId) != nil
    }
}

// MARK: - Resolve Result

struct ResolveResult {
    let verified: Bool
    let clientMatches: Bool
    let serverWinnerId: String
    let goldReward: Int
    let xpReward: Int
    let ratingChange: Int
    let firstWinBonus: Bool
    let leveledUp: Bool
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
    let loot: [PendingLootItem]
    let staminaCurrent: Int
    let staminaMax: Int
    let matchId: String?
    let durabilityDegraded: [DurabilityChangeSnapshot]
    let hpCurrent: Int?
    let hpMax: Int?
}
