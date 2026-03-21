import SwiftUI

/// Compact action pill used in UnifiedHeroWidget row-3 to display contextual actions
/// and status (heal, energy, stats, warnings, PvP, etc.).
@MainActor
struct WidgetPill: View {
    let icon: String                    // SF Symbol name or emoji string
    let text: String
    var count: String? = nil            // e.g. "×3"
<<<<<<< HEAD
    var imageAsset: String? = nil       // Asset catalog image name (replaces emoji icon)
=======
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
    let style: PillStyle
    var isInteractive: Bool = false
    var action: (() -> Void)? = nil

    enum PillStyle {
        case heal, urgent, energy, stat, warn, pvp, streak, bonus, error, offline
    }

    @State private var isGlowing = false

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
<<<<<<< HEAD
            if let asset = imageAsset {
                Image(asset)
                    .resizable().scaledToFit()
                    .frame(width: LayoutConstants.pillIconSize + 4, height: LayoutConstants.pillIconSize + 4)
            } else {
                Text(icon)
                    .font(.system(size: LayoutConstants.pillIconSize))
            }
=======
            Text(icon)
                .font(.system(size: LayoutConstants.pillIconSize))
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73

            // Text
            Text(text)
                .font(DarkFantasyTheme.body(size: LayoutConstants.pillFont).weight(.semibold))
                .foregroundStyle(textColor)
                .lineLimit(1)

            // Count badge (if present)
            if let count = count {
                Text(count)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.pillFont - 1).weight(.bold))
                    .foregroundStyle(textColor.opacity(0.7))
            }
        }
        .frame(height: LayoutConstants.pillHeight)
        .padding(.horizontal, LayoutConstants.pillPaddingH)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.pillRadius)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.pillRadius)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        // Pulsing glow for stat pills
        .if(style == .stat && isGlowing) { view in
            view.shadow(
                color: DarkFantasyTheme.gold.opacity(0.3),
                radius: 6,
                x: 0,
                y: 0
            )
        }
        .onAppear {
            if style == .stat {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
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
<<<<<<< HEAD
        WidgetPill(icon: "bandage", text: "Heal", style: .heal)
        WidgetPill(icon: "exclamationmark.triangle", text: "Critical", style: .urgent)
        WidgetPill(icon: "bolt", text: "Energy", count: "×2", style: .energy, isInteractive: true, action: {})
        WidgetPill(icon: "sparkles", text: "Stats Ready", style: .stat)
        WidgetPill(icon: "hammer", text: "Broken Gear", style: .warn)
        WidgetPill(icon: "trophy.fill", text: "1750 Rating", style: .pvp)
        WidgetPill(icon: "flame", text: "Streak: 3", style: .streak)
        WidgetPill(icon: "gift", text: "First Win!", style: .bonus)
=======
        WidgetPill(icon: "🩹", text: "Heal", style: .heal)
        WidgetPill(icon: "⚠️", text: "Critical", style: .urgent)
        WidgetPill(icon: "⚡", text: "Energy", count: "×2", style: .energy, isInteractive: true, action: {})
        WidgetPill(icon: "✨", text: "Stats Ready", style: .stat)
        WidgetPill(icon: "🔨", text: "Broken Gear", style: .warn)
        WidgetPill(icon: "🏆", text: "1750 Rating", style: .pvp)
        WidgetPill(icon: "🔥", text: "Streak: 3", style: .streak)
        WidgetPill(icon: "🎁", text: "First Win!", style: .bonus)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}
#endif
