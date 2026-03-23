import SwiftUI

/// Reusable empty state component for screens with no data.
///
/// Usage:
/// ```swift
/// EmptyStateView(
///     icon: "backpack",
///     title: "No Items Yet",
///     message: "Win battles or visit the shop to get gear.",
///     actionLabel: "Go to Shop"
/// ) { /* navigate to shop */ }
/// ```
///
/// Follows Hexbound Design System v2.0.0:
/// - DarkFantasyTheme tokens only (no hardcoded colors)
/// - LayoutConstants for all spacing
/// - ButtonStyles for CTA
/// - Accessibility labels included
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            // Ornamental panel card wrapping the content
            VStack(spacing: LayoutConstants.spaceMS) {
                // Icon with subtle glow
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .shadow(color: DarkFantasyTheme.goldDim.opacity(0.2), radius: 8)
                    .padding(.bottom, LayoutConstants.spaceSM)

                // Title
                Text(title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .multilineTextAlignment(.center)

                // Ornamental divider
                GoldDivider()
                    .padding(.horizontal, LayoutConstants.spaceXL)

                // Message
                Text(message)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceSM)

                // Optional CTA
                if let actionLabel, let action {
                    Button(action: action) {
                        Text(actionLabel)
                    }
                    .buttonStyle(.secondary)
                    .padding(.horizontal, LayoutConstants.spaceXL)
                    .padding(.top, LayoutConstants.spaceSM)
                }
            }
            .padding(LayoutConstants.spaceLG)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(
                cornerRadius: LayoutConstants.panelRadius - 3,
                inset: 3,
                color: DarkFantasyTheme.borderMedium.opacity(0.15)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.borderMedium, length: 14, thickness: 1.5)
            .cornerDiamonds(color: DarkFantasyTheme.goldDim, size: 4)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
            .padding(.horizontal, LayoutConstants.screenPadding)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Preset Factories

extension EmptyStateView {

    /// Inventory with no items
    static func inventory(shopAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "backpack",
            title: "No Items Yet",
            message: "Win battles or visit the shop to collect gear.",
            actionLabel: "Visit Shop",
            action: shopAction
        )
    }

    /// Quest log with all quests completed
    static var questsComplete: EmptyStateView {
        EmptyStateView(
            icon: "checkmark.seal",
            title: "All Done!",
            message: "You've completed all available quests. Check back tomorrow for new ones."
        )
    }

    /// Leaderboard with no data
    static var leaderboard: EmptyStateView {
        EmptyStateView(
            icon: "trophy",
            title: "No Rankings Yet",
            message: "Fight in the arena to appear on the leaderboard."
        )
    }

    /// Inbox with no messages
    static var inbox: EmptyStateView {
        EmptyStateView(
            icon: "envelope",
            title: "Inbox Empty",
            message: "No messages yet. Rewards and notifications will appear here."
        )
    }

    /// Shop tab with no items
    static var shopEmpty: EmptyStateView {
        EmptyStateView(
            icon: "cart",
            title: "No Items Available",
            message: "This section is empty right now. Check back later!"
        )
    }

    /// Arena with no opponents
    static func arena(refreshAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "person.2.slash",
            title: "No Opponents Found",
            message: "No worthy challengers right now. Try refreshing.",
            actionLabel: "Refresh",
            action: refreshAction
        )
    }

    /// Dungeon select with nothing unlocked
    static var dungeonLocked: EmptyStateView {
        EmptyStateView(
            icon: "lock.shield",
            title: "Dungeons Locked",
            message: "Reach a higher level to unlock dungeon expeditions."
        )
    }

    /// Achievements with nothing in category
    static var noAchievements: EmptyStateView {
        EmptyStateView(
            icon: "star",
            title: "No Achievements",
            message: "Nothing in this category yet. Keep playing!"
        )
    }

    /// Battle history with no fights
    static var noHistory: EmptyStateView {
        EmptyStateView(
            icon: "clock.arrow.circlepath",
            title: "No Battle History",
            message: "Your combat record will appear here after your first fight."
        )
    }

    /// Generic empty for any screen
    static func generic(title: String = "Nothing Here", message: String = "There's nothing to show right now.") -> EmptyStateView {
        EmptyStateView(
            icon: "tray",
            title: title,
            message: message
        )
    }
}
