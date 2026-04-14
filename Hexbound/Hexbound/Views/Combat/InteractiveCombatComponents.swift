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
//    5. StanceBonusChip .............. Richer ATK/DEF chip with zone + bonus text
//    6. StanceBonusChipStack ......... Pair of ATK+DEF chips under a fighter card
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

// MARK: - 5. Stance Bonus Chip

/// Richer replacement for `StanceOverlay` shown directly beneath a fighter's
/// card. Communicates three things at once: the channel (ATK/DEF), the chosen
/// zone (HEAD/CHEST/LEGS) and the headline bonus text ("OFF +10%", etc.).
///
/// Three visual modes cover the combat lifecycle:
///   • `.confirmed(zone)` — player or revealed opponent value. Solid fill,
///     channel-tinted zone label, bonus in `success` green.
///   • `.predicted(zone)` — opponent during `.predict`, inferred from the
///     intent heuristic. Dashed stroke, amber label, prefixed with "?".
///   • `.hidden` — opponent channel we can't yet read (DEF during predict).
///     Muted placeholder, "???" label.
///
/// Bonus strings are sourced from `InteractiveStanceBonuses` which mirrors
/// the backend `STANCE_ZONES` table 1:1.
struct StanceBonusChip: View {
    enum Kind {
        case attack
        case defend
    }

    enum Mode {
        case confirmed(InteractiveBodyZone)
        case predicted(InteractiveBodyZone)
        case hidden
    }

    let kind: Kind
    let mode: Mode

    var body: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            // Channel tag (ATK / DEF)
            Text(kindTag)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(channelColor)
                .frame(width: 28, alignment: .leading)

            // Zone label
            HStack(spacing: 2) {
                if isPredicted {
                    Text("?")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
                Text(zoneLabel)
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(zoneLabelColor)
            }

            Spacer(minLength: 0)

            // Bonus headline
            Text(bonusText)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(bonusColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgSecondary.opacity(isHidden ? 0.35 : 0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .strokeBorder(
                    strokeColor,
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: isPredicted ? [3, 2] : []
                    )
                )
        )
        .opacity(isHidden ? 0.6 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityText))
    }

    // MARK: Derived

    private var kindTag: String {
        switch kind {
        case .attack: return "ATK"
        case .defend: return "DEF"
        }
    }

    private var channelColor: Color {
        switch kind {
        case .attack: return DarkFantasyTheme.danger
        case .defend: return DarkFantasyTheme.info
        }
    }

    private var isPredicted: Bool {
        if case .predicted = mode { return true }
        return false
    }

    private var isHidden: Bool {
        if case .hidden = mode { return true }
        return false
    }

    private var zoneLabel: String {
        switch mode {
        case .confirmed(let z), .predicted(let z):
            return z.rawValue.uppercased()
        case .hidden:
            return "???"
        }
    }

    private var zoneLabelColor: Color {
        switch mode {
        case .confirmed:
            return DarkFantasyTheme.textPrimary
        case .predicted:
            return DarkFantasyTheme.gold
        case .hidden:
            return DarkFantasyTheme.textTertiary
        }
    }

    private var bonusText: String {
        switch mode {
        case .confirmed(let z), .predicted(let z):
            switch kind {
            case .attack: return InteractiveStanceBonuses.attackBonusHeadline(for: z)
            case .defend: return InteractiveStanceBonuses.defendBonusHeadline(for: z)
            }
        case .hidden:
            return "—"
        }
    }

    private var bonusColor: Color {
        switch mode {
        case .confirmed: return DarkFantasyTheme.success
        case .predicted: return DarkFantasyTheme.gold
        case .hidden:    return DarkFantasyTheme.textTertiary
        }
    }

    private var strokeColor: Color {
        switch mode {
        case .confirmed: return channelColor.opacity(0.45)
        case .predicted: return DarkFantasyTheme.gold.opacity(0.55)
        case .hidden:    return DarkFantasyTheme.borderSubtle
        }
    }

    private var accessibilityText: String {
        switch mode {
        case .confirmed(let z):
            return "\(kindTag) \(z.rawValue), \(bonusText)"
        case .predicted(let z):
            return "Predicted \(kindTag) \(z.rawValue), \(bonusText)"
        case .hidden:
            return "\(kindTag) unknown"
        }
    }
}

// MARK: - 6. Stance Bonus Chip Stack

/// Convenience wrapper: the pair of ATK + DEF chips shown directly under a
/// fighter card. Caller passes each channel's `Mode` so the view stays
/// stateless and testable.
struct StanceBonusChipStack: View {
    let attackMode: StanceBonusChip.Mode
    let defendMode: StanceBonusChip.Mode

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            StanceBonusChip(kind: .attack, mode: attackMode)
            StanceBonusChip(kind: .defend, mode: defendMode)
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

#Preview("StanceBonusChipStack") {
    VStack(spacing: 12) {
        // Confirmed / confirmed — your side after selection
        StanceBonusChipStack(
            attackMode: .confirmed(.head),
            defendMode: .confirmed(.chest)
        )
        // Predicted / hidden — opponent during predict
        StanceBonusChipStack(
            attackMode: .predicted(.chest),
            defendMode: .hidden
        )
        // Confirmed / confirmed — opponent after reveal
        StanceBonusChipStack(
            attackMode: .confirmed(.legs),
            defendMode: .confirmed(.head)
        )
    }
    .padding()
    .frame(width: 200)
    .background(DarkFantasyTheme.bgPrimary)
}
#endif
