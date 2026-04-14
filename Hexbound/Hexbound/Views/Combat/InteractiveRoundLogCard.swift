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

    // Upper bound on card height so a talent-heavy round doesn't dominate
    // the screen. Scroll kicks in above this.
    private let maxListHeight: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            header
            logList
            footer
        }
        .padding(LayoutConstants.spaceMD)
        .background(cardSurface)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .task(id: exchange.id) { await runCountdown() }
        .onAppear { dotPulse.toggle() }
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
                    .stroke(DarkFantasyTheme.gold, lineWidth: 1)
            )
            .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 24, y: 0)
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

    private func dismiss() {
        onDismiss()
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
        finishingBlow: false
    )

    return InteractiveRoundLogCard(exchange: sample) {}
        .padding(LayoutConstants.spaceMD)
        .background(DarkFantasyTheme.bgPrimary)
}
