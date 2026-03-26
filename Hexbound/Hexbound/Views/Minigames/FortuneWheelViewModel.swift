import SwiftUI

/// Sector on the Fortune Wheel — mirrors backend layout.
struct WheelSector: Identifiable {
    let id: Int // index 0..<12
    let multiplier: Double
    let label: String

    var isLose: Bool { multiplier == 0 }

    var color: Color {
        switch multiplier {
        case 0:   return DarkFantasyTheme.danger
        case 1.5: return DarkFantasyTheme.gold
        case 2:   return DarkFantasyTheme.goldBright
        case 3:   return DarkFantasyTheme.purple
        case 5:   return DarkFantasyTheme.info
        default:  return DarkFantasyTheme.gold
        }
    }

    var icon: String {
        switch multiplier {
        case 0:   return "xmark"
        case 1.5: return "star"
        case 2:   return "star.fill"
        case 3:   return "diamond"
        case 5:   return "crown"
        default:  return "star"
        }
    }
}

@MainActor @Observable
final class FortuneWheelViewModel {
    private let appState: AppState

    var selectedBet = 100
    var isSpinning = false
    var result: SpinResult?

    // Wheel layout — 12 sectors, matching backend
    let sectors: [WheelSector] = [
        WheelSector(id: 0,  multiplier: 0,   label: "LOSE"),
        WheelSector(id: 1,  multiplier: 1.5, label: "x1.5"),
        WheelSector(id: 2,  multiplier: 0,   label: "LOSE"),
        WheelSector(id: 3,  multiplier: 2,   label: "x2"),
        WheelSector(id: 4,  multiplier: 0,   label: "LOSE"),
        WheelSector(id: 5,  multiplier: 1.5, label: "x1.5"),
        WheelSector(id: 6,  multiplier: 0,   label: "LOSE"),
        WheelSector(id: 7,  multiplier: 3,   label: "x3"),
        WheelSector(id: 8,  multiplier: 0,   label: "LOSE"),
        WheelSector(id: 9,  multiplier: 1.5, label: "x1.5"),
        WheelSector(id: 10, multiplier: 0,   label: "LOSE"),
        WheelSector(id: 11, multiplier: 5,   label: "x5"),
    ]

    static let bets = [50, 100, 200, 500, 1000]

    init(appState: AppState) {
        self.appState = appState
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }

    var canSpin: Bool {
        gold >= selectedBet && !isSpinning
    }

    struct SpinResult {
        let won: Bool
        let sectorIndex: Int
        let multiplier: Double
        let winAmount: Int
    }

    // MARK: - Spin

    /// Calls the backend, returns sector index for animation. Client animates wheel to that sector.
    func spin() async -> SpinResult? {
        guard canSpin, let charId = appState.currentCharacter?.id else { return nil }

        isSpinning = true
        result = nil

        // Optimistic: deduct bet immediately
        appState.currentCharacter?.gold -= selectedBet

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.fortuneWheelSpin,
                body: [
                    "character_id": charId,
                    "bet_amount": selectedBet
                ]
            )

            let won = data["won"] as? Bool ?? false
            let sectorIndex = data["sector_index"] as? Int ?? 0
            let multiplier = data["multiplier"] as? Double ?? 0
            let winAmount = data["win_amount"] as? Int ?? 0

            let spinResult = SpinResult(
                won: won,
                sectorIndex: sectorIndex,
                multiplier: multiplier,
                winAmount: winAmount
            )

            // Update gold from server
            if let newGold = data["gold"] as? Int {
                appState.currentCharacter?.gold = newGold
            }

            result = spinResult
            appState.invalidateCache("quests")
            return spinResult

        } catch let error as APIError {
            // Revert optimistic deduction
            appState.currentCharacter?.gold += selectedBet
            isSpinning = false

            switch error {
            case .clientError(_, let message):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Fortune Wheel unavailable", subtitle: "Try again later", type: .error)
            }
            return nil
        } catch {
            appState.currentCharacter?.gold += selectedBet
            isSpinning = false
            appState.showToast("Fortune Wheel unavailable", subtitle: "Try again later", type: .error)
            return nil
        }
    }

    /// Called after wheel animation completes — show toast and reset state
    func onAnimationComplete() {
        guard let result else {
            isSpinning = false
            return
        }

        if result.won {
            SFXManager.shared.play(.uiRewardClaim)
            HapticManager.victory()
            appState.showToast("Won \(result.winAmount) gold!", subtitle: "x\(String(format: "%.1f", result.multiplier)) multiplier", type: .reward)
        } else {
            SFXManager.shared.play(.uiError)
            HapticManager.shake()
            appState.showToast("Lost \(selectedBet) gold", subtitle: "Better luck next time", type: .error)
        }

        isSpinning = false
    }

    func reset() {
        result = nil
        isSpinning = false
    }
}
