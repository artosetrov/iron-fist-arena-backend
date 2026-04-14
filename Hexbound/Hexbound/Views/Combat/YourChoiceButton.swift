//
//  YourChoiceButton.swift
//  Hexbound
//
//  Interactive Combat v3 — the locked, read-only badge that replaces the
//  STRIKE button in the CTA row while the round is resolving. It occupies
//  the exact same layout footprint as `TimerRingStrikeButton` so the view
//  swap inside the ZStack doesn't shift any neighbouring UI.
//
//  State machine:
//    Predict   → show `TimerRingStrikeButton` (live, tappable, gold gradient)
//    Resolving → show this view: dark fill, gold 2pt stroke, 50%-opacity
//                corner brackets + diamonds, two-line label
//                ("YOUR CHOICE" over "ATK CHEST · DEF HEAD")
//    Reveal    → still this view until the round dismisses
//
//  No press handling — this is decorative and advisory only.
//

import SwiftUI

/// Locked "YOUR CHOICE" badge rendered while a round is resolving.
struct YourChoiceButton: View {

    let attackZone: InteractiveBodyZone
    let defendZone: InteractiveBodyZone

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text("YOUR CHOICE")
                .font(DarkFantasyTheme.badge)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            HStack(spacing: LayoutConstants.spaceSM) {
                Text("ATK \(attackZone.rawValue.uppercased())")
                    .foregroundStyle(DarkFantasyTheme.danger)

                Text("·")
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                Text("DEF \(defendZone.rawValue.uppercased())")
                    .foregroundStyle(DarkFantasyTheme.info)
            }
            .font(DarkFantasyTheme.buttonLabelCompact)
            .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: LayoutConstants.buttonHeightLG)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .fill(DarkFantasyTheme.bgElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .stroke(DarkFantasyTheme.gold, lineWidth: 2)
        )
        // Ornamental layers at reduced opacity so the silhouette still
        // reads like the live STRIKE button, just dimmed.
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5))
        .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your choice locked. Attack \(attackZone.rawValue), defend \(defendZone.rawValue).")
        .accessibilityHint("Strike locked — awaiting resolution.")
    }
}

// MARK: - Preview

#Preview("YourChoiceButton", traits: .sizeThatFitsLayout) {
    VStack(spacing: LayoutConstants.spaceMD) {
        YourChoiceButton(attackZone: .chest, defendZone: .head)
        YourChoiceButton(attackZone: .head, defendZone: .legs)
        YourChoiceButton(attackZone: .legs, defendZone: .chest)
    }
    .padding(LayoutConstants.spaceLG)
    .background(DarkFantasyTheme.bgPrimary)
}
