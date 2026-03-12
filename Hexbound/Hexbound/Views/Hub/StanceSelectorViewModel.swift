import SwiftUI

@MainActor @Observable
final class StanceSelectorViewModel {
    let appState: AppState
    private let service: CharacterService

    var attackZone: String
    var defenseZone: String
    var isSaving = false

    private let originalAttack: String
    private let originalDefense: String

    static let zones = ["head", "chest", "legs"]

    var hasChanges: Bool {
        attackZone != originalAttack || defenseZone != originalDefense
    }

    init(appState: AppState) {
        self.appState = appState
        self.service = CharacterService(appState: appState)

        let stance = appState.currentCharacter?.combatStance ?? .default
        self.attackZone = stance.attack
        self.defenseZone = stance.defense
        self.originalAttack = stance.attack
        self.originalDefense = stance.defense
    }

    func saveStance() async {
        guard hasChanges else { return }
        isSaving = true
        let success = await service.setStance(attack: attackZone, defense: defenseZone)
        isSaving = false
        if success {
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
        }
    }

    static func zoneColor(for zone: String) -> Color {
        switch zone {
        case "head": DarkFantasyTheme.zoneHead
        case "chest": DarkFantasyTheme.zoneChest
        case "legs": DarkFantasyTheme.zoneLegs
        default: DarkFantasyTheme.textSecondary
        }
    }

    static func zoneIcon(for zone: String) -> String {
        switch zone {
        case "head": "🎯"
        case "chest": "🛡️"
        case "legs": "🦿"
        default: "❓"
        }
    }

    static func zoneLabel(for zone: String) -> String {
        zone.uppercased()
    }
}
