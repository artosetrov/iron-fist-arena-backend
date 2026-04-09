import SwiftUI

/// Currency type for quest reward display.
enum QuestRewardType {
    case gold
    case xp
    case gems

    var assetName: String {
        switch self {
        case .gold: return "icon-gold"
        case .xp:   return "icon-xp"
        case .gems: return "icon-gems"
        }
    }

    var accentColor: Color {
        switch self {
        case .gold: return DarkFantasyTheme.goldBright
        case .xp:   return DarkFantasyTheme.cyan
        case .gems: return DarkFantasyTheme.purple
        }
    }

    /// The color used for border, glow, corner brackets (slightly muted vs accent)
    var borderColor: Color {
        switch self {
        case .gold: return DarkFantasyTheme.gold
        case .xp:   return DarkFantasyTheme.cyan
        case .gems: return DarkFantasyTheme.purple
        }
    }
}

/// Loot-style reward cell — 72×72 square with gradient fill, corner brackets,
/// inner border, radial glow behind icon, and value text.
///
/// Inspired by `ItemCardView` inventory cells but purpose-built for currency rewards.
///
/// Usage:
/// ```
/// QuestRewardCell(type: .gold, value: 150)
/// QuestRewardCell(type: .xp, value: 80)
/// QuestRewardCell(type: .gems, value: 10)
/// ```
struct QuestRewardCell: View {
    let type: QuestRewardType
    let value: Int

    private let cellSize: CGFloat = 72

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            // Icon with radial glow
            ZStack {
                // Radial glow behind icon
                Circle()
                    .fill(type.borderColor)
                    .frame(width: 48, height: 48)
                    .blur(radius: 12)
                    .opacity(0.25)
                    .offset(y: -2)

                Image(type.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
            }

            // Value
            Text("\(value)")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .foregroundStyle(type.accentColor)
                .monospacedDigit()
                .lineLimit(1)
                .shadow(color: Color.black.opacity(0.6), radius: 1.5, y: 1)
        }
        .frame(width: cellSize, height: cellSize)
        // Gradient background (rarity-style: accent 15% top → bgAbyss 95% bottom)
        .background(
            LinearGradient(
                colors: [
                    type.borderColor.opacity(0.15),
                    DarkFantasyTheme.bgAbyss.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
        // Surface lighting overlay
        .surfaceLighting(cornerRadius: LayoutConstants.radiusSM, topHighlight: 0.08, bottomShadow: 0.12)
        // Inner border bevel
        .innerBorder(
            cornerRadius: LayoutConstants.radiusSM - 2,
            inset: 2,
            color: type.borderColor.opacity(0.12)
        )
        // Outer border
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(type.borderColor.opacity(0.5), lineWidth: 1.5)
        )
        // Corner brackets (L-shaped accents)
        .cornerBrackets(
            color: type.borderColor.opacity(0.4),
            length: 8,
            thickness: 1.5
        )
        // Glow shadow
        .shadow(color: type.borderColor.opacity(0.15), radius: 4)
        .shadow(color: Color.black.opacity(0.3), radius: 2, y: 1)
    }
}
