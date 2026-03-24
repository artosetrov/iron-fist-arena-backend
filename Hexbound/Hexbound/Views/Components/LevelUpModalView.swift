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
    private var unlocks: [String] { [] } // e.g. ["Heroic Dungeon", "Roulette"]

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
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textCinematic))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.8), radius: 16)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.4), radius: 4)
                    .scaleEffect(titleScale)
                    .blur(radius: titleBlur)
                    .opacity(titleOpacity)

                // New level number
                Text("LEVEL \(newLevel)")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textCelebration))
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

                // Reward cards
                if showRewards {
                    rewardCardsSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Unlock pills
                if showUnlocks && !unlocks.isEmpty {
                    unlockSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.top, LayoutConstants.spaceMD)
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
                .font(DarkFantasyTheme.title(size: 28))
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .shadow(color: Color.black.opacity(0.3), radius: 2, y: 1)
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
        .padding(.horizontal, LayoutConstants.screenPadding + LayoutConstants.spaceLG)
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(iconColor)
            }

            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Spacer()

            Text("+\(value)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
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
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: iconColor.opacity(0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 4, y: 2)
    }

    // MARK: - Unlock Section

    private var unlockSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("NEW UNLOCKS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(2)

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(unlocks, id: \.self) { unlock in
                    unlockPill(name: unlock)
                }
            }
        }
    }

    private func unlockPill(name: String) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 12))
                .foregroundStyle(DarkFantasyTheme.success)
            Text(name)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.success.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.success.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Ceremony Sequence

    private func startCeremony() {
        // Phase 1: Backdrop + rays
        withAnimation(.easeOut(duration: 0.3)) {
            showBackdrop = true
        }

        // Rays rotation (continuous)
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            raysRotation = 360
        }

        // Phase 2: Rays + shield appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.4)) {
                showRays = true
            }
        }

        // Phase 3: Title scale-in 2.5→1 with blur dissolve
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                showLevel = true
            }
        }

        // Phase 5: Divider
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.25)) {
                showDivider = true
            }
        }

        // Phase 6: Reward cards + tick-up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.35)) {
                showRewards = true
            }
            // Start tick-up counters after cards appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                startTickUp()
            }
        }

        // Phase 7: Unlocks
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                showUnlocks = true
            }
        }

        // Phase 8: Continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
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

