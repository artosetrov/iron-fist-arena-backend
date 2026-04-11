import Foundation

/// W2.D3 — Scripted tutorial fight service.
///
/// Wraps the two backend endpoints:
///   - POST /api/tutorial/scripted-fight/preload  → get hero + scripted opponent payload
///   - POST /api/tutorial/scripted-fight/resolve  → run fight, grant rewards, mark completed
///
/// Unlike PvP/PvE, the scripted fight is isolated:
///   - No stamina cost, no ELO, no daily quest tracking, no durability
///   - Single-shot: server gates on `tutorialCompleted` to prevent replay for rewards
///   - Deterministic: server uses a hardcoded seed to guarantee hero victory
///
/// The client's only job is to (1) show the pre-fight preview, (2) POST resolve,
/// (3) display the victory overlay with rewards.
///
/// See: docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md
@MainActor
final class TutorialService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Preload

    struct PreloadResult {
        let hero: [String: Any]
        let opponent: [String: Any]
        let forcedStance: ForcedStance
        let scripted: Bool
    }

    struct ForcedStance {
        let attack: String
        let defense: String
    }

    /// Preload the hero + scripted opponent payload.
    /// Returns nil if preload fails or tutorial was already completed.
    func preloadScriptedFight(characterId: String) async -> PreloadResult? {
        do {
            let response = try await APIClient.shared.postRaw(
                "/tutorial/scripted-fight/preload",
                body: ["character_id": characterId],
            )

            guard
                let hero = response["hero"] as? [String: Any],
                let opponent = response["opponent"] as? [String: Any],
                let stanceDict = response["forcedStance"] as? [String: Any],
                let attack = stanceDict["attack"] as? String,
                let defense = stanceDict["defense"] as? String
            else {
                #if DEBUG
                print("[TutorialService] Preload decode failure:", response)
                #endif
                return nil
            }

            return PreloadResult(
                hero: hero,
                opponent: opponent,
                forcedStance: ForcedStance(attack: attack, defense: defense),
                scripted: (response["scripted"] as? Bool) ?? true,
            )
        } catch let apiErr as APIError {
            // 409 ALREADY_COMPLETED is expected if the player somehow re-enters the flow.
            // We treat it as "skip cold-open straight to game" — caller handles nil.
            #if DEBUG
            print("[TutorialService] Preload APIError:", apiErr.errorDescription ?? "unknown")
            #endif
            return nil
        } catch {
            #if DEBUG
            print("[TutorialService] Preload error:", error)
            #endif
            return nil
        }
    }

    // MARK: - Resolve

    struct ResolveResult {
        let combat: [String: Any]
        let rewards: Rewards
        let levelUp: LevelUpInfo?
        let unlocks: [String]
        let sanityCheckPassed: Bool
    }

    struct Rewards {
        let gold: Int
        let xp: Int
        let itemCatalogKey: String
        let itemName: String?
    }

    struct LevelUpInfo {
        let leveledUp: Bool
        let newLevel: Int
        let statPointsAwarded: Int
    }

    /// Resolve the scripted fight on the server — runs deterministic combat,
    /// grants rewards, marks tutorialCompleted, applies level up.
    /// Returns nil on failure; caller must handle the null case gracefully.
    func resolveScriptedFight(
        characterId: String,
        stance: ForcedStance,
    ) async -> ResolveResult? {
        do {
            let response = try await APIClient.shared.postRaw(
                "/tutorial/scripted-fight/resolve",
                body: [
                    "character_id": characterId,
                    "stance": [
                        "attack": stance.attack,
                        "defense": stance.defense,
                    ],
                ],
            )

            guard
                let combat = response["combat"] as? [String: Any],
                let rewardsDict = response["rewards"] as? [String: Any],
                let gold = rewardsDict["gold"] as? Int,
                let xp = rewardsDict["xp"] as? Int,
                let itemKey = rewardsDict["itemCatalogKey"] as? String
            else {
                #if DEBUG
                print("[TutorialService] Resolve decode failure:", response)
                #endif
                return nil
            }

            let itemName = rewardsDict["itemName"] as? String

            var levelUpInfo: LevelUpInfo? = nil
            if let lu = response["levelUp"] as? [String: Any],
               let leveled = lu["leveledUp"] as? Bool
            {
                levelUpInfo = LevelUpInfo(
                    leveledUp: leveled,
                    newLevel: (lu["newLevel"] as? Int) ?? 1,
                    statPointsAwarded: (lu["statPointsAwarded"] as? Int) ?? 0,
                )
            }

            let unlocks = (response["unlocks"] as? [String]) ?? []
            let sanityPassed = (response["sanityCheckPassed"] as? Bool) ?? true

            return ResolveResult(
                combat: combat,
                rewards: Rewards(gold: gold, xp: xp, itemCatalogKey: itemKey, itemName: itemName),
                levelUp: levelUpInfo,
                unlocks: unlocks,
                sanityCheckPassed: sanityPassed,
            )
        } catch {
            #if DEBUG
            print("[TutorialService] Resolve error:", error)
            #endif
            let msg = (error as? APIError)?.errorDescription ?? "Failed to resolve tutorial fight"
            appState.showToast(msg, type: .error)
            return nil
        }
    }
}
