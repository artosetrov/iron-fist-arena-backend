import SwiftUI

// MARK: - City Building Label (Banner above building on tap)

struct CityBuildingLabel: View {
    let text: String
    let visible: Bool
    var badge: String? = nil
    var isLocked: Bool = false
    /// Shows a pulsing quest indicator (!) when an NPC quest points to this building
    var hasQuest: Bool = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            // Quest indicator
            if hasQuest && !isLocked {
                Text("!")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(DarkFantasyTheme.gold))
            }

            Text(text)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(isLocked ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.goldBright)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            } else if let badge {
                Text(badge)
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.vertical, LayoutConstants.barInternalPadding)
                    .background(
                        Capsule().fill(DarkFantasyTheme.gold)
                    )
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.88))
        )
        .surfaceLighting(cornerRadius: LayoutConstants.radiusXS, topHighlight: 0.06, bottomShadow: 0.08)
        .innerBorder(cornerRadius: LayoutConstants.radiusXS - 1, inset: 1, color: isLocked ? DarkFantasyTheme.textSecondary.opacity(0.05) : DarkFantasyTheme.gold.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .stroke(
                    isLocked
                        ? DarkFantasyTheme.textSecondary.opacity(0.4)
                        : DarkFantasyTheme.gold.opacity(0.7),
                    lineWidth: 1
                )
        )
        .cornerBrackets(color: isLocked ? DarkFantasyTheme.textSecondary.opacity(0.3) : DarkFantasyTheme.gold.opacity(0.5), length: 8, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 2)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 6)
        .animation(.easeOut(duration: 0.25), value: visible)
    }
}
