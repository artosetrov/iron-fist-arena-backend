import SwiftUI

/// Unified XP progress bar used across screens.
///
/// Sizes:
/// - `.compact` — Thin bar (10pt), no text inside, used in HeroDetailView header
/// - `.widget` — 26pt bar with "LEVEL N · xp/need" inside, used in UnifiedHeroWidget (hub)
/// - `.large` — Tall bar (24pt) with "XP current / max" centered inside, used in HeroIntegratedCard
struct XPBarView: View {
    let currentXp: Int
    let xpNeeded: Int

    /// Display size preset.
    var size: BarSize = .compact

    /// Optional level label prefix shown inside `.widget` bar, e.g. "LEVEL 14".
    /// Ignored for other sizes. When nil, widget size only shows "xp / need".
    var levelLabel: String? = nil

    enum BarSize {
        case compact   // 10pt thin bar (character header)
        case widget    // 26pt bar with level + xp text (hub hero widget)
        case large     // 24pt bar with text inside (hero card)

        var height: CGFloat {
            switch self {
            case .compact: 10
            case .widget: LayoutConstants.widgetBarHeight
            case .large: LayoutConstants.heroBarXpHeight
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .compact: 6
            case .widget: LayoutConstants.widgetBarRadius
            case .large: LayoutConstants.heroBarRadius
            }
        }

        var showsTextAlways: Bool {
            self == .large || self == .widget
        }

        var hasStroke: Bool {
            self == .compact || self == .widget
        }
    }

    private var fraction: Double {
        guard xpNeeded > 0 else { return 0 }
        return min(Double(currentXp) / Double(xpNeeded), 1.0)
    }

    private var isNearLevelUp: Bool { fraction >= 0.9 }

    private var displayText: String {
        switch size {
        case .compact:
            return ""
        case .widget:
            if let label = levelLabel {
                return "\(label) · \(currentXp) / \(xpNeeded) XP\(isNearLevelUp ? " · READY" : "")"
            }
            return "\(currentXp) / \(xpNeeded) XP\(isNearLevelUp ? " · READY" : "")"
        case .large:
            return "XP  \(currentXp) / \(xpNeeded)\(isNearLevelUp ? " READY" : "")"
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(size == .large ? DarkFantasyTheme.textPrimary.opacity(0.06) : DarkFantasyTheme.bgPrimary)
                    .if(size.hasStroke) { view in
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
                        color: isNearLevelUp ? DarkFantasyTheme.goldGlow : DarkFantasyTheme.xpRing.opacity(0.2),
                        radius: isNearLevelUp ? 6 : 3,
                        y: 0
                    )

                // Text with dark pill for readability (widget and large)
                if size.showsTextAlways {
                    HStack {
                        Spacer()
                        Text(displayText)
                            .font(size == .widget ? DarkFantasyTheme.uiLabel.bold() : DarkFantasyTheme.body.bold())
                            .foregroundStyle(isNearLevelUp ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                            .monospacedDigit()
                            .padding(.horizontal, LayoutConstants.spaceXS)
                            .padding(.vertical, LayoutConstants.barInternalPadding)
                            .background(
                                Capsule()
                                    .fill(DarkFantasyTheme.bgAbyss.opacity(0.55))
                            )
                        Spacer()
                    }
                }
            }
        }
        .frame(height: size.height)
        .animation(.easeInOut(duration: MotionConstants.normal), value: fraction)
        .accessibilityLabel(levelLabel.map { "\($0), experience \(currentXp) of \(xpNeeded)" } ?? "Experience: \(currentXp) of \(xpNeeded)")
    }
}
