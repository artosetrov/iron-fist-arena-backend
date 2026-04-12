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

    /// Asset catalog image name for sector icon
    var sectorAsset: String {
        switch multiplier {
        case 0:   return "icon-fortune-lose"
        case 1.5: return "icon-fortune-x15"
        case 2:   return "icon-fortune-x2"
        case 3:   return "icon-fortune-x3"
        case 5:   return "icon-fortune-x5"
        default:  return "icon-fortune-x15"
        }
    }
}

@MainActor @Observable
final class FortuneWheelViewModel {
    private let appState: AppState

    var selectedBet = 100
    var isSpinning = false
    var result: SpinResult?

    // Daily limit
    var spinsRemaining: Int = 10
    var spinsLimit: Int = 10
    var isLoading = true

    // NPC speech lines
    var npcSpeech: String = "Spin the wheel, brave soul! Fortune favors the bold."

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

    /// Static sectors for Xcode Preview (no VM instance needed)
    static let previewSectors: [WheelSector] = [
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

    private let speechLines = [
        "Spin the wheel, brave soul! Fortune favors the bold.",
        "Feeling lucky? The wheel knows no mercy.",
        "Gold in, glory out. Or... nothing. Let's see!",
        "Lady Fortuna smiles upon the daring.",
        "Every spin tells a story. What will yours be?",
        "The wheel turns. Destinies are forged.",
    ]

    private let winSpeechLines = [
        "The wheel rewards the worthy!",
        "Gold flows to those who dare!",
        "Fortune smiles upon you, champion!",
        "A splendid spin! Try your luck again?",
    ]

    private let loseSpeechLines = [
        "The wheel is cruel... but persistence pays.",
        "Not this time. But the next spin could change everything.",
        "Even heroes stumble. Spin again!",
        "The wheel giveth and taketh. Such is fate.",
    ]

    init(appState: AppState) {
        self.appState = appState
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }

    var canSpin: Bool {
        gold >= selectedBet && !isSpinning && spinsRemaining > 0
    }

    var spinsUsed: Int { spinsLimit - spinsRemaining }

    struct SpinResult {
        let won: Bool
        let sectorIndex: Int
        let multiplier: Double
        let winAmount: Int
    }

    // MARK: - Load Status

    func loadStatus() async {
        guard let charId = appState.currentCharacter?.id else {
            isLoading = false
            return
        }

        do {
            let data = try await APIClient.shared.getRaw(
                APIEndpoints.fortuneWheelStatus + "?character_id=\(charId)"
            )
            spinsRemaining = data["spins_remaining"] as? Int ?? 10
            spinsLimit = data["spins_limit"] as? Int ?? 10
        } catch {
            // Default to showing wheel, backend will enforce limits
        }
        isLoading = false
    }

    // MARK: - Spin

    /// Calls the backend, returns sector index for animation. Client animates wheel to that sector.
    func spin() async -> SpinResult? {
        guard canSpin, let charId = appState.currentCharacter?.id else { return nil }

        isSpinning = true
        SFXManager.shared.play(.wheelSpin)
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

            // Update daily limit from server
            if let remaining = data["spins_remaining"] as? Int {
                spinsRemaining = remaining
            }
            if let limit = data["spins_limit"] as? Int {
                spinsLimit = limit
            }

            result = spinResult
            appState.invalidateCache("quests")
            return spinResult

        } catch let error as APIError {
            // Revert optimistic deduction
            appState.currentCharacter?.gold += selectedBet
            isSpinning = false

            switch error {
            case .rateLimited:
                npcSpeech = "The wheel needs rest... come back tomorrow."
                spinsRemaining = 0
            case .clientError(_, let message, _):
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

    /// Called after wheel animation completes — update NPC speech and reset state
    func onAnimationComplete() {
        guard let result else {
            isSpinning = false
            return
        }

        if result.won {
            SFXManager.shared.play(.coinsJingle)
            HapticManager.victory()
            npcSpeech = winSpeechLines.randomElement() ?? winSpeechLines[0]
        } else {
            SFXManager.shared.play(.uiError)
            HapticManager.shake()
            npcSpeech = loseSpeechLines.randomElement() ?? loseSpeechLines[0]
        }

        isSpinning = false
    }

    func reset() {
        result = nil
        isSpinning = false
    }

    func randomizeSpeech() {
        npcSpeech = speechLines.randomElement() ?? speechLines[0]
    }
}
