import SwiftUI

@MainActor @Observable
final class AppState {
    // MARK: - Auth
    var isAuthenticated = false
    var isGuest = false
    var pendingConfirmationEmail: String?
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

    // MARK: - FTUE
    var shouldCheckFTUE = false  // set true after first login to trigger tutorial check

    // MARK: - UI State
    var isLoading = false
    var toasts: [ToastMessage] = []
    var showDailyLoginPopup = false
    var hasAutoShownDailyLogin = false  // prevents auto-popup on every hub visit
    var dailyLoginCanClaim = false       // drives the hub widget badge
    var unreadMailCount = 0               // drives the inbox badge on hub

    // MARK: - Level Up Modal
    var showLevelUpModal = false
    var levelUpNewLevel: Int = 0
    var levelUpStatPoints: Int = 0

    func triggerLevelUpModal(newLevel: Int, statPoints: Int) {
        levelUpNewLevel = newLevel
        levelUpStatPoints = statPoints
        enqueueModal(.levelUp)
    }

    func dismissLevelUpModal() {
        withAnimation(.easeOut(duration: MotionConstants.overlayFade)) {
            showLevelUpModal = false
        }
        // Show next queued modal after brief delay
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            self?.presentNextModal()
        }
    }

    // MARK: - Modal Queue (prevents overlapping modals)

    enum ModalType: Equatable {
        case dailyLogin
        case levelUp
    }

    var modalQueue: [ModalType] = []

    func enqueueModal(_ modal: ModalType) {
        // Don't enqueue duplicates
        guard !modalQueue.contains(modal) else { return }
        modalQueue.append(modal)

        // If nothing is showing, present immediately
        if !showLevelUpModal && !showDailyLoginPopup {
            presentNextModal()
        }
    }

    func presentNextModal() {
        guard !modalQueue.isEmpty else { return }
        // Don't present if something is already showing
        guard !showLevelUpModal && !showDailyLoginPopup else { return }

        let next = modalQueue.removeFirst()
        switch next {
        case .levelUp:
            HapticManager.rankUp()
            withAnimation(MotionConstants.dramatic) {
                showLevelUpModal = true
            }
        case .dailyLogin:
            HapticManager.medium()
            withAnimation(MotionConstants.spring) {
                showDailyLoginPopup = true
            }
        }
    }

    func dismissDailyLoginPopup() {
        withAnimation(.easeOut(duration: MotionConstants.overlayFade)) {
            showDailyLoginPopup = false
        }
        // Pause between modals so transitions don't overlap
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            self?.presentNextModal()
        }
    }

    // MARK: - Methods

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func showToast(_ title: String, subtitle: String = "", type: ToastType = .info, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        let toast = ToastMessage(title: title, subtitle: subtitle, type: type, actionLabel: actionLabel, action: action)
        self.toasts.append(toast)

        let duration: Double = action != nil ? 5 : 3  // longer for actionable toasts
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
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
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
}

enum ToastType {
    case achievement, levelUp, rankUp, quest, reward, info, error

    var color: Color {
        switch self {
        case .achievement: DarkFantasyTheme.toastAchievement
        case .levelUp: DarkFantasyTheme.toastLevelUp
        case .rankUp: DarkFantasyTheme.toastRankUp
        case .quest: DarkFantasyTheme.toastQuest
        case .reward: DarkFantasyTheme.toastReward
        case .info: DarkFantasyTheme.toastInfo
        case .error: DarkFantasyTheme.toastError
        }
    }
}
