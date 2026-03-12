import SwiftUI

// MARK: - Hub View

struct HubView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 10) {
                // Stamina Bar → Potions tab
                if let char = appState.currentCharacter {
                    Button {
                        appState.shopInitialTab = 3
                        appState.mainPath.append(AppRoute.shop)
                    } label: {
                        StaminaBarView(currentStamina: char.currentStamina, maxStamina: char.maxStamina)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceSM)
                }

                // Character Card
                if let char = appState.currentCharacter {
                    Button {
                        appState.mainPath.append(AppRoute.hero)
                    } label: {
                        HubCharacterCard(character: char)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }

                // First Win Bonus — prominent above fold
                if appState.currentCharacter?.firstWinToday == false {
                    FirstWinBonusCard()
                        .padding(.horizontal, LayoutConstants.screenPadding)
                }

                // Interactive city map (replaces nav grid)
                CityMapView()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Floating action icons — top-right, under hero card
            VStack {
                // Offset to sit below stamina + character card
                Spacer().frame(height: LayoutConstants.spaceSM + 20 + 10 + 120 + 50)

                VStack(spacing: 10) {
                    FloatingActionIcon(
                        systemIcon: "gift.fill",
                        badgeActive: appState.dailyLoginCanClaim,
                        accentColor: DarkFantasyTheme.goldBright,
                        size: 50
                    ) {
                        appState.mainPath.append(AppRoute.dailyLogin)
                    }

                    FloatingActionIcon(
                        systemIcon: "scroll.fill",
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

                    FloatingSoundToggle(size: 50)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, LayoutConstants.screenPadding)

        }
        .navigationBarHidden(true)
        .task { await checkDailyLogin() }
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
            .buttonStyle(.plain)

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
            .buttonStyle(.plain)

        }
    }

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Hub Character Card

struct HubCharacterCard: View {
    let character: Character
    var showCurrencies: Bool = true

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                // Avatar — square with level badge
                ZStack(alignment: .bottomTrailing) {
                    AvatarImageView(
                        skinKey: character.avatar,
                        characterClass: character.characterClass,
                        size: 70
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DarkFantasyTheme.gold, lineWidth: 2.5)
                    )
                    .frame(width: 70, height: 70)

                    // Level badge
                    Text("\(character.level)")
                        .font(DarkFantasyTheme.section(size: 11).bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(DarkFantasyTheme.gold))
                        .offset(x: 4, y: 4)
                }

                // Info — Name, HP and XP
                VStack(alignment: .leading, spacing: 5) {
                    Text(character.characterName)
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .lineLimit(1)

                    HubStatBar(
                        label: "HP",
                        valueText: "\(character.currentHp)/\(character.maxHp)",
                        percentage: character.hpPercentage,
                        color: DarkFantasyTheme.hpBlood
                    )

                    HubStatBar(
                        label: "XP",
                        valueText: "\(Int(character.xpPercentage * 100))%",
                        percentage: character.xpPercentage,
                        color: DarkFantasyTheme.cyan
                    )
                }
            }

            // Currencies row (gold + gems) — integrated into hero widget
            if showCurrencies {
                HStack(spacing: 0) {
                    HStack(spacing: 5) {
                        Image("icon-gold")
                            .resizable()
                            .frame(width: 18, height: 18)
                        Text(formatGold(character.gold))
                            .font(DarkFantasyTheme.section(size: 13))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .monospacedDigit()
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Image("icon-gems")
                            .resizable()
                            .frame(width: 18, height: 18)
                        Text("\(character.gems ?? 0)")
                            .font(DarkFantasyTheme.section(size: 13))
                            .foregroundStyle(DarkFantasyTheme.cyan)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1.5)
        )
    }
}

// MARK: - Hub Stat Bar

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
            Text("📜").font(.system(size: 30))

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
        .padding(14)
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
        .padding(14)
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
        .padding(14)
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
            Text("🎁").font(.system(size: 30))

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
        .padding(14)
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
    let systemIcon: String
    let badgeActive: Bool
    let accentColor: Color
    var size: CGFloat = 56
    let action: () -> Void

    @State private var badgePulse = false

    private var iconSize: CGFloat { size * 0.39 }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemIcon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(accentColor)
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
        .buttonStyle(.plain)
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
            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(accentColor)
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
        .buttonStyle(.plain)
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
