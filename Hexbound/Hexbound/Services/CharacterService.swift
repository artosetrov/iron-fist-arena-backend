import Foundation

@MainActor
final class CharacterService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Fetch Characters

    func loadCharacter() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let response: CharacterEnvelope = try await APIClient.shared.get(
                APIEndpoints.character(charId)
            )
            appState.currentCharacter = response.character
            appState.noteAuthoritativeCurrencyWrite()
        } catch {
            appState.showToast("Failed to load character", subtitle: "Check connection and try again", type: .error, actionLabel: "Retry") { [weak self] in
                Task { @MainActor in
                    await self?.loadCharacter()
                }
            }
        }
    }

    /// Background refresh with no error UI — for reconciling server-derived
    /// stats (e.g. max HP after an equip) behind an optimistic update the
    /// player has already seen. A failure leaves the current values; the
    /// next screen load retries.
    func refreshCharacterSilently() async {
        guard let charId = appState.currentCharacter?.id else { return }
        guard let response: CharacterEnvelope = try? await APIClient.shared.get(
            APIEndpoints.character(charId)
        ) else { return }
        // The player may have switched hero while this was in flight.
        guard appState.currentCharacter?.id == response.character.id else { return }
        appState.currentCharacter = response.character
        appState.noteAuthoritativeCurrencyWrite()
    }

    // MARK: - Allocate Stats

    func allocateStats(statChanges: [String: Int]) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response: CharacterEnvelope = try await APIClient.shared.post(
                APIEndpoints.allocateStats(charId),
                body: statChanges
            )
            appState.currentCharacter = response.character
            // "Stats saved!" is shown optimistically by CharacterViewModel.
            return true
        } catch {
            appState.showToast("Failed to save stats", subtitle: "Changes not applied — try again", type: .error)
            return false
        }
    }

    // MARK: - Respec Stats

    func respecStats() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response: CharacterEnvelope = try await APIClient.shared.post(
                APIEndpoints.respecStats(charId),
                body: CharacterIdBody(characterId: charId)
            )
            appState.currentCharacter = response.character
            appState.showToast("Stats reset!", type: .info)
            return true
        } catch {
            appState.showToast("Failed to reset stats", subtitle: "Check connection and try again", type: .error)
            return false
        }
    }

    // MARK: - Buy Stat Points

    func buyStatPoints() async -> BuyStatPointsResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let response: BuyStatPointsResponse = try await APIClient.shared.post(
                APIEndpoints.buyStatPoints(charId),
                body: CharacterIdBody(characterId: charId)
            )
            if let updated = response.character {
                appState.currentCharacter = updated
            }
            return response.purchase
        } catch {
            appState.showToast("Purchase failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    func getStatPurchaseStatus() async -> StatPurchaseStatus? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let response: StatPurchaseStatus = try await APIClient.shared.get(
                APIEndpoints.statPurchaseStatus(charId)
            )
            return response
        } catch {
            return nil
        }
    }

    // MARK: - Stamina Refill (gems)

    /// POST /api/stamina/refill — full refill for gems with diminishing
    /// daily cost. Server is authoritative; this only mirrors the response.
    /// Until AUDIT-2026-10-13 H9 the route existed but nothing on iOS called
    /// it, so an empty bar was a dead end ("No dead ends" rule).
    @discardableResult
    func refillStamina() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        // Latency pass (2026-10-15): the bar fills on the tap (the server
        // always refills to max). The gem price scales per refill and is
        // server-known, so gems update when the response lands. A refusal
        // puts the bar back.
        let previousStamina = appState.currentCharacter?.currentStamina
        if var char = appState.currentCharacter {
            char.currentStamina = char.maxStamina
            appState.currentCharacter = char
        }
        HapticManager.medium()
        func restoreStamina() {
            // Only undo our own fill — if stamina moved since (a fight,
            // regen sync), leave the newer value alone.
            if let previousStamina, var char = appState.currentCharacter,
               char.currentStamina == char.maxStamina {
                char.currentStamina = previousStamina
                appState.currentCharacter = char
            }
        }
        do {
            let response: StaminaRefillResponse = try await APIClient.shared.post(
                APIEndpoints.staminaRefill,
                body: CharacterIdBody(characterId: charId)
            )
            if var char = appState.currentCharacter {
                char.currentStamina = response.stamina.after
                char.gems = response.gemsRemaining
                appState.currentCharacter = char
            }
            HapticManager.success()
            SFXManager.shared.play(.uiPurchase)
            let left = max(0, response.dailyCap - response.refillIndex)
            appState.showToast(
                "Stamina refilled!",
                subtitle: "-\(response.gemsSpent) gems · \(left) refill\(left == 1 ? "" : "s") left today",
                type: .reward
            )
            return true
        } catch let error as APIError {
            restoreStamina()
            if case .clientError(_, let message, _) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Refill failed", subtitle: "Check connection and try again", type: .error)
            }
            return false
        } catch {
            restoreStamina()
            appState.showToast("Refill failed", subtitle: "Check connection and try again", type: .error)
            return false
        }
    }

    /// Shared "out of stamina" toast with a Refill action. Call sites that
    /// pre-check stamina (Arena, Hub banner, Guild Hall duels) use this so the
    /// player always has a next step.
    static func showOutOfStamina(appState: AppState, refillGemCost: Int?) {
        let cost = refillGemCost.map { " (\($0) gems)" } ?? ""
        appState.showToast(
            "Not enough stamina",
            subtitle: "Wait for regen, use a potion, or refill now",
            type: .error,
            actionLabel: "Refill\(cost)"
        ) {
            Task { @MainActor in
                await CharacterService(appState: appState).refillStamina()
            }
        }
    }

    // MARK: - Prestige

    struct PrestigeResult {
        let prestigeLevel: Int
        let statBonusPercent: Double
        let message: String
    }

    /// POST /api/prestige — level → 1, XP → 0, talents wiped, +prestige.
    /// Server validates max level (400 otherwise). Reloads the character.
    /// Until AUDIT-2026-10-13 H12 the endpoint existed but no screen called it.
    func prestige() async -> PrestigeResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let response: PrestigeResponse = try await APIClient.shared.post(
                APIEndpoints.prestige,
                body: CharacterIdBody(characterId: charId)
            )
            await loadCharacter()
            appState.invalidateCache("quests")
            return PrestigeResult(
                prestigeLevel: response.prestigeLevel,
                statBonusPercent: response.statBonusPercent,
                message: response.message
            )
        } catch let error as APIError {
            if case .clientError(_, let message, _) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Prestige failed", subtitle: "Check connection and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Prestige failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    // MARK: - Set Stance

    func setStance(attack: String, defense: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response: CharacterEnvelope = try await APIClient.shared.post(
                APIEndpoints.setStance(charId),
                body: SetStanceBody(stance: StanceSelectionBody(attack: attack, defense: defense))
            )
            appState.currentCharacter = response.character
            appState.showToast("Stance updated!", type: .info)
            return true
        } catch {
            appState.showToast("Failed to update stance", subtitle: "Check connection and try again", type: .error)
            return false
        }
    }

    // MARK: - Train (Simulate Combat)

    func train() async -> Bool {
        appState.showToast(
            "Training unavailable",
            subtitle: "This client path still points at a deprecated combat endpoint",
            type: .info
        )
        return false
    }
}

private struct CharacterEnvelope: Decodable {
    let character: Character
}

private struct BuyStatPointsResponse: Decodable {
    let character: Character?
    let purchase: BuyStatPointsResult?
}

private struct CharacterIdBody: Encodable {
    let characterId: String
}

private struct PrestigeResponse: Decodable {
    let success: Bool
    let prestigeLevel: Int
    let statBonusPercent: Double
    let message: String
}

/// `/api/stamina/refill` response. Backend sends snake_case; APIClient's
/// `.convertFromSnakeCase` maps it — camelCase keys only, no CodingKeys.
private struct StaminaRefillResponse: Decodable {
    struct Stamina: Decodable {
        let before: Int
        let after: Int
        let max: Int
    }
    let stamina: Stamina
    let gemsSpent: Int
    let gemsRemaining: Int
    let refillIndex: Int
    let dailyCap: Int
}

private struct StanceSelectionBody: Encodable {
    let attack: String
    let defense: String
}

private struct SetStanceBody: Encodable {
    let stance: StanceSelectionBody
}
