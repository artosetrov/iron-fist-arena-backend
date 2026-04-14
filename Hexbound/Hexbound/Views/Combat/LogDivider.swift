//
//  LogDivider.swift
//  Hexbound
//
//  Interactive Combat v3 — gold gradient divider with a centered label
//  used inside the Round Exchange card to separate the player's events
//  from the opponent's counter events.
//
//  Pure decorative leaf — no state, no input other than the label.
//

import SwiftUI

/// Thin gold gradient rule with a centered uppercase tag. Typically
/// rendered as `LogDivider(label: "Counter")` between the player-side
/// and enemy-side rows of a round exchange.
struct LogDivider: View {

    let label: String

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            line
            Text(label.uppercased())
                .font(DarkFantasyTheme.badge)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.goldDim)
            line
        }
        .padding(.vertical, LayoutConstants.space2XS)
    }

    private var line: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        DarkFantasyTheme.goldDim.opacity(0.8),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - Preview

#Preview("Log divider", traits: .sizeThatFitsLayout) {
    VStack(spacing: LayoutConstants.spaceMD) {
        LogDivider(label: "Counter")
        LogDivider(label: "Reaction")
    }
    .padding(LayoutConstants.spaceLG)
    .background(DarkFantasyTheme.bgElevated)
}
