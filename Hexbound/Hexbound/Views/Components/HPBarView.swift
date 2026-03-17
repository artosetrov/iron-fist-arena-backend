import SwiftUI

/// Unified HP bar used across Hub, Combat, and Hero screens.
///
/// Uses `DarkFantasyTheme.canonicalHpGradient` for consistent color progression:
/// green (100%) → amber (25-75%) → red (<25%).
struct HPBarView: View {
    let currentHp: Int
    let maxHp: Int

    /// Bar height in points. Default 14.
    var height: CGFloat = 14

    /// Corner radius. Default 4.
    var cornerRadius: CGFloat = 4

    /// Show "current / max" text inside the bar when not full.
    var showTextInside: Bool = false

    /// Pulse animation when HP < 25%.
    var pulseOnCritical: Bool = false

    private var percentage: Double {
        guard maxHp > 0 else { return 0 }
        return Double(currentHp) / Double(maxHp)
    }

    private var isCritical: Bool { percentage < 0.25 && percentage > 0 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )

                // Fill bar
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DarkFantasyTheme.canonicalHpGradient(percentage: percentage))
                    .frame(width: geo.size.width * max(0.02, min(1, percentage)))
                    .opacity(pulseOnCritical && isCritical ? pulseOpacity : 1)

                // Text overlay
                if showTextInside && percentage < 1.0 {
                    Text("\(currentHp) / \(maxHp)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }
        }
        .frame(height: height)
        .animation(.easeInOut(duration: 0.4), value: percentage)
    }

    @State private var pulseOpacity: Double = 1.0
}
