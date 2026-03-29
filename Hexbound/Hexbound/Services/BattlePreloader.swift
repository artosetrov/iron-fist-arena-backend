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

    struct StaminaInfo {
        let current: Int
        let cost: Int
        let hasFreePvp: Bool
        let freePvpRemaining: Int
    }
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
    private let cacheStore = PrepareCacheStore()

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
                var body: [String: Any] = ["character_id": charId]
                if let revengeId { body["revenge_id"] = revengeId }
                if let opponentId { body["opponent_id"] = opponentId }

                let response = try await APIClient.shared.postRaw(
                    APIEndpoints.pvpPrepare,
                    body: body
                )

                guard let ticketId = response["battle_ticket_id"] as? String,
                      let seed = response["battle_seed"] as? Int,
                      let playerDict = response["player_stats"] as? [String: Any],
                      let enemyDict = response["enemy_stats"] as? [String: Any] else {
                    await cacheStore.removeInFlight(cacheKey)
                    return nil
                }

                let configDict = response["combat_config"] as? [String: Any] ?? [:]
                let staminaDict = response["stamina"] as? [String: Any] ?? [:]

                let data = BattlePrepareData(
                    battleTicketId: ticketId,
                    battleSeed: seed,
                    playerStats: FighterStats(from: playerDict),
                    enemyStats: FighterStats(from: enemyDict),
                    combatConfig: CombatConfig(from: configDict),
                    staminaInfo: BattlePrepareData.StaminaInfo(
                        current: staminaDict["current"] as? Int ?? 0,
                        cost: staminaDict["cost"] as? Int ?? 0,
                        hasFreePvp: staminaDict["has_free_pvp"] as? Bool ?? false,
                        freePvpRemaining: staminaDict["free_pvp_remaining"] as? Int ?? 0
                    )
                )

                await cacheStore.set(cacheKey, data)
                await cacheStore.removeInFlight(cacheKey)
                return data

            } catch let error as APIError {
                await cacheStore.removeInFlight(cacheKey)
                if showErrors {
                    await MainActor.run { [weak self] in
                        switch error {
                        case .clientError(_, let message):
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
            var body: [String: Any] = [
                "character_id": charId,
                "opponent_id": opponentId,
                "battle_ticket_id": battleTicketId,
                "battle_seed": battleSeed,
                "client_winner_id": clientWinnerId
            ]
            if let revengeId { body["revenge_id"] = revengeId }
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.pvpResolve,
                body: body
            )

            let resultDict = response["result"] as? [String: Any] ?? [:]
            let lootArray = response["loot"] as? [[String: Any]] ?? []
            let staminaDict = response["stamina"] as? [String: Any] ?? [:]
            let hpDict = response["post_combat_hp"] as? [String: Any] ?? [:]

            let durabilityArray = response["durability_changes"] as? [[String: Any]] ?? []

            return ResolveResult(
                verified: response["verified"] as? Bool ?? false,
                clientMatches: response["client_matches"] as? Bool ?? true,
                serverWinnerId: response["server_winner_id"] as? String ?? clientWinnerId,
                goldReward: resultDict["gold_reward"] as? Int ?? 0,
                xpReward: resultDict["xp_reward"] as? Int ?? 0,
                ratingChange: resultDict["rating_change"] as? Int ?? 0,
                firstWinBonus: resultDict["first_win_bonus"] as? Bool ?? false,
                leveledUp: resultDict["leveled_up"] as? Bool ?? false,
                newLevel: resultDict["new_level"] as? Int,
                statPointsAwarded: resultDict["stat_points_awarded"] as? Int,
                loot: lootArray,
                staminaCurrent: staminaDict["current"] as? Int ?? 0,
                staminaMax: staminaDict["max"] as? Int ?? 120,
                matchId: response["matchId"] as? String,
                durabilityDegraded: durabilityArray,
                hpCurrent: hpDict["player"] as? Int ?? 0,
                hpMax: 0
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
    let loot: [[String: Any]]
    let staminaCurrent: Int
    let staminaMax: Int
    let matchId: String?
    let durabilityDegraded: [[String: Any]]
    let hpCurrent: Int
    let hpMax: Int
}
