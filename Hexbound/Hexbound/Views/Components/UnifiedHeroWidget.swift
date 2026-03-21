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
    var onAllocateStats: (() -> Void)? = nil
    var onRefillStamina: (() -> Void)? = nil

    @Environment(AppState.self) private var appState
    @State private var healFlash = false

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
    }

    // MARK: - Avatar Section (fixed 72×72 square with XP Ring)

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

            // Level badge (bottom-left)
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
                        .stroke(DarkFantasyTheme.xpRing, lineWidth: 1)
                )
                .offset(y: LayoutConstants.space2XS)
        }
        .frame(width: size, height: size)
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

<<<<<<< HEAD
            // Currencies (when visible — animated tick-up)
=======
            // Currencies (when visible)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
            if showCurrencies {
                HStack(spacing: LayoutConstants.spaceMS) {
                    // Gold
                    HStack(spacing: LayoutConstants.space2XS) {
                        Image("icon-gold")
                            .resizable()
                            .frame(width: 14, height: 14)

<<<<<<< HEAD
                        NumberTickUpText(
                            value: character.gold,
                            color: DarkFantasyTheme.textGold,
                            font: DarkFantasyTheme.body(size: LayoutConstants.textLabel)
                        )
                        .lineLimit(1)
=======
                        Text(formatGold(character.gold))
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textGold)
                            .monospacedDigit()
                            .lineLimit(1)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                    }

                    // Gems (hub and hero only)
                    if context == .hub || context == .hero {
                        HStack(spacing: LayoutConstants.space2XS) {
                            Image("icon-gems")
                                .resizable()
                                .frame(width: 14, height: 14)

<<<<<<< HEAD
                            NumberTickUpText(
                                value: character.gems ?? 0,
                                color: DarkFantasyTheme.gems,
                                font: DarkFantasyTheme.body(size: LayoutConstants.textLabel)
                            )
                            .lineLimit(1)
=======
                            Text("\(character.gems ?? 0)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.gems)
                                .monospacedDigit()
                                .lineLimit(1)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                        }
                    }
                }
            }
        }
    }

    // MARK: - Row 2: HP Bar (full width, text inside)

    private var hpBarSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 0.5)
                    )

                // Fill
                RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                    .fill(DarkFantasyTheme.canonicalHpGradient(percentage: hpPercent))
                    .frame(width: geo.size.width * max(0.02, min(1, hpPercent)))
                    .opacity(isCriticalHP ? pulseOpacity : 1)

                // Text centered inside
                Text("\(character.currentHp)/\(character.maxHp)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.widgetBarFont).bold())
<<<<<<< HEAD
                    .foregroundStyle(.textPrimary)
                    .shadow(color: .bgAbyss.opacity(0.6), radius: 1, x: 0, y: 1)
=======
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: LayoutConstants.widgetBarHeight)
        .animation(.easeInOut(duration: 0.4), value: hpPercent)
    }

    @State private var pulseOpacity: Double = 1.0

    // MARK: - Row 3: Stamina Bar (full width, text inside)

    private var staminaBarSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 0.5)
                    )

                // Fill
                RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                    .fill(DarkFantasyTheme.staminaGradient)
                    .frame(width: geo.size.width * max(0.02, min(1, staminaPercent)))

<<<<<<< HEAD
                // Text centered inside (animated tick-up)
                HStack(spacing: 2) {
                    NumberTickUpText(
                        value: character.currentStamina,
                        color: .textPrimary,
                        font: DarkFantasyTheme.body(size: LayoutConstants.widgetBarFont).bold()
                    )
                    Text("/\(character.maxStamina)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.widgetBarFont).bold())
                        .foregroundStyle(.textPrimary)
                }
                .shadow(color: .bgAbyss.opacity(0.6), radius: 1, x: 0, y: 1)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: LayoutConstants.widgetBarHeight)
        .animation(.easeInOut(duration: MotionConstants.normal), value: staminaPercent)
        // Low stamina: subtle breathing pulse as urgency hint
        .breathing(scale: 0.01, isActive: isLowStamina)
=======
                // Text centered inside
                Text("\(character.currentStamina)/\(character.maxStamina)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.widgetBarFont).bold())
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: LayoutConstants.widgetBarHeight)
        .animation(.easeInOut(duration: 0.4), value: staminaPercent)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
    }

    // MARK: - Row 4: Pills (Context-dependent, shown below bars)

    @ViewBuilder
    private var row4Content: some View {
        // Priority logic: first match wins
        if isCriticalHP && healthPotionCount > 0 {
            WidgetPill(
<<<<<<< HEAD
                icon: "bandage",
=======
                icon: "🩹",
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                text: "Heal",
                count: healthPotionCount > 0 ? "×\(healthPotionCount)" : nil,
                style: .urgent,
                isInteractive: true,
                action: {
                    onUseHealthPotion?()
                    triggerHealFlash()
                }
            )
            .frame(height: LayoutConstants.pillHeight)
        } else if isCriticalHP && healthPotionCount == 0 {
<<<<<<< HEAD
            WidgetPill(icon: "exclamationmark.triangle", text: "Critical HP", style: .warn)
                .frame(height: LayoutConstants.pillHeight)
        } else if isLowHP && healthPotionCount > 0 {
            WidgetPill(
                icon: "bandage",
=======
            WidgetPill(icon: "⚠️", text: "Critical HP", style: .warn)
                .frame(height: LayoutConstants.pillHeight)
        } else if isLowHP && healthPotionCount > 0 {
            WidgetPill(
                icon: "🩹",
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                text: "Heal",
                count: "×\(healthPotionCount)",
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
<<<<<<< HEAD
                icon: "bolt",
=======
                icon: "⚡",
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                text: "Energy",
                count: "×\(staminaPotionCount)",
                style: .energy,
                isInteractive: true,
                action: {
                    onUseStaminaPotion?()
                }
            )
            .frame(height: LayoutConstants.pillHeight)
        } else if statPointsAvailable > 0 && !hasBrokenGear {
            WidgetPill(
<<<<<<< HEAD
                icon: "sparkles",
=======
                icon: "✨",
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                text: "Allocate Stats",
                style: .stat,
                isInteractive: true,
                action: {
                    onAllocateStats?()
                }
            )
            .frame(height: LayoutConstants.pillHeight)
        } else if statPointsAvailable > 0 && hasBrokenGear {
            HStack(spacing: LayoutConstants.pillSpacing) {
                WidgetPill(
<<<<<<< HEAD
                    icon: "sparkles",
=======
                    icon: "✨",
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                    text: "Allocate Stats",
                    style: .stat,
                    isInteractive: true,
                    action: {
                        onAllocateStats?()
                    }
                )
                .frame(height: LayoutConstants.pillHeight)

<<<<<<< HEAD
                WidgetPill(icon: "hammer", text: "Repair", style: .warn)
                    .frame(height: LayoutConstants.pillHeight)
            }
        } else if hasBrokenGear {
            WidgetPill(icon: "hammer", text: "Repair Gear", style: .warn)
=======
                WidgetPill(icon: "🔨", text: "Repair", style: .warn)
                    .frame(height: LayoutConstants.pillHeight)
            }
        } else if hasBrokenGear {
            WidgetPill(icon: "🔨", text: "Repair Gear", style: .warn)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                .frame(height: LayoutConstants.pillHeight)
        } else if context == .arena {
            arenaRow4Pills
        }
        // Default: no pills row (clean layout per prototype)
    }

    // MARK: - Arena Pills

    private var arenaRow4Pills: some View {
        HStack(spacing: LayoutConstants.pillSpacing) {
            let rank = PvPRank.fromRating(character.pvpRating)

            WidgetPill(
                icon: rank.icon,
                text: "\(character.pvpRating)",
                style: .pvp
            )
            .frame(height: LayoutConstants.pillHeight)

            if (character.pvpWinStreak ?? 0) > 0 {
                WidgetPill(
<<<<<<< HEAD
                    icon: "flame",
=======
                    icon: "🔥",
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                    text: "Streak: \(character.pvpWinStreak ?? 0)",
                    style: .streak
                )
                .frame(height: LayoutConstants.pillHeight)
            }

            if character.firstWinToday == true {
                WidgetPill(
<<<<<<< HEAD
                    icon: "",
                    text: "First Win!",
                    imageAsset: "reward-first-win",
=======
                    icon: "🎁",
                    text: "First Win!",
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
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
