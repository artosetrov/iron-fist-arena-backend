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
            !quest.rewardClaimed
        }),
           let title = activeQuest.title ?? questTitle(for: activeQuest.questId),
           let npcMessage = activeQuest.npcMessage ?? questNpcMessage(for: activeQuest.questId) {
            TutorialQuestBanner(
                questId: activeQuest.questId,
                title: title,
                npcMessage: npcMessage,
                progress: activeQuest.progress,
                target: activeQuest.target,
                isCompleted: activeQuest.isCompleted,
                rewardClaimed: activeQuest.rewardClaimed,
                onTap: { navigateToQuestTarget(activeQuest.questId) },
                onClaim: { claimQuestReward(activeQuest.questId) }
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
            if let result, let rewardConfig = buildTutorialQuestRewardConfig(from: result, questId: questId) {
                appState.claimRewardConfig = rewardConfig
            } else if result != nil {
                appState.showToast("Quest updated", type: .info)
            } else {
                appState.showToast("Claim failed", subtitle: "Try again", type: .error)
            }
            // Refresh character data to update currency
            await appState.reloadCharacter()
        }
    }

    private func buildTutorialQuestRewardConfig(
        from result: TutorialQuestClaimResponse,
        questId: String
    ) -> ClaimRewardConfig? {
        let goldReward = max(0, result.goldDelta ?? 0)
        var lootItems: [ClaimLootItem] = []

        if
            let rewards = result.rewards,
            let consumableType = rewards.consumableType,
            let quantity = rewards.consumableAmount,
            quantity > 0
        {
            let metadata = ConsumableCatalog.metadata(
                consumableType: consumableType,
                catalogId: consumableType,
                imageKey: consumableType
            )
            let rarity = metadata?.rarity ?? .uncommon
            lootItems = [
                ClaimLootItem(
                    id: consumableType,
                    name: metadata?.displayName ?? ConsumableCatalog.displayName(forKnownOrRaw: consumableType),
                    quantity: quantity,
                    imageKey: metadata?.imageKey,
                    fallbackIcon: metadata?.systemIcon ?? "cross.vial",
                    rarity: rarity,
                    rarityColor: DarkFantasyTheme.rarityColor(for: rarity)
                )
            ]
        }

        guard goldReward > 0 || !lootItems.isEmpty else { return nil }

        return ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: questTitle(for: questId) ?? "Tutorial Quest",
            goldReward: goldReward,
            gemsReward: 0,
            xpReward: 0,
            lootItems: lootItems
        )
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
            // Honor cross-screen requests to land on the dungeon map with the
            // full hub HUD (e.g. tapping the dungeon daily quest card). The
            // standalone .dungeonMap route renders without the hero widget /
            // floating icons, so we route those entries back to the hub and
            // flip showDungeonMap here instead.
            if appState.pendingShowDungeonMap {
                appState.pendingShowDungeonMap = false
                if !showDungeonMap {
                    triggerMapTransition(toDungeon: true)
                }
            }
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
        from cache: (slots: [GoldMineSlotResponse], maxSlots: Int)?
    ) -> (ready: Int, idle: Int) {
        guard let cache else { return (0, 0) }
        var ready = 0
        var idle = 0
        for slot in cache.slots {
            let status = slot.resolvedStatus()
            if status == .ready {
                ready += 1
            } else if status == .idle {
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
        guard let snapshot = await dungeonService.getProgress() else { return }
        let progress = snapshot.progress
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
            let data: GoldMineStatusResponse = try await APIClient.shared.get(
                APIEndpoints.goldMineStatus,
                params: ["character_id": charId]
            )
            await MainActor.run {
                cache.cacheGoldMine(status: data)
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
