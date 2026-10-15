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
    var pendingPushRoute: AppRoute?

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
    /// Dice combat in Dungeon Rush: the settled room result, handed from the
    /// battle screen back to `DungeonRushViewModel` when the rush view reappears.
    var pendingRushFightResult: DungeonRushFightResponse?

    // MARK: - Cache
    var cachedInventory: [Item]?
    var cachedTypedQuests: [Quest]?
    var cachedDailyLogin: DailyLoginData?
    var cachedBonusClaimedToday = false

    // MARK: - Dungeon
    var selectedDungeonId: String?

    /// Set by entry points outside the Hub (daily quests, contextual hints,
    /// etc.) that want the player to land on the dungeon map *with* the full
    /// hub HUD (hero card, floating icons, ADVENTURES/CASTLE button) rather
    /// than the bare standalone `DungeonMapView`. HubView consumes the flag
    /// in `.onAppear`, flips `showDungeonMap = true`, and clears it.
    var pendingShowDungeonMap = false

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
    var dailyLoginCanClaim = false       // drives the hub widget badge
    var unreadMailCount = 0               // drives the inbox badge on hub

    // MARK: - Boss Reveal Overlay
    //
    // Root-level ceremonial intro for new bosses. Two call sites:
    //   1. DungeonSelectViewModel — once-per-boss on first unlock
    //      (locked → current), gated by UserDefaults cache.
    //   2. DungeonRushViewModel — every miniboss room reveal.
    //
    // Lives at root in HexboundApp.swift so the overlay survives
    // NavigationStack pushes / `currentScreen` transitions that would
    // otherwise tear it down mid-choreography.
    // Both of these now read the modal queue (see ModalType below), so a
    // reveal waits its turn behind a level-up instead of landing on top of
    // it. The payload used to be a second stored property cleared 350 ms
    // after the flag; it is the queue entry itself now, and the removal
    // transition plays from the `withAnimation` in `dismissActiveModal()`.
    var isBossRevealing: Bool { activeModal?.kind == .bossReveal }

    var pendingBossReveal: BossRevealData? {
        if case .bossReveal(let data) = activeModal { return data }
        return nil
    }

    func presentBossReveal(_ data: BossRevealData) {
        enqueueModal(.bossReveal(data))
    }

    func dismissBossReveal() {
        guard activeModal?.kind == .bossReveal else { return }
        dismissActiveModal()
    }

    // MARK: - Rank Up Ceremony
    //
    // Queued like everything else, which matters here: a fight that levels
    // the player up AND promotes them enqueues both, and they play one after
    // the other instead of landing on top of each other.
    var activeRankUp: RankUpData? {
        if case .rankUp(let data) = activeModal { return data }
        return nil
    }

    func presentRankUp(_ data: RankUpData) {
        enqueueModal(.rankUp(data))
    }

    func dismissRankUp() {
        guard activeModal?.kind == .rankUp else { return }
        dismissActiveModal()
    }

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

    // MARK: - Push Deep Links

    func handlePushRoute(_ route: AppRoute) {
        if currentScreen == .game {
            mainPath.append(route)
        } else {
            pendingPushRoute = route
        }
    }

    func consumePendingPushRouteIfNeeded() {
        guard currentScreen == .game, let route = pendingPushRoute else { return }
        pendingPushRoute = nil
        mainPath.append(route)
    }

    // MARK: - Session Expired Modal
    var showSessionExpiredModal = false

    // MARK: - Claim Reward Modal (root-level)
    // Used by call sites that have no own VM (e.g. ActiveQuestBanner, Hub cards)
    // so they can surface a CLAIMED ceremony instead of a toast.
    //
    // Still assigned the same way — `appState.claimRewardConfig = cfg` to
    // present, `= nil` to dismiss — but it is backed by the modal queue now,
    // so it can no longer appear on top of a level-up. Screens that own a
    // view model keep their own `claimRewardConfig`; those are in-screen and
    // not part of this race.
    var claimRewardConfig: ClaimRewardConfig? {
        get {
            if case .claimReward(let config) = activeModal { return config }
            return nil
        }
        set {
            if let newValue {
                enqueueModal(.claimReward(newValue))
            } else if activeModal?.kind == .claimReward {
                dismissActiveModal()
            }
        }
    }

    /// Read by the root overlay chain in `HexboundApp`. Writes go through
    /// `enqueueModal(.dailyLogin)` / `dismissDailyLoginPopup()`; nothing
    /// outside AppState ever set this flag directly.
    var showDailyLoginPopup: Bool { activeModal?.kind == .dailyLogin }

    // MARK: - Level Up Modal
    var showLevelUpModal: Bool { activeModal?.kind == .levelUp }
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
    /// between `fromLevel` (exclusive) and `toLevel` (inclusive), deduped
    /// against already-pending. Lv 12 now crosses two thresholds at once
    /// (guild hall + black market), which the queue already handles.
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
        guard activeModal?.kind == .levelUp else { return }
        dismissActiveModal()
    }

    func dismissDailyLoginPopup() {
        guard activeModal?.kind == .dailyLogin else { return }
        dismissActiveModal()
    }

    // MARK: - Modal Queue (prevents overlapping modals)
    //
    // One root ceremony at a time. Until 2026-10-14 the queue knew only
    // two of them and decided whether it was busy with the expression
    // `!showLevelUpModal && !showDailyLoginPopup`, written out twice. The
    // boss reveal and the root claim-reward modal had their own stored
    // flags and never consulted it, so either could mount on top of a
    // level-up — two dimmed backdrops and two cards, with the one
    // underneath unreachable.

    enum ModalType {
        case dailyLogin
        case levelUp
        case claimReward(ClaimRewardConfig)
        case bossReveal(BossRevealData)
        case rankUp(RankUpData)

        /// The case without its payload. Both payloads carry closures, so
        /// `ModalType` cannot be `Equatable`; comparing kinds is what the
        /// queue actually needs.
        enum Kind { case dailyLogin, levelUp, claimReward, bossReveal, rankUp }

        var kind: Kind {
            switch self {
            case .dailyLogin: .dailyLogin
            case .levelUp: .levelUp
            case .claimReward: .claimReward
            case .bossReveal: .bossReveal
            case .rankUp: .rankUp
            }
        }

        /// Whether the music steps out while this is on screen. The two
        /// cinematic beats take the room; a level-up or a claimed reward is
        /// routine and plays over the track like everything else.
        var ducksMusic: Bool {
            switch kind {
            case .bossReveal, .rankUp: true
            case .dailyLogin, .levelUp, .claimReward: false
            }
        }

        /// True for the ceremonies that say the same thing every time, so a
        /// second enqueue is the same modal and can be dropped. A second
        /// claimed reward or a second boss is not — each carries its own
        /// payload and has to be shown.
        var isIdempotent: Bool {
            switch kind {
            case .dailyLogin, .levelUp: true
            case .claimReward, .bossReveal, .rankUp: false
            }
        }
    }

    /// The ceremony on screen right now, or nil. The single source of truth
    /// for "is a root modal up?".
    var activeModal: ModalType?
    var modalQueue: [ModalType] = []

    func enqueueModal(_ modal: ModalType) {
        if modal.isIdempotent {
            guard activeModal?.kind != modal.kind else { return }
            guard !modalQueue.contains(where: { $0.kind == modal.kind }) else { return }
        }
        modalQueue.append(modal)
        if activeModal == nil {
            presentNextModal()
        }
    }

    func presentNextModal() {
        guard activeModal == nil, !modalQueue.isEmpty else { return }

        let next = modalQueue.removeFirst()
        if next.ducksMusic {
            AudioManager.shared.duckBGM(for: .ceremony)
        }
        switch next.kind {
        case .levelUp:
            HapticManager.rankUp()
            withAnimation(MotionConstants.dramatic) { activeModal = next }
        case .dailyLogin:
            HapticManager.medium()
            withAnimation(MotionConstants.spring) { activeModal = next }
        case .bossReveal:
            withAnimation(.easeInOut(duration: MotionConstants.overlayFade)) { activeModal = next }
        case .claimReward:
            withAnimation(MotionConstants.snappy) { activeModal = next }
        case .rankUp:
            HapticManager.rankUp()
            withAnimation(MotionConstants.dramatic) { activeModal = next }
        }
    }

    /// Dismiss whatever is on screen and hand over to the next in line after
    /// a beat, so two transitions never overlap.
    func dismissActiveModal() {
        guard let closing = activeModal else { return }
        if closing.ducksMusic {
            AudioManager.shared.restoreBGM(for: .ceremony)
        }
        withAnimation(.easeOut(duration: MotionConstants.overlayFade)) {
            activeModal = nil
        }
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
        currentScreen = .characterSelect
    }

    func logout() {
        currentScreen = .auth
        isGuest = false
        currentCharacter = nil
        userCharacters = []
        currentUser = nil
        ObservabilityService.setUser(id: nil)
        combatData = nil
        combatResult = nil
        pendingLoot = []
        resolveResult = nil
        cachedInventory = nil
        cachedTypedQuests = nil
        cachedDailyLogin = nil
        cachedBonusClaimedToday = false
        // A logout mid-ceremony would otherwise leave the music ducked
        // with nothing left to restore it.
        AudioManager.shared.restoreBGM(for: .ceremony)
        activeModal = nil
        modalQueue.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.dailyLoginShownKey)
        dailyLoginCanClaim = false
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
