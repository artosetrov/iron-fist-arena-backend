import SwiftUI

// MARK: - Hub View

struct HubView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    var body: some View {
        VStack(spacing: 0) {
            // HUD widgets at top
            VStack(spacing: 10) {
                // Unified Hero Widget (replaces StaminaBarView + HubCharacterCardWrapper)
                if let char = appState.currentCharacter {
                    UnifiedHeroWidget(
                        character: char,
                        context: .hub,
                        onTap: { appState.mainPath.append(AppRoute.hero) },
                        onUseHealthPotion: {
                            Task { await useHealthPotion() }
                        },
                        onUseStaminaPotion: {
                            Task { await useStaminaPotion() }
                        },
                        onAllocateStats: { appState.mainPath.append(AppRoute.hero) },
                        onRefillStamina: { appState.mainPath.append(AppRoute.shop) }
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

            // City map — fills remaining space, bleeds to bottom edge
            CityMapView()
                .tutorialAnchor(.hubCityMap)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 10) {
                        FloatingActionIcon(
                            customIcon: "hud-gift",
                            badgeActive: appState.dailyLoginCanClaim,
                            accentColor: DarkFantasyTheme.goldBright,
                            size: 50
                        ) {
                            appState.mainPath.append(AppRoute.dailyLogin)
                        }
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

                        FloatingActionIcon(
                            systemIcon: "envelope.fill",
                            badgeActive: appState.unreadMailCount > 0,
                            accentColor: DarkFantasyTheme.gold,
                            size: 50
                        ) {
                            appState.mainPath.append(AppRoute.inbox)
                        }

                        FloatingSoundToggle(size: 50)
                    }
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.trailing, LayoutConstants.screenPadding)
                }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .tutorialOverlay(steps: [.hubStamina, .hubCharacterCard, .hubCityMap, .hubDailyLogin])
        .task { await checkDailyLogin() }
        .task { await fetchUnreadMailCount() }
        .onAppear {
            // Start BGM
            AudioManager.shared.playBGM("Stray City.mp3")
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

            // Auto-navigate to daily login once per session
            if canClaim && !appState.hasAutoShownDailyLogin {
                appState.hasAutoShownDailyLogin = true
                appState.mainPath.append(AppRoute.dailyLogin)
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
        guard let items = appState.cachedInventory else {
            appState.showToast("Open inventory first", type: .info)
            return
        }

        guard let potion = items.first(where: {
            $0.consumableType?.contains("health_potion") == true && ($0.quantity ?? 0) > 0
        }) else {
            appState.showToast("No health potions", subtitle: "Buy potions at the shop", type: .error)
            return
        }

        let hpBefore = appState.currentCharacter?.currentHp ?? 0
        let service = InventoryService(appState: appState)
        let success = await service.useItem(
            inventoryId: potion.id,
            consumableType: potion.consumableType
        )

        if success {
            let hpAfter = appState.currentCharacter?.currentHp ?? 0
            let healAmount = hpAfter - hpBefore
            appState.showToast(
                "+\(healAmount) HP restored!",
                type: .reward
            )
        }
    }

    private func useStaminaPotion() async {
        // Find the first available stamina potion from cached inventory
        guard let items = appState.cachedInventory else {
            appState.showToast("Open inventory first", type: .info)
            return
        }

        guard let potion = items.first(where: {
            $0.consumableType?.contains("stamina_potion") == true && ($0.quantity ?? 0) > 0
        }) else {
            appState.showToast("No stamina potions", subtitle: "Buy potions at the shop", type: .error)
            return
        }

        let staminaBefore = appState.currentCharacter?.currentStamina ?? 0
        let service = InventoryService(appState: appState)
        let success = await service.useItem(
            inventoryId: potion.id,
            consumableType: potion.consumableType
        )

        if success {
            let staminaAfter = appState.currentCharacter?.currentStamina ?? 0
            let recoveredAmount = staminaAfter - staminaBefore
            appState.showToast(
                "+\(recoveredAmount) Stamina restored!",
                type: .reward
            )
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
            // Gold
            Button {
                onTapCurrency?()
            } label: {
                HStack(spacing: 5) {
                    Image("icon-gold")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(formatGold(character?.gold ?? 0))
                        .font(DarkFantasyTheme.section(size: 15))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                .frame(minHeight: LayoutConstants.touchMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.scalePress(0.95))

            Spacer()

            // Gems
            Button {
                onTapCurrency?()
            } label: {
                HStack(spacing: 5) {
                    Image("icon-gems")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("\(character?.gems ?? 0)")
                        .font(DarkFantasyTheme.section(size: 15))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
                .frame(minHeight: LayoutConstants.touchMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.scalePress(0.95))

        }
    }

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Hub Stat Bar (used by CompactHeroWidget and other views)

struct HubStatBar: View {
    let label: String
    let valueText: String
    let percentage: Double
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(DarkFantasyTheme.body(size: 11).bold())
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(width: 20, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(1, percentage)))
                }
            }
            .frame(height: 10)

            Text(valueText)
                .font(DarkFantasyTheme.body(size: 11))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(width: 58, alignment: .trailing)
        }
    }
}

// MARK: - Hub Character Card Wrapper (handles navigation vs potion tap)

struct HubCharacterCardWrapper: View {
    let character: Character
    @Environment(AppState.self) private var appState

    var body: some View {
        HubCharacterCard(
            character: character,
            onUsePotion: { Task { await useHealthPotion() } }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            appState.mainPath.append(AppRoute.hero)
        }
    }

    private func useHealthPotion() async {
        // Find the first available health potion from cached inventory
        guard let items = appState.cachedInventory else {
            appState.showToast("Open inventory first", type: .info)
            return
        }

        guard let potion = items.first(where: {
            $0.consumableType?.contains("health_potion") == true && ($0.quantity ?? 0) > 0
        }) else {
            appState.showToast("No health potions", subtitle: "Buy potions at the shop", type: .error)
            return
        }

        let service = InventoryService(appState: appState)
        let success = await service.useItem(
            inventoryId: potion.id,
            consumableType: potion.consumableType
        )

        if success {
            let healed = (appState.currentCharacter?.currentHp ?? 0) - character.currentHp
            let healAmount = max(healed, 0)
            appState.showToast(
                "+\(healAmount) HP restored!",
                type: .reward
            )
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
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let tomorrow = utc.date(byAdding: .day, value: 1, to: now),
              let midnight = utc.date(from: utc.dateComponents([.year, .month, .day], from: tomorrow))
        else { return "" }
        let remaining = Int(midnight.timeIntervalSince(now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        return "\(h)h \(m)m"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image("hud-quests")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
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
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.bgTertiary)
                    if total > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(appState.cachedBonusClaimedToday ? DarkFantasyTheme.success : DarkFantasyTheme.gold)
                            .frame(width: geo.size.width * (Double(completed) / Double(total)))
                    }
                }
            }
            .frame(width: 80, height: 10)
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(appState.cachedBonusClaimedToday ? DarkFantasyTheme.success.opacity(0.4) : DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Battle Pass Card

struct BattlePassCard: View {
    // TODO: wire real battle pass data from AppState
    var level: Int = 7
    var maxLevel: Int = 30

    var body: some View {
        HStack(spacing: 12) {
            Text("🎖️").font(.system(size: 30))

            VStack(alignment: .leading, spacing: 3) {
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
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.gold)
                        .frame(width: geo.size.width * (maxLevel > 0 ? Double(level) / Double(maxLevel) : 0))
                }
            }
            .frame(width: 80, height: 10)
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - First Win Bonus Card

struct FirstWinBonusCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("🎯").font(.system(size: 30))

            VStack(alignment: .leading, spacing: 3) {
                Text("FIRST WIN BONUS")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(DarkFantasyTheme.success)
                Text("Win a PvP match for ×2 Gold & ×2 XP")
                    .font(DarkFantasyTheme.body(size: 12))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            Spacer()
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.success.opacity(0.6), lineWidth: 1.5)
        )
    }
}

// MARK: - Daily Login Card

struct DailyLoginCard: View {
    let canClaim: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image("hud-gift")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text("DAILY LOGIN")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(canClaim ? DarkFantasyTheme.goldBright : DarkFantasyTheme.gold)
                Text(canClaim ? "Tap to claim today's reward!" : "Reward claimed today ✓")
                    .font(DarkFantasyTheme.body(size: 12))
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
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(
                    canClaim ? DarkFantasyTheme.goldBright.opacity(0.7) : DarkFantasyTheme.success.opacity(0.4),
                    lineWidth: canClaim ? 1.5 : 1
                )
        )
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
                        Circle()
                            .fill(DarkFantasyTheme.bgSecondary)
                    )
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: accentColor.opacity(0.3), radius: 8, y: 2)

                // Notification badge
                if badgeActive {
                    Circle()
                        .fill(DarkFantasyTheme.danger)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(DarkFantasyTheme.bgPrimary, lineWidth: 2)
                        )
                        .scaleEffect(badgePulse ? 1.15 : 0.95)
                        .offset(x: 2, y: -2)
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
                AudioManager.shared.playBGM("Stray City.mp3")
            }
        } label: {
            Image(isMuted ? "hud-sound-off" : "hud-sound-on")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.75, height: size * 0.75)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: accentColor.opacity(0.3), radius: 8, y: 2)
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
    }
}
