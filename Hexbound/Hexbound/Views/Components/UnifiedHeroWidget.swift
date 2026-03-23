import SwiftUI

/// Unified hero widget replacing HubCharacterCard, StaminaBarView header, and currency displays.
/// Adapts layout and actions based on context (Hub, Arena, Dungeon, Hero).
///
/// Layout (matching prototype):
/// ┌──────────────────────────────────────────┐
/// │ [Avatar]  Name              💎 18,838 💠 151 │
/// │ [Lv.14]  ████████ HP 1,030/1,030 ████████  │
/// │          ████████ STA 120/120 ████████████  │
/// │          [Pills row — conditional]          │
/// └──────────────────────────────────────────┘
@MainActor
struct UnifiedHeroWidget: View {
    let character: Character
    let context: WidgetContext
    var showCurrencies: Bool = true
    var onTap: (() -> Void)? = nil
    var onUseHealthPotion: (() -> Void)? = nil
    var onUseStaminaPotion: (() -> Void)? = nil
    var onRefillStamina: (() -> Void)? = nil

    @Environment(AppState.self) private var appState
    @State private var healFlash = false
    @State private var lowHPPulse = false
    @State private var statBadgePulse = false

    enum WidgetContext {
        case hub
        case arena
        case dungeon
        case hero
    }

    private var hpPercent: Double { character.hpPercentage }
    private var staminaPercent: Double {
        guard character.maxStamina > 0 else { return 0 }
        return Double(character.currentStamina) / Double(character.maxStamina)
    }

    private var isCriticalHP: Bool { hpPercent < 0.25 }
    private var isLowHP: Bool { hpPercent < 0.50 }
    private var isLowStamina: Bool { staminaPercent < 0.30 }

    private var healthPotionCount: Int {
        guard let items = appState.cachedInventory else { return 0 }
        return items.filter { $0.consumableType?.contains("health_potion") == true }
            .reduce(0) { $0 + ($1.quantity ?? 0) }
    }

    private var staminaPotionCount: Int {
        guard let items = appState.cachedInventory else { return 0 }
        return items.filter { $0.consumableType?.contains("stamina_potion") == true }
            .reduce(0) { $0 + ($1.quantity ?? 0) }
    }

    private var hasBrokenGear: Bool {
        guard let items = appState.cachedInventory else { return false }
        return items.contains { ($0.durability ?? 1) <= 0 && ($0.isEquipped ?? false) }
    }

    private var statPointsAvailable: Int { character.statPoints ?? 0 }

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    var body: some View {
        HStack(spacing: LayoutConstants.widgetGap) {
            // MARK: Left — Avatar with XP Ring + Level Badge
            avatarSection

            // MARK: Right — Name/Currencies, HP bar, Stamina bar, Pills
            VStack(alignment: .leading, spacing: LayoutConstants.widgetRowGap) {
                // Row 1: Name + Currencies
                nameAndCurrenciesRow

                // Row 2: HP bar (full width, text inside)
                hpBarSection

                // Row 3: Stamina bar (full width, text inside)
                staminaBarSection

                // Row 4: Pills (conditional)
                row4Content
            }
        }
        .frame(minHeight: LayoutConstants.widgetMinHeight)
        .padding(.vertical, LayoutConstants.widgetPadding)
        .padding(.horizontal, LayoutConstants.widgetPaddingH)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.widgetRadius)
                .fill(DarkFantasyTheme.bgCardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.widgetRadius)
                .stroke(DarkFantasyTheme.bgCardBorder, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.widgetRadius)
                .fill(DarkFantasyTheme.healFlash.opacity(healFlash ? 0.25 : 0))
                .allowsHitTesting(false)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .animation(.easeInOut(duration: 0.3), value: hpPercent)
        .task {
            if isCriticalHP {
                while true {
                    try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                    withAnimation(.easeInOut(duration: 0.8)) {
                        lowHPPulse.toggle()
                    }
                }
            }
        }

    }

    // MARK: - Avatar Section (fixed 72×72 square with XP Ring + Stat Badge)

    private var avatarSection: some View {
        let size = LayoutConstants.widgetAvatarFullSize
        let innerSize = size - LayoutConstants.widgetXpRingInset * 2

        return ZStack(alignment: .bottom) {
            // XP Ring background
            RoundedRectangle(cornerRadius: LayoutConstants.widgetAvatarRadius + 2)
                .stroke(DarkFantasyTheme.xpRingTrack, lineWidth: LayoutConstants.widgetXpRingWidth)

            // XP Ring fill
            XPRingShape()
                .trim(from: 0, to: character.xpPercentage)
                .stroke(
                    DarkFantasyTheme.xpRing,
                    style: StrokeStyle(lineWidth: LayoutConstants.widgetXpRingWidth, lineCap: .round)
                )
                .shadow(color: DarkFantasyTheme.xpRing.opacity(0.4), radius: 4)
                .animation(.easeInOut(duration: 1.0), value: character.xpPercentage)

            // Avatar image
            AvatarImageView(
                skinKey: character.avatar,
                characterClass: character.characterClass,
                size: innerSize
            )
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.widgetAvatarRadius))

            // Corner diamond accents on avatar frame
            CornerDiamondOverlay(color: DarkFantasyTheme.xpRing.opacity(0.6), size: 3)

            // Level badge (bottom-left) with glow
            Text("Lv. \(character.level)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.widgetLevelBadgeFont).weight(.bold))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.horizontal, LayoutConstants.spaceXS)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(
                    Capsule()
                        .fill(DarkFantasyTheme.bgElevated)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [DarkFantasyTheme.xpRing, DarkFantasyTheme.xpRing.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: DarkFantasyTheme.xpRing.opacity(0.3), radius: 4)
                .offset(y: LayoutConstants.space2XS)

            // Low HP red pulsing overlay
            if isCriticalHP {
                Circle()
                    .fill(DarkFantasyTheme.danger.opacity(lowHPPulse ? 0.3 : 0))
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: lowHPPulse)
            }
        }
        .frame(width: size, height: size)
        // Stat points badge (top-right of avatar, pulsing)
        .overlay(alignment: .topTrailing) {
            if statPointsAvailable > 0 {
                Text("+\(statPointsAvailable)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .padding(.horizontal, LayoutConstants.spaceXS)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(DarkFantasyTheme.goldBright)
                )
                .overlay(
                    Capsule()
                        .stroke(DarkFantasyTheme.bgAbyss, lineWidth: 1.5)
                )
                .shadow(
                    color: DarkFantasyTheme.goldBright.opacity(statBadgePulse ? 0.8 : 0.2),
                    radius: statBadgePulse ? 8 : 3
                )
                .offset(x: 4, y: -4)
                .accessibilityLabel("\(statPointsAvailable) stat points available")
            }
        }
        .onAppear {
            if statPointsAvailable > 0 {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    statBadgePulse = true
                }
            }
        }
        .onChange(of: statPointsAvailable) { _, newVal in
            if newVal > 0 && !statBadgePulse {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    statBadgePulse = true
                }
            } else if newVal == 0 {
                statBadgePulse = false
            }
        }
    }

    // MARK: - Row 1: Name + Currencies

    private var nameAndCurrenciesRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Character name
            Text(character.characterName)
                .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: LayoutConstants.spaceXS)

            // Currencies (unified component, compact size)
            if showCurrencies {
                CurrencyDisplay(
                    gold: character.gold,
                    gems: character.gems,
                    size: .compact,
                    showGems: context == .hub || context == .hero
                )
            }
        }
    }

    // MARK: - Row 2: HP Bar (unified component, widget size)

    private var hpBarSection: some View {
        HPBarView(
            currentHp: character.currentHp,
            maxHp: character.maxHp,
            size: .widget,
            pulseOnCritical: isCriticalHP
        )
    }

    // MARK: - Row 3: Stamina Bar (widget-size inline bar with tick-up text)
    // Note: StaminaBarView doesn't have a .widget size with NumberTickUpText,
    // so we keep a slim custom version here that delegates to the shared gradient.

    private var staminaBarSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 0.5)
                    )

                RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                    .fill(DarkFantasyTheme.staminaGradient)
                    .frame(width: geo.size.width * max(0.02, min(1, staminaPercent)))

                HStack(spacing: 2) {
                    NumberTickUpText(
                        value: character.currentStamina,
                        color: DarkFantasyTheme.textPrimary,
                        font: DarkFantasyTheme.body(size: LayoutConstants.widgetBarFont).bold()
                    )
                    Text("/\(character.maxStamina)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.widgetBarFont).bold())
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 1, x: 0, y: 1)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: LayoutConstants.widgetBarHeight)
        .animation(.easeInOut(duration: MotionConstants.normal), value: staminaPercent)
        .breathing(scale: 0.01, isActive: isLowStamina)
    }

    // MARK: - Row 4: Pills (Context-dependent, shown below bars)

    @ViewBuilder
    private var row4Content: some View {
        // Priority logic: first match wins
        if isCriticalHP && healthPotionCount > 0 {
            WidgetPill(
                icon: "",
                text: "Heal",
                count: "×\(healthPotionCount)",
                imageAsset: "pot_health_small",
                style: .urgent,
                isInteractive: true,
                action: {
                    onUseHealthPotion?()
                    triggerHealFlash()
                }
            )
            .frame(height: LayoutConstants.pillHeight)
        } else if isCriticalHP && healthPotionCount == 0 {
            WidgetPill(icon: "", text: "Critical HP", imageAsset: "icon-vitality", style: .warn)
                .frame(height: LayoutConstants.pillHeight)
        } else if isLowHP && healthPotionCount > 0 {
            WidgetPill(
                icon: "",
                text: "Heal",
                count: "×\(healthPotionCount)",
                imageAsset: "pot_health_small",
                style: .heal,
                isInteractive: true,
                action: {
                    onUseHealthPotion?()
                    triggerHealFlash()
                }
            )
            .frame(height: LayoutConstants.pillHeight)
        } else if isLowStamina && staminaPotionCount > 0 {
            WidgetPill(
                icon: "",
                text: "Energy",
                count: "×\(staminaPotionCount)",
                imageAsset: "pot_stamina_small",
                style: .energy,
                isInteractive: true,
                action: {
                    onUseStaminaPotion?()
                }
            )
            .frame(height: LayoutConstants.pillHeight)
        } else if hasBrokenGear {
            WidgetPill(icon: "", text: "Repair Gear", imageAsset: "icon-strength", style: .warn)
                .frame(height: LayoutConstants.pillHeight)
        } else if context == .arena {
            arenaRow4Pills
        }
        // Default: no pills row (clean layout per prototype)
    }

    // MARK: - Arena Pills

    private var arenaRow4Pills: some View {
        HStack(spacing: LayoutConstants.pillSpacing) {
            WidgetPill(
                icon: "",
                text: "\(character.pvpRating)",
                imageAsset: "icon-pvp-rating",
                style: .pvp
            )
            .frame(height: LayoutConstants.pillHeight)

            if (character.pvpWinStreak ?? 0) > 0 {
                WidgetPill(
                    icon: "",
                    text: "Streak: \(character.pvpWinStreak ?? 0)",
                    imageAsset: "icon-wins",
                    style: .streak
                )
                .frame(height: LayoutConstants.pillHeight)
            }

            if character.firstWinToday == true {
                WidgetPill(
                    icon: "",
                    text: "First Win!",
                    imageAsset: "reward-first-win",
                    style: .bonus
                )
                .frame(height: LayoutConstants.pillHeight)
            }
        }
    }

    // MARK: - Helpers

    private func triggerHealFlash() {
        withAnimation(.easeIn(duration: 0.15)) { healFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) { healFlash = false }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Hub Context") {
    let mockChar = Character(
        id: "test-1",
        characterName: "Degon",
        characterClass: .warrior,
        origin: .human,
        avatar: "skin-warrior-001",
        level: 14,
        experience: 5500,
        gold: 18838,
        gems: 151,
        currentHp: 1030,
        maxHp: 1030,
        currentStamina: 120,
        maxStamina: 120,
        pvpRating: 1650,
        pvpWins: 42,
        pvpLosses: 18,
        pvpWinStreak: 3,
        firstWinToday: true,
        statPoints: 0
    )

    return UnifiedHeroWidget(
        character: mockChar,
        context: .hub,
        showCurrencies: true
    )
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
    .environment(AppState())
}

#Preview("Arena Context") {
    let mockChar = Character(
        id: "test-2",
        characterName: "Shadowblade",
        characterClass: .rogue,
        origin: .orc,
        avatar: "skin-rogue-002",
        level: 22,
        experience: 8200,
        gold: 75000,
        gems: 320,
        currentHp: 95,
        maxHp: 95,
        currentStamina: 30,
        maxStamina: 30,
        pvpRating: 2150,
        pvpWins: 87,
        pvpLosses: 25,
        pvpWinStreak: 7,
        firstWinToday: false,
        statPoints: 0
    )

    return UnifiedHeroWidget(
        character: mockChar,
        context: .arena,
        showCurrencies: false
    )
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
    .environment(AppState())
}

#Preview("Low HP + Potions") {
    let mockChar = Character(
        id: "test-3",
        characterName: "Grimhold",
        characterClass: .warrior,
        origin: .human,
        avatar: "skin-warrior-001",
        level: 15,
        experience: 5500,
        gold: 42500,
        gems: 150,
        currentHp: 35,
        maxHp: 180,
        currentStamina: 8,
        maxStamina: 30,
        pvpRating: 1650,
        pvpWins: 42,
        pvpLosses: 18,
        pvpWinStreak: 0,
        firstWinToday: false,
        statPoints: 2
    )

    return UnifiedHeroWidget(
        character: mockChar,
        context: .hub,
        showCurrencies: true
    )
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
    .environment(AppState())
}
#endif
