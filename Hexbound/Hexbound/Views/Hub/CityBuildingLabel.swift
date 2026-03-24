import SwiftUI

// MARK: - City Building Label (Banner above building on tap)

struct CityBuildingLabel: View {
    let text: String
    let visible: Bool
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            if let badge {
                Text(badge)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.vertical, 1)
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
        .innerBorder(cornerRadius: LayoutConstants.radiusXS - 1, inset: 1, color: DarkFantasyTheme.gold.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .stroke(DarkFantasyTheme.gold.opacity(0.7), lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 8, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 2)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 6)
        .animation(.easeOut(duration: 0.25), value: visible)
    }
}
