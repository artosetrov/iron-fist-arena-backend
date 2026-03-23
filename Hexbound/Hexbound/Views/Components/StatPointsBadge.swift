import SwiftUI

/// Unified stat points indicator used across all screens.
///
/// Styles:
/// - `.banner` — Full-width green-bordered banner with star icon (HeroDetailView stats tab)
/// - `.pill` — Compact WidgetPill style for cards (HeroIntegratedCard, UnifiedHeroWidget)
/// - `.reward` — Inline reward row for modals (LevelUpModal)
struct StatPointsBadge: View {
    let points: Int

    /// Display style preset.
    var style: BadgeStyle = .banner

    /// Interactive action (pill style only).
    var onTap: (() -> Void)? = nil

    enum BadgeStyle {
        case banner   // Full-width green banner (character detail / stats tab)
        case pill     // Compact WidgetPill (hero card / widget)
        case reward   // Reward row for modals
    }

    var body: some View {
        switch style {
        case .banner:
            bannerLayout
        case .pill:
            WidgetPill(
                icon: "⭐",
                text: "+\(points) Stats",
                style: .stat,
                isInteractive: onTap != nil,
                action: onTap
            )
        case .reward:
            rewardLayout
        }
    }

    // MARK: - Banner Layout (full-width, green border)

    private var bannerLayout: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("Stat Points: \(points)")
            }
            .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
            .foregroundStyle(DarkFantasyTheme.textSuccess)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.success.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .stroke(DarkFantasyTheme.success.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Stat Points available: \(points)")
    }

    // MARK: - Reward Layout (inline row for modals)

    private var rewardLayout: some View {
        HStack {
            Text("⭐")
                .font(.system(size: LayoutConstants.textCard))
            Text("Stat Points")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text("+\(points)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody).bold())
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .accessibilityLabel("Stat Points reward: plus \(points)")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        StatPointsBadge(points: 5, style: .banner)
            .padding(.horizontal, LayoutConstants.spaceMD)
        StatPointsBadge(points: 3, style: .pill, onTap: {})
        StatPointsBadge(points: 2, style: .reward)
            .padding(.horizontal, LayoutConstants.spaceMD)
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}
#endif
