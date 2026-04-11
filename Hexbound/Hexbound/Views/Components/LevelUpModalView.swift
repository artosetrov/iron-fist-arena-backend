import SwiftUI

// MARK: - Level Up Modal (Ceremony Upgrade — Sprint 1)
// Full ornamental redesign: rotating rays, scale-in title, tick-up reward counters,
// gold particle burst, unlock pills, shimmer CTA.
// Server fields used: levelUpNewLevel, levelUpStatPoints
// Future: passivePointsAwarded, staminaRefill, unlocks[] (when backend adds them)

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
    @State private var displayedStamina: Int = 0

    // Title entrance
    @State private var titleScale: CGFloat = 2.5
    @State private var titleBlur: CGFloat = 12
    @State private var titleOpacity: Double = 0

    private var newLevel: Int { appState.levelUpNewLevel }
    private var statPoints: Int { appState.levelUpStatPoints }
    // TODO: Add when backend returns these fields
    private var passivePoints: Int { 1 }
    private var staminaRefill: Int { 120 }

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

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Shield / emblem area with burst
                ZStack {
                    if showBurst {
                        RewardBurstView(style: .levelUp, isActive: $showBurst, particleCount: 30)
                            .allowsHitTesting(false)
                    }

                    shieldEmblem
                }
                .frame(height: 120)
                .padding(.bottom, LayoutConstants.spaceSM)

                // "LEVEL UP!" title — scale-in with blur
                Text("LEVEL UP!")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.8), radius: 16)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.4), radius: 4)
                    .scaleEffect(titleScale)
                    .blur(radius: titleBlur)
                    .opacity(titleOpacity)

                // New level number
                Text("LEVEL \(newLevel)")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .opacity(showLevel ? 1 : 0)
                    .offset(y: showLevel ? 0 : 8)
                    .padding(.top, LayoutConstants.spaceSM)

                // Ornamental divider
                if showDivider {
                    ScrollworkDivider(
                        color: DarkFantasyTheme.gold.opacity(0.5),
                        accentColor: DarkFantasyTheme.goldBright
                    )
                    .frame(width: 200)
                    .padding(.vertical, LayoutConstants.spaceMD)
                    .transition(.opacity)
                }

                // Reward cards in ornamental panel
                if showRewards {
                    VStack(spacing: LayoutConstants.spaceMD) {
                        rewardCardsSection

                        // Unlock pills
                        if showUnlocks && !unlocks.isEmpty {
                            unlockSection
                        }
                    }
                    .padding(LayoutConstants.spaceMD)
                    .background(
                        RadialGlowBackground(
                            baseColor: DarkFantasyTheme.bgSecondary,
                            glowColor: DarkFantasyTheme.bgTertiary,
                            glowIntensity: 0.4,
                            cornerRadius: LayoutConstants.modalRadius
                        )
                    )
                    .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
                    .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: DarkFantasyTheme.gold.opacity(0.1))
                    .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 18, thickness: 2.0)
                    .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.4), size: 6)
                    .compositingGroup()
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 10)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Continue button
                if showButton {
                    Button("CONTINUE") {
                        HapticManager.medium()
                        appState.dismissLevelUpModal()
                    }
                    .buttonStyle(.primary)
                    .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.4, isActive: true)
                    .shimmer(color: DarkFantasyTheme.gold, duration: 3)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceLG * 2)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear(perform: startCeremony)
        .onDisappear {
            resetState()
        }
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

    // MARK: - Shield Emblem

    private var shieldEmblem: some View {
        ZStack {
            // Gold glow behind shield
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DarkFantasyTheme.goldBright.opacity(0.35),
                            DarkFantasyTheme.gold.opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Shield shape
            shieldPath
                .fill(
                    LinearGradient(
                        colors: [
                            DarkFantasyTheme.gold,
                            DarkFantasyTheme.borderOrnament,
                            DarkFantasyTheme.goldDim
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 64, height: 76)
                .overlay(
                    shieldPath
                        .stroke(DarkFantasyTheme.goldBright, lineWidth: 2)
                        .frame(width: 64, height: 76)
                )
                .surfaceLighting(cornerRadius: 0, topHighlight: 0.15, bottomShadow: 0.2)
                .shadow(color: DarkFantasyTheme.goldBright.opacity(0.5), radius: 12)

            // Level number inside shield
            Text("\(newLevel)")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
        }
        .opacity(showTitle ? 1 : 0)
    }

    // Shield shape path
    private var shieldPath: some Shape {
        ShieldShape()
    }

    // MARK: - Reward Cards Section

    private var rewardCardsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            rewardCard(
                iconName: "star.fill",
                iconColor: DarkFantasyTheme.goldBright,
                label: "Stat Points",
                value: displayedStatPoints,
                targetValue: statPoints
            )

            rewardCard(
                iconName: "sparkles",
                iconColor: DarkFantasyTheme.purple,
                label: "Passive Point",
                value: displayedPassivePoints,
                targetValue: passivePoints
            )

            rewardCard(
                iconName: "bolt.fill",
                iconColor: DarkFantasyTheme.stamina,
                label: "Stamina Refill",
                value: displayedStamina,
                targetValue: staminaRefill
            )
        }
    }

    @ViewBuilder
    private func rewardCard(
        iconName: String,
        iconColor: Color,
        label: String,
        value: Int,
        targetValue: Int
    ) -> some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(DarkFantasyTheme.body.bold())
                    .foregroundStyle(iconColor)
            }

            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Spacer()

            Text("+\(value)")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.1), value: value)
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: iconColor.opacity(0.1)
        )
        .cornerBrackets(color: iconColor.opacity(0.3), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: iconColor.opacity(0.15), radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 4, y: 2)
    }

    // MARK: - Unlock Section

    private var unlockSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("NEW UNLOCKS")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(2)

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(unlocks) { unlock in
                    unlockPill(entry: unlock)
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
        // Sound + haptic
        SFXManager.shared.play(.uiLevelUp)
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
                    displayedStamina = Int(Double(staminaRefill) * fraction)
                }
            }
        }

        // Ensure final values are exact
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.tickUpDuration + 0.05) {
            displayedStatPoints = statPoints
            displayedPassivePoints = passivePoints
            displayedStamina = staminaRefill
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
        displayedStamina = 0
    }
}

// MARK: - Shield Shape

private struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        var path = Path()
        // Top flat edge
        path.move(to: CGPoint(x: w * 0.1, y: 0))
        path.addLine(to: CGPoint(x: w * 0.9, y: 0))
        // Right edge curves in
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.5),
            control: CGPoint(x: w, y: h * 0.15)
        )
        // Bottom point
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 0.75, y: h * 0.8)
        )
        // Left bottom
        path.addQuadCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.5),
            control: CGPoint(x: w * 0.25, y: h * 0.8)
        )
        // Left edge back up
        path.addQuadCurve(
            to: CGPoint(x: w * 0.1, y: 0),
            control: CGPoint(x: 0, y: h * 0.15)
        )
        path.closeSubpath()
        return path
    }
}

