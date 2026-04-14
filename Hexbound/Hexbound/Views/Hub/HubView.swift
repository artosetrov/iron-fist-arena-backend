import SwiftUI

// MARK: - Map Transition Phase

/// Phases for the parallax + fade transition between Hub and Dungeon maps
enum MapTransitionPhase {
    case idle       // No transition in progress
    case fadingOut  // Current map fading out + parallax shifting away
    case switching  // Content swap (instant, hidden behind black)
    case fadingIn   // New map fading in + parallax settling into place
}

// MARK: - Hub View

struct HubView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var showDungeonMap = false
    @State private var hubHint: NPCHint?

    // Parallax + Fade transition state
    @State private var mapTransitionPhase: MapTransitionPhase = .idle

    // Onboarding flow state
    @State private var currentOnboardingStep = 0
    /// Latched once on appear — prevents NPC from vanishing mid-sequence
    /// when TutorialManager state changes (e.g. server sync completing).
    @State private var onboardingActive = false
    private let onboardingSteps = [
        (title: "Welcome, Adventurer!", message: "This is your Hub — the center of your journey."),
        (title: "Explore the City", message: "Visit the SHOP to gear up, the ARENA to fight other players, or the DUNGEON to explore."),
        (title: "Earn & Reward", message: "Check the GOLD MINE to earn gold, and don't forget your DAILY LOGIN rewards!")
    ]

    private var shouldShowOnboarding: Bool {
        // Use latched state — once onboarding starts, it stays active until
        // the user completes/dismisses all steps. Prevents NPC from vanishing
        // mid-sequence when TutorialManager syncs with server.
        return onboardingActive && currentOnboardingStep < onboardingSteps.count
    }

    // MARK: - Tutorial Quest Banner (NPC Quest Chain)

    /// Builds the TutorialQuestBanner for the first active (incomplete or unclaimed) quest
    @ViewBuilder
    private var tutorialQuestBanner: some View {
        let tutorial = TutorialManager.shared
        let quests = tutorial.tutorialQuests
        // Find the first quest that isn't fully claimed
        if let activeQuest = quests.first(where: { quest in
            let claimed = quest["rewardClaimed"] as? Bool ?? false
            return !claimed
        }),
           let questId = activeQuest["questId"] as? String,
           let title = activeQuest["title"] as? String ?? questTitle(for: questId),
           let npcMessage = activeQuest["npcMessage"] as? String ?? questNpcMessage(for: questId) {
            let progress = activeQuest["progress"] as? Int ?? 0
            let target = activeQuest["target"] as? Int ?? 1
            let isCompleted = activeQuest["isCompleted"] as? Bool ?? false
            let rewardClaimed = activeQuest["rewardClaimed"] as? Bool ?? false
            TutorialQuestBanner(
                questId: questId,
                title: title,
                npcMessage: npcMessage,
                progress: progress,
                target: target,
                isCompleted: isCompleted,
                rewardClaimed: rewardClaimed,
                onTap: { navigateToQuestTarget(questId) },
                onClaim: { claimQuestReward(questId) }
            )
        }
    }

    /// Navigate to the building associated with a quest
    private func navigateToQuestTarget(_ questId: String) {
        let routeMap: [String: AppRoute] = [
            "equip_gear": .shop,
            "win_3_pvp": .arena,
            "first_dungeon": .dungeonSelect,
            "start_mining": .goldMine,
            "try_tavern": .tavern,
            "explore_endgame": .battlePass,
            "join_guild": .guildHall,
        ]
        if let route = routeMap[questId] {
            appState.mainPath.append(route)
        }
    }

    /// Claim quest reward via TutorialManager
    private func claimQuestReward(_ questId: String) {
        guard let charId = appState.currentCharacter?.id else { return }
        Task {
            let result = await TutorialManager.shared.claimQuestReward(
                characterId: charId,
                questId: questId
            )
            if let gold = result?["goldAwarded"] as? Int, gold > 0 {
                appState.showToast("Reward claimed! +\(gold) gold", type: .success)
            } else {
                appState.showToast("Reward claimed!", type: .success)
            }
            // Refresh character data to update currency
            await appState.reloadCharacter()
        }
    }

    /// Fallback quest titles (matches backend TUTORIAL_QUESTS)
    private func questTitle(for questId: String) -> String? {
        let titles: [String: String] = [
            "equip_gear": "Warrior's Gear",
            "win_3_pvp": "Battle Hardened",
            "first_dungeon": "Into the Depths",
            "start_mining": "Gold Vein",
            "try_tavern": "Try Your Luck",
            "explore_endgame": "Path of Glory",
            "join_guild": "Brotherhood",
        ]
        return titles[questId]
    }

    /// Fallback NPC messages (matches backend TUTORIAL_QUESTS)
    private func questNpcMessage(for questId: String) -> String? {
        let messages: [String: String] = [
            "equip_gear": "You have a weapon, but your defense is lacking. Visit the Shop.",
            "win_3_pvp": "Win 3 more arena fights to gain experience.",
            "first_dungeon": "Dungeons lurk beneath the city. Defeat the first floor boss.",
            "start_mining": "The mine earns gold while you sleep. Start mining.",
            "try_tavern": "They gamble for gold at the tavern. Give it a try.",
            "explore_endgame": "The battle pass holds treasures. The leaderboard shows what you're made of.",
            "join_guild": "A lone wolf won't make it far. Join a guild.",
        ]
        return messages[questId]
    }

    var body: some View {
        VStack(spacing: 0) {
            // HUD widgets at top — stays in place during map transition
            VStack(spacing: LayoutConstants.spaceMS) {
                // Unified Hero Widget (replaces StaminaBarView + HubCharacterCardWrapper)
                if let char = appState.currentCharacter {
                    UnifiedHeroWidget(
                        character: char,
                        context: .hub,
                        onTap: { appState.mainPath.append(AppRoute.hero) }
                    )
                    .tutorialAnchor(.hubCharacterCard)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }

                // First Win Bonus — prominent above fold
                if appState.currentCharacter?.firstWinToday == false {
                    FirstWinBonusCard()
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }

                // Battle Invite Banner — shows when pending PvP challenges exist
                BattleInviteBanner()
                    .padding(.horizontal, LayoutConstants.screenPadding)

                // Quest Reward Widget — shows when completed quests have unclaimed rewards
                QuestRewardWidget()
                    .padding(.horizontal, LayoutConstants.screenPadding)

                // Tutorial Quest Banner — active NPC quest for onboarding
                tutorialQuestBanner
                    .padding(.horizontal, LayoutConstants.screenPadding)
            }
            .background(DarkFantasyTheme.bgPrimary)
            .zIndex(10) // Keep HUD above map transitions

            // Map area — CityMap and DungeonMap with parallax + fade transition
            ZStack {
                // Black base to avoid any white flashes
                DarkFantasyTheme.bgPrimary

                // Hub city map — parallax shifts up when going to dungeons
                CityMapView()
                    .tutorialAnchor(.hubCityMap)
                    .offset(y: cityMapOffset)
                    .opacity(cityMapOpacity)

                // Dungeon map — parallax shifts up from below when appearing
                DungeonMapView(
                    onBack: {
                        triggerMapTransition(toDungeon: false)
                    },
                    onNavigate: { route in
                        appState.mainPath.append(route)
                    }
                )
                .offset(y: dungeonMapOffset)
                .opacity(dungeonMapOpacity)
            }
            .clipped()
            .overlay(alignment: .top) {
                // Top fade gradient — smooth transition from HUD to map
                LinearGradient(
                    colors: [
                        DarkFantasyTheme.bgPrimary,
                        DarkFantasyTheme.bgPrimary.opacity(0.7),
                        DarkFantasyTheme.bgPrimary.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topTrailing) {
                // Floating action icons — stay in place during transition
                VStack(spacing: LayoutConstants.spaceSM) {
                    FloatingActionIcon(
                        customIcon: "hud-daily-login",
                        badgeActive: appState.dailyLoginCanClaim,
                        accentColor: DarkFantasyTheme.goldBright,
                        size: 62
                    ) {
                        // BUG-53: route manual opens through the shared modal
                        // queue so Daily Login and Level Up can't stack, and
                        // mark "shown today" so a cold restart on the same day
                        // won't re-auto-open. Previously this bypassed both
                        // the queue and the shown-today guard.
                        appState.markDailyLoginShownToday()
                        appState.enqueueModal(.dailyLogin)
                    }
                    .accessibilityLabel("Daily Login")
                    .tutorialAnchor(.hubDailyLogin)

                    FloatingActionIcon(
                        customIcon: "hud-daily-quests",
                        badgeActive: {
                            guard let quests = appState.cachedTypedQuests, !quests.isEmpty else { return false }
                            let hasClaimable = quests.contains(where: \.canClaim)
                            let hasIncomplete = quests.contains(where: { !$0.completed })
                            return hasClaimable || hasIncomplete
                        }(),
                        accentColor: DarkFantasyTheme.gold,
                        size: 62
                    ) {
                        appState.mainPath.append(AppRoute.dailyQuests)
                    }
                    .accessibilityLabel("Daily Quests")

                    FloatingActionIcon(
                        customIcon: "hud-inbox",
                        badgeActive: appState.unreadMailCount > 0,
                        accentColor: DarkFantasyTheme.gold,
                        size: 62
                    ) {
                        appState.mainPath.append(AppRoute.inbox)
                    }
                    .accessibilityLabel("Inbox")

                    FloatingSoundToggle(size: 50)
                        .accessibilityLabel("Toggle sound")
                }
                .padding(.top, LayoutConstants.spaceLG)
                .padding(.trailing, LayoutConstants.screenPadding)
            }
            .overlay(alignment: .bottom) {
                // Bottom button — switches between ADVENTURES and CASTLE
                Button {
                    HapticManager.medium()
                    triggerMapTransition(toDungeon: !showDungeonMap)
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(showDungeonMap ? "ui-arrow-up" : "ui-arrow-down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text(showDungeonMap ? "CASTLE" : "ADVENTURES")
                            .font(DarkFantasyTheme.section)
                    }
                    // Fixed width so button doesn't resize between CASTLE / ADVENTURES
                    .frame(width: 200)
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.vertical, LayoutConstants.spaceSM)
                }
                .buttonStyle(.compactPrimary)
                .animation(nil, value: showDungeonMap)
                .disabled(mapTransitionPhase != .idle)
                .accessibilityLabel(showDungeonMap ? "Go to Adventures" : "Go to Castle")
                .padding(.bottom, LayoutConstants.safeAreaBottom + LayoutConstants.spaceSM)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .persistentSystemOverlays(.hidden)
        .navigationBarHidden(true)
        .overlay {
            // W2.D4 — Building unlock ceremony queue. Mounts above the hub
            // and consumes `appState.pendingBuildingUnlocks` one at a time.
            BuildingUnlockCeremonyHost()
                .allowsHitTesting(!appState.pendingBuildingUnlocks.isEmpty)
                .zIndex(200)
        }
        .overlay {
            // Onboarding NPCGuideWidget overlay (first-time visit)
            // NPCGuideOverlay handles full-screen dim + tap-block + bottom placement.
            if shouldShowOnboarding, let char = appState.currentCharacter {
                NPCGuideOverlay(onBackdropTap: { dismissOnboarding() }) {
                    NPCGuideWidget(
                        npcTitle: onboardingSteps[currentOnboardingStep].title,
                        onDismiss: { dismissOnboarding() },
                        avatarSkinKey: char.avatar,
                        avatarClass: char.characterClass,
                        plainMessage: onboardingSteps[currentOnboardingStep].message,
                        onContinue: { advanceOnboarding() },
                        messageId: currentOnboardingStep  // Animate message transitions
                    )
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .tutorialOverlay(steps: [.hubStamina, .hubCharacterCard, .hubCityMap, .hubDailyLogin])
        .contextualHint(hubHint, onCTA: {
            if let hint = hubHint {
                switch hint.id {
                case "hub_first_pvp":
                    appState.mainPath.append(AppRoute.arena)
                case "hub_first_dungeon":
                    // Jump straight into the next available dungeon's boss list,
                    // skipping the world map. Falls back to the map if nothing
                    // is currently unlocked (e.g. character too low level).
                    if let nextId = nextAvailableDungeonId(
                        from: cache,
                        characterLevel: appState.currentCharacter?.level ?? 1
                    ) {
                        appState.selectedDungeonId = nextId
                        appState.mainPath.append(AppRoute.dungeonRoom)
                    } else {
                        appState.mainPath.append(AppRoute.dungeonMap)
                    }
                case "hub_first_mine", "hub_mine_ready":
                    appState.mainPath.append(AppRoute.goldMine)
                case "hub_unclaimed_rewards":
                    appState.mainPath.append(AppRoute.dailyQuests)
                default:
                    break
                }
            }
        }, bottomInset: LayoutConstants.space2XL + LayoutConstants.spaceLG)
        // BUG-53: daily login is no longer polled from Hub. GameInitService
        // enqueues the modal at app/character-select boot and is the single
        // decision point. Hub only mirrors `appState.dailyLoginCanClaim` for
        // the tile badge and routes manual taps through the modal queue.
        .task { await fetchUnreadMailCount() }
        .onAppear {
            // Latch onboarding state once on appear — prevents NPC vanishing mid-sequence
            if !onboardingActive, appState.currentCharacter != nil {
                let tutorial = TutorialManager.shared
                if tutorial.shouldShow(.hubCharacterCard) {
                    onboardingActive = true
                }
            }
            updateHubHint()
            // Start BGM + ambient atmosphere
            AudioManager.shared.playBGM("stray-city.mp3")
            AmbientManager.shared.setZone(.hub)
            // Reload quests if cache was invalidated (e.g., after PvP/dungeon)
            if appState.cachedTypedQuests == nil {
                Task { await loadQuests() }
            }
            // Background-prefetch opponents so Arena opens instantly
            if cache.cachedOpponents() == nil {
                Task { await prefetchOpponents() }
            }
            // Background-prefetch shop + achievements + dungeons so those screens open instantly
            if cache.cachedShop() == nil {
                Task { await prefetchShop() }
            }
            if cache.cachedAchievements() == nil {
                Task { await prefetchAchievements() }
            }
            if cache.cachedDungeonProgress() == nil {
                Task { await prefetchDungeons() }
            }
            // Background-prefetch battle pass for badge + instant screen open
            if cache.cachedBattlePass() == nil {
                Task { await prefetchBattlePass() }
            }
            // Background-prefetch gold mine so the contextual hint can decide
            // whether there's actually something to do (ready slots / idle
            // slots) instead of nagging the player with a stale "visit the
            // mine" widget when all slots are already productively mining.
            if cache.cachedGoldMine() == nil {
                Task { await prefetchGoldMine() }
            }
            // Background-prefetch social status for Guild Hall badge
            if cache.cachedSocialStatus() == nil {
                Task { await prefetchSocialStatus() }
            }
            // Background-prefetch incoming challenges for battle invite banner
            if cache.cachedIncomingChallenges() == nil {
                Task { await prefetchIncomingChallenges() }
            }
            // Fetch tutorial quest state for NPC quest banner + building indicators
            if let charId = appState.currentCharacter?.id {
                Task {
                    // Fallback: if welcome gift was never claimed (tutorialStep == 0), claim it now
                    let tutorial = TutorialManager.shared
                    await tutorial.fetchTutorialState(characterId: charId)
                    if tutorial.serverTutorialStep == 0 && !tutorial.tutorialSkipped {
                        let claimed = await tutorial.initializeTutorial(characterId: charId)
                        if claimed {
                            // Reload game data to pick up starter weapon + potions
                            let initService = GameInitService(appState: appState, cache: cache)
                            await initService.loadGameData()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Parallax + Fade Transition

    /// Parallax offset for the city map (hub)
    private var cityMapOffset: CGFloat {
        switch mapTransitionPhase {
        case .idle: return showDungeonMap ? -30 : 0
        case .fadingOut: return showDungeonMap ? 0 : -30  // moving up (going to dungeons)
        case .switching: return showDungeonMap ? 30 : -30
        case .fadingIn: return showDungeonMap ? -30 : 0
        }
    }

    private var cityMapOpacity: Double {
        switch mapTransitionPhase {
        case .idle: return showDungeonMap ? 0 : 1
        case .fadingOut: return 0
        case .switching: return 0
        case .fadingIn: return showDungeonMap ? 0 : 1
        }
    }

    /// Parallax offset for the dungeon map
    private var dungeonMapOffset: CGFloat {
        switch mapTransitionPhase {
        case .idle: return showDungeonMap ? 0 : 30
        case .fadingOut: return showDungeonMap ? 30 : 0  // moving down (going back to castle)
        case .switching: return showDungeonMap ? 30 : -30
        case .fadingIn: return showDungeonMap ? 0 : 30
        }
    }

    private var dungeonMapOpacity: Double {
        switch mapTransitionPhase {
        case .idle: return showDungeonMap ? 1 : 0
        case .fadingOut: return 0
        case .switching: return 0
        case .fadingIn: return showDungeonMap ? 1 : 0
        }
    }

    // MARK: - Contextual Hint

    private func updateHubHint() {
        guard let char = appState.currentCharacter else { return }
        let totalPvpFights = char.pvpWins + char.pvpLosses
        let dungeonProgress = cache.cachedDungeonProgress() ?? [:]
        let totalDungeonClears = dungeonProgress.values.reduce(0, +)
        let mineCache = cache.cachedGoldMine()
        let hasVisitedMine = mineCache != nil
        // Derive actionable mine state from cached slots. A slot is "ready"
        // once its timer has elapsed server-side, "idle" when unused. We only
        // nudge the player when there's something to do.
        let (readySlots, idleSlots) = Self.mineSlotCounts(from: mineCache)
        let hasUnclaimedRewards = appState.cachedTypedQuests?.contains(where: \.canClaim) ?? false

        hubHint = ContextualHintProvider.hubHint(
            character: char,
            totalPvpFights: totalPvpFights,
            totalDungeonClears: totalDungeonClears,
            hasVisitedMine: hasVisitedMine,
            mineReadySlots: readySlots,
            mineIdleSlots: idleSlots,
            hasUnclaimedQuestRewards: hasUnclaimedRewards
        )
    }

    /// Extract (ready, idle) slot counts from the cached gold-mine payload.
    /// Matches the client-side logic in `GoldMineViewModel.slotStatus`:
    /// a slot is "ready" if `status == ready` OR it's "mining" with an
    /// elapsed `ends_at` timestamp.
    private static func mineSlotCounts(
        from cache: (slots: [[String: Any]], maxSlots: Int)?
    ) -> (ready: Int, idle: Int) {
        guard let cache else { return (0, 0) }
        var ready = 0
        var idle = 0
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        for slot in cache.slots {
            let raw = slot["status"] as? String ?? "idle"
            if raw == "ready" {
                ready += 1
            } else if raw == "mining", let endStr = slot["ends_at"] as? String {
                let end = formatter.date(from: endStr) ?? fallback.date(from: endStr)
                if let end, now >= end {
                    ready += 1
                }
            } else if raw == "idle" {
                idle += 1
            }
        }
        // Account for unlocked-but-unused slots that may not appear in the
        // slots array (e.g. maxSlots=3 but only 2 entries returned).
        let missing = max(0, cache.maxSlots - cache.slots.count)
        idle += missing
        return (ready, idle)
    }

    private func triggerMapTransition(toDungeon: Bool) {
        guard mapTransitionPhase == .idle else { return }

        // Phase 1: fade out current + parallax shift
        withAnimation(.easeIn(duration: 0.3)) {
            mapTransitionPhase = .fadingOut
        }

        // Phase 2: switch content (instantaneous, hidden by black)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            mapTransitionPhase = .switching
            showDungeonMap = toDungeon

            // Phase 3: fade in new + parallax settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.35)) {
                    mapTransitionPhase = .fadingIn
                }

                // Phase 4: back to idle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    mapTransitionPhase = .idle
                }
            }
        }
    }

    private func fetchUnreadMailCount() async {
        guard let charId = appState.currentCharacter?.id else { return }
        let vm = InboxViewModel()
        // Fetch both mail + player message unread counts in parallel
        async let mailTask: () = vm.fetchUnreadCount(characterId: charId)
        async let scrollsTask: () = vm.fetchScrollsUnreadCount(characterId: charId)
        _ = await (mailTask, scrollsTask)
        appState.unreadMailCount = vm.totalUnreadCount
    }

    // BUG-53: `checkDailyLogin` / `checkLogin` were removed. The auto-open
    // decision was moved to `GameInitService.loadGameData()` so it runs once
    // per session at game boot, unaffected by NavigationStack pop-back or any
    // subsequent `.task` re-fire on the Hub view. Tile taps now call
    // `appState.enqueueModal(.dailyLogin)` directly. All login paths
    // (auto-login, manual login, character select, onboarding) are
    // responsible for invoking `GameInitService.loadGameData()` before
    // HubView appears; Hub itself is now a passive consumer of
    // `appState.cachedDailyLogin` / `dailyLoginCanClaim`.

    private func loadQuests() async {
        let service = QuestService(appState: appState)
        // Fire-and-forget refresh — Hub widgets read from appState.cachedTypedQuests,
        // so failure here is silent; the next open will retry.
        _ = try? await service.loadQuests()
    }

    private func prefetchOpponents() async {
        let pvpService = PvPService(appState: appState)
        let opponents = await pvpService.getOpponents()
        if !opponents.isEmpty {
            await MainActor.run { cache.cacheOpponents(opponents) }

            // Phase 2 (2026-04-13): warm BattlePreloader from Hub so
            // tap-to-combat latency drops from ~1.5s to <500ms. The
            // shared PrepareCacheStore means ArenaViewModel and Combat
            // will find the result already cached when the user taps
            // Fight. Fire-and-forget, background priority.
            let preloader = BattlePreloader(appState: appState)
            for opponent in opponents.prefix(3) {
                Task(priority: .background) {
                    _ = await preloader.prepare(opponentId: opponent.id, showErrors: false)
                }
            }
        }
    }

    private func prefetchShop() async {
        let shopService = ShopService(appState: appState)
        let items = await shopService.getItems()
        if !items.isEmpty {
            await MainActor.run { cache.cacheShop(items) }
        }
    }

    private func prefetchAchievements() async {
        let achievementService = AchievementService(appState: appState)
        let achievements = await achievementService.loadAchievements()
        if !achievements.isEmpty {
            await MainActor.run { cache.cacheAchievements(achievements) }
        }
    }

    private func prefetchDungeons() async {
        let dungeonService = DungeonService(appState: appState)
        guard let data = await dungeonService.getProgress() else { return }
        var progress: [String: Int] = [:]
        if let p = data["progress"] as? [String: Any] {
            for (key, value) in p {
                if let defeated = value as? Int {
                    progress[key] = defeated
                } else if let info = value as? [String: Any] {
                    progress[key] = info["defeated"] as? Int ?? 0
                }
            }
        }
        if !progress.isEmpty {
            await MainActor.run { cache.cacheDungeonProgress(progress) }
        }
    }

    private func prefetchBattlePass() async {
        let bpService = BattlePassService(appState: appState)
        guard let data = await bpService.loadBattlePass() else { return }
        cache.cacheBattlePass(data)
    }

    /// Prefetch gold-mine status so the contextual hint has real slot state
    /// (ready / idle / mining) rather than guessing from "cache empty".
    /// Refreshes `hubHint` after the fetch completes.
    private func prefetchGoldMine() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let data = try await APIClient.shared.getRaw(
                APIEndpoints.goldMineStatus,
                params: ["character_id": charId]
            )
            let slots = data["slots"] as? [[String: Any]] ?? []
            let maxSlots = data["max_slots"] as? Int ?? 3
            await MainActor.run {
                cache.cacheGoldMine(slots: slots, maxSlots: maxSlots)
                updateHubHint()
            }
        } catch {
            // Silent — hint stays nil, which is the right default here.
        }
    }

    private func prefetchSocialStatus() async {
        guard let charId = appState.currentCharacter?.id else { return }
        guard let status = await SocialService.shared.getSocialStatus(characterId: charId) else { return }
        cache.cacheSocialStatus(status)
    }

    private func prefetchIncomingChallenges() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let response = try await ChallengeService.shared.getChallenges(characterId: charId)
            cache.cacheIncomingChallenges(response.incoming)
        } catch {
            // Silent — banner just won't show
        }
    }

    // MARK: - Onboarding Methods

    private func advanceOnboarding() {
        currentOnboardingStep += 1
        if currentOnboardingStep >= onboardingSteps.count {
            // Mark onboarding as complete by dismissing the hub tutorial
            markOnboardingComplete()
        }
    }

    private func dismissOnboarding() {
        // Mark onboarding as complete immediately if dismissed
        onboardingActive = false
        markOnboardingComplete()
    }

    private func markOnboardingComplete() {
        // Mark all hub onboarding steps as complete
        onboardingActive = false
        TutorialManager.shared.completeHubOnboarding()
    }

    private func staminaRecoveryText(current: Int, max: Int) -> String? {
        guard current < max else { return nil }
        let missing = max - current
        let minutesPerPoint = 5 // 5 minutes per stamina point
        let totalMinutes = missing * minutesPerPoint
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "Full in \(hours)h \(minutes)m"
        } else {
            return "Full in \(minutes)m"
        }
    }

    private func useHealthPotion() async {
        // Find the first available health potion from cached inventory
        guard var items = appState.cachedInventory else {
            appState.showToast("Open inventory first", type: .info)
            return
        }

        guard let potion = items.first(where: {
            $0.consumableType?.contains("health_potion") == true && ($0.quantity ?? 0) > 0
        }) else {
            appState.showToast("No health potions", subtitle: "Buy potions at the shop", type: .error)
            return
        }

        // Optimistic UI — update cache + HP immediately
        let previousItems = items
        let previousHp = appState.currentCharacter?.currentHp ?? 0
        let maxHp = appState.currentCharacter?.maxHp ?? 1

        if let qty = potion.quantity, qty > 1 {
            items = items.map { existing in
                guard existing.id == potion.id else { return existing }
                var updated = existing
                updated.quantity = qty - 1
                return updated
            }
        } else {
            items.removeAll { $0.id == potion.id }
        }
        appState.cachedInventory = items

        let estimatedHeal = max(Int(Double(maxHp) * 0.3), 50)
        let newHp = min(previousHp + estimatedHeal, maxHp)
        appState.currentCharacter?.currentHp = newHp

        HapticManager.success()
        appState.showToast("Healed! HP: \(newHp)/\(maxHp)", type: .reward)

        // Fire API in background
        let potionId = potion.id
        let consumableType = potion.consumableType
        let service = InventoryService(appState: appState)
        Task {
            let success = await service.useItem(inventoryId: potionId, consumableType: consumableType)
            if !success {
                await MainActor.run {
                    appState.cachedInventory = previousItems
                    appState.currentCharacter?.currentHp = previousHp
                    appState.showToast("Failed to use potion", type: .error)
                }
            }
        }
    }

    private func useStaminaPotion() async {
        guard var items = appState.cachedInventory else {
            appState.showToast("Open inventory first", type: .info)
            return
        }

        guard let potion = items.first(where: {
            $0.consumableType?.contains("stamina_potion") == true && ($0.quantity ?? 0) > 0
        }) else {
            appState.showToast("No stamina potions", subtitle: "Buy potions at the shop", type: .error)
            return
        }

        // Optimistic UI — update cache + stamina immediately
        let previousItems = items
        let previousStamina = appState.currentCharacter?.currentStamina ?? 0

        if let qty = potion.quantity, qty > 1 {
            items = items.map { existing in
                guard existing.id == potion.id else { return existing }
                var updated = existing
                updated.quantity = qty - 1
                return updated
            }
        } else {
            items.removeAll { $0.id == potion.id }
        }
        appState.cachedInventory = items

        let maxStamina = appState.currentCharacter?.maxStamina ?? 100
        let estimatedRestore = max(Int(Double(maxStamina) * 0.3), 20)
        let newStamina = min(previousStamina + estimatedRestore, maxStamina)
        appState.currentCharacter?.currentStamina = newStamina

        HapticManager.success()
        appState.showToast("+\(newStamina - previousStamina) Stamina restored!", type: .reward)

        // Fire API in background
        let potionId = potion.id
        let consumableType = potion.consumableType
        let service = InventoryService(appState: appState)
        Task {
            let success = await service.useItem(inventoryId: potionId, consumableType: consumableType)
            if !success {
                await MainActor.run {
                    appState.cachedInventory = previousItems
                    appState.currentCharacter?.currentStamina = previousStamina
                    appState.showToast("Failed to use potion", type: .error)
                }
            }
        }
    }
}

// MARK: - Top Currency Bar

struct TopCurrencyBar: View {
    let character: Character?
    var onTapCurrency: (() -> Void)?

    private var settings: SettingsManager { SettingsManager.shared }

    var body: some View {
        HStack(spacing: 0) {
            // Gold (animated tick-up)
            Button {
                onTapCurrency?()
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gold")
                        .resizable()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                    NumberTickUpText(
                        value: character?.gold ?? 0,
                        color: DarkFantasyTheme.goldBright,
                        font: DarkFantasyTheme.section
                    )
                }
                .frame(minHeight: LayoutConstants.touchMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.scalePress(0.95))
            .accessibilityLabel("Gold: \(character?.gold ?? 0)")

            Spacer()

            // Gems (animated tick-up)
            Button {
                onTapCurrency?()
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gems")
                        .resizable()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                    NumberTickUpText(
                        value: character?.gems ?? 0,
                        color: DarkFantasyTheme.cyan,
                        font: DarkFantasyTheme.section
                    )
                }
                .frame(minHeight: LayoutConstants.touchMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.scalePress(0.95))
            .accessibilityLabel("Gems: \(character?.gems ?? 0)")

        }
    }
}

// MARK: - Daily Quests Card

struct DailyQuestsCard: View {
    @Environment(AppState.self) private var appState

    private var completed: Int {
        appState.cachedTypedQuests?.filter(\.completed).count ?? 0
    }
    private var total: Int {
        appState.cachedTypedQuests?.count ?? 0
    }

    private func timeUntilReset() -> String {
        let now = Date()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        guard let tomorrow = utc.date(byAdding: .day, value: 1, to: now),
              let midnight = utc.date(from: utc.dateComponents([.year, .month, .day], from: tomorrow))
        else { return "" }
        let remaining = Int(midnight.timeIntervalSince(now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        return "\(h)h \(m)m"
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Image("hud-daily-quests")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.gold)
                if appState.cachedBonusClaimedToday {
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text("✓ Bonus claimed • \(timeUntilReset())")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                } else {
                    Text(total > 0 ? "\(completed)/\(total) completed" : "Loading...")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                    if total > 0 {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(appState.cachedBonusClaimedToday ? DarkFantasyTheme.success : DarkFantasyTheme.gold)
                            .frame(width: geo.size.width * max(0, min(1, Double(completed) / Double(total))))
                            .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                    }
                }
            }
            .frame(width: 80, height: 10)
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(appState.cachedBonusClaimedToday ? DarkFantasyTheme.success.opacity(0.4) : DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
        )
        .cornerBrackets(color: appState.cachedBonusClaimedToday ? DarkFantasyTheme.success.opacity(0.5) : DarkFantasyTheme.gold.opacity(0.5), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 1)
    }
}

// MARK: - Battle Pass Card

struct BattlePassCard: View {
    // TODO: wire real battle pass data from AppState
    var level: Int = 7
    var maxLevel: Int = 30

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Image(systemName: "medal.fill")
                .font(DarkFantasyTheme.iconLarge)
                .foregroundStyle(DarkFantasyTheme.gold)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("BATTLE PASS")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text("Season 1 • Level \(level)/\(maxLevel)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.gold)
                        .frame(width: geo.size.width * (maxLevel > 0 ? Double(level) / Double(maxLevel) : 0))
                        .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                }
            }
            .frame(width: 80, height: 10)
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 1)
    }
}

// MARK: - First Win Bonus Card

struct FirstWinBonusCard: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            SFXManager.shared.play(.uiTap)
            HapticManager.medium()
            appState.mainPath.append(AppRoute.arena)
        } label: {
            VStack(spacing: LayoutConstants.spaceSM) {
                // Title row
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("reward-first-win")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)

                    Text("FIRST WIN BONUS")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
                }

                // Reward pills row
                HStack(spacing: LayoutConstants.spaceSM) {
                    // Gold reward pill
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-gold")
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                        Text("×2 Gold")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(DarkFantasyTheme.gold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1))

                    // XP reward pill
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-xp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                        Text("×2 XP")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(DarkFantasyTheme.gold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1))

                    Spacer()
                }
            }
            .padding(LayoutConstants.bannerPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1.5)
            )
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.6), length: 14, thickness: 1.5)
            .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.5), size: 5)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.gold.opacity(0.15), radius: 8, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 1)
            .glowPulse(color: DarkFantasyTheme.gold, intensity: 0.4)
            .shimmer(color: DarkFantasyTheme.gold.opacity(0.3), duration: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Battle Invite Banner

/// Shows on Hub when there are pending incoming PvP challenges.
/// Single invite: shows challenger info + FIGHT / DECLINE buttons.
/// Multiple invites: shows first invite + "N more" counter.
/// Hidden when no pending challenges exist.
struct BattleInviteBanner: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    @State private var isAccepting = false
    @State private var isDeclining = false

    private var challenges: [IncomingChallenge] {
        cache.incomingChallenges
    }

    private var firstChallenge: IncomingChallenge? {
        challenges.first
    }

    var body: some View {
        if let challenge = firstChallenge {
            inviteCard(challenge)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func inviteCard(_ challenge: IncomingChallenge) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Header row
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "swords")
                    .font(DarkFantasyTheme.body.bold())
                    .foregroundStyle(DarkFantasyTheme.btnOrangePrimary)

                Text("BATTLE CHALLENGE")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.btnOrangePrimary)

                Spacer()

                if challenges.count > 1 {
                    Text("+\(challenges.count - 1) more")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }

            // Challenger info row
            HStack(spacing: LayoutConstants.spaceMD) {
                // Avatar
                if let avatar = challenge.challenger.avatar, !avatar.isEmpty {
                    AvatarImageView(
                        skinKey: avatar,
                        characterClass: challenge.challenger.classEnum,
                        size: 40
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                } else {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        )
                }

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(challenge.challenger.characterName)
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("Lv.\(challenge.challenger.level)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text(challenge.challenger.rankName)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: LayoutConstants.spaceSM) {
                Button {
                    acceptChallenge(challenge)
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        if isAccepting {
                            HexPulseLoader(.compact)
                                .tint(DarkFantasyTheme.textOnGold)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "swords")
                                .font(DarkFantasyTheme.body.bold())
                        }
                        Text("FIGHT")
                            .font(DarkFantasyTheme.body)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .disabled(isAccepting || isDeclining)

                Button {
                    declineChallenge(challenge)
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        if isDeclining {
                            HexPulseLoader(.compact)
                                .tint(DarkFantasyTheme.textSecondary)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "xmark")
                                .font(DarkFantasyTheme.body.bold())
                        }
                        Text("DECLINE")
                            .font(DarkFantasyTheme.body)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
                .disabled(isAccepting || isDeclining)

                // View all button (if multiple)
                if challenges.count > 1 {
                    Button {
                        HapticManager.light()
                        appState.mainPath.append(AppRoute.guildHall)
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(DarkFantasyTheme.body.weight(.semibold))
                    }
                    .buttonStyle(.secondary)
                    .disabled(isAccepting || isDeclining)
                }
            }
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.btnOrangePrimary.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.btnOrangePrimary.opacity(0.5), lineWidth: 1.5)
        )
        .cornerBrackets(color: DarkFantasyTheme.btnOrangePrimary.opacity(0.5), length: 14, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.btnOrangePrimary.opacity(0.12), radius: 8, y: 2)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 1)
    }

    // MARK: - Actions

    private func acceptChallenge(_ challenge: IncomingChallenge) {
        guard !isAccepting else { return }

        // Client-side stamina pre-check — mirrors ArenaViewModel so the user
        // gets immediate feedback instead of a round-trip "Not enough stamina"
        // server error.
        let staminaCost = cache.gameConfig?.pvpStaminaCost ?? AppConstants.pvpStaminaCost
        if (appState.currentCharacter?.currentStamina ?? 0) < staminaCost {
            appState.showToast("Not enough stamina", subtitle: "Wait for regen or use a potion", type: .error)
            return
        }

        isAccepting = true
        HapticManager.heavy()

        Task {
            guard let charId = appState.currentCharacter?.id else {
                isAccepting = false
                return
            }
            do {
                let result = try await ChallengeService.shared.acceptChallenge(
                    characterId: charId,
                    challengeId: challenge.id
                )

                // Build CombatData for playback (same pattern as GuildHallViewModel)
                let playerFighter = CombatFighter(
                    id: result.defender.id,
                    characterName: result.defender.characterName,
                    characterClass: CharacterClass(rawValue: result.defender.characterClass) ?? .warrior,
                    origin: CharacterOrigin(rawValue: result.defender.origin ?? "human") ?? .human,
                    level: result.defender.level,
                    maxHp: result.defender.maxHp,
                    currentHp: nil,
                    avatar: result.defender.avatar
                )
                let enemyFighter = CombatFighter(
                    id: result.challenger.id,
                    characterName: result.challenger.characterName,
                    characterClass: CharacterClass(rawValue: result.challenger.characterClass) ?? .warrior,
                    origin: CharacterOrigin(rawValue: result.challenger.origin ?? "human") ?? .human,
                    level: result.challenger.level,
                    maxHp: result.challenger.maxHp,
                    currentHp: nil,
                    avatar: result.challenger.avatar
                )
                let combatResultInfo = CombatResultInfo(
                    isWin: result.won,
                    winnerId: result.winnerId,
                    goldReward: result.goldReward,
                    xpReward: result.xpReward,
                    turnsTaken: result.totalTurns,
                    ratingChange: result.ratingChange,
                    firstWinBonus: nil, leveledUp: nil, newLevel: nil, statPointsAwarded: nil
                )
                let combatData = CombatData(
                    player: playerFighter, enemy: enemyFighter,
                    combatLog: result.combatLog, result: combatResultInfo,
                    rewards: CombatRewards(gold: result.goldReward, xp: result.xpReward),
                    source: "challenge", matchId: result.matchId
                )

                // Clear combat state + navigate
                appState.combatData = nil
                appState.combatResult = nil
                appState.resolveResult = nil
                appState.pendingLoot = []
                appState.mainPath.append(AppRoute.combat)
                appState.combatData = combatData
                appState.resolveResult = ResolveResult(
                    verified: true, clientMatches: true,
                    serverWinnerId: result.winnerId,
                    goldReward: result.goldReward, xpReward: result.xpReward,
                    ratingChange: result.ratingChange,
                    firstWinBonus: false, leveledUp: false,
                    newLevel: nil, statPointsAwarded: nil,
                    loot: [],
                    staminaCurrent: appState.currentCharacter?.currentStamina ?? 0,
                    staminaMax: appState.currentCharacter?.maxStamina ?? 120,
                    matchId: result.matchId,
                    durabilityDegraded: [], hpCurrent: nil, hpMax: nil
                )

                // Remove from cache
                cache.cacheIncomingChallenges(
                    cache.incomingChallenges.filter { $0.id != challenge.id }
                )
            } catch let apiError as APIError {
                switch apiError {
                case .serverError(_, let msg):
                    appState.showToast(msg, type: .error)
                default:
                    appState.showToast(apiError.localizedDescription, type: .error)
                }
                HapticManager.error()
            } catch {
                appState.showToast("Failed to start duel", type: .error)
                HapticManager.error()
            }
            isAccepting = false
        }
    }

    private func declineChallenge(_ challenge: IncomingChallenge) {
        guard !isDeclining else { return }
        isDeclining = true
        HapticManager.light()

        // Optimistic: remove from cache
        let savedChallenges = cache.incomingChallenges
        cache.cacheIncomingChallenges(
            cache.incomingChallenges.filter { $0.id != challenge.id }
        )

        Task {
            guard let charId = appState.currentCharacter?.id else {
                isDeclining = false
                return
            }
            do {
                try await ChallengeService.shared.declineChallenge(
                    characterId: charId,
                    challengeId: challenge.id
                )
                appState.showToast("Challenge declined", type: .info)
            } catch {
                // Revert on failure
                cache.cacheIncomingChallenges(savedChallenges)
                appState.showToast("Failed to decline", type: .error)
            }
            isDeclining = false
        }
    }
}

// MARK: - Quest Reward Widget

/// Shows on Hub when there are completed-but-unclaimed daily quests.
/// Single quest: shows title + reward + Claim button.
/// Multiple quests: shows summary "X rewards ready" + Go to Quests button.
/// Hidden when no claimable quests exist.
struct QuestRewardWidget: View {
    @Environment(AppState.self) private var appState

    @State private var claimingId: String?

    private var claimableQuests: [Quest] {
        appState.cachedTypedQuests?.filter(\.canClaim) ?? []
    }

    var body: some View {
        if !claimableQuests.isEmpty {
            questContent()
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeOut(duration: 0.3), value: claimableQuests.count)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func questContent() -> some View {
        if claimableQuests.count == 1, let quest = claimableQuests.first {
            singleQuestCard(quest)
        } else {
            multiQuestCard()
        }
    }

    // MARK: - Single Quest

    private func singleQuestCard(_ quest: Quest) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Quest icon
            AssetPlaceholderView(systemIcon: "scroll.fill")
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(quest.title)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                // Reward pills
                rewardRow(gold: quest.rewardGold, xp: quest.rewardXp, gems: quest.rewardGems)
            }

            Spacer(minLength: 4)

            // Claim button
            Button {
                claimQuest(quest)
            } label: {
                if claimingId == quest.id {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.textOnGold)
                        .frame(width: 60)
                } else {
                    Text("Claim")
                        .frame(minWidth: 60)
                }
            }
            .buttonStyle(.compactPrimary)
            .disabled(claimingId != nil)
        }
        .modifier(QuestRewardCardStyle(accentColor: DarkFantasyTheme.cyan))
    }

    // MARK: - Multiple Quests

    private func multiQuestCard() -> some View {
        Button {
            SFXManager.shared.play(.uiTap)
            HapticManager.medium()
            appState.mainPath.append(AppRoute.dailyQuests)
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                // Quest icon
                Image("hud-daily-quests")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("\(claimableQuests.count) REWARDS READY")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Text("Tap to claim your quest rewards")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .modifier(QuestRewardCardStyle(accentColor: DarkFantasyTheme.gold))
    }

    // MARK: - Reward Pills

    private func rewardRow(gold: Int, xp: Int, gems: Int?) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if gold > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-gold")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("+\(gold)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            if xp > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-xp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("+\(xp)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
            }
            if let gems, gems > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-gems")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("+\(gems)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.purple)
                }
            }
        }
    }

    // MARK: - Claim Logic

    private func claimQuest(_ quest: Quest) {
        claimingId = quest.id

        // BUG-51 (QA 2026-04-10): do NOT pre-show the "Quest Complete!" toast
        // or mark the quest rewardClaimed before the API confirms — the
        // previous version did this optimistically and then NEVER awaited
        // `refreshCharacter()`, so gold/XP stayed stale even on success and
        // the toast fired on failure. Fire API first, commit state after.
        let questId = quest.id
        Task {
            let service = QuestService(appState: appState)
            let result = await service.claimQuest(questId: questId)
            claimingId = nil

            guard let result = result else {
                appState.showToast(
                    "Failed to claim quest",
                    subtitle: "Please try again",
                    type: .error,
                    actionLabel: "Retry",
                    action: {
                        if let q = appState.cachedTypedQuests?.first(where: { $0.id == questId && $0.canClaim }) {
                            claimQuest(q)
                        }
                    },
                )
                return
            }

            // Commit claimed state now that the server confirmed. The service
            // has already awaited refreshCharacter(), so gold/XP on the HUD
            // are already up-to-date by the time we land here.
            if let idx = appState.cachedTypedQuests?.firstIndex(where: { $0.id == questId }) {
                withAnimation(.easeOut(duration: 0.3)) {
                    appState.cachedTypedQuests?[idx].rewardClaimed = true
                }
            }

            HapticManager.success()
            SFXManager.shared.play(.uiRewardClaim)

            // Show the REAL rewards from the server, not the stale Quest model.
            var parts: [String] = []
            if result.rewardGold > 0 { parts.append("+\(result.rewardGold)g") }
            if result.rewardXp > 0 { parts.append("+\(result.rewardXp) XP") }
            if result.rewardGems > 0 { parts.append("+\(result.rewardGems) gems") }
            let subtitle = parts.isEmpty ? quest.title : parts.joined(separator: "  ")
            appState.showToast("Quest Complete!", subtitle: subtitle, type: .quest)
        }
    }
}

// MARK: - Quest Reward Card Style

private struct QuestRewardCardStyle: ViewModifier {
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.bannerPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: accentColor.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
            )
            .cornerBrackets(color: accentColor.opacity(0.4), length: 12, thickness: 1.5)
            .compositingGroup()
            .shadow(color: accentColor.opacity(0.12), radius: 6, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 1)
    }
}

// MARK: - Daily Login Card

struct DailyLoginCard: View {
    let canClaim: Bool

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Image("hud-daily-login")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("DAILY LOGIN")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(canClaim ? DarkFantasyTheme.goldBright : DarkFantasyTheme.gold)
                Text(canClaim ? "Tap to claim today's reward!" : "Reward claimed today ✓")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(canClaim ? DarkFantasyTheme.goldBright : DarkFantasyTheme.success)
            }

            Spacer()

            if canClaim {
                // Pulsing dot to attract attention
                Circle()
                    .fill(DarkFantasyTheme.goldBright)
                    .frame(width: 10, height: 10)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.6), radius: 4)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: canClaim ? DarkFantasyTheme.goldDim.opacity(0.12) : DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(
                    canClaim ? DarkFantasyTheme.goldBright.opacity(0.7) : DarkFantasyTheme.success.opacity(0.4),
                    lineWidth: canClaim ? 1.5 : 1
                )
        )
        .cornerBrackets(color: canClaim ? DarkFantasyTheme.goldBright.opacity(0.6) : DarkFantasyTheme.success.opacity(0.4), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 1)
    }
}

// MARK: - Floating Action Icon

struct FloatingActionIcon: View {
    let systemIcon: String?
    let customIcon: String?
    let badgeActive: Bool
    let accentColor: Color
    var size: CGFloat = 56
    let action: () -> Void

    init(systemIcon: String, badgeActive: Bool, accentColor: Color, size: CGFloat = 56, action: @escaping () -> Void) {
        self.systemIcon = systemIcon
        self.customIcon = nil
        self.badgeActive = badgeActive
        self.accentColor = accentColor
        self.size = size
        self.action = action
    }

    init(customIcon: String, badgeActive: Bool, accentColor: Color, size: CGFloat = 56, action: @escaping () -> Void) {
        self.systemIcon = nil
        self.customIcon = customIcon
        self.badgeActive = badgeActive
        self.accentColor = accentColor
        self.size = size
        self.action = action
    }

    @State private var badgePulse = false

    private var iconSize: CGFloat { size * 0.39 }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let customIcon {
                        Image(customIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size, height: size)
                    } else if let systemIcon {
                        Image(systemName: systemIcon)
                            .font(.system(size: iconSize, weight: .semibold)) // dynamic — based on component size param
                            .foregroundStyle(accentColor)
                            .frame(width: size, height: size)
                    }
                }
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 2)

                // Notification badge — gold pulsing dot
                if badgeActive {
                    Circle()
                        .fill(DarkFantasyTheme.goldBright)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(DarkFantasyTheme.bgPrimary, lineWidth: 2)
                        )
                        .shadow(color: DarkFantasyTheme.gold.opacity(badgePulse ? 0.8 : 0.2), radius: badgePulse ? 6 : 2)
                        .offset(x: 2, y: -2)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.scalePress(0.9))
        .contentShape(Circle())
        .onAppear {
            if badgeActive {
                withAnimation(MotionConstants.pulse) {
                    badgePulse = true
                }
            }
        }
        .onDisappear {
            badgePulse = false
        }
    }
}

// MARK: - Floating Sound Toggle (matches FloatingActionIcon style)

struct FloatingSoundToggle: View {
    var size: CGFloat = 56
    private let settings = SettingsManager.shared
    @State private var isMuted: Bool = SettingsManager.shared.isMuted

    // Tap feedback
    @State private var tapScale: CGFloat = 1.0

    // Sound wave rings (expand + fade on tap)
    @State private var waveScales: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var waveOpacities: [Double] = [0.0, 0.0, 0.0]

    // Idle animation (sound on)
    @State private var idleGlow = false
    @State private var eq1: CGFloat = 0.35
    @State private var eq2: CGFloat = 0.5
    @State private var eq3: CGFloat = 0.25

    private var accentColor: Color {
        isMuted ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.gold
    }

    private var glowOpacity: Double {
        if isMuted { return 0.15 }
        return idleGlow ? 0.5 : 0.25
    }

    private var glowRadius: CGFloat {
        if isMuted { return 4 }
        return idleGlow ? 14 : 8
    }

    var body: some View {
        Button {
            performToggle()
        } label: {
            ZStack {
                // Expanding wave rings (tap only)
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            DarkFantasyTheme.gold,
                            lineWidth: 1.5 - CGFloat(i) * 0.3
                        )
                        .frame(width: size, height: size)
                        .scaleEffect(waveScales[i])
                        .opacity(waveOpacities[i])
                }

                // Main icon + chrome
                soundButtonContent

                // Equalizer bars below icon (idle indicator)
                if !isMuted {
                    equalizerBars
                        .transition(.opacity.animation(.easeInOut(duration: MotionConstants.normal)))
                }
            }
        }
        .buttonStyle(.scalePress(0.9))
        .contentShape(Circle())
        .onAppear {
            if !isMuted { startIdleLoop() }
        }
        .onDisappear {
            stopIdleLoop()
        }
    }

    // MARK: - Main Button Content

    private var soundButtonContent: some View {
        Image(isMuted ? "hud-sound-off" : "hud-sound-on")
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.75, height: size * 0.75)
            .frame(width: size, height: size)
            .background(
                ZStack {
                    Circle()
                        .fill(DarkFantasyTheme.bgSecondary)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accentColor.opacity(isMuted ? 0.04 : 0.12), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: size / 2
                            )
                        )
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DarkFantasyTheme.textPrimary.opacity(0.08),
                                    Color.clear,
                                    DarkFantasyTheme.bgAbyss.opacity(0.12)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                Circle()
                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [DarkFantasyTheme.textPrimary.opacity(0.08), Color.clear, DarkFantasyTheme.bgAbyss.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .padding(LayoutConstants.spaceXS)
            )
            .shadow(color: accentColor.opacity(glowOpacity), radius: glowRadius, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 2, y: 1)
            .scaleEffect(tapScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.45), value: tapScale)
            .animation(.easeInOut(duration: 2.5), value: idleGlow)
            .animation(MotionConstants.smooth, value: isMuted)
    }

    // MARK: - Equalizer Bars

    private var equalizerBars: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            equalizerBar(height: eq1, maxHeight: 8)
            equalizerBar(height: eq2, maxHeight: 8)
            equalizerBar(height: eq3, maxHeight: 8)
        }
        .offset(y: size * 0.52)
    }

    private func equalizerBar(height: CGFloat, maxHeight: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1) // keep — sub-pixel decorative equalizer bar
            .fill(
                LinearGradient(
                    colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2.5, height: max(2.5, height * maxHeight))
            .shadow(color: DarkFantasyTheme.gold.opacity(0.4), radius: 2)
    }

    // MARK: - Actions

    private func performToggle() {
        isMuted.toggle()
        settings.isMuted = isMuted

        if isMuted {
            AudioManager.shared.stopBGM()
            AmbientManager.shared.stopAll()
            stopIdleLoop()
        } else {
            AudioManager.shared.syncVolume()
            AmbientManager.shared.syncVolume()
            AudioManager.shared.playBGM("stray-city.mp3")
            triggerTapBounce()
            triggerWaves()
            startIdleLoop()
        }
    }

    private func triggerTapBounce() {
        tapScale = 1.15
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            tapScale = 1.0
        }
    }

    private func triggerWaves() {
        let delays: [Int] = [0, 100, 200]
        let maxScales: [CGFloat] = [1.7, 2.0, 2.3]

        for i in 0..<3 {
            Task { @MainActor in
                if delays[i] > 0 {
                    try? await Task.sleep(for: .milliseconds(delays[i]))
                }
                waveScales[i] = 1.0
                waveOpacities[i] = 0.4 - Double(i) * 0.06
                withAnimation(.easeOut(duration: 0.65)) {
                    waveScales[i] = maxScales[i]
                    waveOpacities[i] = 0.0
                }
            }
        }
    }

    private func startIdleLoop() {
        withAnimation(MotionConstants.breathing) {
            idleGlow = true
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            eq1 = 0.9
        }
        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(0.15)) {
            eq2 = 0.85
        }
        withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(0.3)) {
            eq3 = 1.0
        }
    }

    private func stopIdleLoop() {
        idleGlow = false
        eq1 = 0.35
        eq2 = 0.5
        eq3 = 0.25
    }
}

// MARK: - Nav Tile

struct NavTile: View {
    let icon: String
    let label: String
    var asset: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: LayoutConstants.spaceXS) {
                if let asset {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                } else {
                    AssetPlaceholderView(systemIcon: "scroll.fill")
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                }
                Text(label)
            }
        }
        .buttonStyle(.navGrid)
        .accessibilityLabel(label)
    }
}
