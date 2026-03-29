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
                            let completed = appState.cachedTypedQuests?.filter(\.completed).count ?? 0
                            let total = appState.cachedTypedQuests?.count ?? 0
                            return total > 0 && completed < total
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
                        Image(showDungeonMap ? "icon-lobby" : "icon-dungeons")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
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
        }
    }

    private func fetchUnreadMailCount() async {
        guard let charId = appState.currentCharacter?.id else { return }
        let vm = InboxViewModel()
        await vm.fetchUnreadCount(characterId: charId)
        appState.unreadMailCount = vm.unreadCount
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
                .frame(width: 34, height: 34)

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
            .shadow(color: DarkFantasyTheme.gold.opacity(0.15), radius: 8, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 1)
            .glowPulse(color: DarkFantasyTheme.gold, intensity: 0.4)
            .shimmer(color: DarkFantasyTheme.gold.opacity(0.3), duration: 5)
        }
        .buttonStyle(.plain)
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
                .frame(width: 34, height: 34)

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

    private var accentColor: Color {
        isMuted ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.gold
    }

    private var iconSize: CGFloat { size * 0.39 }

    var body: some View {
        Button {
            isMuted.toggle()
            settings.isMuted = isMuted
            if isMuted {
                AudioManager.shared.stopBGM()
            } else {
                AudioManager.shared.syncVolume()
                AudioManager.shared.playBGM("stray-city.mp3")
            }
        } label: {
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
        }
        .buttonStyle(.scalePress(0.9))
        .contentShape(Circle())
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
