import SwiftUI

@MainActor @Observable
final class AppState {
    // MARK: - Auth
    var isAuthenticated = false
    var currentUser: [String: Any]?

    // MARK: - Character
    var currentCharacter: Character?

    // MARK: - Navigation
    var authPath = NavigationPath()
    var mainPath = NavigationPath()
    var selectedTab: HubTab = .hub

    // MARK: - Combat
    var combatData: CombatData?
    var combatResult: CombatData?
    var pendingLoot: [[String: Any]] = []
    var resolveResult: ResolveResult?

    // MARK: - Cache
    var cachedInventory: [Item]?
    var cachedQuests: [[String: Any]]?
    var cachedTypedQuests: [Quest]?
    var cachedAchievements: [[String: Any]]?
    var cachedDailyLogin: [String: Any]?
    var cachedBonusClaimedToday = false

    // MARK: - Dungeon
    var selectedDungeonId: String?

    // MARK: - Shop
    var shopInitialTab: Int = 0

    // MARK: - UI State
    var isLoading = false
    var toasts: [ToastMessage] = []
    var showDailyLoginPopup = false
    var hasAutoShownDailyLogin = false  // prevents auto-popup on every hub visit
    var dailyLoginCanClaim = false       // drives the hub widget badge

    // MARK: - Level Up Modal
    var showLevelUpModal = false
    var levelUpNewLevel: Int = 0
    var levelUpStatPoints: Int = 0

    func triggerLevelUpModal(newLevel: Int, statPoints: Int) {
        levelUpNewLevel = newLevel
        levelUpStatPoints = statPoints
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showLevelUpModal = true
        }
    }

    func dismissLevelUpModal() {
        withAnimation(.easeOut(duration: 0.25)) {
            showLevelUpModal = false
        }
    }

    // MARK: - Methods

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func showToast(_ title: String, subtitle: String = "", type: ToastType = .info) {
        let toast = ToastMessage(title: title, subtitle: subtitle, type: type)
        self.toasts.append(toast)

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            self?.toasts.removeAll { $0.id == toast.id }
        }
    }

    func logout() {
        isAuthenticated = false
        currentCharacter = nil
        currentUser = nil
        combatData = nil
        combatResult = nil
        pendingLoot = []
        resolveResult = nil
        cachedInventory = nil
        cachedQuests = nil
        cachedTypedQuests = nil
        cachedAchievements = nil
        cachedDailyLogin = nil
        cachedBonusClaimedToday = false
        hasAutoShownDailyLogin = false
        dailyLoginCanClaim = false
        selectedTab = .hub
        authPath = NavigationPath()
        mainPath = NavigationPath()
        KeychainManager.shared.clearAll()
    }

    func invalidateCache(_ key: String) {
        switch key {
        case "inventory": cachedInventory = nil
        case "quests": cachedQuests = nil; cachedTypedQuests = nil
        case "achievements": cachedAchievements = nil
        case "daily_login": cachedDailyLogin = nil
        default: break
        }
    }
}

// MARK: - Toast

struct ToastMessage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let type: ToastType
}

enum ToastType {
    case achievement, levelUp, rankUp, quest, reward, info, error

    var color: Color {
        switch self {
        case .achievement: Color(red: 1.0, green: 0.85, blue: 0.2)
        case .levelUp: Color(red: 0.4, green: 1.0, blue: 0.4)
        case .rankUp: Color(red: 0.6, green: 0.4, blue: 1.0)
        case .quest: Color(red: 0.3, green: 0.85, blue: 1.0)
        case .reward: Color(red: 1.0, green: 0.65, blue: 0.2)
        case .info: Color(red: 0.8, green: 0.8, blue: 0.85)
        case .error: Color(red: 1.0, green: 0.35, blue: 0.35)
        }
    }
}
