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

    // NPC speech
    var npcSpeech: String = ""

    // Daily plays limit (backend = 20/day)
    var playsRemaining: Int = 20
    var playsLimit: Int = 20

    private var sessionId: String?

    static let bets = [50, 100, 200, 500, 1000]

    init(appState: AppState) {
        self.appState = appState
        randomizeSpeech()
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }

    var canPlay: Bool {
        gold >= selectedBet && !isPlaying && playsRemaining > 0
    }

    var playsUsed: Int { playsLimit - playsRemaining }

    var cups: [Int] { [0, 1, 2] }

    // MARK: - NPC Speech Lines

    private static let defaultLines = [
        "Step right up! Find the golden ball, double your gold...",
        "Think you've got sharp eyes? Let's put them to the test!",
        "The cups move fast, but your wits must be faster.",
        "A simple game... for those with a keen eye.",
        "Fortune favors the brave. Place your bet!",
        "My cups have fooled kings and thieves alike.",
    ]

    private static let winLines = [
        "Well played! Sharp eyes you have, adventurer!",
        "Impressive! Not many can track my shuffle.",
        "A worthy winner! The gold is yours.",
        "You've bested me... this time.",
    ]

    private static let loseLines = [
        "So close! The ball was hiding elsewhere...",
        "Better luck next time, adventurer!",
        "The cups are tricky, aren't they?",
        "Don't feel bad — even rogues miss sometimes.",
    ]

    func randomizeSpeech() {
        npcSpeech = Self.defaultLines.randomElement() ?? ""
    }

    func onResultComplete() {
        if result == "win" {
            npcSpeech = Self.winLines.randomElement() ?? ""
        } else {
            npcSpeech = Self.loseLines.randomElement() ?? ""
        }
    }

    // MARK: - Load Status (daily plays)

    func loadStatus() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let data: ShellGameStatusResponse = try await APIClient.shared.get(
                APIEndpoints.shellGameStatus,
                params: ["character_id": charId]
            )
            playsRemaining = data.playsRemaining
            playsLimit = data.playsLimit
        } catch {
            // Keep defaults (20/20) — non-critical
        }
    }

    // MARK: - Step 1: Start session

    /// Called when user presses START. Returns a local animation cup index, not
    /// the server's winning cup. The real result is revealed only after guess().
    func startGame() async -> Int? {
        guard canPlay, let charId = appState.currentCharacter?.id else { return nil }

        isPlaying = true
        result = nil
        winAmount = 0
        sessionId = nil
        winningCup = nil

        // Optimistic: deduct gold before API call
        let savedGold = appState.currentCharacter?.gold ?? 0
        appState.currentCharacter?.gold = savedGold - selectedBet

        do {
            let data: ShellGameStartResponse = try await APIClient.shared.post(
                APIEndpoints.shellGameStart,
                body: ShellGameStartRequest(characterId: charId, betAmount: selectedBet)
            )
            sessionId = data.sessionId

            // Update plays from server response if available
            playsRemaining = data.playsRemaining
            playsLimit = data.playsLimit

            return Int.random(in: 0...2)
        } catch let error as APIError {
            isPlaying = false
            appState.currentCharacter?.gold = savedGold // revert
            switch error {
            case .rateLimited(let message):
                appState.showToast(message, type: .error)
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Shell game unavailable", subtitle: "Try again later", type: .error)
            }
            return nil
        } catch {
            isPlaying = false
            appState.currentCharacter?.gold = savedGold // revert
            appState.showToast("Shell game unavailable", subtitle: "Try again later", type: .error)
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
            let data: ShellGameGuessResponse = try await APIClient.shared.post(
                APIEndpoints.shellGameGuess,
                body: ShellGameGuessRequest(characterId: charId, sessionId: sessionId, chosenCup: cup)
            )

            winningCup = data.winningCup
            let won = data.won
            winAmount = data.winAmount
            isPlaying = false

            if won {
                result = "win"
            } else {
                result = "lose"
            }

            appState.currentCharacter?.gold = data.gold
            appState.invalidateCache("quests")
        } catch {
            isPlaying = false
            appState.showToast("Shell game failed", subtitle: "Check connection and try again", type: .error)
        }
    }

    func reset() {
        selectedCup = nil
        winningCup = nil
        result = nil
        winAmount = 0
        isPlaying = false
        sessionId = nil
        randomizeSpeech()
    }
}
