import SwiftUI

@MainActor @Observable
final class ShellGameViewModel {
    private let appState: AppState

    var selectedBet = 100
    var isPlaying = false
    var selectedCup: Int?
    var winningCup: Int?
    var result: String?
    var winAmount = 0

    private var sessionId: String?

    static let bets = [50, 100, 200, 500]

    init(appState: AppState) {
        self.appState = appState
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }

    var canPlay: Bool {
        gold >= selectedBet && !isPlaying
    }

    var cups: [Int] { [0, 1, 2] }

    // MARK: - Step 1: Start session

    /// Called when user presses START. Returns winning cup index for reveal, or nil on failure.
    func startGame() async -> Int? {
        guard canPlay, let charId = appState.currentCharacter?.id else { return nil }

        isPlaying = true
        result = nil
        winAmount = 0
        sessionId = nil
        winningCup = nil

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.shellGameStart,
                body: [
                    "character_id": charId,
                    "bet_amount": selectedBet
                ]
            )
            let sid = data["session_id"] as? String
            let revealCup = data["winning_cup"] as? Int ?? Int.random(in: 0...2)

            guard let sid else {
                isPlaying = false
                return nil
            }

            sessionId = sid
            appState.currentCharacter?.gold -= selectedBet

            return revealCup
        } catch let error as APIError {
            isPlaying = false
            switch error {
            case .clientError(_, let message):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Shell game unavailable", type: .error)
            }
            return nil
        } catch {
            isPlaying = false
            appState.showToast("Shell game unavailable", type: .error)
            return nil
        }
    }

    // MARK: - Step 2: Submit guess

    /// Called after the shuffle animation when user picks a cup.
    func guess(cup: Int) async {
        guard let charId = appState.currentCharacter?.id,
              let sessionId else {
            isPlaying = false
            return
        }

        selectedCup = cup

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.shellGameGuess,
                body: [
                    "character_id": charId,
                    "session_id": sessionId,
                    "chosen_cup": cup
                ]
            )

            winningCup = data["winning_cup"] as? Int
            let won = data["won"] as? Bool ?? false
            winAmount = data["win_amount"] as? Int ?? 0
            isPlaying = false

            if won {
                result = "win"
                appState.showToast("Won \(winAmount) gold!", type: .reward)
            } else {
                result = "lose"
                appState.showToast("Wrong cup! Lost \(selectedBet) gold", type: .error)
            }

            if let newGold = data["gold"] as? Int {
                appState.currentCharacter?.gold = newGold
            }
            appState.invalidateCache("quests")
        } catch {
            isPlaying = false
            appState.showToast("Shell game failed", type: .error)
        }
    }

    func reset() {
        selectedCup = nil
        winningCup = nil
        result = nil
        winAmount = 0
        isPlaying = false
        sessionId = nil
    }
}
