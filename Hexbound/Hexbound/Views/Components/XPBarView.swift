import SwiftUI

/// Unified XP progress bar used across screens.
///
/// Sizes:
/// - `.compact` — Thin bar (10pt), no text inside, used in HeroDetailView header
/// - `.large` — Tall bar (20pt) with "XP current / max" centered inside, used in HeroIntegratedCard
struct XPBarView: View {
    let currentXp: Int
    let xpNeeded: Int

    /// Display size preset.
    var size: BarSize = .compact

    enum BarSize {
        case compact   // 10pt thin bar (character header)
        case large     // 20pt bar with text inside (hero card)

        var height: CGFloat {
            switch self {
            case .compact: 10
            case .large: LayoutConstants.heroBarXpHeight
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .compact: 6
            case .large: LayoutConstants.heroBarRadius
            }
        }
    }

    private var fraction: Double {
        guard xpNeeded > 0 else { return 0 }
        return min(Double(currentXp) / Double(xpNeeded), 1.0)
    }

    private var isNearLevelUp: Bool { fraction >= 0.9 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(size == .compact ? DarkFantasyTheme.bgPrimary : DarkFantasyTheme.textPrimary.opacity(0.06))
                    .if(size == .compact) { view in
                        view.overlay(
                            RoundedRectangle(cornerRadius: size.cornerRadius)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                    }

                // Fill with top highlight
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(isNearLevelUp ? DarkFantasyTheme.xpGoldenGradient : DarkFantasyTheme.xpGradient)
                    .overlay(
                        BarFillHighlight(cornerRadius: size.cornerRadius)
                    )
                    .frame(width: geo.size.width * fraction)
                    .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
                    .shadow(
                        color: isNearLevelUp ? DarkFantasyTheme.goldGlow : DarkFantasyTheme.purple.opacity(0.2),
                        radius: isNearLevelUp ? 6 : 3,
                        y: 0
                    )

                // Text (large only)
                if size == .large {
                    HStack {
                        Spacer()
                        Text("XP  \(currentXp) / \(xpNeeded)\(isNearLevelUp ? " ⬆" : "")")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.heroBarFont).bold())
                            .foregroundStyle(isNearLevelUp ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 2)
                            .monospacedDigit()
                        Spacer()
                    }
                }
            }
        }
        .frame(height: size.height)
        .animation(.easeInOut(duration: 0.4), value: fraction)
        .accessibilityLabel("Experience: \(currentXp) of \(xpNeeded)")
    }
}
