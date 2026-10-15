//
//  DiceSummaryButton.swift
//  Hexbound
//
//  Inventory-tab entry to Hero → DICE. Took the stance widget's slot: dice
//  combat rolls zones instead of picking them (DICE_RUNES_DESIGN.md).
//

import SwiftUI

struct DiceSummaryButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LayoutConstants.spaceMS) {
                HStack(spacing: -LayoutConstants.spaceSM) {
                    Image("dice-showcase-attack")
                        .resizable().scaledToFit()
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-8))
                    Image("dice-showcase-guard")
                        .resizable().scaledToFit()
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(8))
                }
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("DICE & RUNES")
                        .font(DarkFantasyTheme.cardTitle)
                        .tracking(1.5)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text("Socket runes into your attack and guard dice")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: LayoutConstants.spaceXS)
                Image(systemName: "chevron.right")
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .padding(LayoutConstants.spaceMS)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1.5)
            )
            .cardShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dice and runes")
    }
}
