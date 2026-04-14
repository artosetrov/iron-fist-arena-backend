import SwiftUI

extension DungeonRushDetailView {
    // MARK: - Start View

    @ViewBuilder
    func startView(vm: DungeonRushViewModel) -> some View {
        ZStack(alignment: .bottom) {
            // Atmospheric dungeon background — stronger presence
            Image("bg-dungeon")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
                .clipped()
                .ignoresSafeArea()
                .opacity(0.45)

            // Vignette — radial center clarity + edge darkening
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    DarkFantasyTheme.bgPrimary.opacity(0.5),
                    DarkFantasyTheme.bgPrimary.opacity(0.85)
                ]),
                center: .init(x: 0.5, y: 0.28),
                startRadius: 80,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Bottom fade for CTA readability
            LinearGradient(
                colors: [
                    Color.clear,
                    DarkFantasyTheme.bgPrimary.opacity(0.7),
                    DarkFantasyTheme.bgPrimary
                ],
                startPoint: .init(x: 0.5, y: 0.55),
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating dust particles
            dungeonDustOverlay()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    Spacer().frame(height: LayoutConstants.spaceSM)

                    // ── Hero Zone: Portal ──
                    ZStack {
                        // Outer pulsing glow rings
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 220, height: 220)
                            .shadow(color: DarkFantasyTheme.purple.opacity(portalGlow ? 0.25 : 0.08), radius: 60)
                            .shadow(color: DarkFantasyTheme.gold.opacity(portalGlow ? 0.2 : 0.06), radius: 40)
                            .animation(MotionConstants.glowLoop, value: portalGlow)

                        // Main circle
                        Circle()
                            .fill(RadialGradient(
                                gradient: Gradient(colors: [
                                    DarkFantasyTheme.bgElevated,
                                    DarkFantasyTheme.bgSecondary,
                                    DarkFantasyTheme.bgAbyss.opacity(0.8)
                                ]),
                                center: .init(x: 0.4, y: 0.35),
                                startRadius: 0,
                                endRadius: 95
                            ))
                            .frame(width: 200, height: 200)
                            .overlay(
                                Circle().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(DarkFantasyTheme.gold.opacity(0.12), lineWidth: 1)
                                    .padding(LayoutConstants.spaceSM)
                            )
                            .shadow(color: DarkFantasyTheme.gold.opacity(portalGlow ? 0.35 : 0.15), radius: 30)
                            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 12, y: 5)
                            .animation(MotionConstants.glowLoop, value: portalGlow)

                        Image("icon-dungeon-rush")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        // Corner diamonds around portal
                        ForEach([0, 90, 180, 270], id: \.self) { deg in
                            Rectangle()
                                .fill(DarkFantasyTheme.gold.opacity(0.35))
                                .frame(width: 6, height: 6)
                                .rotationEffect(.degrees(45))
                                .offset(y: -108)
                                .rotationEffect(.degrees(Double(deg)))
                        }
                    }

                    // Subtitle only (title is in toolbar)
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Text("12 rooms of combat, treasure & mystery")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        // Reward preview pills
                        rewardPreviewPills()
                    }

                    GoldDivider()
                        .padding(.horizontal, LayoutConstants.spaceXL)

                    // Risk callout (enhanced)
                    riskCallout()

                    // Stats panel (ornamental)
                    statsPanel()

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }

            // Pinned CTA
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [DarkFantasyTheme.bgPrimary.opacity(0), DarkFantasyTheme.bgPrimary],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 56)
                .allowsHitTesting(false)

                VStack(spacing: LayoutConstants.spaceXS) {
                    Button {
                        Task { await vm.startRush() }
                    } label: {
                        if vm.isLoading {
                            HexPulseLoader.onGold()
                        } else {
                            Text("ENTER THE DEPTHS")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(vm.isLoading)

                    // Stamina cost indicator
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-stamina")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("3 Stamina")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.stamina)
                    }
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(
                        Capsule().fill(DarkFantasyTheme.stamina.opacity(0.08))
                    )
                    .overlay(
                        Capsule().stroke(DarkFantasyTheme.stamina.opacity(0.15), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceMD)
                .background(DarkFantasyTheme.bgPrimary)
            }
        }
        .onAppear { portalGlow = true }
        .onDisappear { portalGlow = false }
    }

    // MARK: - Reward Preview Pills (replaced room map)

    @ViewBuilder
    func rewardPreviewPills() -> some View {
        let rewards: [(String, String, Color)] = [
            ("icon-gold", "Gold", DarkFantasyTheme.gold),
            ("icon-xp", "XP", DarkFantasyTheme.xpRing),
            ("reward-loot", "Loot", DarkFantasyTheme.cyan),
            ("icon-gems", "Rare+", DarkFantasyTheme.stamina),
        ]

        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(rewards.enumerated()), id: \.offset) { _, reward in
                let (icon, text, color) = reward
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text(text)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(color)
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    Capsule().fill(color.opacity(0.06))
                )
                .overlay(
                    Capsule().stroke(color.opacity(0.15), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Dungeon Dust Overlay

    @ViewBuilder
    func dungeonDustOverlay() -> some View {
        Canvas { context, size in
            let particleCount = 12
            for i in 0..<particleCount {
                let seed = Double(i) * 137.5
                let phase = dustPhase + CGFloat(seed)
                let x = (sin(phase * 0.013 + seed) * 0.5 + 0.5) * size.width
                let y = (cos(phase * 0.009 + seed * 0.7) * 0.5 + 0.5) * size.height
                let particleSize = 2.0 + sin(seed) * 1.5
                let opacity = 0.08 + sin(phase * 0.02 + seed) * 0.12

                let color = i % 3 == 0
                    ? DarkFantasyTheme.gold.opacity(opacity)
                    : DarkFantasyTheme.purple.opacity(opacity * 0.7)

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                    with: .color(color)
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            // Use Timer-based approach to avoid withAnimation conflict with .transaction
            Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
                dustPhase += 1
            }
        }
        .onDisappear { dustPhase = 0 }
    }

    // MARK: - Risk Callout (Enhanced)

    @ViewBuilder
    func riskCallout() -> some View {
        HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
            Image("rush-ui-combat-skull")
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                .shadow(color: DarkFantasyTheme.danger.opacity(0.3), radius: 8)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("ONE LIFE ONLY")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .shadow(color: DarkFantasyTheme.danger.opacity(0.25), radius: 6)
                Text("Defeat = lose all gold & XP. Escape anytime to keep rewards.")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .padding(LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.danger.opacity(0.06),
                glowColor: DarkFantasyTheme.danger.opacity(0.03),
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.04, bottomShadow: 0.08)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.danger.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.danger.opacity(portalGlow ? 0.3 : 0.12), lineWidth: 1)
                .animation(MotionConstants.breathing, value: portalGlow)
        )
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.danger.opacity(0.08), radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    // MARK: - Stats Panel (Ornamental)

    @ViewBuilder
    func statsPanel() -> some View {
        HStack(spacing: 0) {
            statCell(value: "12", label: "ROOMS", icon: "rush-node-combat")
            statDivider()
            statCell(value: "1", label: "SHOP", icon: "rush-dungeon-merchant")
            statDivider()
            statCell(value: "2", label: "BOSSES", icon: "rush-node-miniboss")
            statDivider()
            statCell(value: "2", label: "EVENTS", icon: "rush-node-event")
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.25), length: 12, thickness: 1.5)
        .compositingGroup()
        .cardShadow()
    }

    @ViewBuilder
    func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .opacity(0.6)
            Text(value)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .shadow(color: DarkFantasyTheme.goldGlow, radius: 8)
                .monospacedDigit()
            Text(label)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
    }

    @ViewBuilder
    func statDivider() -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, DarkFantasyTheme.gold.opacity(0.2), Color.clear],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 1)
            .padding(.vertical, LayoutConstants.spaceSM)
    }

    // MARK: - Rush View (Active)

}
