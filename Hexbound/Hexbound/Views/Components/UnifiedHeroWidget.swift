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

    @Environment(AppState.self) private var appState
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
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .animation(.easeInOut(duration: 0.3), value: hpPercent)
        .onChange(of: isCriticalHP) { _, critical in
            if critical {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    lowHPPulse = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    lowHPPulse = false
                }
            }
        }
        .onAppear {
            if isCriticalHP {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    lowHPPulse = true
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
                    showGems: context == .hub || context == .hero,
                    animated: false
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
    }

    // Pills removed — contextual actions now shown via NPC widget
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
