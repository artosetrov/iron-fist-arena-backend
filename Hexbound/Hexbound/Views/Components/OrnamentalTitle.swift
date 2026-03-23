import SwiftUI

// MARK: - Ornamental Screen Title
// Reusable centered title with scrollwork divider and optional subtitle.
// Used across: Shop, Arena, Dungeon, Hero, Inventory, Settings, Leaderboard screens.
//
// Usage:
//   OrnamentalTitle("SHOP")
//   OrnamentalTitle("ARENA", subtitle: "Prove your worth")
//   OrnamentalTitle("BESTIARY", accentColor: DarkFantasyTheme.purple)

struct OrnamentalTitle: View {
    let title: String
    var subtitle: String? = nil
    var accentColor: Color = DarkFantasyTheme.gold
    var titleSize: CGFloat = LayoutConstants.textScreen
    var showDivider: Bool = true

    init(_ title: String, subtitle: String? = nil, accentColor: Color = DarkFantasyTheme.gold, titleSize: CGFloat = LayoutConstants.textScreen, showDivider: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.titleSize = titleSize
        self.showDivider = showDivider
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Title text
            Text(title)
                .font(DarkFantasyTheme.title(size: titleSize))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .tracking(3)
                .textCase(.uppercase)
                .shadow(color: accentColor.opacity(0.2), radius: 8)

            // Scrollwork divider
            if showDivider {
                ScrollworkDivider(
                    color: accentColor.opacity(0.4),
                    accentColor: accentColor
                )
                .frame(width: min(titleWidth, 240))
            }

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    /// Approximate title width for divider sizing
    private var titleWidth: CGFloat {
        CGFloat(title.count) * titleSize * 0.55
    }
}

// MARK: - Inline Ornamental Section Header
// Smaller version for section headers within screens (e.g. "EQUIPMENT", "STATS")

struct OrnamentalSectionHeader: View {
    let title: String
    var accentColor: Color = DarkFantasyTheme.gold

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Left line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, accentColor.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Diamond + title + diamond
            HStack(spacing: LayoutConstants.spaceXS) {
                Rectangle()
                    .fill(accentColor.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))

                Text(title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(accentColor)
                    .tracking(2)
                    .textCase(.uppercase)

                Rectangle()
                    .fill(accentColor.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
            }

            // Right line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
}

#Preview {
    ZStack {
        DarkFantasyTheme.bgPrimary.ignoresSafeArea()
        VStack(spacing: LayoutConstants.spaceLG) {
            OrnamentalTitle("SHOP", subtitle: "Equip yourself for battle")
            OrnamentalTitle("ARENA", accentColor: DarkFantasyTheme.stamina)
            OrnamentalSectionHeader(title: "Equipment")
            OrnamentalSectionHeader(title: "Stats", accentColor: DarkFantasyTheme.purple)
        }
        .padding()
    }
}
