import SwiftUI

// MARK: - Level Up Modal (Ceremony Upgrade — Sprint 1)
// Full ornamental redesign: rotating rays, scale-in title, tick-up reward counters,
// gold particle burst, unlock pills, shimmer CTA.
// Since 2026-10-22 the ceremony plays on an ascension reward card (RewardCard.swift):
// winged-sun crest, the metal of the new level's bracket (the hero-card ladder),
// the player's hero as the illustration.
// Server-authoritative fields used today: levelUpNewLevel, levelUpStatPoints.
// Building unlocks are derived from local unlock config crossed by the new level.
// Keep this ceremony honest: do not surface extra reward rows unless the
// backend actually returns them in the active claim/runtime contract.

struct LevelUpModalView: View {
    @Environment(AppState.self) private var appState

    // MARK: - Animation State
    @State private var showBackdrop = false
    @State private var showRays = false
    @State private var showTitle = false
    @State private var showLevel = false
    @State private var showDivider = false
    @State private var showRewards = false
    @State private var showUnlocks = false
    @State private var showButton = false
    @State private var showBurst = false
    @State private var raysRotation: Double = 0

    // Tick-up counters
    @State private var displayedStatPoints: Int = 0
    @State private var displayedPassivePoints: Int = 0

    // Title entrance
    @State private var titleScale: CGFloat = 2.5
    @State private var titleBlur: CGFloat = 12
    @State private var titleOpacity: Double = 0

    private var newLevel: Int { appState.levelUpNewLevel }
    private var statPoints: Int { appState.levelUpStatPoints }
    private var passivePoints: Int { appState.levelUpPassivePoints }

    /// Lightweight row describing a single newly-unlocked building for the modal.
    private struct UnlockRow: Identifiable {
        let id: String        // CityBuilding.id
        let label: String     // display name
    }

    /// Buildings unlocked at this exact level (e.g. Lv3 → Dungeon, Lv5 → Gold Mine)
    private var unlocks: [UnlockRow] {
        BuildingUnlockConfig.levels
            .filter { $0.value == newLevel }
            .map { UnlockRow(id: $0.key, label: buildingDisplayName($0.key)) }
            .sorted { $0.label < $1.label }
    }

    private func buildingDisplayName(_ id: String) -> String {
        switch id {
        case "arena":      return "Arena"
        case "shop":        return "Shop"
        case "achievements": return "Achievements"
        case "dungeon":     return "Dungeon Rush"
        case "gold-mine":   return "Gold Mine"
        case "tavern":      return "Tavern"
        case "battlepass":  return "Battle Pass"
        case "ranks":       return "Leaderboard"
        case "guild-hall":  return "Guild Hall"
        default:            return id.capitalized
        }
    }

    /// The player's hero, standing in the forge's light.
    private var heroArt: RewardCardArt {
        guard let hero = appState.currentCharacter else {
            return .object("reward-level-up", fill: 0.6)
        }
        return .hero(skinKey: hero.avatar, characterClass: hero.characterClass)
    }

    var body: some View {
        ZStack {
            // Backdrop
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()
                .opacity(showBackdrop ? 1 : 0)

            // Rotating conic rays
            if showRays {
                raysLayer
                    .transition(.opacity)
            }

            // The card: frame and hero arrive with the rays, the ceremony plays on it.
            RewardCardStage { width, artRatio in
                RewardCard(
                    family: .ascension,
                    tier: RewardCardTier(level: newLevel),
                    art: heroArt,
                    width: width,
                    artRatio: artRatio,
                    header: { cardHeader },
                    content: { cardContent },
                    actions: { continueButton }
                )
            }
            .opacity(showRays ? 1 : 0)

            // Particle burst over the illustration
            if showBurst {
                GeometryReader { geo in
                    RewardBurstView(style: .levelUp, isActive: $showBurst, particleCount: 30)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.32)
                }
                .allowsHitTesting(false)
            }
        }
        .onAppear(perform: startCeremony)
        .onDisappear {
            resetState()
        }
    }

    // MARK: - Card

    /// "LEVEL UP!" slams in (the approved 2.5 → 1 title beat), then the level, then the divider.
    private var cardHeader: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("LEVEL UP!")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .shadow(color: DarkFantasyTheme.gold.opacity(0.8), radius: 16)
                .shadow(color: DarkFantasyTheme.goldBright.opacity(0.4), radius: 4)
                .scaleEffect(titleScale)
                .blur(radius: titleBlur)
                .opacity(titleOpacity)
                .accessibilityAddTraits(.isHeader)

            // New level number
            Text("LEVEL \(newLevel)")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .opacity(showLevel ? 1 : 0)
                .offset(y: showLevel ? 0 : 8)

            // Ornamental divider
            ScrollworkDivider(
                color: DarkFantasyTheme.gold.opacity(0.5),
                accentColor: DarkFantasyTheme.goldBright
            )
            .frame(width: 200)
            .padding(.top, LayoutConstants.spaceXS)
            .opacity(showDivider ? 1 : 0)
        }
    }

    /// Rewards and unlocks are laid out from the start and faded in, so the card
    /// keeps its height while the ceremony plays.
    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            rewardCardsSection
                .opacity(showRewards ? 1 : 0)
                .offset(y: showRewards ? 0 : 10)

            if !unlocks.isEmpty {
                unlockSection
                    .opacity(showUnlocks ? 1 : 0)
            }
        }
    }

    private var continueButton: some View {
        Button {
            HapticManager.medium()
            appState.dismissLevelUpModal()
        } label: {
            Text("CONTINUE")
                .font(DarkFantasyTheme.buttonLabel)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.4, isActive: showButton)
        .shimmer(color: DarkFantasyTheme.gold, duration: 3)
        .opacity(showButton ? 1 : 0)
        .offset(y: showButton ? 0 : 15)
        .allowsHitTesting(showButton)
        // Laid out from the start (the card keeps its height); out of VoiceOver's
        // reach until it shows.
        .accessibilityHidden(!showButton)
    }

    // MARK: - Rotating Rays

    private var raysLayer: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.35)
            let rayCount = 12

            ZStack {
                ForEach(0..<rayCount, id: \.self) { i in
                    let angle = Double(i) * (360.0 / Double(rayCount))
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DarkFantasyTheme.goldBright.opacity(0.15),
                                    DarkFantasyTheme.gold.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: geo.size.height * 0.5)
                        .rotationEffect(.degrees(angle + raysRotation))
                        .position(center)
                }
            }
            .mask(
                RadialGradient(
                    colors: [.white, .white.opacity(0.3), .clear],
                    center: UnitPoint(x: 0.5, y: 0.35),
                    startRadius: 10,
                    endRadius: 300
                )
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Reward Cards Section

    private var rewardCardsSection: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            RewardCardRow(
                icon: "reward-level-up",
                value: "+\(displayedStatPoints)",
                label: "Stat Points",
                color: DarkFantasyTheme.goldBright
            )

            if passivePoints > 0 {
                RewardCardRow(
                    icon: "reward-first-win",
                    value: "+\(displayedPassivePoints)",
                    label: passivePoints == 1 ? "Passive Point" : "Passive Points",
                    color: DarkFantasyTheme.purple
                )
            }
        }
    }

    // MARK: - Unlock Section

    private var unlockSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("NEW UNLOCKS")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(2)

            // Two to a row: the card is narrower than the screen.
            let rows = stride(from: 0, to: unlocks.count, by: 2).map {
                Array(unlocks[$0..<min($0 + 2, unlocks.count)])
            }
            VStack(spacing: LayoutConstants.spaceSM) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(row) { unlock in
                            unlockPill(entry: unlock)
                        }
                    }
                }
            }
        }
    }

    /// Vertical card: building asset on top, label below. Falls back to the
    /// catalog SF-Symbol if no PNG asset is shipped for the building id.
    private func unlockPill(entry: UnlockRow) -> some View {
        let assetName = "building-\(entry.id)"
        let hasAsset = UIImage(named: assetName) != nil
        let catalogEntry = BuildingUnlockCatalog.entry(for: entry.id, fallbackLabel: entry.label)

        return VStack(spacing: LayoutConstants.spaceXS) {
            ZStack {
                // Radial gold glow behind the asset to sell the "new unlock" moment
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.gold.opacity(0.25),
                                DarkFantasyTheme.gold.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 38
                        )
                    )
                    .frame(width: 72, height: 72)

                if hasAsset {
                    Image(assetName)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .shadow(color: DarkFantasyTheme.goldBright.opacity(0.35), radius: 6)
                } else {
                    // Non-building fallback: show the catalog feature icon
                    Image(systemName: catalogEntry.icon)
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(catalogEntry.accent)
                        .frame(width: 60, height: 60)
                }
            }

            Text(entry.label.uppercased())
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .tracking(1)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceSM)
        .frame(minWidth: 88)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.gold.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Ceremony Sequence

    private func startCeremony() {
        // Sound + haptic — epic horn fanfare for the ceremony
        SFXManager.shared.play(.epicHornFanfare)
        HapticManager.heavy()

        // Phase 1: Backdrop + rays
        withAnimation(.easeOut(duration: MotionConstants.ceremonyPhase1)) {
            showBackdrop = true
        }

        // Rays rotation (continuous)
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            raysRotation = 360
        }

        // Phase 2: Rays + shield appear
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.navigationDelay) {
            withAnimation(.easeOut(duration: 0.4)) {
                showRays = true
            }
        }

        // Phase 3: Title scale-in 2.5→1 with blur dissolve
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyPhase1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                showTitle = true
                titleScale = 1.0
                titleBlur = 0
                titleOpacity = 1
            }
            // Trigger particle burst
            showBurst = true
        }

        // Phase 4: Level number
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyPhase2) {
            withAnimation(.easeOut(duration: MotionConstants.ceremonyPhase1)) {
                showLevel = true
            }
        }

        // Phase 5: Divider
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyPhase3) {
            withAnimation(.easeOut(duration: 0.25)) {
                showDivider = true
            }
        }

        // Phase 6: Reward cards + tick-up
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyPhase4) {
            withAnimation(.easeOut(duration: 0.35)) {
                showRewards = true
            }
            // Start tick-up counters after cards appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                startTickUp()
            }
        }

        // Phase 7: Unlocks (with SFX if new buildings open)
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyPhase5) {
            withAnimation(.easeOut(duration: MotionConstants.ceremonyPhase1)) {
                showUnlocks = true
            }
            if !unlocks.isEmpty {
                SFXManager.shared.play(.dungeonUnlock)
                HapticManager.medium()
            }
        }

        // Phase 8: Continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyButton) {
            withAnimation(MotionConstants.spring) {
                showButton = true
            }
        }
    }

    // MARK: - Tick-Up Animation

    private func startTickUp() {
        let steps = 12
        let interval = MotionConstants.tickUpDuration / Double(steps)

        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                let fraction = Double(step) / Double(steps)
                withAnimation(.easeOut(duration: 0.08)) {
                    displayedStatPoints = Int(Double(statPoints) * fraction)
                    displayedPassivePoints = Int(Double(passivePoints) * fraction)
                }
            }
        }

        // Ensure final values are exact
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.tickUpDuration + 0.05) {
            displayedStatPoints = statPoints
            displayedPassivePoints = passivePoints
        }
    }

    // MARK: - Reset

    private func resetState() {
        showBackdrop = false
        showRays = false
        showTitle = false
        showLevel = false
        showDivider = false
        showRewards = false
        showUnlocks = false
        showButton = false
        showBurst = false
        raysRotation = 0
        titleScale = 2.5
        titleBlur = 12
        titleOpacity = 0
        displayedStatPoints = 0
        displayedPassivePoints = 0
    }
}
