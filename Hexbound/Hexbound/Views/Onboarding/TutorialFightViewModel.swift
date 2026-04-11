import SwiftUI

/// W2.D3 — State machine for the scripted tutorial fight.
///
/// States: loading → ready → resolving → (advance to .tutorialVictory) | error
///
/// Owns the rewards payload so VictoryOverlayView can read it off AppState
/// (parked under `appState.tutorialRewards`) when the screen transitions.
@MainActor @Observable
final class TutorialFightViewModel {
    enum State: Equatable {
        case loading
        case ready
        case resolving
        case error(String)
    }

    // MARK: - Dependencies

    private let appState: AppState
    private let service: TutorialService

    // MARK: - State

    var state: State = .loading
    var showSkipConfirmation: Bool = false

    // Preloaded data (minimal — only what pre-fight panel shows)
    var heroClass: String?
    var heroMaxHp: Int = 0
    var opponentName: String?
    var opponentMaxHp: Int = 0

    private var forcedStance: TutorialService.ForcedStance?

    init(appState: AppState) {
        self.appState = appState
        self.service = TutorialService(appState: appState)
    }

    // MARK: - Preload

    func preload() async {
        state = .loading

        guard let charId = appState.currentCharacter?.id else {
            state = .error("No character loaded")
            return
        }

        guard let result = await service.preloadScriptedFight(characterId: charId) else {
            // Preload failed — could be network or 409 ALREADY_COMPLETED.
            // In the 409 case the cleanest UX is to just skip to hub (tutorial is done).
            // We fall through to error so the player can retry or skip.
            state = .error("Could not load tutorial fight. Tap retry or skip.")
            return
        }

        // Extract hero display values
        heroClass = result.hero["class"] as? String
        heroMaxHp = (result.hero["maxHp"] as? Int) ?? 0

        // Extract opponent display values
        opponentName = result.opponent["name"] as? String
        opponentMaxHp = (result.opponent["maxHp"] as? Int) ?? 0

        forcedStance = result.forcedStance
        state = .ready
    }

    // MARK: - Resolve

    func resolve(heroName: String) async {
        guard state == .ready else { return }
        guard let charId = appState.currentCharacter?.id else {
            state = .error("No character loaded")
            return
        }
        guard let stance = forcedStance else {
            state = .error("Missing stance data. Tap retry.")
            return
        }

        state = .resolving
        HapticManager.heavy()

        guard let result = await service.resolveScriptedFight(characterId: charId, stance: stance) else {
            state = .error("Server could not resolve the fight. Tap retry.")
            return
        }

        // Park rewards on AppState so VictoryOverlayView can read them
        appState.tutorialRewards = TutorialRewardsPayload(
            gold: result.rewards.gold,
            xp: result.rewards.xp,
            itemName: result.rewards.itemName,
            itemCatalogKey: result.rewards.itemCatalogKey,
            leveledUp: result.levelUp?.leveledUp ?? false,
            newLevel: result.levelUp?.newLevel,
            unlocks: result.unlocks,
        )

        // Reload character so gold/XP/level reflects server state before hub entry
        await appState.reloadCharacter()

        // Advance to victory overlay
        withAnimation(.easeInOut(duration: 0.3)) {
            appState.currentScreen = .tutorialVictory(heroName: heroName)
        }
    }

    // MARK: - Skip

    func requestSkipConfirmation() {
        showSkipConfirmation = true
    }

    func skipToHub() async {
        // Skipping forfeits rewards per design — player confirmed they understand.
        // Route straight to loreIntro (same as victory path) so they still see
        // the cinematic lore sequence once, just without the rewards.
        guard let character = appState.currentCharacter else {
            appState.currentScreen = .game
            return
        }
        appState.tutorialRewards = nil
        // Mark tutorial as skipped on the server so we don't prompt again
        _ = await TutorialManager.shared.skipTutorial(characterId: character.id)
        withAnimation(.easeInOut(duration: 0.3)) {
            appState.currentScreen = .loreIntro(heroName: character.characterName)
        }
    }
}

// MARK: - Reward Payload

/// Lightweight snapshot of the scripted-fight rewards, parked on AppState
/// so VictoryOverlayView can read it without re-fetching.
/// Cleared when the player enters the hub.
struct TutorialRewardsPayload: Equatable {
    let gold: Int
    let xp: Int
    let itemName: String?
    let itemCatalogKey: String
    let leveledUp: Bool
    let newLevel: Int?
    let unlocks: [String]
}
