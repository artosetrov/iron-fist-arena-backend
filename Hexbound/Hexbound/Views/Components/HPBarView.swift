import SwiftUI

/// Unified HP bar used across Hub, Combat, and Hero screens.
///
/// Uses `DarkFantasyTheme.canonicalHpGradient` for consistent color progression:
/// green (100%) → amber (25-75%) → red (<25%).
///
/// Sizes:
/// - `.compact` — 14pt, small text, used in widget/lists (default)
/// - `.widget` — 22pt, text inside, used in UnifiedHeroWidget
/// - `.large` — 24pt, label + value centered, used in HeroIntegratedCard
struct HPBarView: View {
    let currentHp: Int
    let maxHp: Int

    /// Display size preset.
    var size: BarSize = .compact

    /// Show "current / max" text inside the bar when not full.
    /// Ignored for `.large` and `.widget` (always shows text).
    var showTextInside: Bool = false

    /// Pulse animation when HP < 25%.
    var pulseOnCritical: Bool = false

    /// Optional label prefix (e.g. "HP") shown for `.large` size.
    var label: String = "HP"

    enum BarSize {
        case compact   // 14pt — lists, small cards
        case widget    // 22pt — UnifiedHeroWidget
        case large     // 24pt — HeroIntegratedCard

        var height: CGFloat {
            switch self {
            case .compact: 14
            case .widget: LayoutConstants.widgetBarHeight
            case .large: LayoutConstants.heroBarHeight
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .compact: 4
            case .widget: LayoutConstants.widgetBarRadius
            case .large: LayoutConstants.heroBarRadius
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .compact: LayoutConstants.textBadge
            case .widget: LayoutConstants.widgetBarFont
            case .large: LayoutConstants.heroBarFont
            }
        }

        var showsTextAlways: Bool {
            self == .large || self == .widget
        }

        var trackColor: Color {
            switch self {
            case .compact: DarkFantasyTheme.bgTertiary
            case .widget: DarkFantasyTheme.bgTertiary
            case .large: DarkFantasyTheme.textPrimary.opacity(0.06)
            }
        }

        var hasStroke: Bool {
            self == .compact || self == .widget
        }
    }

    private var percentage: Double {
        guard maxHp > 0 else { return 0 }
        return Double(currentHp) / Double(maxHp)
    }

    private var isCritical: Bool { percentage < 0.25 && percentage > 0 }

    private var shouldShowText: Bool {
        size.showsTextAlways || (showTextInside && percentage < 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(size.trackColor)
                    .if(size.hasStroke) { view in
                        view.overlay(
                            RoundedRectangle(cornerRadius: size.cornerRadius)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: size == .widget ? 0.5 : 1)
                        )
                    }

                // Fill bar with top highlight
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(DarkFantasyTheme.canonicalHpGradient(percentage: percentage))
                    .overlay(
                        BarFillHighlight(cornerRadius: size.cornerRadius)
                    )
                    .frame(width: geo.size.width * max(0.02, min(1, percentage)))
                    .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
                    .shadow(
                        color: isCritical ? DarkFantasyTheme.danger.opacity(0.4) : DarkFantasyTheme.success.opacity(0.15),
                        radius: isCritical ? 6 : 3,
                        y: 0
                    )
                    .opacity(pulseOnCritical && isCritical ? pulseOpacity : 1)

                // Text overlay
                if shouldShowText {
                    HStack {
                        Spacer()
                        Text(textContent)
                            .font(DarkFantasyTheme.body(size: size.fontSize).bold())
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(size == .large ? 0.6 : 0.5), radius: size == .large ? 2 : 1)
                            .monospacedDigit()
                        Spacer()
                    }
                }
            }
        }
        .frame(height: size.height)
        .animation(.easeInOut(duration: 0.4), value: percentage)
        .accessibilityLabel("Health: \(currentHp) of \(maxHp)")
    }

    private var textContent: String {
        switch size {
        case .large:
            "\(label)  \(currentHp) / \(maxHp)"
        case .widget:
            "\(currentHp)/\(maxHp)"
        case .compact:
            "\(currentHp) / \(maxHp)"
        }
    }

    @State private var pulseOpacity: Double = 1.0
}
