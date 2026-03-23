import SwiftUI

/// Unified stamina bar used across all screens.
///
/// Sizes:
/// - `.compact` — HStack with bolt icon, bar, value text, optional plus button (Arena style)
/// - `.large` — Full-width bar with "Stamina X / Y" centered inside (Hero card style)
/// Wrap in a Button externally if you need tap-to-navigate behavior.
struct StaminaBarView: View {
    let currentStamina: Int
    let maxStamina: Int

    /// Display size preset.
    var size: BarSize = .compact

    /// Show "+" button (compact only).
    var showPlus: Bool = true

    /// Recovery text label (compact only).
    var recoveryText: String? = nil

    enum BarSize {
        case compact   // HStack with icon + bar + value (Arena style)
        case large     // Full-width bar with text inside (Hero card style)
    }

    private var fraction: Double {
        maxStamina > 0 ? Double(currentStamina) / Double(maxStamina) : 0
    }

    private var isLow: Bool { currentStamina < 10 }

    var body: some View {
        switch size {
        case .compact:
            compactLayout
        case .large:
            largeLayout
        }
    }

    // MARK: - Compact Layout (original Arena style)

    private var compactLayout: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "bolt.fill")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody).bold())
                .foregroundStyle(DarkFantasyTheme.stamina)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.staminaGradient)
                        .overlay(
                            BarFillHighlight(cornerRadius: LayoutConstants.radiusSM)
                        )
                        .frame(width: geo.size.width * fraction)
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                        .shadow(color: DarkFantasyTheme.stamina.opacity(0.2), radius: 3, y: 0)
                }
            }
            .frame(height: 14)

            Text("\(currentStamina)/\(maxStamina)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.stamina)
                .monospacedDigit()

            if showPlus {
                Image(systemName: "plus.circle.fill")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            if let recoveryText, currentStamina < maxStamina {
                Text(recoveryText)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .padding(.horizontal, LayoutConstants.cardPadding)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.stamina.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.stamina.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Stamina: \(currentStamina) of \(maxStamina)")
    }

    // MARK: - Large Layout (Hero card style — same pattern as HPBarView.large)

    private var largeLayout: some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                .fill(DarkFantasyTheme.textPrimary.opacity(0.06))
                .frame(height: LayoutConstants.heroBarXpHeight)

            // Fill with top highlight
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                    .fill(DarkFantasyTheme.staminaGradient)
                    .overlay(
                        BarFillHighlight(cornerRadius: LayoutConstants.heroBarRadius)
                    )
                    .frame(width: geo.size.width * fraction)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius))
                    .shadow(color: DarkFantasyTheme.stamina.opacity(0.2), radius: 4, y: 0)
            }
            .frame(height: LayoutConstants.heroBarXpHeight)

            // Label + Value centered
            HStack {
                Spacer()
                Text("Stamina  \(currentStamina) / \(maxStamina)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.heroBarFont).bold())
                    .foregroundStyle(isLow ? DarkFantasyTheme.textWarning : DarkFantasyTheme.textPrimary)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 2)
                    .monospacedDigit()
                Spacer()
            }
            .frame(height: LayoutConstants.heroBarXpHeight)
        }
        .accessibilityLabel("Stamina: \(currentStamina) of \(maxStamina)")
    }
}
