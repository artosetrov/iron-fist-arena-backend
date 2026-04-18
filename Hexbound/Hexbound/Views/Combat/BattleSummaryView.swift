//
//  BattleSummaryView.swift
//  Hexbound
//
//  Interactive Combat v3 — end-of-battle results surface. Replaces the
//  `predictPanel` when phase == .summary, so the existing YOU/ENEMY
//  fighter-card header stays on screen. Renders the full chronological
//  battle log (all `RoundExchange`s) and a CONTINUE CTA that hands
//  control to the VM's `continueFromSummary()` — which in turn fires
//  the existing `/match/complete` pipeline.
//
//  No scale animations — per project rule `feedback_no_scale_animations`.
//
//  The log here is NOT the stagger-animated card from `.reveal` —
//  rounds render already-settled, ordered by round number, split by
//  `LogDivider` labels showing the round index.
//

import SwiftUI

/// Full-battle log shown after the finishing blow, before navigation to
/// `CombatResultDetailView`. Host: `InteractiveBattleView.predictPanel`.
struct BattleSummaryView: View {

    @Bindable var vm: InteractiveBattleViewModel

    /// IDs of rounds currently expanded in the log. Multiple can be open at
    /// once — the last round (finishing blow) is auto-expanded on first
    /// appear so the killing strike is always visible without an extra tap.
    @State private var expandedRounds: Set<UUID> = []
    @State private var didAutoExpand = false

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            header
            BattleStatsHeader(stats: stats, playerWon: playerWon)
            logCard
            continueButton
        }
    }

    /// Cached aggregate so the view doesn't recompute on every rebuild.
    /// `battleLog` is append-only during the match and frozen in `.summary`,
    /// so this is stable for the lifetime of the screen.
    private var stats: RoundExchange.BattleStats {
        RoundExchange.aggregate(log: vm.battleLog)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(outcomeLabel)
                .font(DarkFantasyTheme.title)
                .tracking(3)
                .foregroundStyle(outcomeColor)

            Text("BATTLE LOG")
                .font(DarkFantasyTheme.badge)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var outcomeLabel: String {
        playerWon ? "VICTORY" : "DEFEAT"
    }

    private var outcomeColor: Color {
        playerWon ? DarkFantasyTheme.gold : DarkFantasyTheme.danger
    }

    private var playerWon: Bool {
        vm.state.winnerId == vm.state.attackerId
    }

    // MARK: - Log card

    private var logCard: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                ForEach(Array(vm.battleLog.enumerated()), id: \.element.id) { index, exchange in
                    CollapsibleRoundBlock(
                        exchange: exchange,
                        isLast: index == vm.battleLog.count - 1,
                        isExpanded: expandedRounds.contains(exchange.id),
                        onToggle: { toggleExpanded(exchange.id) }
                    )
                }

                if vm.battleLog.isEmpty {
                    Text("No rounds recorded.")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, LayoutConstants.spaceLG)
                }
            }
            .padding(LayoutConstants.spaceMD)
        }
        .frame(maxHeight: 360)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .fill(DarkFantasyTheme.bgElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: DarkFantasyTheme.gold.opacity(0.15), radius: 16, y: 0)
        .onAppear { autoExpandFinishingRound() }
    }

    private func toggleExpanded(_ id: UUID) {
        HapticManager.selection()
        if expandedRounds.contains(id) {
            expandedRounds.remove(id)
        } else {
            expandedRounds.insert(id)
        }
    }

    /// Auto-expand the finishing blow on first mount so the killing strike
    /// is immediately visible. Idempotent — re-appears (tab switches etc.)
    /// don't re-override user's manual collapse.
    private func autoExpandFinishingRound() {
        guard !didAutoExpand else { return }
        didAutoExpand = true
        if let finisher = vm.battleLog.first(where: { $0.finishingBlow }) {
            expandedRounds.insert(finisher.id)
        } else if let last = vm.battleLog.last {
            expandedRounds.insert(last.id)
        }
    }

    // MARK: - Continue button

    private var continueButton: some View {
        Button {
            vm.continueFromSummary()
        } label: {
            Text("CONTINUE")
                .font(DarkFantasyTheme.buttonLabel)
                .tracking(2)
                .frame(maxWidth: .infinity, minHeight: LayoutConstants.buttonHeightLG)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

// MARK: - Collapsible Round Block
//
// One row per round in the summary log. Default state is COLLAPSED — shows
// round number, verdict dot, compact clash strip, net HP delta. Tap
// anywhere on the row to toggle expansion and reveal the detailed ally /
// counter event rows (the same rows we draw during live reveal).
//
// The collapsed state is the one most players spend time in: a 15-round
// battle fits on screen without scrolling, and anything worth inspecting
// is one tap away. Finishing blow auto-expands in the parent so the
// killing strike is visible by default.

private struct CollapsibleRoundBlock: View {
    let exchange: RoundExchange
    let isLast: Bool
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            header
            if isExpanded {
                detail
                    .transition(.opacity)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(borderColor, lineWidth: isExpanded ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    // MARK: Header (always visible)

    private var header: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Circle()
                .fill(verdictColor)
                .frame(width: 8, height: 8)

            Text(roundTitle)
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Spacer(minLength: LayoutConstants.spaceXS)

            Text(netDamageLabel)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(netDamageColor)
                .lineLimit(1)

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }

    // MARK: Detail (expanded)

    private var detail: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            ForEach(exchange.allyEvents, id: \.id) { ev in
                CombatLogRow(event: ev, staggerDelay: .zero)
            }
            if !exchange.enemyEvents.isEmpty && !exchange.allyEvents.isEmpty {
                LogDivider(label: "Counter")
            }
            ForEach(exchange.enemyEvents, id: \.id) { ev in
                CombatLogRow(event: ev, staggerDelay: .zero)
            }
        }
        .padding(.top, LayoutConstants.space2XS)
    }

    // MARK: Derived

    private var roundTitle: String {
        if isLast && exchange.finishingBlow {
            return "R\(exchange.roundNumber) · FINISHING BLOW"
        }
        return "ROUND \(exchange.roundNumber)"
    }

    /// Net HP exchange this round from the player's perspective.
    /// Positive number = you came out ahead; negative = the enemy did.
    private var netDamageLabel: String {
        let dealt = exchange.allyEvents.reduce(0) { $0 + $1.damageDealt }
        let taken = exchange.enemyEvents.reduce(0) { $0 + $1.damageDealt }
        let net = dealt - taken
        if net > 0  { return "+\(net)" }
        if net < 0  { return "\(net)" }
        // Both blocked / both missed — show no delta but don't leave empty.
        return "—"
    }

    private var netDamageColor: Color {
        let dealt = exchange.allyEvents.reduce(0) { $0 + $1.damageDealt }
        let taken = exchange.enemyEvents.reduce(0) { $0 + $1.damageDealt }
        if dealt > taken  { return DarkFantasyTheme.success }
        if taken > dealt  { return DarkFantasyTheme.danger }
        return DarkFantasyTheme.textTertiary
    }

    private var verdictColor: Color {
        switch exchange.verdict {
        case .outplayed:     return DarkFantasyTheme.gold
        case .struck:        return DarkFantasyTheme.success
        case .held:          return DarkFantasyTheme.textSecondary
        case .outread:       return DarkFantasyTheme.danger
        }
    }

    private var borderColor: Color {
        if exchange.finishingBlow { return DarkFantasyTheme.gold.opacity(0.6) }
        if isExpanded             { return DarkFantasyTheme.gold.opacity(0.35) }
        return DarkFantasyTheme.borderSubtle
    }
}

// MARK: - Stats Header
//
// Compact four-tile stat grid shown between the VICTORY/DEFEAT title and
// the round log. The point is immediate post-battle legibility: the player
// should know their overall damage output, accuracy, rounds survived, and
// peak hit in under a second — without scrolling through the log. Uses
// only DS tokens; no raw hex colors or magic numbers.

struct BattleStatsHeader: View {
    let stats: RoundExchange.BattleStats
    let playerWon: Bool

    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceSM) {
                statTile(
                    label: "DAMAGE DEALT",
                    value: "\(stats.damageDealt)",
                    tint: DarkFantasyTheme.success
                )
                statTile(
                    label: "DAMAGE TAKEN",
                    value: "\(stats.damageTaken)",
                    tint: DarkFantasyTheme.danger
                )
            }
            HStack(spacing: LayoutConstants.spaceSM) {
                statTile(
                    label: "ACCURACY",
                    value: stats.hitAttempts > 0 ? "\(stats.accuracyPercent)%" : "—",
                    tint: DarkFantasyTheme.gold
                )
                statTile(
                    label: peakLabel,
                    value: peakValue,
                    tint: DarkFantasyTheme.gold
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private var peakLabel: String {
        stats.bestRoundNumber == nil ? "ROUNDS" : "BEST HIT"
    }

    private var peakValue: String {
        if let round = stats.bestRoundNumber {
            return "\(stats.bestHitDamage) · R\(round)"
        }
        return "\(stats.rounds)"
    }

    private var accessibilitySummary: String {
        "Dealt \(stats.damageDealt), took \(stats.damageTaken). "
            + "Accuracy \(stats.accuracyPercent)%. "
            + "\(stats.rounds) rounds."
    }

    private func statTile(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.badge)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text(value)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("BattleSummaryView", traits: .sizeThatFitsLayout) {
    // Stubbed — previews should not boot a full VM. See live view preview
    // inside `InteractiveBattleView` for the wired variant.
    Text("See live preview in InteractiveBattleView")
        .font(DarkFantasyTheme.caption)
        .foregroundStyle(DarkFantasyTheme.textTertiary)
        .padding(LayoutConstants.spaceLG)
        .background(DarkFantasyTheme.bgPrimary)
}
