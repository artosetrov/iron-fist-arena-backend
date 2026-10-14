import SwiftUI

/// Accent colours for a minigame outcome. Non-generic so call sites can read
/// `MinigameResultAccent.color(isWin:)` without naming a specialization.
enum MinigameResultAccent {
    static let win = DarkFantasyTheme.gold
    static let lose = DarkFantasyTheme.danger

    static func color(isWin: Bool) -> Color { isWin ? win : lose }
}

/// Win/lose result card shared by the shell game and the fortune wheel.
///
/// The two screens carried near-identical ~90-line `resultModal` functions —
/// same layout, same ornamental stack, same duplicated CONTINUE button written
/// out twice per file so the win and lose variants could differ only by button
/// style. Both now build this one view inside `GameModal`.
struct MinigameResultModal<Illustration: View>: View {
    let isWin: Bool
    let title: String
    let amountText: String
    /// Two lines on the wheel (sector names run long), one in the shell game.
    var amountLineLimit: Int = 1
    let onContinue: () -> Void
    @ViewBuilder var illustration: () -> Illustration

    /// Gold for a win, danger for a loss — also the modal's accent.
    var accent: Color { MinigameResultAccent.color(isWin: isWin) }

    var body: some View {
        VStack(spacing: 0) {
            illustration()
                .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                .shadow(color: accent.opacity(DarkFantasyTheme.opacityStrong), radius: 8)
                .padding(.bottom, LayoutConstants.spaceMD)
                .accessibilityHidden(true)

            Text(title)
                .font(DarkFantasyTheme.title)
                .foregroundStyle(isWin ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)
                .padding(.bottom, LayoutConstants.spaceXS)

            Text(amountText)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(amountLineLimit)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
                .padding(.bottom, LayoutConstants.spaceLG)

            Button(action: onContinue) {
                Text("CONTINUE")
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(2)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightMD)
            }
            .buttonStyle(isWin ? AnyButtonStyle(PrimaryButtonStyle()) : AnyButtonStyle(DangerButtonStyle()))
            .accessibilityLabel("Continue")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(amountText)")
    }
}
