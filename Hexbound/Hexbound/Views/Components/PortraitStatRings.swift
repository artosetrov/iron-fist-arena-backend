import SwiftUI

/// PortraitStatRings — compact stacked rings showing HP + Energy/Stamina.
///
/// ## Why this exists
/// Hero selection / portrait cards previously rendered HP and Stamina as two
/// linear bars at the bottom of the card. At small hero-grid sizes those bars
/// became cramped and unreadable. Per rule #1 (component reusability everywhere)
/// this is a single shared DS atom that any portrait-sized card can drop into
/// a top/bottom corner.
///
/// ## Design
/// Two stacked circular progress rings:
/// - HP ring — uses `DarkFantasyTheme.canonicalHpGradient(percentage:)` so the
///   color itself communicates danger (red at <25%), making a separate "LOW HP"
///   text badge unnecessary.
/// - Energy ring — uses `DarkFantasyTheme.staminaGradient`.
///
/// Each ring is composed of:
/// 1. A dark translucent background disc (`bgAbyss @ 0.55`) for punchy contrast
///    on any avatar art — no `.ultraThinMaterial` (not used elsewhere in the DS).
/// 2. A track `Circle().stroke(xpRingTrack)` at the same lineWidth.
/// 3. A trimmed `Circle().stroke(gradient)` that starts at 12 o'clock and goes
///    clockwise — matches the trim direction of `XPRingShape` and `UnifiedHeroWidget`.
/// 4. A centered SF Symbol icon (`heart.fill` / `bolt.fill`) — same assets the
///    rest of the app uses for these two stats (`DungeonBossCard`, `ItemDetailSheet`, etc.)
///
/// ## Conditional HP
/// `hideHPWhenFull` (default `true`) hides the HP ring when `hpPercentage >= 1.0`.
/// This declutters the card for healthy heroes and keeps the attention on energy —
/// the HP ring reappears the moment the hero takes any damage.
///
/// ## No animations on appear
/// Per project rule (no scale grow/shrink anywhere): the ring renders at its final
/// trim value immediately. Opacity-only transitions are used for the conditional
/// HP ring show/hide.
@MainActor
struct PortraitStatRings: View {
    /// Layout orientation for the two rings.
    enum Orientation {
        /// HP on top, Energy below. Use for top/bottom card corners.
        case vertical
        /// HP on the left, Energy on the right. Use when the rings need to sit
        /// above a horizontal stat row (e.g. `HeroSelectionCard` stat pills).
        case horizontal
    }

    // MARK: - Inputs

    let hpPercentage: Double
    let staminaPercentage: Double

    /// Stack direction. Defaults to `.vertical` — matches the original
    /// corner-badge usage and existing call sites.
    var orientation: Orientation = .vertical

    /// Outer diameter of each ring (background disc). Default matches
    /// `CardLevelBadge` size so the two read as paired chrome in card corners.
    var ringSize: CGFloat = LayoutConstants.cardLvlBadgeSize

    /// Hide the HP ring when the hero is at full HP. Default `true` — declutters
    /// healthy hero cards and makes damage immediately visible when it happens.
    var hideHPWhenFull: Bool = true

    // MARK: - Derived

    private var showHP: Bool {
        if hideHPWhenFull && hpPercentage >= 1.0 { return false }
        return true
    }

    private var clampedHP: Double { min(max(hpPercentage, 0), 1) }
    private var clampedStamina: Double { min(max(staminaPercentage, 0), 1) }

    // MARK: - Body

    @ViewBuilder
    private var ringsContent: some View {
        if showHP {
            StatRing(
                percentage: clampedHP,
                gradient: DarkFantasyTheme.canonicalHpGradient(percentage: clampedHP),
                icon: "heart.fill",
                iconColor: DarkFantasyTheme.textPrimary,
                diameter: ringSize
            )
            .transition(.opacity)
        }

        StatRing(
            percentage: clampedStamina,
            gradient: DarkFantasyTheme.staminaGradient,
            icon: "bolt.fill",
            iconColor: DarkFantasyTheme.textPrimary,
            diameter: ringSize
        )
    }

    var body: some View {
        Group {
            switch orientation {
            case .vertical:
                VStack(spacing: LayoutConstants.space2XS) {
                    ringsContent
                }
            case .horizontal:
                HStack(spacing: LayoutConstants.spaceXS) {
                    ringsContent
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showHP)
    }
}

// MARK: - StatRing (private primitive)

/// A single progress ring with centered icon. Not exposed — always used through
/// `PortraitStatRings` so hero/opponent cards stay consistent.
private struct StatRing: View {
    let percentage: Double
    let gradient: LinearGradient
    let icon: String
    let iconColor: Color
    let diameter: CGFloat

    private var lineWidth: CGFloat {
        // Ring stroke stays ~9% of diameter so it scales visually with ringSize.
        max(3, diameter * 0.09)
    }

    private var iconSize: CGFloat {
        // Icon fills ~42% of the disc interior.
        diameter * 0.42
    }

    var body: some View {
        ZStack {
            // 1. Dark background disc — contrast against avatar art
            Circle()
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.55))

            // 2. Track ring
            Circle()
                .stroke(DarkFantasyTheme.xpRingTrack, lineWidth: lineWidth)
                .padding(lineWidth / 2)

            // 3. Progress arc (clockwise from 12 o'clock)
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(lineWidth / 2)

            // 4. Centered SF Symbol stat icon
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(iconColor)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 2, y: 1)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.7), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview("PortraitStatRings — states") {
    HStack(spacing: LayoutConstants.spaceLG) {
        PortraitStatRings(hpPercentage: 1.0, staminaPercentage: 0.8)
        PortraitStatRings(hpPercentage: 0.75, staminaPercentage: 0.5)
        PortraitStatRings(hpPercentage: 0.35, staminaPercentage: 0.2)
        PortraitStatRings(hpPercentage: 0.1, staminaPercentage: 0.0)
    }
    .padding(LayoutConstants.spaceLG)
    .background(DarkFantasyTheme.bgAbyss)
}
