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

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            header
            logCard
            continueButton
        }
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
        // Server-authoritative check: player wins if their HP > 0 at end.
        vm.state.attackerHp > 0 && vm.state.defenderHp <= 0
    }

    // MARK: - Log card

    private var logCard: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                ForEach(Array(vm.battleLog.enumerated()), id: \.element.id) { index, exchange in
                    roundBlock(
                        exchange: exchange,
                        isLast: index == vm.battleLog.count - 1
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
    }

    @ViewBuilder
    private func roundBlock(exchange: RoundExchange, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            LogDivider(label: roundLabel(exchange: exchange, isLast: isLast))

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
    }

    private func roundLabel(exchange: RoundExchange, isLast: Bool) -> String {
        if isLast && exchange.finishingBlow {
            return "Round \(exchange.roundNumber) · Finishing Blow"
        }
        return "Round \(exchange.roundNumber)"
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
