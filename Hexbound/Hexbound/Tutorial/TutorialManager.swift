import SwiftUI

// MARK: - FTUE Objective Definitions (3-Step Guided Onboarding)

/// First-Time User Experience objectives — shown as a full screen after character creation.
/// These are the "big 3" guided steps, NOT the contextual tooltips (those are `TutorialStep`).
enum FTUEObjective: String, CaseIterable, Identifiable {
    case firstBattle   = "ftue_first_battle"
    case gearUp        = "ftue_gear_up"
    case exploreDungeon = "ftue_explore_dungeon"

    var id: String { rawValue }

    /// Display order index (0-based)
    var index: Int {
        switch self {
        case .firstBattle:    return 0
        case .gearUp:         return 1
        case .exploreDungeon: return 2
        }
    }

    /// User-facing title
    var title: String {
        switch self {
        case .firstBattle:    return "FIRST BATTLE"
        case .gearUp:         return "GEAR UP"
        case .exploreDungeon: return "EXPLORE DUNGEON"
        }
    }

    /// User-facing description
    var subtitle: String {
        switch self {
        case .firstBattle:    return "Fight your first opponent in the Arena"
        case .gearUp:         return "Equip your first item from the Shop"
        case .exploreDungeon: return "Complete Floor 1 of the Normal Dungeon"
        }
    }

    /// Icon asset name (game assets, not SF Symbols)
    var iconAsset: String {
        switch self {
        case .firstBattle:    return "icon-fights"
        case .gearUp:         return "icon-equipment"
        case .exploreDungeon: return "icon-dungeon"
        }
    }

    /// SF Symbol fallback if icon asset missing
    var fallbackIcon: String {
        switch self {
        case .firstBattle:    return "shield.lefthalf.filled"
        case .gearUp:         return "bag.fill"
        case .exploreDungeon: return "door.left.hand.open"
        }
    }

    /// Reward description text
    var rewardText: String {
        switch self {
        case .firstBattle:    return "50 Gold + 25 XP"
        case .gearUp:         return "100 Gold"
        case .exploreDungeon: return "3 Gems"
        }
    }

    /// NPC dialog for this step
    var npcDialog: String {
        switch self {
        case .firstBattle:
            return "Welcome, adventurer! Head to the Arena and prove your mettle in combat. Even a loss teaches you something."
        case .gearUp:
            return "Well done! Now visit the Shop and equip something useful. Even the simplest armor is better than bare skin!"
        case .exploreDungeon:
            return "You're getting stronger! The Dungeons hold rare treasures and powerful foes. Complete Floor 1 to earn Gems."
        }
    }

    /// CTA button label
    var ctaLabel: String {
        switch self {
        case .firstBattle:    return "GO TO ARENA"
        case .gearUp:         return "GO TO SHOP"
        case .exploreDungeon: return "GO TO DUNGEON"
        }
    }

    /// The required previous objective (nil for first step)
    var prerequisite: FTUEObjective? {
        switch self {
        case .firstBattle:    return nil
        case .gearUp:         return .firstBattle
        case .exploreDungeon: return .gearUp
        }
    }
}

// MARK: - FTUE State

enum FTUEObjectiveState {
    case completed
    case current
    case locked
}

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

// MARK: - Server Tutorial DTOs

struct TutorialQuestState: Decodable, Identifiable, Equatable {
    let id: String
    let questId: String
    let target: Int
    let progress: Int
    let isCompleted: Bool
    let rewardClaimed: Bool
    let title: String?
    let npcMessage: String?
}

struct AvailableTutorialQuest: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let npcMessage: String
    let target: Int
}

struct TutorialStateResponse: Decodable {
    let tutorialStep: Int
    let tutorialSkipped: Bool
    let referralCode: String?
    let unlockedBuildings: [String: Bool]
    let quests: [TutorialQuestState]
    let availableQuests: [AvailableTutorialQuest]
}

struct TutorialInitRequest: Encodable {
    let characterId: String
    let referralCode: String?
}

struct TutorialInitResponse: Decodable {
    let tutorialStep: Int
}

struct TutorialStepRequest: Encodable {
    let characterId: String
    let step: Int
}

struct TutorialStepResponse: Decodable {
    let tutorialStep: Int
}

struct TutorialSkipResponse: Decodable {
    let tutorialStep: Int
    let tutorialSkipped: Bool
}

enum TutorialQuestAction: String, Encodable {
    case progress
    case claim
}

struct TutorialQuestRequest: Encodable {
    let characterId: String
    let questId: String
    let action: TutorialQuestAction
    let amount: Int?
}

struct TutorialQuestProgressResponse: Decodable {
    let justCompleted: Bool
}

struct TutorialQuestRewardPayload: Decodable {
    let gold: Int?
    let itemCatalogId: String?
    let consumableType: String?
    let consumableAmount: Int?
}

struct TutorialQuestClaimResponse: Decodable {
    let claimed: Bool
    let goldDelta: Int?
    let rewards: TutorialQuestRewardPayload?
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

        let ftueSaved = defaults.stringArray(forKey: AppConstants.udFTUECompleted) ?? []
        ftueCompleted = Set(ftueSaved)
        ftueDismissed = defaults.bool(forKey: AppConstants.udFTUEDismissed)
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

    /// Mark onboarding complete (all hub intro steps).
    func completeHubOnboarding() {
        completedSteps.insert(TutorialStep.hubCharacterCard.rawValue)
        completedSteps.insert(TutorialStep.hubCityMap.rawValue)
        completedSteps.insert(TutorialStep.hubDailyLogin.rawValue)
        persist()
    }

    /// Reset tutorials (for dev/testing).
    func reset() {
        completedSteps.removeAll()
        persist()
        activeStep = nil
    }

    // MARK: - FTUE Objectives (3-Step Guided Onboarding)

    /// Completed FTUE objective IDs
    private(set) var ftueCompleted: Set<String>
    /// Whether user has dismissed the FTUE screen entirely
    private(set) var ftueDismissed: Bool

    /// State of a specific FTUE objective
    func ftueState(for objective: FTUEObjective) -> FTUEObjectiveState {
        if ftueCompleted.contains(objective.rawValue) {
            return .completed
        }
        // Current = first non-completed objective whose prerequisite is done
        if let prereq = objective.prerequisite {
            if ftueCompleted.contains(prereq.rawValue) {
                // Check no earlier uncompleted objective exists
                let isFirst = FTUEObjective.allCases
                    .first { !ftueCompleted.contains($0.rawValue) }
                return isFirst == objective ? .current : .locked
            }
            return .locked
        }
        // No prerequisite — current if not completed
        let isFirst = FTUEObjective.allCases
            .first { !ftueCompleted.contains($0.rawValue) }
        return isFirst == objective ? .current : .locked
    }

    /// The current active FTUE objective (first uncompleted)
    var currentFTUEObjective: FTUEObjective? {
        FTUEObjective.allCases.first { !ftueCompleted.contains($0.rawValue) }
    }

    /// Number of completed FTUE objectives
    var ftueCompletedCount: Int {
        FTUEObjective.allCases.filter { ftueCompleted.contains($0.rawValue) }.count
    }

    /// Whether all 3 FTUE objectives are done
    var isFTUEComplete: Bool {
        FTUEObjective.allCases.allSatisfy { ftueCompleted.contains($0.rawValue) }
    }

    /// Whether the FTUE screen should be shown
    var shouldShowFTUE: Bool {
        !ftueDismissed && !isFTUEComplete
    }

    /// Mark an FTUE objective as completed
    func completeFTUEObjective(_ objective: FTUEObjective) {
        ftueCompleted.insert(objective.rawValue)
        persistFTUE()
    }

    /// Dismiss the FTUE screen permanently
    func dismissFTUE() {
        ftueDismissed = true
        defaults.set(true, forKey: AppConstants.udFTUEDismissed)
    }

    /// Reset FTUE (for dev/testing)
    func resetFTUE() {
        ftueCompleted.removeAll()
        ftueDismissed = false
        persistFTUE()
        defaults.set(false, forKey: AppConstants.udFTUEDismissed)
    }

    private func persistFTUE() {
        defaults.set(Array(ftueCompleted), forKey: AppConstants.udFTUECompleted)
    }

    // MARK: - Server-Synced Tutorial (Hard Guided + Quests)

    /// Server tutorial step: 0=new, 1=weapon_equipped, 2=first_fight, 3=completed
    private(set) var serverTutorialStep: Int = 3
    /// Whether tutorial was skipped via "I'm experienced" button
    private(set) var tutorialSkipped: Bool = false
    /// Whether the hard guided tutorial should be shown
    var shouldShowHardTutorial: Bool {
        serverTutorialStep < 3 && !tutorialSkipped
    }
    /// Building unlock levels (mirrors server config)
    private(set) var unlockedBuildings: [String: Bool] = [:]
    /// Active tutorial quests from server
    private(set) var tutorialQuests: [TutorialQuestState] = []
    /// Available quests not yet started
    private(set) var availableQuests: [AvailableTutorialQuest] = []
    /// Referral code
    private(set) var referralCode: String?

    /// Fetch tutorial state from server
    func fetchTutorialState(characterId: String) async {
        do {
            let response: TutorialStateResponse = try await APIClient.shared.get(
                "/tutorial",
                params: ["character_id": characterId]
            )
            serverTutorialStep = response.tutorialStep
            tutorialSkipped = response.tutorialSkipped
            unlockedBuildings = response.unlockedBuildings
            tutorialQuests = response.quests
            availableQuests = response.availableQuests
            referralCode = response.referralCode
        } catch {
            // Silently fail — tutorial is non-critical
            #if DEBUG
            print("Tutorial state fetch failed:", error)
            #endif
        }
    }

    /// Initialize tutorial (claim welcome gift). Called after character creation.
    func initializeTutorial(characterId: String, referralCode: String? = nil) async -> Bool {
        do {
            let response: TutorialInitResponse = try await APIClient.shared.post(
                "/tutorial",
                body: TutorialInitRequest(characterId: characterId, referralCode: referralCode)
            )
            serverTutorialStep = response.tutorialStep
            return true
        } catch {
            #if DEBUG
            print("Tutorial init failed:", error)
            #endif
            return false
        }
    }

    /// Advance tutorial step on server
    func advanceTutorialStep(characterId: String) async -> Bool {
        let nextStep = serverTutorialStep + 1
        guard nextStep <= 3 else { return false }
        do {
            let response: TutorialStepResponse = try await APIClient.shared.post(
                "/tutorial/step",
                body: TutorialStepRequest(characterId: characterId, step: nextStep)
            )
            serverTutorialStep = response.tutorialStep
            return true
        } catch {
            #if DEBUG
            print("Tutorial step advance failed:", error)
            #endif
            return false
        }
    }

    /// Skip tutorial entirely
    func skipTutorial(characterId: String, referralCode: String? = nil) async -> Bool {
        do {
            let response: TutorialSkipResponse = try await APIClient.shared.post(
                "/tutorial/skip",
                body: TutorialInitRequest(characterId: characterId, referralCode: referralCode)
            )
            serverTutorialStep = response.tutorialStep
            tutorialSkipped = response.tutorialSkipped
            return true
        } catch {
            #if DEBUG
            print("Tutorial skip failed:", error)
            #endif
            return false
        }
    }

    /// Update quest progress on server
    func updateQuestProgress(characterId: String, questId: String, amount: Int = 1) async {
        do {
            let _: TutorialQuestProgressResponse = try await APIClient.shared.post(
                "/tutorial/quest",
                body: TutorialQuestRequest(
                    characterId: characterId,
                    questId: questId,
                    action: .progress,
                    amount: amount
                )
            )
            // Refresh state
            await fetchTutorialState(characterId: characterId)
        } catch {
            #if DEBUG
            print("Quest progress update failed:", error)
            #endif
        }
    }

    /// Claim quest reward
    func claimQuestReward(characterId: String, questId: String) async -> TutorialQuestClaimResponse? {
        do {
            let response: TutorialQuestClaimResponse = try await APIClient.shared.post(
                "/tutorial/quest",
                body: TutorialQuestRequest(
                    characterId: characterId,
                    questId: questId,
                    action: .claim,
                    amount: nil
                )
            )
            // Refresh state
            await fetchTutorialState(characterId: characterId)
            return response
        } catch {
            #if DEBUG
            print("Quest claim failed:", error)
            #endif
            return nil
        }
    }

    // MARK: - Persistence

    private func persist() {
        defaults.set(Array(completedSteps), forKey: AppConstants.udTutorialCompleted)
    }
}
