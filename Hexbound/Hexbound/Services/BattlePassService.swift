import Foundation

private struct BattlePassBuyPremiumResponse: Codable {
    struct BattlePassSummary: Codable {
        let id: String
        let premium: Bool
        let bpXp: Int
    }

    let battlePass: BattlePassSummary
    let gemsRemaining: Int
    let cost: Int
}

@MainActor
final class BattlePassService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadBattlePass() async -> BattlePassData? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            var bp: BattlePassData = try await APIClient.shared.get(
                APIEndpoints.battlePass,
                params: ["character_id": charId]
            )
            // Tag tracks
            var free = bp.freeRewards
            for i in free.indices { free[i].track = "free" }
            var premium = bp.premiumRewards
            for i in premium.indices { premium[i].track = "premium" }
            bp = BattlePassData(
                seasonName: bp.seasonName,
                currentLevel: bp.currentLevel,
                currentXp: bp.currentXp,
                xpToNext: bp.xpToNext,
                hasPremium: bp.hasPremium,
                freeRewards: free,
                premiumRewards: premium
            )
            return bp
        } catch {
            return nil
        }
    }

    /// Claims all eligible rewards at the given BP level.
    /// Throws on failure so callers can show context-specific messages.
    func claimReward(level: Int) async throws -> BattlePassClaimResponse {
        guard let charId = appState.currentCharacter?.id else {
            throw BattlePassClaimError.noCharacter
        }
        do {
            let response: BattlePassClaimResponse = try await APIClient.shared.post(
                APIEndpoints.battlePassClaim(level),
                body: ["character_id": charId]
            )
            return response
        } catch let error as APIError {
            switch error {
            case .clientError(let code, let msg, _):
                if code == 400 && msg.contains("already claimed") {
                    throw BattlePassClaimError.alreadyClaimed
                } else if code == 400 && msg.contains("not yet reached") {
                    throw BattlePassClaimError.levelNotReached
                } else if code == 409 {
                    throw BattlePassClaimError.inventoryFull
                } else {
                    throw BattlePassClaimError.serverError(msg)
                }
            case .rateLimited:
                throw BattlePassClaimError.rateLimited
            case .unauthorized:
                throw BattlePassClaimError.unauthorized
            default:
                throw BattlePassClaimError.serverError(error.localizedDescription)
            }
        } catch let error as DecodingError {
            throw BattlePassClaimError.serverError(error.localizedDescription)
        }
    }

    func buyPremium() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response: BattlePassBuyPremiumResponse = try await APIClient.shared.post(
                APIEndpoints.battlePassBuyPremium,
                body: ["character_id": charId]
            )
            if var char = appState.currentCharacter {
                char.gems = response.gemsRemaining
                appState.currentCharacter = char
            }
            return true
        } catch let error as APIError {
            let subtitle: String
            switch error {
            case .clientError(_, let msg, _), .serverError(_, let msg):
                if msg.contains("Not enough gems") {
                    subtitle = "Not enough gems"
                } else if msg.contains("already premium") {
                    subtitle = "Already premium"
                } else if msg.contains("No active season") {
                    subtitle = "No active season available"
                } else {
                    subtitle = msg
                }
            default:
                subtitle = error.localizedDescription
            }
            appState.showToast("Failed to buy premium", subtitle: subtitle, type: .error)
            return false
        } catch {
            appState.showToast("Failed to buy premium", subtitle: "Check connection and try again", type: .error)
            return false
        }
    }
}

// MARK: - Claim Errors

enum BattlePassClaimError: LocalizedError {
    case noCharacter
    case alreadyClaimed
    case levelNotReached
    case inventoryFull
    case rateLimited
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .noCharacter: "No active character"
        case .alreadyClaimed: "Already claimed"
        case .levelNotReached: "Level not reached yet"
        case .inventoryFull: "Inventory full"
        case .rateLimited: "Too many requests"
        case .unauthorized: "Session expired"
        case .serverError(let msg): msg
        }
    }

    /// User-facing subtitle for the toast
    var toastSubtitle: String {
        switch self {
        case .alreadyClaimed: "This reward was already collected"
        case .levelNotReached: "Earn more XP to unlock this level"
        case .inventoryFull: "Free up inventory space first"
        case .rateLimited: "Wait a moment and try again"
        case .unauthorized: "Please log in again"
        case .noCharacter: "Select a character first"
        case .serverError(let msg): msg
        }
    }
}
