import SwiftUI

/// Reusable opponent stat comparison cell — shows stat name, icon, value,
/// and a delta badge comparing against the player's value.
/// Used in CharacterProfileView and LeaderboardPlayerDetailSheet.
///
/// Usage:
/// ```swift
/// OpponentStatCell(stat: .strength, value: 120, playerValue: 100)
/// ```
struct OpponentStatCell: View {
    let stat: StatType
    let value: Int
    let playerValue: Int

    private var statColor: Color {
        DarkFantasyTheme.statColor(for: stat.rawValue)
    }

    private var delta: Int { value - playerValue }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(stat.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            Text(stat.fullName)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(statColor)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Comparison delta badge
            if delta != 0 {
                DeltaBadge(delta: delta)
            }

            Text("\(value)")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .frame(minWidth: 36, alignment: .trailing)
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius).stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }
}

/// Reusable delta comparison badge — shows ▲/▼ with colored background.
/// Positive delta = danger (opponent stronger), negative = success (you're stronger).
///
/// Usage:
/// ```swift
/// DeltaBadge(delta: 15)   // shows ▲+15 in red
/// DeltaBadge(delta: -8)   // shows ▼-8 in green
/// ```
struct DeltaBadge: View {
    let delta: Int

    private var deltaColor: Color {
        delta > 0 ? DarkFantasyTheme.danger : DarkFantasyTheme.success
    }

    var body: some View {
        let arrow = delta > 0 ? "▲" : "▼"
        let label = delta > 0 ? "\(arrow)+\(delta)" : "\(arrow)\(delta)"

        Text(label)
            .font(DarkFantasyTheme.body.bold())
            .foregroundStyle(deltaColor)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(deltaColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(deltaColor.opacity(0.4), lineWidth: 1)
                    )
            )
    }
}
