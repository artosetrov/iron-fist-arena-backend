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

    func saveStance() {
        guard hasChanges else { return }

        // Optimistic: update character stance + navigate back instantly
        let prevAttack = appState.currentCharacter?.combatStance?.attack
        let prevDefense = appState.currentCharacter?.combatStance?.defense
        appState.currentCharacter?.combatStance = CombatStance(attack: attackZone, defense: defenseZone)
        HapticManager.success()
        if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }

        // Fire API in background
        let attack = attackZone
        let defense = defenseZone
        Task { [weak self] in
            guard let self else { return }
            let success = await service.setStance(attack: attack, defense: defense)
            if !success {
                // Revert on failure
                if let prevAttack, let prevDefense {
                    appState.currentCharacter?.combatStance = CombatStance(attack: prevAttack, defense: prevDefense)
                }
                appState.showToast("Failed to save stance", subtitle: "Please try again", type: .error)
            }
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
        case "head": "target"
        case "chest": "shield"
        case "legs": "person.crop.circle.badge.checkmark"
        default: "questionmark.circle"
        }
    }

    static func zoneAsset(for zone: String) -> String {
        switch zone {
        case "head": "icon-helmet"
        case "chest": "icon-chest"
        case "legs": "icon-legs"
        default: "icon-helmet"
        }
    }

    static func zoneLabel(for zone: String) -> String {
        zone.uppercased()
    }

    // MARK: - Stance Bonus Data

    /// Attack zone intrinsic bonuses (from balance.ts STANCE_ZONES.ATTACK_ZONE)
    static func attackBonuses(for zone: String) -> (offense: Int, crit: Int) {
        switch zone {
        case "head":  return (10, 5)
        case "chest": return (5, 0)
        case "legs":  return (0, -3)
        default:      return (0, 0)
        }
    }

    /// Defense zone intrinsic bonuses (from balance.ts STANCE_ZONES.DEFENSE_ZONE)
    static func defenseBonuses(for zone: String) -> (defense: Int, dodge: Int) {
        switch zone {
        case "head":  return (0, 8)
        case "chest": return (10, 0)
        case "legs":  return (5, 3)
        default:      return (0, 0)
        }
    }

    /// Short flavor description for attack zone
    static func attackDescription(for zone: String) -> String {
        switch zone {
        case "head":  return "High risk, high reward. Maximum damage and crit chance."
        case "chest": return "Balanced offense. Moderate damage bonus."
        case "legs":  return "Conservative. No bonus, reduced crit chance."
        default:      return ""
        }
    }

    /// Short flavor description for defense zone
    static func defenseDescription(for zone: String) -> String {
        switch zone {
        case "head":  return "Evasive. High dodge chance, no armor bonus."
        case "chest": return "Tanky. Maximum damage reduction."
        case "legs":  return "Balanced defense. Moderate armor and dodge."
        default:      return ""
        }
    }
}
