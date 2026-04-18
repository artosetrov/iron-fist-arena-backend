import SwiftUI

struct CurrentUserSnapshot: Codable {
    let id: String
    let email: String?
    let username: String?
    let gold: Int
    let gems: Int
    let premiumUntil: String?
    let role: String?
    let createdAt: String?
    let lastLogin: String?
}

@MainActor @Observable
final class AppState {
    // MARK: - App Screen (onboarding-reordered navigation)
    //
    // W2.D2 R1 — onboarding flow reorder (tutorial BEFORE cinematic):
    //   characterSelect → cinematicOpen → scriptedTutorial → tutorialVictory → loreIntro → game
    //
    // Rationale: Epic Seven pattern. Cinematic lore is a reward for earning your
    // first victory, not an unskippable gate between creation and gameplay.
    // See: docs/07_ui_ux/W2_D2_REALITY_CHECK.md
    enum AppScreen: Equatable {
        case auth                              // not logged in → AuthRouterView
        case characterSelect                   // logged in, hero not chosen → CharacterSelectionView
        case cinematicOpen(heroName: String)   // W2.D2 R2 — 10-15s cold-open (typewriter + ambient SFX)
        case scriptedTutorial(heroName: String) // W2.D3 — scripted first fight (guaranteed win)
        case tutorialVictory(heroName: String) // W2.D3 — victory overlay with reward reveal
        case loreIntro(heroName: String)       // existing — OnboardingCinematicView (now AFTER victory)
        case game                              // logged in, hero chosen → MainRouterView
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
    var currentUser: CurrentUserSnapshot?

    /// True if the logged-in user has admin role (used to show dev tools)
    var isAdmin: Bool {
        currentUser?.role == "admin"
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
    var pendingLoot: [PendingLootItem] = []
    var resolveResult: ResolveResult?

    // MARK: - Interactive Combat v1 Fallback
    //
    // When /pvp/match/start returns 404 (feature flag on client but endpoint
    // not deployed / rolled back on server), `InteractiveBattleView` sets
    // `interactiveCombatLocallyDisabled = true` for the rest of the session
    // and sets `pendingClassicFightOpponentId` so `ArenaDetailView` re-runs
    // `fight(opponentId:, forceClassic: true)` automatically.
    var interactiveCombatLocallyDisabled = false
    var pendingClassicFightOpponentId: String?

    // MARK: - Cache
    var cachedInventory: [Item]?
    var cachedTypedQuests: [Quest]?
    var cachedDailyLogin: DailyLoginData?
    var cachedBonusClaimedToday = false

    // MARK: - Dungeon
    var selectedDungeonId: String?

    // MARK: - Shop
    var shopInitialTab: Int = 0

    // MARK: - FTUE
    var shouldCheckFTUE = false  // set true after first login to trigger tutorial check

    // MARK: - Scripted Tutorial (W2.D3)
    /// Rewards payload from the scripted tutorial fight, parked here so
    /// VictoryOverlayView can read it across the screen transition.
    /// Cleared when the player enters the hub.
    var tutorialRewards: TutorialRewardsPayload?
    /// Pending building unlocks queued from level up during tutorial — consumed
    /// by the hub via BuildingUnlockCeremony on first mount.
    var pendingBuildingUnlocks: [String] = []

    /// Pending dungeon unlocks (slugs) — enqueued by `DungeonRoomViewModel`
    /// when the player clears a dungeon and the next one in the sequence
    /// just became available. Consumed by `DungeonUnlockCeremonyHost`
    /// attached on top of `DungeonMapView`.
    var pendingDungeonUnlocks: [String] = []

    // MARK: - UI State
    var isLoading = false
    var toasts: [ToastMessage] = []
    var showDailyLoginPopup = false
    var dailyLoginCanClaim = false       // drives the hub widget badge
    var unreadMailCount = 0               // drives the inbox badge on hub

    // MARK: - Hero Forge Overlay (BUG-08)
    //
    // Root-level "Forging Your Hero..." loading overlay owned by HexboundApp.
    // Driven by OnboardingViewModel.createCharacter() — raised before the API
    // call, lowered after the destination screen (`.loreIntro` / `.characterSelect`)
    // has had a chance to mount its first frame. Lives at root so the loading
    // UI persists across the cross-fade between OnboardingDetailView and the
    // destination view, eliminating the black gap where the old inline overlay
    // used to disappear mid-transition.
    var isForgingHero = false

    // MARK: - Daily Login "shown today" (BUG-53)
    //
    // Persisted in UserDefaults by calendar day so auto-open survives every
    // `.task` re-fire path that exists — NavigationStack pop-back, hot reload,
    // multiple GameInitService calls, etc. The previous `hasAutoShownDailyLogin`
    // bool lived only in memory and was trivially bypassed by any code path
    // that bypassed `checkLogin()`.
    //
    // Decision rule: auto-open once per *local calendar day*. Manual taps on
    // the hub tile also mark "shown today" so a subsequent app relaunch on the
    // same day doesn't reopen automatically.
    private static let dailyLoginShownKey = "dailyLoginAutoShownDate"

    var dailyLoginShownToday: Bool {
        guard let date = UserDefaults.standard.object(forKey: Self.dailyLoginShownKey) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(date)
    }

    func markDailyLoginShownToday() {
        UserDefaults.standard.set(Date(), forKey: Self.dailyLoginShownKey)
    }

    /// Enqueue the Daily Login modal iff the server says a reward is claimable
    /// AND the player hasn't already been shown the modal today. Single source
    /// of truth for "should we open it?" logic — called from GameInitService
    /// after /game/init populates `cachedDailyLogin`.
    func maybeEnqueueDailyLogin() {
        guard let cached = cachedDailyLogin,
              cached.canClaim else {
            dailyLoginCanClaim = false
            return
        }
        dailyLoginCanClaim = true
        guard !dailyLoginShownToday else { return }
        markDailyLoginShownToday()
        enqueueModal(.dailyLogin)
    }

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

    // MARK: - Claim Reward Modal (root-level)
    // Used by call sites that have no own VM (e.g. ActiveQuestBanner, Hub cards)
    // so they can surface a CLAIMED ceremony instead of a toast.
    var claimRewardConfig: ClaimRewardConfig?

    // MARK: - Level Up Modal
    var showLevelUpModal = false
    var levelUpNewLevel: Int = 0
    var levelUpStatPoints: Int = 0
    var levelUpPassivePoints: Int = 0

    func triggerLevelUpModal(
        newLevel: Int,
        statPoints: Int,
        passivePoints: Int = 0,
        previousLevel: Int? = nil
    ) {
        levelUpNewLevel = newLevel
        levelUpStatPoints = statPoints
        levelUpPassivePoints = passivePoints
        // W2.D4 — enqueue building unlock ceremonies for every threshold
        // crossed between the old level and the new one. We use the character
        // cache's level as the "from" reference because server just returned
        // newLevel and the modal will reload character afterwards.
        let rawFromLevel = previousLevel ?? (currentCharacter?.level ?? (newLevel - 1))
        let fromLevel = min(rawFromLevel, newLevel - 1)
        enqueueBuildingUnlocks(fromLevel: fromLevel, toLevel: newLevel)
        enqueueModal(.levelUp)
    }

    /// W2.D4 — queue building unlock ceremonies for any threshold crossed
    /// between `fromLevel` (exclusive) and `toLevel` (inclusive). Skips the
    /// Lv99 "Coming Soon" buildings and dedupes against already-pending.
    func enqueueBuildingUnlocks(fromLevel: Int, toLevel: Int) {
        guard toLevel > fromLevel else { return }
        var newUnlocks: [String] = []
        for lvl in (fromLevel + 1)...toLevel {
            let ids = BuildingUnlockConfig.buildingsUnlocking(at: lvl)
            for id in ids where !pendingBuildingUnlocks.contains(id) && !newUnlocks.contains(id) {
                newUnlocks.append(id)
            }
        }
        if !newUnlocks.isEmpty {
            pendingBuildingUnlocks.append(contentsOf: newUnlocks)
        }
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

    /// Reload character data from the server (e.g. after gold/XP changes)
    func reloadCharacter() async {
        let charService = CharacterService(appState: self)
        await charService.loadCharacter()
    }

    /// Apply server-authoritative reward / progression values to the cached
    /// character so HUD-level state updates immediately after a claim.
    @discardableResult
    func applyAuthoritativeRewardState(
        gold: Int? = nil,
        gems: Int? = nil,
        xp: Int? = nil,
        leveledUp: Bool? = nil,
        newLevel: Int? = nil,
        statPointsAwarded: Int? = nil,
        passivePointsAwarded: Int? = nil,
        previousLevel: Int? = nil
    ) -> Bool {
        guard var char = currentCharacter else { return false }

        let levelBefore = previousLevel ?? char.level

        if let gold {
            char.gold = gold
        }
        if let gems {
            char.gems = gems
        }
        if let xp {
            char.experience = xp
        }

        let didLevelUp = leveledUp == true && newLevel != nil

        if didLevelUp, let newLevel {
            char.level = newLevel
        }
        if didLevelUp, let statPointsAwarded, statPointsAwarded > 0 {
            char.statPoints = (char.statPoints ?? 0) + statPointsAwarded
        }
        if didLevelUp, let passivePointsAwarded, passivePointsAwarded > 0 {
            char.passivePointsAvailable = (char.passivePointsAvailable ?? 0) + passivePointsAwarded
        }

        currentCharacter = char

        if didLevelUp, let newLevel {
            triggerLevelUpModal(
                newLevel: newLevel,
                statPoints: statPointsAwarded ?? 0,
                passivePoints: passivePointsAwarded ?? 0,
                previousLevel: levelBefore
            )
        }

        return didLevelUp
    }

    func showToast(_ title: String, subtitle: String = "", type: ToastType = .info, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        // Deduplicate: if a toast with the same (title + type + subtitle) already exists, reset its timer
        if let existingIndex = toasts.firstIndex(where: { $0.title == title && $0.type == type && $0.subtitle == subtitle }) {
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
        cachedTypedQuests = nil
        cachedDailyLogin = nil
        cachedBonusClaimedToday = false
        UserDefaults.standard.removeObject(forKey: Self.dailyLoginShownKey)
        dailyLoginCanClaim = false
        selectedTab = .hub
        authPath = NavigationPath()
        mainPath = NavigationPath()
        KeychainManager.shared.clearAll()
    }

    func invalidateCache(_ key: String) {
        switch key {
        case "inventory": cachedInventory = nil
        case "quests": cachedTypedQuests = nil
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
    case achievement, levelUp, rankUp, quest, reward, success, info, error

    var color: Color {
        switch self {
        case .achievement: DarkFantasyTheme.toastAchievement
        case .levelUp: DarkFantasyTheme.toastLevelUp
        case .rankUp: DarkFantasyTheme.toastRankUp
        case .quest: DarkFantasyTheme.toastQuest
        case .reward: DarkFantasyTheme.toastReward
        case .success: DarkFantasyTheme.success
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
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }
}
