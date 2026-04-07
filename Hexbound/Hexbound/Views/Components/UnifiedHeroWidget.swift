import SwiftUI

/// Unified hero widget replacing HubCharacterCard, StaminaBarView header, and currency displays.
/// Adapts layout and actions based on context (Hub, Arena, Dungeon, Hero).
///
/// Layout:
/// ┌───────────────────────────────────────────────────┐
/// │ [Avatar]  Name           💰 18,838  💎 151  ⚡ 120/120 │
/// │ [Lv.14]  ████████████ HP 1,030/1,030 ████████████ │
/// └───────────────────────────────────────────────────┘
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
    private var isCriticalHP: Bool { hpPercent < 0.25 }
    private var isStaminaLow: Bool { character.maxStamina > 0 && Double(character.currentStamina) / Double(character.maxStamina) < 0.15 }
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

            // MARK: Right — Name/Resources, HP bar
            VStack(alignment: .leading, spacing: LayoutConstants.widgetRowGap) {
                // Row 1: Name + Currencies + Stamina inline
                nameAndResourcesRow

                // Row 2: HP bar (full width, text inside)
                hpBarSection
            }
        }
        .frame(minHeight: LayoutConstants.widgetMinHeight)
        .padding(.vertical, LayoutConstants.widgetPadding)
        .padding(.horizontal, LayoutConstants.widgetPaddingH)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.widgetRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.widgetRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.widgetRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .compositingGroup()
        .cardShadow()
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .animation(MotionConstants.smooth, value: hpPercent)
        .onChange(of: isCriticalHP) { _, critical in
            if critical {
                withAnimation(MotionConstants.pulse) {
                    lowHPPulse = true
                }
            } else {
                withAnimation(MotionConstants.smooth) {
                    lowHPPulse = false
                }
            }
        }
        .onAppear {
            if isCriticalHP {
                withAnimation(MotionConstants.pulse) {
                    lowHPPulse = true
                }
            }
        }
        .onDisappear {
            // Stop continuous animations when widget leaves screen
            lowHPPulse = false
            statBadgePulse = false
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
                .font(DarkFantasyTheme.badge.weight(.bold))
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
                    .animation(MotionConstants.pulse, value: lowHPPulse)
            }
        }
        .frame(width: size, height: size)
        // Stat points badge (top-right of avatar, pulsing)
        .overlay(alignment: .topTrailing) {
            if statPointsAvailable > 0 {
                Text("+\(statPointsAvailable)")
                    .font(DarkFantasyTheme.badge.bold())
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .padding(.horizontal, LayoutConstants.spaceXS)
                .padding(.vertical, LayoutConstants.space2XS)
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

    // MARK: - Row 1: Name + Currencies + Stamina Inline

    private var nameAndResourcesRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Character name
            Text(character.characterName)
                .font(DarkFantasyTheme.cardTitle)
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

            // Stamina inline (always visible — it's an action resource, not a currency)
            staminaInlineView
        }
    }

    // MARK: - Stamina Inline Display (⚡ 85/120)

    private var staminaInlineView: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image("icon-stamina")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)

            HStack(spacing: 0) {
                NumberTickUpText(
                    value: character.currentStamina,
                    color: isStaminaLow ? DarkFantasyTheme.danger : DarkFantasyTheme.stamina,
                    font: DarkFantasyTheme.uiLabel.bold()
                )
                Text("/\(character.maxStamina)")
                    .font(DarkFantasyTheme.uiLabel.bold())
                    .foregroundStyle(
                        (isStaminaLow ? DarkFantasyTheme.danger : DarkFantasyTheme.stamina)
                            .opacity(0.6)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stamina \(character.currentStamina) of \(character.maxStamina)")
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

#Preview("Zero Stamina") {
    let mockChar = Character(
        id: "test-4",
        characterName: "Exhausted",
        characterClass: .mage,
        origin: .skeleton,
        avatar: "skin-mage-001",
        level: 10,
        experience: 3000,
        gold: 5000,
        gems: 20,
        currentHp: 200,
        maxHp: 200,
        currentStamina: 0,
        maxStamina: 120,
        pvpRating: 1200,
        pvpWins: 5,
        pvpLosses: 3,
        pvpWinStreak: 0,
        firstWinToday: false,
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
#endif
