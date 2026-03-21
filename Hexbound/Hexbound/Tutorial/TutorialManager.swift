import SwiftUI

// MARK: - Tutorial Step Definitions

/// Each tutorial step is a contextual tooltip shown once on a specific screen.
enum TutorialStep: String, CaseIterable {
    // Hub screen (post-onboarding)
    case hubCharacterCard   = "hub_character_card"
    case hubCityMap         = "hub_city_map"
    case hubDailyLogin      = "hub_daily_login"
    case hubStamina         = "hub_stamina"

    // Arena
    case arenaOpponent      = "arena_opponent"
    case arenaStance        = "arena_stance"

    // Shop
    case shopGems           = "shop_gems"

    // Dungeon
    case dungeonEntry       = "dungeon_entry"

    /// User-facing title
    var title: String {
        switch self {
        case .hubCharacterCard: return "Your Hero"
        case .hubCityMap:       return "Explore the City"
        case .hubDailyLogin:    return "Daily Rewards"
        case .hubStamina:       return "Stamina"
        case .arenaOpponent:    return "Pick Your Fight"
        case .arenaStance:      return "Combat Stance"
        case .shopGems:         return "Premium Currency"
        case .dungeonEntry:     return "Dungeons"
        }
    }

    /// User-facing description
    var message: String {
        switch self {
        case .hubCharacterCard:
            return "Tap your hero card to see stats, equipment, and inventory."
        case .hubCityMap:
            return "Tap buildings to visit the Arena, Shop, Dungeons, and more."
        case .hubDailyLogin:
            return "Claim free rewards every day — streaks give bonus loot!"
        case .hubStamina:
            return "Stamina refills over time. Tap here to buy potions when you run low."
        case .arenaOpponent:
            return "Choose an opponent wisely — check their level and class before fighting."
        case .arenaStance:
            return "Your stance affects attack and defense zones. Tap to change it before battle."
        case .shopGems:
            return "Gems buy rare items. Spend wisely — the game will ask you to confirm gem purchases."
        case .dungeonEntry:
            return "Clear dungeon floors for XP, gold, and unique equipment drops."
        }
    }

    /// Arrow direction — where the tooltip arrow points
    var arrowEdge: Edge {
        switch self {
        case .hubCharacterCard: return .top
        case .hubCityMap:       return .bottom
        case .hubDailyLogin:    return .trailing
        case .hubStamina:       return .top
        case .arenaOpponent:    return .bottom
        case .arenaStance:      return .top
        case .shopGems:         return .top
        case .dungeonEntry:     return .top
        }
    }

    /// NPC name displayed in storytelling dialogue
    var npcName: String {
        switch self {
        case .shopGems:         return "Merchant"
        case .arenaOpponent, .arenaStance: return "Arena Master"
        case .dungeonEntry:     return "Dungeon Keeper"
        default:                return "Guide"
        }
    }

    /// NPC image asset for storytelling portrait
    var npcImageAsset: String {
        switch self {
        case .shopGems:         return "shopkeeper"
        case .arenaOpponent, .arenaStance: return "npc-arena-master"
        case .dungeonEntry:     return "npc-dungeon-keeper"
        default:                return "shopkeeper"
        }
    }

    /// SF Symbol fallback if NPC image asset is missing
    var npcFallbackIcon: String {
        switch self {
        case .shopGems:         return "bag.fill"
        case .arenaOpponent, .arenaStance: return "shield.lefthalf.filled"
        case .dungeonEntry:     return "door.left.hand.open"
        default:                return "person.fill"
        }
    }
}

// MARK: - Tutorial Manager

/// Tracks which tutorial steps have been shown. Persists via UserDefaults.
@MainActor @Observable
final class TutorialManager {
    static let shared = TutorialManager()

    private(set) var completedSteps: Set<String>
    /// Currently visible tooltip (only one at a time)
    var activeStep: TutorialStep?

    private let defaults = UserDefaults.standard

    private init() {
        let saved = defaults.stringArray(forKey: AppConstants.udTutorialCompleted) ?? []
        completedSteps = Set(saved)
    }

    // MARK: - Public API

    /// Returns true if this step hasn't been shown yet.
    func shouldShow(_ step: TutorialStep) -> Bool {
        !completedSteps.contains(step.rawValue)
    }

    /// Try to present a tooltip. Only succeeds if no other tooltip is active
    /// and this step hasn't been completed yet.
    func tryShow(_ step: TutorialStep) {
        guard activeStep == nil, shouldShow(step) else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            activeStep = step
        }
    }

    /// Mark current step complete and dismiss.
    func dismiss() {
        guard let step = activeStep else { return }
        completedSteps.insert(step.rawValue)
        persist()
        withAnimation(.easeIn(duration: 0.2)) {
            activeStep = nil
        }
    }

    /// Skip all remaining tutorials.
    func skipAll() {
        for step in TutorialStep.allCases {
            completedSteps.insert(step.rawValue)
        }
        persist()
        withAnimation(.easeIn(duration: 0.2)) {
            activeStep = nil
        }
    }

    /// Reset tutorials (for dev/testing).
    func reset() {
        completedSteps.removeAll()
        persist()
        activeStep = nil
    }

    // MARK: - Persistence

    private func persist() {
        defaults.set(Array(completedSteps), forKey: AppConstants.udTutorialCompleted)
    }
}
