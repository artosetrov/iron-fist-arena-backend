import SwiftUI

/// Full boss detail screen — opened when tapping a DungeonBossCard.
/// Used as a NavigationStack push (isNavigationMode = true, default)
/// or as a sheet for legacy/fallback.
struct BossDetailSheet: View {
    let boss: BossInfo
    let state: BossState
    let bossIndex: Int
    let stamina: Int
    let energyCost: Int
    let isFighting: Bool
    let onFight: () -> Void
    let onLootTap: (LootPreview) -> Void
    /// When true: full-screen nav push with toolbar back button (no sheet modifiers).
    var isNavigationMode: Bool = true

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var selectedLootForModal: LootPreview? = nil
    @State private var showLootModal = false
    @State private var hasTriggeredReveal = false

    private var stateColor: Color {
        switch state {
        case .defeated: return DarkFantasyTheme.success
        case .current: return DarkFantasyTheme.bossBorderPurple
        case .locked: return DarkFantasyTheme.lockedGray
        }
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgDungeonGradient.ignoresSafeArea()

            atmosphericBackdrop

            ScrollView {
                VStack(spacing: LayoutConstants.sectionGap) {
                    heroPortraitSection
                    titleAndStatusSection
                    loreCard

                    if !boss.loot.isEmpty {
                        lootPillRow
                    }

                    Spacer(minLength: LayoutConstants.spaceLG)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, isNavigationMode ? LayoutConstants.spaceMD : LayoutConstants.spaceLG)
                .padding(.bottom, state == .current ? 100 : LayoutConstants.spaceLG)
                .frame(maxWidth: .infinity)
            }

            // Sticky fight button at bottom (only for current boss)
            if state == .current {
                VStack {
                    Spacer()
                    stickyFightButton
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }

            // Fullscreen loading overlay when fight is in progress
            if isFighting {
                ZStack {
                    DarkFantasyTheme.bgAbyss.opacity(0.75)
                        .ignoresSafeArea()

                    VStack(spacing: LayoutConstants.spaceMD) {
                        HexPulseLoader(.standard, message: "PREPARING FOR BATTLE")
                    }
                    .padding(LayoutConstants.spaceLG)
                    .background(
                        RadialGlowBackground(
                            baseColor: DarkFantasyTheme.bgSecondary,
                            glowColor: DarkFantasyTheme.gold.opacity(0.08),
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
                }
                .transition(.opacity)
            }
        }
        // Sheet mode only: close X button + sheet presentation modifiers
        .overlay(alignment: .topTrailing) {
            if !isNavigationMode {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.closeButton)
                .padding(.top, LayoutConstants.spaceMD)
                .padding(.trailing, LayoutConstants.screenPadding)
            }
        }
        // Loot detail modal — renders ON TOP of boss detail (FIX #4)
        .overlay {
            if showLootModal, let loot = selectedLootForModal {
                LootPreviewSheet(loot: loot, onClose: {
                    withAnimation(MotionConstants.snappy) {
                        showLootModal = false
                    }
                })
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .modifier(BossDetailPresentationModifier(isNavigationMode: isNavigationMode))
        .navigationBarBackButtonHidden(isNavigationMode)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if isNavigationMode {
                ToolbarItem(placement: .navigationBarLeading) {
                    HubLogoButton { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text(boss.name.uppercased())
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(stateColor)
                        .tracking(2)
                        .lineLimit(1)
                }
            }
        }
        .onAppear { maybeTriggerReveal() }
    }

    // MARK: - Boss Reveal (once-per-boss ceremony)

    /// Fires the root-level `BossRevealOverlayView` the first time the
    /// player opens a real boss in `.current` state. Gated by
    /// UserDefaults so subsequent visits skip the ceremony.
    private func maybeTriggerReveal() {
        guard !hasTriggeredReveal else { return }
        guard boss.isRealBoss else { return }
        guard state == .current else { return }

        let key = "bossRevealSeen_\(boss.name)_\(boss.id)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        hasTriggeredReveal = true

        // Small delay so the sheet/nav push animation settles before
        // the overlay fades in — avoids a double transition.
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.navigationDelay) {
            let data = BossRevealData.fromDungeonBoss(
                boss,
                onChallenge: { appState.dismissBossReveal() },
                onSkip: { appState.dismissBossReveal() }
            )
            appState.presentBossReveal(data)
        }
    }

    // MARK: - Atmospheric Backdrop

    /// Full-screen blurred boss image behind content. Mirrors the prototype's
    /// dusty volumetric-light vibe without fighting the card hierarchy.
    private var atmosphericBackdrop: some View {
        ZStack {
            Group {
                if UIImage(named: boss.fullImage) != nil {
                    Image(boss.fullImage).resizable().scaledToFill()
                } else if UIImage(named: boss.portraitImage) != nil {
                    Image(boss.portraitImage).resizable().scaledToFill()
                } else {
                    Color.clear
                }
            }
            .opacity(state == .locked ? 0.12 : 0.22)
            .blur(radius: 14)
            .saturation(0.35)
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    DarkFantasyTheme.bgDungeonDeep.opacity(0.3),
                    DarkFantasyTheme.bgDungeonDeep.opacity(0.6),
                    DarkFantasyTheme.bgDungeonDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Hero Portrait Section

    private var heroPortraitSection: some View {
        let size: CGFloat = 176

        return ZStack {
            // Rarity halo glow
            Circle()
                .fill(stateColor.opacity(DarkFantasyTheme.opacityMild))
                .frame(width: size + 48, height: size + 48)
                .blur(radius: 32)

            // Physical frame
            Circle()
                .fill(DarkFantasyTheme.bgAbyss)
                .frame(width: size, height: size)
                .overlay(
                    Group {
                        if UIImage(named: boss.portraitImage) != nil {
                            Image(boss.portraitImage)
                                .resizable()
                                .scaledToFill()
                        } else if UIImage(named: boss.fullImage) != nil {
                            Image(boss.fullImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            AssetPlaceholderView(systemIcon: "flame.fill")
                                .frame(width: 64, height: 64)
                        }
                    }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                )
                .overlay(
                    Circle().stroke(stateColor.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1.5)
                )
                .overlay(
                    Circle()
                        .inset(by: 3)
                        .stroke(DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy), lineWidth: 1)
                )
                .opacity(state == .locked ? 0.5 : 1.0)
                .shadow(color: stateColor.opacity(DarkFantasyTheme.opacityMedium), radius: 18)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityOpaque), radius: 12, y: 6)

            // Floating LVL badge — overlaps bottom of portrait
            levelBadge
                .offset(y: size / 2)
        }
        .frame(height: size + LayoutConstants.spaceMD)
        .frame(maxWidth: .infinity)
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceMD)
    }

    private var levelBadge: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: "bolt.fill")
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.gold)
            Text("LVL \(boss.level)")
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .tracking(1.5)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            Capsule().fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            Capsule().stroke(DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy), radius: 6, y: 3)
    }

    // MARK: - Title & Status Section

    private var titleAndStatusSection: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            Text(boss.name.uppercased())
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .tracking(2)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityOpaque), radius: 6)
                .multilineTextAlignment(.center)

            Text(bossSubtitleLabel)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textBossDesc)
                .tracking(3)

            statusPill
        }
        .frame(maxWidth: .infinity)
    }

    private var bossSubtitleLabel: String {
        let role = boss.isRealBoss ? "BOSS" : "ENEMY"
        return "\(role) • LEVEL \(boss.level)"
    }

    @ViewBuilder
    private var statusPill: some View {
        switch state {
        case .defeated:
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "checkmark.circle.fill")
                    .font(DarkFantasyTheme.body)
                Text("DEFEATED")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .tracking(1.5)
            }
            .foregroundStyle(DarkFantasyTheme.textStatusGood)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(Capsule().fill(DarkFantasyTheme.pill(.heal, .bg)))
            .overlay(Capsule().stroke(DarkFantasyTheme.pill(.heal, .border), lineWidth: 1))

        case .current:
            HStack(spacing: LayoutConstants.spaceSM) {
                Circle()
                    .fill(DarkFantasyTheme.success)
                    .frame(width: LayoutConstants.spaceSM, height: LayoutConstants.spaceSM)
                    .shadow(color: DarkFantasyTheme.success.opacity(DarkFantasyTheme.opacityHeavy), radius: 4)
                Text("READY TO FIGHT")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .tracking(1.5)
            }
            .foregroundStyle(DarkFantasyTheme.textStatusGood)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(Capsule().fill(DarkFantasyTheme.pill(.heal, .bg)))
            .overlay(Capsule().stroke(DarkFantasyTheme.pill(.heal, .border), lineWidth: 1))

        case .locked:
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-padlock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                Text("LOCKED")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .tracking(1.5)
            }
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(Capsule().fill(DarkFantasyTheme.pill(.offline, .bg)))
            .overlay(Capsule().stroke(DarkFantasyTheme.pill(.offline, .border), lineWidth: 1))
        }
    }

    // MARK: - Lore Card (recessed italic quote)

    private var loreCard: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityMedium), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, LayoutConstants.spaceXL)

            Text("\u{201C}\(boss.extendedLore)\u{201D}")
                .font(DarkFantasyTheme.body.italic())
                .foregroundStyle(DarkFantasyTheme.textBossDesc)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(LayoutConstants.cardPadding)
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgDungeonDeep,
                glowColor: DarkFantasyTheme.bgSecondary,
                glowIntensity: 0.2,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderSubtle.opacity(DarkFantasyTheme.opacityLight))
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityStrong), radius: 4, y: 2)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("BOSS STATS")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: LayoutConstants.spaceSM
            ) {
                bossStatRow("Level", value: "\(boss.level)", color: DarkFantasyTheme.gold)
                bossStatRow("Hit Points", value: formatNumber(boss.hp), color: DarkFantasyTheme.danger)
                bossStatRow("Boss #", value: "\(boss.id) / 10", color: stateColor)
                bossStatRow("Drops", value: "\(boss.loot.count) items", color: DarkFantasyTheme.lootGold)
            }

            // HP bar
            VStack(spacing: LayoutConstants.space2XS) {
                HStack {
                    Text("HP")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Spacer()
                    Text(
                        state == .defeated
                            ? "0 / \(formatNumber(boss.hp))"
                            : "\(formatNumber(boss.hp)) / \(formatNumber(boss.hp))"
                    )
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .monospacedDigit()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.bgTertiary)

                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.dungeonHpGradient)
                            .frame(width: geo.size.width * (state == .defeated ? 0 : 1.0))
                            .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                    }
                }
                .frame(height: 14)
            }
            .padding(LayoutConstants.spaceSM + 2)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.danger.opacity(0.08))
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        }
    }

    @ViewBuilder
    private func bossStatRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary.opacity(0.5),
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.2,
                cornerRadius: LayoutConstants.radiusSM
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.radiusSM - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
    }

    // MARK: - Loot Pill Row

    private var lootPillRow: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            // Divider label — horizontal lines on both sides
            HStack(spacing: LayoutConstants.spaceMS) {
                dividerLine
                Text("POSSIBLE LOOT")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                    .tracking(2)
                dividerLine
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.spaceMS) {
                    ForEach(boss.loot) { lootItem in
                        lootPillCard(lootItem)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }
            .padding(.horizontal, -LayoutConstants.screenPadding)
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, DarkFantasyTheme.borderSubtle.opacity(DarkFantasyTheme.opacityHeavy), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    @ViewBuilder
    private func lootPillCard(_ loot: LootPreview) -> some View {
        let rarityColor = DarkFantasyTheme.rarityColor(for: loot.rarity)

        Button {
            selectedLootForModal = loot
            withAnimation(MotionConstants.snappy) { showLootModal = true }
        } label: {
            HStack(spacing: LayoutConstants.spaceMS) {
                lootIcon(loot)
                    .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(loot.rarity.displayName)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(rarityColor)
                        .tracking(1.5)
                    Text(loot.name)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(rarityColor.opacity(DarkFantasyTheme.opacityMedium), lineWidth: 1)
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityStrong), radius: 4, y: 2)
        }
        .buttonStyle(.scalePress)
    }

    @ViewBuilder
    private func lootIcon(_ loot: LootPreview) -> some View {
        if let key = loot.resolvedImageKey, UIImage(named: key) != nil {
            Image(key)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: loot.icon)
                .font(DarkFantasyTheme.iconMedium)
                .foregroundStyle(DarkFantasyTheme.rarityColor(for: loot.rarity))
        }
    }

    // MARK: - Sticky Fight Button

    private var stickyFightButton: some View {
        let hasEnergy = stamina >= energyCost

        return VStack(spacing: 0) {
            // Top fade gradient
            LinearGradient(
                colors: [Color.clear, DarkFantasyTheme.bgPrimary.opacity(0.95)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: LayoutConstants.iconMD)

            VStack(spacing: LayoutConstants.spaceXS) {
                Button {
                    HapticManager.heavy()
                    onFight()
                } label: {
                    if isFighting {
                        HexPulseLoader(.compact)
                    } else {
                        VStack(spacing: LayoutConstants.space2XS) {
                            HStack(spacing: LayoutConstants.spaceSM) {
                                // BUG-42 (QA 2026-04-10): Training Camp practice
                                // enemies (Straw Dummy, etc.) should not be called
                                // "FIGHT BOSS" — they're labeled ENEMY in the header
                                // (see line 195), so the CTA must match. Only real
                                // bosses (floor-10 culminations) keep the shield icon
                                // and "FIGHT BOSS" copy.
                                Image(systemName: boss.isRealBoss ? "bolt.shield.fill" : "bolt.fill")
                                    .font(DarkFantasyTheme.cardTitle.bold())
                                Text(boss.isRealBoss ? "FIGHT BOSS" : "FIGHT ENEMY")
                            }

                            HStack(spacing: LayoutConstants.spaceXS) {
                                Image(systemName: "bolt.fill")
                                    .font(DarkFantasyTheme.body.weight(.semibold))
                                Text("\(energyCost) Energy")
                                    .font(DarkFantasyTheme.body)
                            }
                            .opacity(0.7)
                        }
                    }
                }
                .buttonStyle(.fight(accent: DarkFantasyTheme.arenaRankGold))
                .disabled(isFighting || !hasEnergy)

                if !hasEnergy {
                    Text("Not enough energy — \(stamina)/\(energyCost)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.danger)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceSM)
            .padding(.bottom, LayoutConstants.spaceMD)
            .background(DarkFantasyTheme.bgPrimary.opacity(0.95))
            .overlay(alignment: .top) {
                FiligreeLine(
                    color: DarkFantasyTheme.gold.opacity(0.3),
                    notchColor: DarkFantasyTheme.gold.opacity(0.5),
                    notchCount: 5,
                    notchSize: 3
                )
            }
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Presentation modifier (sheet mode only)

/// Animated diamond dot for loading indicator — matches LoadingOverlay style.
private struct DiamondLoadingDot: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(DarkFantasyTheme.gold)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(45))
            .opacity(isAnimating ? 1.0 : 0.3)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: MotionConstants.reward)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

private struct BossDetailPresentationModifier: ViewModifier {
    let isNavigationMode: Bool
    func body(content: Content) -> some View {
        if isNavigationMode {
            content
        } else {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(DarkFantasyTheme.bgPrimary)
                .presentationCornerRadius(20)
        }
    }
}
