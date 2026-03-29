import SwiftUI

// MARK: - Hub View

struct HubView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var showDungeonMap = false
    @State private var showDailyLoginSheet = false

    // Onboarding flow state
    @State private var currentOnboardingStep = 0
    private let onboardingSteps = [
        (title: "Welcome, Adventurer!", message: "This is your Hub — the center of your journey."),
        (title: "Explore the City", message: "Visit the SHOP to gear up, the ARENA to fight other players, or the DUNGEON to explore."),
        (title: "Earn & Reward", message: "Check the GOLD MINE to earn gold, and don't forget your DAILY LOGIN rewards!")
    ]

    private var shouldShowOnboarding: Bool {
        // Check if this is the first time visiting hub (no onboarding completed yet)
        guard appState.currentCharacter != nil else { return false }
        let tutorial = TutorialManager.shared
        // Show onboarding if hubCharacterCard hasn't been shown (first-time visit indicator)
        return tutorial.shouldShow(.hubCharacterCard) && currentOnboardingStep < onboardingSteps.count
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
            }
            .background(DarkFantasyTheme.bgPrimary)
            .zIndex(10) // Keep HUD above map transitions

            // Map area — CityMap and DungeonMap with crossfade transition
            ZStack {
                // Black base to avoid any white flashes
                DarkFantasyTheme.bgPrimary

                // Hub city map
                CityMapView()
                    .tutorialAnchor(.hubCityMap)
                    .opacity(showDungeonMap ? 0 : 1)

                // Dungeon map — navigates via mainPath so DungeonRoom/Combat share one stack
                DungeonMapView(
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.45)) {
                            showDungeonMap = false
                        }
                    },
                    onNavigate: { route in
                        appState.mainPath.append(route)
                    }
                )
                .opacity(showDungeonMap ? 1 : 0)
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
                VStack(spacing: LayoutConstants.spaceMS) {
                    FloatingActionIcon(
                        customIcon: "hud-gift",
                        badgeActive: appState.dailyLoginCanClaim,
                        accentColor: DarkFantasyTheme.goldBright,
                        size: 50
                    ) {
                        showDailyLoginSheet = true
                    }
                    .accessibilityLabel("Daily Login")
                    .tutorialAnchor(.hubDailyLogin)

                    FloatingActionIcon(
                        customIcon: "hud-quests",
                        badgeActive: {
                            guard let quests = appState.cachedTypedQuests, !quests.isEmpty else { return false }
                            let hasClaimable = quests.contains(where: \.canClaim)
                            let hasIncomplete = quests.contains(where: { !$0.completed })
                            return hasClaimable || hasIncomplete
                        }(),
                        accentColor: DarkFantasyTheme.gold,
                        size: 50
                    ) {
                        appState.mainPath.append(AppRoute.dailyQuests)
                    }
                    .accessibilityLabel("Daily Quests")

                    FloatingActionIcon(
                        systemIcon: "envelope.fill",
                        badgeActive: appState.unreadMailCount > 0,
                        accentColor: DarkFantasyTheme.gold,
                        size: 50
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
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showDungeonMap.toggle()
                    }
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(showDungeonMap ? "ui-arrow-up" : "ui-arrow-down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text(showDungeonMap ? "CASTLE" : "ADVENTURES")
                            .font(DarkFantasyTheme.section)
                    }
                    .frame(minWidth: 220)
                    .padding(.horizontal, LayoutConstants.buttonPaddingH)
                    .padding(.vertical, LayoutConstants.spaceMD)
                }
                .buttonStyle(.compactPrimary)
                .animation(nil, value: showDungeonMap)
                .accessibilityLabel(showDungeonMap ? "Go to Adventures" : "Go to Castle")
                .padding(.bottom, LayoutConstants.safeAreaBottom + LayoutConstants.spaceSM)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .persistentSystemOverlays(.hidden)
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) {
            // Onboarding NPCGuideWidget overlay (first-time visit)
            if shouldShowOnboarding, let char = appState.currentCharacter {
                VStack(spacing: 0) {
                    Spacer()
                    NPCGuideWidget(
                        npcTitle: onboardingSteps[currentOnboardingStep].title,
                        onDismiss: { dismissOnboarding() },
                        avatarSkinKey: char.avatar,
                        avatarClass: char.characterClass,
                        plainMessage: onboardingSteps[currentOnboardingStep].message,
                        onContinue: { advanceOnboarding() },
                        messageId: currentOnboardingStep  // Animate message transitions
                    )
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.screenPadding + LayoutConstants.safeAreaBottom)
                }
                .background(DarkFantasyTheme.bgAbyss.opacity(0.5))
                .ignoresSafeArea(edges: .bottom)
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .tutorialOverlay(steps: [.hubStamina, .hubCharacterCard, .hubCityMap, .hubDailyLogin])
        .sheet(isPresented: $showDailyLoginSheet) {
            DailyLoginDetailView()
                .environment(appState)
                .environment(cache)
        }
        .task { await checkDailyLogin() }
        .task { await fetchUnreadMailCount() }
        .onAppear {
            // Start BGM
            AudioManager.shared.playBGM("stray-city.mp3")
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
            // Background-prefetch social status for Guild Hall badge
            if cache.cachedSocialStatus() == nil {
                Task { await prefetchSocialStatus() }
            }
            // Background-prefetch incoming challenges for battle invite banner
            if cache.cachedIncomingChallenges() == nil {
                Task { await prefetchIncomingChallenges() }
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

    private func checkDailyLogin() async {
        try? await Task.sleep(for: .seconds(0.5))
        // If game/init hasn't run yet (manual login path), run it now
        if !cache.isInitLoaded {
            let initService = GameInitService(appState: appState, cache: cache)
            // Parallelize game/init with login check
            async let gameInit: Void = initService.loadGameData()
            async let loginCheck: Void = checkLogin()
            _ = await (gameInit, loginCheck)
            // Quest data comes from game/init, but load if still missing
            if appState.cachedTypedQuests == nil {
                await loadQuests()
            }
        } else if appState.cachedTypedQuests == nil {
            // game/init already done — load quests + login in parallel
            async let questLoad: Void = loadQuests()
            async let loginCheck: Void = checkLogin()
            _ = await (questLoad, loginCheck)
        } else {
            await checkLogin()
        }
    }

    private func loadQuests() async {
        let service = QuestService(appState: appState)
        _ = await service.loadQuests()
    }

    private func checkLogin() async {
        var canClaim = false

        // Use cached daily login from /game/init if available
        if let cached = appState.cachedDailyLogin,
           let claim = cached["canClaim"] as? Bool {
            canClaim = claim
        } else {
            // Fallback to API call
            let service = DailyLoginService(appState: appState)
            if let data = await service.getStatus() {
                canClaim = data.canClaim
            }
        }

        await MainActor.run {
            appState.dailyLoginCanClaim = canClaim

            // Auto-show daily login sheet once per session
            if canClaim && !appState.hasAutoShownDailyLogin {
                appState.hasAutoShownDailyLogin = true
                showDailyLoginSheet = true
            }
        }
    }

    private func prefetchOpponents() async {
        let pvpService = PvPService(appState: appState)
        let opponents = await pvpService.getOpponents()
        if !opponents.isEmpty {
            await MainActor.run { cache.cacheOpponents(opponents) }
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
        markOnboardingComplete()
    }

    private func markOnboardingComplete() {
        // Mark all hub onboarding steps as complete
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
                        .frame(width: 20, height: 20)
                    NumberTickUpText(
                        value: character?.gold ?? 0,
                        color: DarkFantasyTheme.goldBright,
                        font: DarkFantasyTheme.section(size: 15)
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
                        .frame(width: 20, height: 20)
                    NumberTickUpText(
                        value: character?.gems ?? 0,
                        color: DarkFantasyTheme.cyan,
                        font: DarkFantasyTheme.section(size: 15)
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
            Image("hud-quests")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(DarkFantasyTheme.gold)
                if appState.cachedBonusClaimedToday {
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text("✓ Bonus claimed • \(timeUntilReset())")
                            .font(DarkFantasyTheme.body(size: 12))
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                } else {
                    Text(total > 0 ? "\(completed)/\(total) completed" : "Loading...")
                        .font(DarkFantasyTheme.body(size: 12))
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
            Text("🎖️").font(.system(size: 30))

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("BATTLE PASS")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text("Season 1 • Level \(level)/\(maxLevel)")
                    .font(DarkFantasyTheme.body(size: 12))
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
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: LayoutConstants.textLabel, weight: .semibold))
                        .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
                }

                // Reward pills row
                HStack(spacing: LayoutConstants.spaceSM) {
                    // Gold reward pill
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-gold")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("×2 Gold")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
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
                            .frame(width: 16, height: 16)
                        Text("×2 XP")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.orange)

                Text("BATTLE CHALLENGE")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.orange)

                Spacer()

                if challenges.count > 1 {
                    Text("+\(challenges.count - 1) more")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
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
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("Lv.\(challenge.challenger.level)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text(challenge.challenger.rankName)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
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
                            ProgressView()
                                .tint(DarkFantasyTheme.textOnGold)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "swords")
                                .font(.system(size: 12, weight: .bold))
                        }
                        Text("FIGHT")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
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
                            ProgressView()
                                .tint(DarkFantasyTheme.textSecondary)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text("DECLINE")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
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
                            .font(.system(size: 14, weight: .semibold))
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
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.orange.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.orange.opacity(0.5), lineWidth: 1.5)
        )
        .cornerBrackets(color: DarkFantasyTheme.orange.opacity(0.5), length: 14, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.orange.opacity(0.12), radius: 8, y: 2)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 1)
    }

    // MARK: - Actions

    private func acceptChallenge(_ challenge: IncomingChallenge) {
        guard !isAccepting else { return }
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
            Text(quest.icon)
                .font(.system(size: 24))

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(quest.title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
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
                    ProgressView()
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
                Image("hud-quests")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("\(claimableQuests.count) REWARDS READY")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Text("Tap to claim your quest rewards")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: LayoutConstants.textLabel, weight: .semibold))
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
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
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
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
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
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.purple)
                }
            }
        }
    }

    // MARK: - Claim Logic

    private func claimQuest(_ quest: Quest) {
        claimingId = quest.id

        // Optimistic: mark claimed instantly
        if let idx = appState.cachedTypedQuests?.firstIndex(where: { $0.id == quest.id }) {
            withAnimation(.easeOut(duration: 0.3)) {
                appState.cachedTypedQuests?[idx].rewardClaimed = true
            }
        }

        HapticManager.success()
        SFXManager.shared.play(.uiRewardClaim)
        appState.showToast("Quest Complete! \(quest.title)", type: .quest)
        claimingId = nil

        // Fire API in background
        let questId = quest.id
        Task {
            let service = QuestService(appState: appState)
            let success = await service.claimQuest(questId: questId)
            if !success {
                // Revert on failure
                if let idx = appState.cachedTypedQuests?.firstIndex(where: { $0.id == questId }) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        appState.cachedTypedQuests?[idx].rewardClaimed = false
                    }
                }
                appState.showToast("Failed to claim quest", subtitle: "Please try again", type: .error,
                                   actionLabel: "Retry", action: {
                    if let q = appState.cachedTypedQuests?.first(where: { $0.id == questId && $0.canClaim }) {
                        claimQuest(q)
                    }
                })
            }
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
            Image("hud-gift")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("DAILY LOGIN")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(canClaim ? DarkFantasyTheme.goldBright : DarkFantasyTheme.gold)
                Text(canClaim ? "Tap to claim today's reward!" : "Reward claimed today ✓")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
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
                    .font(.system(size: 18))
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
                            .frame(width: size * 0.75, height: size * 0.75)
                    } else if let systemIcon {
                        Image(systemName: systemIcon)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }
                }
                    .frame(width: size, height: size)
                    .background(
                        ZStack {
                            Circle()
                                .fill(DarkFantasyTheme.bgSecondary)
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [accentColor.opacity(0.08), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: size / 2
                                    )
                                )
                            // Surface lighting on circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.08),
                                            Color.clear,
                                            Color.black.opacity(0.12)
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
                        // Inner bevel on circle
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.clear, Color.black.opacity(0.12)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                            .padding(3)
                    )
                    .shadow(color: accentColor.opacity(0.25), radius: 8, y: 2)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 2, y: 1)

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
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
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
                        .transition(.opacity.animation(.easeInOut(duration: 0.4)))
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
                                    Color.white.opacity(0.08),
                                    Color.clear,
                                    Color.black.opacity(0.12)
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
                            colors: [Color.white.opacity(0.08), Color.clear, Color.black.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .padding(3)
            )
            .shadow(color: accentColor.opacity(glowOpacity), radius: glowRadius, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 2, y: 1)
            .scaleEffect(tapScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.45), value: tapScale)
            .animation(.easeInOut(duration: 2.5), value: idleGlow)
            .animation(.easeInOut(duration: 0.3), value: isMuted)
    }

    // MARK: - Equalizer Bars

    private var equalizerBars: some View {
        HStack(spacing: 2) {
            equalizerBar(height: eq1, maxHeight: 8)
            equalizerBar(height: eq2, maxHeight: 8)
            equalizerBar(height: eq3, maxHeight: 8)
        }
        .offset(y: size * 0.52)
    }

    private func equalizerBar(height: CGFloat, maxHeight: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1)
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
            stopIdleLoop()
        } else {
            AudioManager.shared.syncVolume()
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
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
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
                    Text(icon)
                        .font(.system(size: 24))
                }
                Text(label)
            }
        }
        .buttonStyle(.navGrid)
        .accessibilityLabel(label)
    }
}
