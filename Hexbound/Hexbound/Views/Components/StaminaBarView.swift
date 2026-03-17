import SwiftUI

/// Reusable stamina bar matching the Arena style.
/// Wrap in a Button externally if you need tap-to-navigate behavior.
struct StaminaBarView: View {
    let currentStamina: Int
    let maxStamina: Int
    var showPlus: Bool = true
    var recoveryText: String? = nil

    private var fraction: Double {
        maxStamina > 0 ? Double(currentStamina) / Double(maxStamina) : 0
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "bolt.fill")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody).bold())
                .foregroundStyle(DarkFantasyTheme.stamina)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DarkFantasyTheme.staminaGradient)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 14)

            Text("\(currentStamina)/\(maxStamina)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.stamina)
                .monospacedDigit()

            if showPlus {
                Image(systemName: "plus.circle.fill")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            if let recoveryText, currentStamina < maxStamina {
                Text(recoveryText)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .padding(.horizontal, LayoutConstants.cardPadding)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.stamina.opacity(0.3), lineWidth: 1)
        )
    }
}
