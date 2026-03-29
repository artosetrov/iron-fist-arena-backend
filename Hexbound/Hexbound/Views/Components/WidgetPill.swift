import SwiftUI

/// Action pill used in UnifiedHeroWidget row-4 to display contextual actions
/// and status (heal, energy, warnings, PvP, etc.).
///
/// Redesigned for comfortable touch targets (44pt height, 14px font, icon in circle).
@MainActor
struct WidgetPill: View {
    let icon: String                    // SF Symbol name or emoji string
    let text: String
    var count: String? = nil            // e.g. "×3"
    var imageAsset: String? = nil       // Asset catalog image name (replaces emoji icon)
    let style: PillStyle
    var isInteractive: Bool = false
    var action: (() -> Void)? = nil

    enum PillStyle {
        case heal, urgent, energy, stat, warn, pvp, streak, bonus, error, offline
    }

    @State private var isGlowing = false

    private var accentColor: Color {
        switch style {
        case .heal, .bonus: DarkFantasyTheme.success
        case .urgent, .warn, .streak, .error: DarkFantasyTheme.danger
        case .energy: DarkFantasyTheme.stamina
        case .stat: DarkFantasyTheme.gold
        case .pvp: DarkFantasyTheme.gold
        case .offline: DarkFantasyTheme.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .heal: DarkFantasyTheme.pillHealBg
        case .urgent: DarkFantasyTheme.pillUrgentBg
        case .energy: DarkFantasyTheme.pillEnergyBg
        case .stat: DarkFantasyTheme.pillStatBg
        case .warn: DarkFantasyTheme.pillWarnBg
        case .pvp: DarkFantasyTheme.pillPvpBg
        case .streak: DarkFantasyTheme.pillStreakBg
        case .bonus: DarkFantasyTheme.pillBonusBg
        case .error: DarkFantasyTheme.pillErrorBg
        case .offline: DarkFantasyTheme.pillOfflineBg
        }
    }

    private var borderColor: Color {
        switch style {
        case .heal: DarkFantasyTheme.pillHealBorder
        case .urgent: DarkFantasyTheme.pillUrgentBorder
        case .energy: DarkFantasyTheme.pillEnergyBorder
        case .stat: DarkFantasyTheme.pillStatBorder
        case .warn: DarkFantasyTheme.pillWarnBorder
        case .pvp: DarkFantasyTheme.pillPvpBorder
        case .streak: DarkFantasyTheme.pillStreakBorder
        case .bonus: DarkFantasyTheme.pillBonusBorder
        case .error: DarkFantasyTheme.pillErrorBorder
        case .offline: DarkFantasyTheme.pillOfflineBorder
        }
    }

    private var textColor: Color {
        switch style {
        case .heal: DarkFantasyTheme.pillHealText
        case .urgent: DarkFantasyTheme.pillUrgentText
        case .energy: DarkFantasyTheme.pillEnergyText
        case .stat: DarkFantasyTheme.pillStatText
        case .warn: DarkFantasyTheme.pillWarnText
        case .pvp, .streak, .bonus, .error, .offline: DarkFantasyTheme.textSecondary
        }
    }

    var body: some View {
        if isInteractive, let action = action {
            Button(action: action) {
                pillContent
            }
            .buttonStyle(.scalePress(0.9))
        } else {
            pillContent
        }
    }

    private var pillContent: some View {
        HStack(spacing: LayoutConstants.pillGap) {
            // Icon
            iconView

            // Label
            Text(text)
                .font(DarkFantasyTheme.body(size: LayoutConstants.pillFont).weight(.semibold))
                .foregroundStyle(textColor)
                .lineLimit(1)

            // Count badge (right-aligned)
            if let count = count {
                Spacer(minLength: 0)
                Text(count)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.pillCountFont).weight(.bold))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.widgetBarRadius)
                            .fill(accentColor.opacity(0.2))
                    )
            }
        }
        .frame(height: LayoutConstants.pillHeight)
        .padding(.horizontal, LayoutConstants.pillPaddingH)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.pillRadius)
                    .fill(backgroundColor)
                // Inner top highlight for convex look
                RoundedRectangle(cornerRadius: LayoutConstants.pillRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), .clear, Color.black.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                // Subtle radial glow from accent color
                RoundedRectangle(cornerRadius: LayoutConstants.pillRadius)
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                // Border
                RoundedRectangle(cornerRadius: LayoutConstants.pillRadius)
                    .stroke(borderColor, lineWidth: 1.5)
                // Inner bevel
                RoundedRectangle(cornerRadius: LayoutConstants.pillRadius - 2)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), .clear, Color.black.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                    .padding(2)
            }
        )
        // Pulsing glow for urgent pills
        .shadow(
            color: style == .urgent && isGlowing ? accentColor.opacity(0.4) : accentColor.opacity(0.08),
            radius: style == .urgent && isGlowing ? 8 : 3
        )
        .onAppear {
            if style == .urgent {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
        }
    }

    // MARK: - Icon View

    @ViewBuilder
    private var iconView: some View {
        if let asset = imageAsset {
            Image(asset)
                .resizable().scaledToFit()
                .frame(width: LayoutConstants.pillIconSize + 4, height: LayoutConstants.pillIconSize + 4)
        } else if !icon.isEmpty {
            Text(icon)
                .font(.system(size: LayoutConstants.pillIconSize))
        }
    }
}

// MARK: - View Modifier Extension

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        WidgetPill(icon: "", text: "Heal", count: "×3", imageAsset: "pot_health_small", style: .heal, isInteractive: true, action: {})
        WidgetPill(icon: "", text: "Heal", count: "×1", imageAsset: "pot_health_small", style: .urgent, isInteractive: true, action: {})
        WidgetPill(icon: "", text: "Energy", count: "×2", imageAsset: "pot_stamina_small", style: .energy, isInteractive: true, action: {})
        WidgetPill(icon: "", text: "Repair Gear", imageAsset: "icon-strength", style: .warn)
        WidgetPill(icon: "", text: "1750 Rating", imageAsset: "icon-pvp-rating", style: .pvp)
        WidgetPill(icon: "", text: "Streak: 3", imageAsset: "icon-wins", style: .streak)
        WidgetPill(icon: "", text: "First Win!", imageAsset: "reward-first-win", style: .bonus)

        // Two pills side by side
        HStack(spacing: LayoutConstants.pillSpacing) {
            WidgetPill(icon: "", text: "Heal", count: "×3", imageAsset: "pot_health_small", style: .heal, isInteractive: true, action: {})
            WidgetPill(icon: "", text: "Energy", count: "×2", imageAsset: "pot_stamina_small", style: .energy, isInteractive: true, action: {})
        }
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}
#endif
