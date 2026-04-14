//
//  InteractiveCombatComponents.swift
//  Hexbound
//
//  New UI building blocks for Interactive Combat v2 (Variant B2).
//  These are drop-in pieces consumed by InteractiveBattleView in Phase 3.
//
//  All components obey the design system:
//    • Colors: DarkFantasyTheme only
//    • Spacing / radii: LayoutConstants only
//    • Fonts: DarkFantasyTheme.* tokens only
//    • No scale animations (opacity / color feedback only)
//    • No hardcoded corner radii or hex colors
//
//  Contents:
//    1. StanceOverlay ................ Small zone chip pinned to a fighter card
//    2. TimerRingStrikeButton ........ STRIKE CTA with radial countdown arc
//    3. FighterStatusChip ............ Streak + gear-score row
//    4. EnemyIntentPill .............. "Likely: HEAD" hint pill (ghost style)
//
//  Phase 3 will wire these into the combat screen; this file changes
//  nothing on its own until then.
//

import SwiftUI

// MARK: - 1. Stance Overlay

/// Compact chip that reveals the fighter's current stance over their portrait
/// or underneath their name. Shows a localized label (HEAD / CHEST / LEGS) and
/// an SF Symbol icon tinted with the zone color. Pass `nil` to render the
/// "unknown" placeholder (used for the opponent during `.predict`).
struct StanceOverlay: View {
    enum Kind {
        case attack
        case defend
    }

    let kind: Kind
    /// `nil` renders the "?" placeholder used while the opponent is hidden.
    let zone: InteractiveBodyZone?
    /// When `true`, the chip uses a muted tint (used for opponent preview).
    var isGhost: Bool = false

    var body: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image(systemName: kindIcon)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(zoneColor)
            Text(labelText)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgSecondary.opacity(isGhost ? 0.4 : 0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(zoneColor.opacity(isGhost ? 0.25 : 0.55), lineWidth: 1)
        )
        .opacity(isGhost ? 0.85 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(kindPrefix) \(labelText)"))
    }

    private var labelText: String {
        zone?.rawValue.uppercased() ?? "?"
    }

    private var kindPrefix: String {
        switch kind {
        case .attack: return "Attack"
        case .defend: return "Defend"
        }
    }

    private var kindIcon: String {
        switch kind {
        case .attack: return "scope"
        case .defend: return "shield.lefthalf.filled"
        }
    }

    private var zoneColor: Color {
        guard let zone else { return DarkFantasyTheme.textTertiary }
        switch zone {
        case .head:  return DarkFantasyTheme.zoneHead
        case .chest: return DarkFantasyTheme.zoneChest
        case .legs:  return DarkFantasyTheme.zoneLegs
        }
    }
}

// MARK: - 2. Timer Ring STRIKE Button

/// STRIKE CTA with an integrated radial timer arc that drains clockwise as
/// time runs out. Fill becomes `danger` with a soft pulse in the last 1.5s.
/// Pass a bound `fraction` in `[0, 1]` (1 = full time remaining).
///
/// - The button uses the shared `PrimaryButtonStyle` visual (via
///   `TimerRingButtonStyle`) so ornamental treatment (SurfaceLighting,
///   cornerBrackets, cornerDiamonds, innerBorder) stays consistent with the
///   rest of the gold CTA family.
struct TimerRingStrikeButton: View {
    let remainingFraction: Double
    let isCritical: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text("STRIKE")
                    .font(DarkFantasyTheme.buttonLabel)
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: LayoutConstants.buttonHeightLG)
        }
        .buttonStyle(PrimaryButtonStyle())
        .overlay(alignment: .leading) {
            // Timer arc: linear sliver along the top edge draining from full
            // to empty. We use a thin overlay rather than a circle so the
            // button's rectangular brackets remain untouched.
            GeometryReader { geo in
                let width = max(0, geo.size.width * remainingFraction)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(Color.black.opacity(0.25))
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(isCritical ? DarkFantasyTheme.danger : DarkFantasyTheme.gold.opacity(0.9))
                        .frame(width: width)
                        .animation(.linear(duration: 0.1), value: remainingFraction)
                }
                .frame(height: 4)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, LayoutConstants.spaceXS)
                .allowsHitTesting(false)
            }
        }
        .overlay {
            if isCritical {
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.danger.opacity(0.55), lineWidth: 1.5)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .opacity(isBusy ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCritical)
        .accessibilityLabel(Text("Strike"))
        .accessibilityValue(Text(isCritical ? "Time running out" : "Ready"))
    }
}

// MARK: - 3. Fighter Status Chip

/// Horizontal info row summarizing a fighter's meta-state: current win streak
/// and gear score. Used on the duel header beneath the fighter's name. Uses
/// tokenized surface + subtle border to match the compact pill vocabulary
/// (`GlassStatPill`, `StatusPill`) of the existing DS.
struct FighterStatusChip: View {
    let streak: Int
    let gearScore: Int?
    /// When `true`, renders in muted tone (used for enemy side).
    var isOpponent: Bool = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if streak > 0 {
                chipItem(icon: "flame.fill",
                         color: DarkFantasyTheme.gold,
                         text: "\(streak)")
            }
            if let gs = gearScore {
                chipItem(icon: "shield.righthalf.filled",
                         color: DarkFantasyTheme.textSecondary,
                         text: "GS \(gs)")
            }
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            Capsule()
                .fill(DarkFantasyTheme.bgSecondary.opacity(isOpponent ? 0.4 : 0.6))
        )
        .overlay(
            Capsule()
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .opacity(isOpponent ? 0.85 : 1.0)
        .accessibilityElement(children: .combine)
    }

    private func chipItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image(systemName: icon)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(color)
            Text(text)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
    }
}

// MARK: - 4. Enemy Intent Pill

/// Small ghost pill hinting at the opponent's likely next stance. Sourced from
/// a simple last-round heuristic (computed by the VM in Phase 4). Appears
/// under the enemy fighter card during `.predict` and fades out once the
/// round resolves.
///
/// Ghost styling (dashed stroke, low-alpha fill) signals uncertainty — this
/// is a read, not a guaranteed tell.
struct EnemyIntentPill: View {
    enum Channel { case attack, defend }

    let channel: Channel
    let likelyZone: InteractiveBodyZone

    var body: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image(systemName: "eye")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Text(prefix)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Text(likelyZone.rawValue.uppercased())
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(zoneColor)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .strokeBorder(
                    DarkFantasyTheme.borderSubtle,
                    style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Likely \(prefix.lowercased()) \(likelyZone.rawValue)"))
    }

    private var prefix: String {
        switch channel {
        case .attack: return "LIKELY HITS"
        case .defend: return "LIKELY GUARDS"
        }
    }

    private var zoneColor: Color {
        switch likelyZone {
        case .head:  return DarkFantasyTheme.zoneHead
        case .chest: return DarkFantasyTheme.zoneChest
        case .legs:  return DarkFantasyTheme.zoneLegs
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("StanceOverlay") {
    HStack(spacing: 8) {
        StanceOverlay(kind: .attack, zone: .head)
        StanceOverlay(kind: .defend, zone: .chest)
        StanceOverlay(kind: .attack, zone: nil, isGhost: true)
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}

#Preview("TimerRingStrikeButton") {
    VStack(spacing: 16) {
        TimerRingStrikeButton(remainingFraction: 1.0, isCritical: false, isBusy: false) { }
        TimerRingStrikeButton(remainingFraction: 0.35, isCritical: false, isBusy: false) { }
        TimerRingStrikeButton(remainingFraction: 0.1, isCritical: true, isBusy: false) { }
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}

#Preview("FighterStatusChip") {
    HStack {
        FighterStatusChip(streak: 3, gearScore: 1240)
        FighterStatusChip(streak: 0, gearScore: 980, isOpponent: true)
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}

#Preview("EnemyIntentPill") {
    VStack {
        EnemyIntentPill(channel: .attack, likelyZone: .head)
        EnemyIntentPill(channel: .defend, likelyZone: .legs)
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}
#endif
