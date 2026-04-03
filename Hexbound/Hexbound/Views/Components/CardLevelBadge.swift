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
        case standard   // 48×48, font 18 — matches CardActionButton, default for selection / arena cards
        case compact    // 36×36, font 15 — for tighter layouts

        var diameter: CGFloat {
            switch self {
            case .standard: return LayoutConstants.touchMin // 48
            case .compact: return 36
            }
        }

        var font: CGFloat {
            switch self {
            case .standard: return 18
            case .compact: return 15
            }
        }

        var strokeWidth: CGFloat {
            switch self {
            case .standard: return 2.0
            case .compact: return 1.5
            }
        }
    }

    var size: Size = .standard

    var body: some View {
        Text("\(level)")
            .font(DarkFantasyTheme.section(size: size.font))
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .frame(width: size.diameter, height: size.diameter)
            .background(
                Circle()
                    .fill(accentColor)
            )
            .overlay(
                Circle()
                    .stroke(accentColor.opacity(0.3), lineWidth: size.strokeWidth + 2)
                    .blur(radius: 3)
            )
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
                .font(DarkFantasyTheme.uiLabel.weight(.semibold))
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
    }
}

#Preview {
    ZStack {
        DarkFantasyTheme.bgAbyss.ignoresSafeArea()
        VStack(spacing: 20) {
            CardLevelBadge(level: 16, accentColor: DarkFantasyTheme.gold)
            CardLevelBadge(level: 3, accentColor: DarkFantasyTheme.info, size: .compact)
            CardActionButton(icon: "trash", color: DarkFantasyTheme.danger) {}
        }
    }
}
