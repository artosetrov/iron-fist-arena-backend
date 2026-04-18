//
//  InteractiveRoundLogCard.swift
//  Hexbound
//
//  Interactive Combat v3 — the gold-bordered "Round Exchange" card that
//  slides in where the zone picker was. It holds a header, a stagger-
//  animated list of `CombatLogRow`s split by a `LogDivider`, and a
//  footer with a pulsing dot + "Next round in X.Xs" countdown.
//
//  Tap the card to skip the auto-dismiss. Auto-dismiss fires via a
//  `task(id: exchange.id)` so it automatically cancels if the view
//  disappears or if the VM swaps in a new `RoundExchange`.
//
//  NO scale animations — only opacity + translate (per project rule
//  `feedback_no_scale_animations`).
//

import SwiftUI

/// Round Exchange card. Owns its own auto-dismiss timer and tap-to-skip.
/// The parent (`InteractiveBattleView`) simply hands over a `RoundExchange`
/// and a `onDismiss` callback; state ownership stays in the VM.
struct InteractiveRoundLogCard: View {

    let exchange: RoundExchange
    let onDismiss: () -> Void

    // Countdown visible in the footer ("Next round in 1.8s"). Starts at
    // the exchange's configured delay and ticks every 100ms.
    @State private var secondsRemaining: Double = 0
    @State private var dotPulse = false
    // Phase 4 — OUTPLAYED border tween (gold-dim → gold → gold-dim) fires
    // once per peak reveal. Opacity only, no scale.
    @State private var outplayedBorderBright = false

    // Upper bound on card height so a talent-heavy round doesn't dominate
    // the screen. Scroll kicks in above this.
    private let maxListHeight: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            RoundVerdictHeader(verdict: exchange.verdict)
            ClashStripRow(exchange: exchange)
            header
            logList
            footer
        }
        .padding(LayoutConstants.spaceMD)
        .background(cardSurface)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .task(id: exchange.id) { await runCountdown() }
        .task(id: exchange.id) { await runOutplayedBorderTween() }
        .task(id: exchange.id) { fireVerdictHaptic() }
        .onAppear { dotPulse.toggle() }
    }

    // MARK: - Haptics

    /// One haptic per resolved round, keyed off `exchange.id` via `.task`.
    /// The intensity maps to the verdict so the player's hand distinguishes
    /// a dominant round (OUTPLAYED) from a mutual trade (STRUCK) without
    /// having to look at the card. Finishing blow gets a rankUp slam.
    private func fireVerdictHaptic() {
        if exchange.finishingBlow {
            HapticManager.rankUp()
            return
        }
        switch exchange.verdict {
        case .outplayed: HapticManager.heavy()
        case .struck:    HapticManager.medium()
        case .outread:   HapticManager.warning()
        case .held:      HapticManager.light()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("ROUND \(exchange.roundNumber)")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.gold)

            Text("EXCHANGE")
                .font(DarkFantasyTheme.badge)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Spacer(minLength: 0)

            if exchange.finishingBlow {
                Text("FINISHING BLOW")
                    .font(DarkFantasyTheme.badge)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.danger)
            }
        }
    }

    // MARK: - Log list

    private var logList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                ForEach(Array(exchange.allyEvents.enumerated()), id: \.element.id) { offset, ev in
                    CombatLogRow(
                        event: ev,
                        staggerDelay: .milliseconds(offset * 120)
                    )
                }

                if !exchange.enemyEvents.isEmpty && !exchange.allyEvents.isEmpty {
                    LogDivider(label: "Counter")
                }

                ForEach(Array(exchange.enemyEvents.enumerated()), id: \.element.id) { offset, ev in
                    let base = exchange.allyEvents.count + offset
                    CombatLogRow(
                        event: ev,
                        staggerDelay: .milliseconds(base * 120 + 240)
                    )
                }
            }
            .padding(.vertical, LayoutConstants.space2XS)
        }
        .frame(maxHeight: maxListHeight)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Circle()
                .fill(DarkFantasyTheme.gold)
                .frame(width: 6, height: 6)
                .opacity(dotPulse ? 1.0 : 0.3)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: dotPulse
                )

            Text(footerLabel)
                .font(DarkFantasyTheme.caption)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Spacer(minLength: 0)

            Text("TAP TO SKIP")
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.7))
        }
    }

    private var footerLabel: String {
        let clamped = max(0.0, secondsRemaining)
        return String(format: "NEXT ROUND IN %.1fs", clamped)
    }

    // MARK: - Card surface

    private var cardSurface: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
            .fill(DarkFantasyTheme.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(borderStrokeColor, lineWidth: 1)
            )
            .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 24, y: 0)
    }

    private var borderStrokeColor: Color {
        guard exchange.verdict == .outplayed else { return DarkFantasyTheme.gold }
        return outplayedBorderBright
            ? DarkFantasyTheme.gold
            : DarkFantasyTheme.gold.opacity(0.45)
    }

    // MARK: - Countdown

    /// Ticks every 100ms until the auto-dismiss window elapses. SwiftUI
    /// will cancel this Task automatically if `exchange.id` changes or
    /// the view leaves the hierarchy — no manual Task handle needed.
    private func runCountdown() async {
        let totalMs = Int(exchange.autoDismissDelay.components.seconds * 1000)
            + Int(exchange.autoDismissDelay.components.attoseconds / 1_000_000_000_000_000)
        let total = Double(max(100, totalMs)) / 1000.0

        secondsRemaining = total
        let tick: UInt64 = 100_000_000 // 100ms in ns

        while secondsRemaining > 0 {
            try? await Task.sleep(nanoseconds: tick)
            if Task.isCancelled { return }
            secondsRemaining = max(0, secondsRemaining - 0.1)
        }

        if !Task.isCancelled {
            onDismiss()
        }
    }

    /// One-shot gold-dim → gold → gold-dim border tween for the OUTPLAYED
    /// peak verdict. Other verdicts leave the border static at full gold.
    private func runOutplayedBorderTween() async {
        guard exchange.verdict == .outplayed else {
            outplayedBorderBright = false
            return
        }
        outplayedBorderBright = false
        withAnimation(.easeInOut(duration: 0.6)) { outplayedBorderBright = true }
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.easeInOut(duration: 0.6)) { outplayedBorderBright = false }
    }

    private func dismiss() {
        onDismiss()
    }
}

// MARK: - Verdict Header

private struct RoundVerdictHeader: View {
    let verdict: RoundVerdict
    @State private var pulseOn = false

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(verdict.bannerText)
                .font(DarkFantasyTheme.cardTitle)
                .tracking(4)
                .foregroundStyle(textColor)

            Text(verdict.subtitle)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle)
                .frame(height: 1)
        }
        .task {
            if verdict == .outplayed { pulseOn = true }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch verdict {
        case .outplayed:
            LinearGradient(
                colors: [
                    DarkFantasyTheme.gold.opacity(0.26),
                    DarkFantasyTheme.gold.opacity(0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                Rectangle()
                    .fill(DarkFantasyTheme.gold.opacity(pulseOn ? 0.16 : 0.04))
                    .animation(
                        .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                        value: pulseOn
                    )
            )
        case .held, .struck:
            DarkFantasyTheme.success.opacity(0.14)
        case .outread:
            DarkFantasyTheme.danger.opacity(0.16)
        }
    }

    private var textColor: Color {
        switch verdict {
        case .outplayed:     return DarkFantasyTheme.gold
        case .held, .struck: return DarkFantasyTheme.success
        case .outread:       return DarkFantasyTheme.danger
        }
    }
}

// MARK: - Clash Strip

private struct ClashStripRow: View {
    let exchange: RoundExchange

    var body: some View {
        HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
            side(
                label: "YOU",
                atkZone: exchange.playerAttackZone,
                defZone: exchange.playerDefendZone,
                youHit: exchange.verdict == .outplayed || exchange.verdict == .struck,
                youHeld: exchange.verdict == .outplayed || exchange.verdict == .held
            )

            Text("VS")
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            side(
                label: "OPP",
                atkZone: exchange.opponentAttackZone,
                defZone: exchange.opponentDefendZone,
                youHit: !(exchange.verdict == .outplayed || exchange.verdict == .struck),
                youHeld: !(exchange.verdict == .outplayed || exchange.verdict == .held)
            )
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    private func side(
        label: String,
        atkZone: InteractiveBodyZone,
        defZone: InteractiveBodyZone,
        youHit: Bool,
        youHeld: Bool
    ) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            HStack(spacing: LayoutConstants.space2XS) {
                ZoneChip(kind: .attack, zone: atkZone, glowing: youHit)
                ZoneChip(kind: .defense, zone: defZone, glowing: youHeld)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ZoneChip: View {
    enum Kind { case attack, defense }

    let kind: Kind
    let zone: InteractiveBodyZone
    let glowing: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(kind == .attack ? "ATK" : "DEF")
                .font(DarkFantasyTheme.badge)
                .tracking(1)
            Text(zone.rawValue.uppercased())
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1.2)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .shadow(color: glowColor, radius: glowing ? 8 : 0, y: 0)
    }

    private var foregroundColor: Color {
        switch kind {
        case .attack:  return DarkFantasyTheme.danger
        case .defense: return DarkFantasyTheme.gold
        }
    }
    private var borderColor: Color {
        switch kind {
        case .attack:  return DarkFantasyTheme.danger.opacity(0.4)
        case .defense: return DarkFantasyTheme.gold.opacity(0.4)
        }
    }
    private var glowColor: Color {
        guard glowing else { return .clear }
        switch kind {
        case .attack:  return DarkFantasyTheme.danger.opacity(0.5)
        case .defense: return DarkFantasyTheme.success.opacity(0.5)
        }
    }
}

// MARK: - Preview

#Preview("InteractiveRoundLogCard", traits: .sizeThatFitsLayout) {
    let sample = RoundExchange(
        id: UUID(),
        roundNumber: 3,
        allyEvents: [
            .talentFired(index: 31, side: .ally, action: .burstDamage, actorName: "You"),
            .crit(index: 32, side: .ally, zone: .head,
                  actorName: "You", damage: 342, skillName: "Heavy Strike")
        ],
        enemyEvents: [
            .blocked(index: 33, side: .enemy, zone: .chest,
                     actorName: "Enemy", targetName: "You")
        ],
        talentFired: true,
        finishingBlow: false,
        verdict: .outplayed,
        playerAttackZone: .head,
        playerDefendZone: .chest,
        opponentAttackZone: .chest,
        opponentDefendZone: .legs
    )

    return InteractiveRoundLogCard(exchange: sample) {}
        .padding(LayoutConstants.spaceMD)
        .background(DarkFantasyTheme.bgPrimary)
}
