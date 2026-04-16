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
/// Contract note:
/// - canonical backend fields are snake_case (`forced_stance`, `level_up`,
///   `item_catalog_key`, `sanity_check_passed`)
/// - the shared `APIClient` decoder uses `convertFromSnakeCase`, so this client
///   still accepts the earlier camelCase aliases without a separate raw bridge
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
        let hero: HeroPreview
        let opponent: OpponentPreview
        let forcedStance: ForcedStance
        let scripted: Bool
    }

    struct HeroPreview: Decodable {
        let characterClass: CharacterClass
        let maxHp: Int

        enum CodingKeys: String, CodingKey {
            case characterClass = "class"
            case maxHp
        }
    }

    struct OpponentPreview: Decodable {
        let name: String
        let maxHp: Int
    }

    struct ForcedStance: Codable {
        let attack: String
        let defense: String
    }

    /// Preload the hero + scripted opponent payload.
    /// Returns nil if preload fails or tutorial was already completed.
    func preloadScriptedFight(characterId: String) async -> PreloadResult? {
        do {
            let response: ScriptedFightPreloadResponse = try await APIClient.shared.post(
                "/tutorial/scripted-fight/preload",
                body: ScriptedFightPreloadRequest(characterId: characterId)
            )

            return PreloadResult(
                hero: response.hero,
                opponent: response.opponent,
                forcedStance: response.forcedStance,
                scripted: response.scripted ?? true
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
        let rewards: Rewards
        let levelUp: LevelUpInfo?
        let unlocks: [String]
    }

    struct Rewards: Decodable {
        let gold: Int
        let xp: Int
        let itemCatalogKey: String
        let itemName: String?
    }

    struct LevelUpInfo: Decodable {
        let leveledUp: Bool
        let newLevel: Int
        let statPointsAwarded: Int
        let passivePointsAwarded: Int
    }

    /// Resolve the scripted fight on the server — runs deterministic combat,
    /// grants rewards, marks tutorialCompleted, applies level up.
    /// Returns nil on failure; caller must handle the null case gracefully.
    func resolveScriptedFight(
        characterId: String,
        stance: ForcedStance,
    ) async -> ResolveResult? {
        do {
            let response: ScriptedFightResolveResponse = try await APIClient.shared.post(
                "/tutorial/scripted-fight/resolve",
                body: ScriptedFightResolveRequest(
                    characterId: characterId,
                    stance: stance
                )
            )

            return ResolveResult(
                rewards: response.rewards,
                levelUp: response.levelUp,
                unlocks: response.unlocks
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

private struct ScriptedFightPreloadRequest: Encodable {
    let characterId: String
}

private struct ScriptedFightPreloadResponse: Decodable {
    let hero: TutorialService.HeroPreview
    let opponent: TutorialService.OpponentPreview
    let forcedStance: TutorialService.ForcedStance
    let scripted: Bool?
}

private struct ScriptedFightResolveRequest: Encodable {
    let characterId: String
    let stance: TutorialService.ForcedStance
}

private struct ScriptedFightResolveResponse: Decodable {
    let rewards: TutorialService.Rewards
    let levelUp: TutorialService.LevelUpInfo?
    let unlocks: [String]
}
