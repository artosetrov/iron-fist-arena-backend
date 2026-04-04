import SwiftUI

/// Ornamental stat group header — centered gold label with diamond-tipped gradient lines.
/// Used as section dividers in stat grids (CharacterProfileView, LeaderboardPlayerDetailSheet, HeroDetailView).
///
/// Usage:
/// ```swift
/// StatGroupHeader("Offensive")
/// StatGroupHeader("Defensive")
/// ```
struct StatGroupHeader: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Left line with diamond end
            HStack(spacing: 0) {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, DarkFantasyTheme.goldDim.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
            }

            Text(label)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.gold.opacity(0.6))
                .lineLimit(1)
                .fixedSize()

            // Right line with diamond start
            HStack(spacing: 0) {
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
                Rectangle()
                    .fill(LinearGradient(colors: [DarkFantasyTheme.goldDim.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
            }
        }
        .padding(.top, LayoutConstants.spaceXS)
    }
}
