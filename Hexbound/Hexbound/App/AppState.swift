import SwiftUI

@MainActor @Observable
final class AppState {
    // MARK: - App Screen (3-state navigation)
    enum AppScreen: Equatable {
        case auth             // not logged in → AuthRouterView
        case characterSelect  // logged in, hero not chosen → CharacterSelectionView
        case loreIntro(heroName: String) // first hero just created → LoreIntroView
        case game             // logged in, hero chosen → MainRouterView
    }

    var currentScreen: AppScreen = .auth

    // MARK: - Auth
    var isAuthenticated: Bool {
        get { currentScreen == .game }
        set {
            // Legacy setter — bridges old code that sets isAuthenticated = true
            if newValue {
                currentScreen = .game
            } else {
                currentScreen = .auth
            }
        }
    }
    var isGuest = false
    var pendingConfirmationEmail: String?
    var currentUser: [String: Any]?

    /// True if the logged-in user has admin role (used to show dev tools)
    var isAdmin: Bool {
        (currentUser?["role"] as? String) == "admin"
    }

    // MARK: - Character
    var currentCharacter: Character?
    var userCharacters: [Character] = []

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

    // MARK: - Celebration Banner (Layer 3 — milestone events)
    var celebrationBanner: CelebrationBanner?
    private var celebrationDismissTask: Task<Void, Never>?

    func showCelebration(_ type: CelebrationType, title: String, subtitle: String = "") {
        // Cancel pending dismiss
        celebrationDismissTask?.cancel()

        HapticManager.medium()
        withAnimation(MotionConstants.spring) {
            celebrationBanner = CelebrationBanner(type: type, title: title, subtitle: subtitle)
        }

        // Auto-dismiss after duration
        let duration = type.displayDuration
        celebrationDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.dismissCelebration()
        }
    }

    func dismissCelebration() {
        celebrationDismissTask?.cancel()
        withAnimation(.easeOut(duration: MotionConstants.overlayFade)) {
            celebrationBanner = nil
        }
    }

    // MARK: - Session Expired Modal
    var showSessionExpiredModal = false

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
        // Deduplicate: if a toast with the same title already exists, reset its timer instead of adding a new one
        if let existingIndex = toasts.firstIndex(where: { $0.title == title }) {
            // Remove old toast and re-add with fresh timer (resets auto-dismiss)
            toasts.remove(at: existingIndex)
            let toast = ToastMessage(title: title, subtitle: subtitle, type: type, actionLabel: actionLabel, action: action)
            toasts.append(toast)
            scheduleToastDismissal(toast, duration: action != nil ? 5 : 3)
            return
        }

        let toast = ToastMessage(title: title, subtitle: subtitle, type: type, actionLabel: actionLabel, action: action)

        // Limit: max 1 visible toast — new one replaces old one
        if !toasts.isEmpty {
            toasts.removeAll()
        }
        toasts.append(toast)
        scheduleToastDismissal(toast, duration: action != nil ? 5 : 3)
    }

    func dismissToast(_ id: UUID) {
        toasts.removeAll { $0.id == id }
    }

    private func scheduleToastDismissal(_ toast: ToastMessage, duration: Double) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            self?.toasts.removeAll { $0.id == toast.id }
        }
    }

    /// Show session expired as a blocking modal instead of a dismissable toast.
    /// Call this from the 401 handler instead of showing a toast.
    func triggerSessionExpired() {
        // Dismiss any existing toasts — session expired takes priority
        toasts.removeAll()
        withAnimation(MotionConstants.spring) {
            showSessionExpiredModal = true
        }
    }

    func dismissSessionExpiredAndLogout() {
        withAnimation(.easeOut(duration: MotionConstants.overlayFade)) {
            showSessionExpiredModal = false
        }
        logout()
    }

    /// Switch back to character selection screen (from Settings or after character creation)
    func switchToCharacterSelect() {
        currentCharacter = nil
        mainPath = NavigationPath()
        selectedTab = .hub
        currentScreen = .characterSelect
    }

    func logout() {
        currentScreen = .auth
        isGuest = false
        currentCharacter = nil
        userCharacters = []
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

// MARK: - Celebration Banner

struct CelebrationBanner: Identifiable {
    let id = UUID()
    let type: CelebrationType
    let title: String
    let subtitle: String
}

enum CelebrationType {
    case achievement
    case levelUp
    case rankUp
    case questComplete
    case rareDrop
    case dungeonClear

    var color: Color {
        switch self {
        case .achievement: DarkFantasyTheme.toastAchievement
        case .levelUp: DarkFantasyTheme.toastLevelUp
        case .rankUp: DarkFantasyTheme.toastRankUp
        case .questComplete: DarkFantasyTheme.toastQuest
        case .rareDrop: DarkFantasyTheme.toastReward
        case .dungeonClear: DarkFantasyTheme.toastQuest
        }
    }

    var icon: String {
        switch self {
        case .achievement: "trophy.fill"
        case .levelUp: "arrow.up.circle.fill"
        case .rankUp: "crown.fill"
        case .questComplete: "scroll.fill"
        case .rareDrop: "sparkles"
        case .dungeonClear: "flag.checkered"
        }
    }

    /// How long the banner stays visible (seconds)
    var displayDuration: Double {
        switch self {
        case .levelUp, .rankUp: 4.0
        case .achievement, .dungeonClear: 3.5
        case .questComplete, .rareDrop: 3.0
        }
    }
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

    /// SF Symbol icon for each toast type — replaces the 8px colored dot for better a11y (color + icon + text)
    var icon: String {
        switch self {
        case .achievement: "trophy.fill"
        case .levelUp: "arrow.up.circle.fill"
        case .rankUp: "crown.fill"
        case .quest: "scroll.fill"
        case .reward: "gift.fill"
        case .info: "info.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }
}
