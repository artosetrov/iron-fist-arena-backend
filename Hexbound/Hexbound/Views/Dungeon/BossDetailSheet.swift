import SwiftUI

/// Boss dossier — opened from the dungeon stage (tap the boss or the dossier
/// button). Always a NavigationStack push; the name is historical.
///
/// Layout (2026-10-15): the boss full-height on a lit floor, name and stage
/// line, HP / level / energy tiles, the hook line and the lore (three lines,
/// "Read more" expands), possible loot as tiles, FIGHT pinned at the bottom.
/// The old blurred full-screen backdrop was `scaledToFill` without a clip
/// and widened the whole screen, pushing the lore off the right edge.
struct BossDetailSheet: View {
    let boss: BossInfo
    let state: BossState
    let bossIndex: Int
    let stamina: Int
    let energyCost: Int
    let isFighting: Bool
    let onFight: () -> Void
    let onLootTap: (LootPreview) -> Void
    var totalStages: Int = 10
    /// A dungeon run is open — energy was paid when it started, so this
    /// fight is free and the button shows no cost.
    var runActive: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var selectedLootForModal: LootPreview? = nil
    @State private var showLootModal = false
    @State private var hasTriggeredReveal = false
    @State private var loreExpanded = false

    private static let heroHeight: CGFloat = 300
    private static let tileHeight: CGFloat = 64

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgDungeonGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroSection

                    VStack(spacing: LayoutConstants.sectionGap) {
                        statTiles
                        if state != .locked {
                            loreSection
                        }
                        if !boss.loot.isEmpty {
                            lootSection
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceMD)
                }
                .padding(.bottom, state == .current ? 112 : LayoutConstants.spaceLG)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

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
        // Loot detail modal — renders ON TOP of boss detail (FIX #4)
        .overlay {
            if showLootModal, let loot = selectedLootForModal {
                LootPreviewSheet(loot: loot, onClose: {
                    withAnimation(MotionConstants.snappy) {
                        showLootModal = false
                    }
                })
                .transition(.opacity)
                .zIndex(ZLayer.modal)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                statusPill
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            BossStageArt(boss: boss, style: BossArtStyle(state))
                .frame(height: Self.heroHeight)
                .frame(maxWidth: .infinity)
                .clipped()

            Text(roleLine)
                .font(DarkFantasyTheme.body)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.gold)

            Text(state == .locked ? "???" : boss.name.uppercased())
                .font(DarkFantasyTheme.cinematicTitle)
                .tracking(1)
                .foregroundStyle(state == .current ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, LayoutConstants.screenPadding)
        }
        .accessibilityElement(children: .combine)
    }

    private var roleLine: String {
        let role = boss.isRealBoss ? "BOSS" : "SPARRING"
        return "\(role) · STAGE \(bossIndex + 1) OF \(totalStages)"
    }

    @ViewBuilder
    private var statusPill: some View {
        switch state {
        case .defeated:
            Text("Defeated")
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textStatusGood)
                .badgeCapsule(color: DarkFantasyTheme.success)
        case .current:
            Text("Ready to fight")
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textStatusGood)
                .badgeCapsule(color: DarkFantasyTheme.success)
        case .locked:
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-padlock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                Text("Locked")
                    .font(DarkFantasyTheme.body.weight(.semibold))
            }
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .badgeCapsule(color: DarkFantasyTheme.textSecondary)
        }
    }

    // MARK: - Stat Tiles

    private var statTiles: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            statTile(value: "\(boss.hp)", label: "HP", color: DarkFantasyTheme.danger)
            statTile(value: "\(boss.level)", label: "Level", color: DarkFantasyTheme.xpRing)
            statTile(value: "\(energyCost)", label: "Energy", color: DarkFantasyTheme.goldBright, icon: "icon-stamina")
        }
    }

    private func statTile(value: String, label: String, color: Color, icon: String? = nil) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: LayoutConstants.space2XS) {
                if let icon {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                }
                Text(value)
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.tileHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(color.opacity(DarkFantasyTheme.opacityMedium), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Lore

    /// The lore without the hook line it usually starts with.
    private var loreBody: String {
        let full = boss.extendedLore
        let hook = boss.hookLine
        guard full.hasPrefix(hook) else { return full }
        return String(full.dropFirst(hook.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var loreSection: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            if !boss.hookLine.isEmpty {
                Text("\u{201C}\(boss.hookLine)\u{201D}")
                    .font(DarkFantasyTheme.body.italic())
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !loreBody.isEmpty {
                Text(loreBody)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textBossDesc)
                    .lineSpacing(4)
                    .lineLimit(loreExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)

                if loreBody.count > 140 {
                    Button {
                        withAnimation(.easeInOut(duration: MotionConstants.fast)) {
                            loreExpanded.toggle()
                        }
                    } label: {
                        Text(loreExpanded ? "Show less" : "Read more")
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.gold)
                            .frame(minHeight: LayoutConstants.touchMin, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loot

    private var lootSection: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("POSSIBLE LOOT")
                .font(DarkFantasyTheme.body)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
                    GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
                ],
                spacing: LayoutConstants.spaceSM
            ) {
                ForEach(boss.loot) { loot in
                    lootTile(loot)
                }
            }
        }
    }

    private func lootTile(_ loot: LootPreview) -> some View {
        let rarityColor = DarkFantasyTheme.rarityColor(for: loot.rarity)

        return Button {
            selectedLootForModal = loot
            withAnimation(MotionConstants.snappy) { showLootModal = true }
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                lootIcon(loot)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 0) {
                    Text(loot.name)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(loot.detail)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(loot.rarity == .common ? DarkFantasyTheme.textSecondary : rarityColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .frame(height: Self.tileHeight)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(rarityColor.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(loot.name), \(loot.detail)"))
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
        let hasEnergy = runActive || stamina >= energyCost

        return VStack(spacing: 0) {
            // Top fade gradient
            LinearGradient(
                colors: [Color.clear, DarkFantasyTheme.bgPrimary.opacity(0.95)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: LayoutConstants.iconMD)

            VStack(spacing: LayoutConstants.spaceXS) {
                Button {
                    guard hasEnergy else {
                        // No dead end: the toast carries the refill.
                        HapticManager.error()
                        CharacterService.showOutOfStamina(
                            appState: appState,
                            refillGemCost: cache.gameConfig?.staminaRefillGems
                        )
                        return
                    }
                    HapticManager.heavy()
                    onFight()
                } label: {
                    if isFighting {
                        HexPulseLoader(.compact)
                    } else {
                        // BUG-42: Training Camp practice enemies are not
                        // "bosses" — only real bosses get "FIGHT BOSS".
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Text(boss.isRealBoss ? "FIGHT BOSS" : "FIGHT")
                            if !runActive {
                                HStack(spacing: LayoutConstants.space2XS) {
                                    Image("icon-stamina")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                                    Text("\(energyCost)")
                                }
                                .opacity(hasEnergy ? 1 : 0.6)
                            }
                        }
                    }
                }
                .buttonStyle(.primary)
                .disabled(isFighting)
                .accessibilityLabel(Text(runActive
                                         ? "Fight \(boss.name)"
                                         : "Fight \(boss.name), costs \(energyCost) energy"))

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
}
