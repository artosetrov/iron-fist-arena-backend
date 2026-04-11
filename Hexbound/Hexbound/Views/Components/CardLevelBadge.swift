import SwiftUI

/// Reusable level badge for card headers (HeroSelectionCard, ArenaOpponentCard, etc.)
/// Ensures consistent sizing, fill, contrast, and premium feel across all card types.
///
/// Usage:
///   CardLevelBadge(level: 16, accentColor: classColor)
///   CardLevelBadge(level: 16, accentColor: classColor, size: .compact)
struct CardLevelBadge: View {
    let level: Int
    let accentColor: Color

    enum Size {
        /// 38×38 — portrait cards (Arena, Hero selection, Boss)
        /// Shows number + "LVL" micro-label for unambiguous readability
        case standard
        /// 32×32 — compact layouts (grid thumbnails, inline refs)
        /// Shows number only to save space
        case compact

        var diameter: CGFloat {
            switch self {
            case .standard: return LayoutConstants.cardLvlBadgeSize  // 38
            case .compact:  return 32
            }
        }

        var numberFont: CGFloat {
            switch self {
            case .standard: return 14
            case .compact:  return 13
            }
        }

        var strokeWidth: CGFloat {
            switch self {
            case .standard: return 2.0
            case .compact:  return 1.5
            }
        }

        /// Whether to show the "LVL" micro-label below the number
        var showsLabel: Bool {
            switch self {
            case .standard: return true
            case .compact:  return false
            }
        }
    }

    var size: Size = .standard

    var body: some View {
        ZStack {
            Circle()
                .fill(accentColor)
            Circle()
                .stroke(accentColor.opacity(0.3), lineWidth: size.strokeWidth + 2)
                .blur(radius: 3)

            if size.showsLabel {
                // Number + "LVL" — standard portrait badge
                VStack(spacing: 0) {
                    Text("\(level)")
                        .font(.system(size: size.numberFont, weight: .bold, design: .default))
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("LVL")
                        .font(.system(size: 7, weight: .semibold, design: .default))
                        .foregroundStyle(DarkFantasyTheme.textOnGold.opacity(0.65))
                        .tracking(0.3)
                }
            } else {
                // Number only — compact badge
                Text("\(level)")
                    .font(.system(size: size.numberFont, weight: .bold, design: .default))
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .shadow(color: accentColor.opacity(0.4), radius: 6, y: 2)
    }
}

/// Reusable circular action button for card overlays (edit, delete, info, etc.)
/// Guarantees 48×48 minimum tap target per Apple HIG.
///
/// Usage:
///   CardActionButton(icon: "trash", color: .danger) { deleteAction() }
struct CardActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: LayoutConstants.touchMin, height: LayoutConstants.touchMin)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.8))
                )
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        DarkFantasyTheme.bgAbyss.ignoresSafeArea()
        VStack(spacing: LayoutConstants.spaceLG) {
            HStack(spacing: LayoutConstants.spaceMD) {
                CardLevelBadge(level: 7,  accentColor: DarkFantasyTheme.classWarrior)
                CardLevelBadge(level: 19, accentColor: DarkFantasyTheme.classTank)
                CardLevelBadge(level: 4,  accentColor: DarkFantasyTheme.classRogue)
                CardLevelBadge(level: 12, accentColor: DarkFantasyTheme.classMage)
            }
            HStack(spacing: LayoutConstants.spaceMD) {
                CardLevelBadge(level: 7,  accentColor: DarkFantasyTheme.classWarrior, size: .compact)
                CardLevelBadge(level: 99, accentColor: DarkFantasyTheme.gold,         size: .compact)
            }
            CardActionButton(icon: "trash", color: DarkFantasyTheme.danger) {}
        }
    }
}
