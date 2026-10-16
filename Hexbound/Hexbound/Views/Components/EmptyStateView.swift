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
                    .font(DarkFantasyTheme.cinematicTitle.weight(.thin))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .shadow(color: DarkFantasyTheme.goldDim.opacity(0.2), radius: 8)
                    .padding(.bottom, LayoutConstants.spaceSM)

                // Title
                Text(title)
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .multilineTextAlignment(.center)

                // Ornamental divider
                GoldDivider()
                    .padding(.horizontal, LayoutConstants.spaceXL)

                // Message
                Text(message)
                    .font(DarkFantasyTheme.body)
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
            .compositingGroup()
            .cardShadow()
            .padding(.horizontal, LayoutConstants.screenPadding)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Illustrated Empty States (2026-10-16)
//
// Pen-and-ink illustrations live in Assets.xcassets/EmptyStates
// (prompts + job ids: docs/08_prompts/EMPTY_STATE_ICONS_PROMPTS.md).
// The warm light under the art is drawn here, never baked into the PNG
// (ART_STYLE_GUIDE: "AI paints, code rules").
//
// Two layouts, one rule — say what this place is for, then give one next step:
// - EmptyStateScene  — illustration, title, one line, one main action.
// - EmptyStateHeader — compact art + title row for screens that fill the rest
//   with something useful (warriors you've met, how-it-works steps).

/// Empty-state illustration standing in a pool of warm light. Decorative only.
struct EmptyStateArt: View {
    let asset: String
    var size: CGFloat = 180

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DarkFantasyTheme.gold.opacity(0.16),
                            DarkFantasyTheme.goldDim.opacity(0.07),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.62
                    )
                )
                .frame(width: size * 1.24, height: size * 1.24)

            // Asset rule (Hexbound/CLAUDE.md): never render a missing image.
            if UIImage(named: asset) != nil {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: size, maxHeight: size)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Full empty state: illustration → what this place is → one main action.
struct EmptyStateScene: View {
    let art: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
    var hint: String? = nil

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            EmptyStateArt(asset: art, size: 180)
                .padding(.bottom, LayoutConstants.spaceXS)

            VStack(spacing: LayoutConstants.spaceSM) {
                Text(title)
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text(message)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                }
                .buttonStyle(.primary)
                .padding(.top, LayoutConstants.spaceSM)
            }

            if let hint {
                Text(hint)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceLG)
        .padding(.vertical, LayoutConstants.spaceLG)
        .frame(maxWidth: .infinity)
    }
}

/// Compact empty-state header — the rest of the screen carries the next step.
struct EmptyStateHeader: View {
    let art: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            EmptyStateArt(asset: art, size: 104)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text(title)
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text(message)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)
        }
    }
}

/// Numbered "how it works" card for an empty state.
struct EmptyStateSteps: View {
    let steps: [String]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: LayoutConstants.spaceMS) {
                    Text("\(index + 1)")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DarkFantasyTheme.gold, lineWidth: 1.5))

                    Text(step)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, LayoutConstants.spaceMS)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Step \(index + 1). \(step)")

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1)
        .compositingGroup()
        .cardShadow()
    }
}

// MARK: - Preset Factories

extension EmptyStateView {

    /// Inventory with no items
    static var stash: EmptyStateView {
        EmptyStateView(
            icon: "shippingbox",
            title: "Your Chest Is Empty",
            message: "Store items here from your inventory to share them between characters."
        )
    }

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
