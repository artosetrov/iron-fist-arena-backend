import SwiftUI

/// Reusable error state component for screens that failed to load.
///
/// Usage:
/// ```swift
/// ErrorStateView(
///     title: "Connection Lost",
///     message: "Could not load opponents.",
///     retryAction: { await vm.loadOpponents() }
/// )
/// ```
///
/// Follows Hexbound Design System v2.0.0:
/// - DarkFantasyTheme tokens only
/// - LayoutConstants for all spacing
/// - ButtonStyles for Retry CTA
/// - Accessibility labels included
/// Retry button layout variants.
///
/// - `.compact`: secondary style, content-width, centered. Default for most contexts.
/// - `.fullWidth`: primary style, matches `.buttonStyle(.primary)` bottom CTAs
///   (maxWidth + screenPadding + height 56). Use when the error state is shown
///   on a screen that already has a bottom primary CTA (e.g. character selection),
///   so retry and the bottom CTA look identical in width and weight.
enum ErrorStateRetryLayout {
    case compact
    case fullWidth
}

struct ErrorStateView: View {
    @Environment(\.dismiss) private var dismiss

    /// SF Symbol name — used only when `assetIcon` is nil.
    var icon: String = "exclamationmark.triangle"
    /// Optional Assets.xcassets image name. When set, renders the art asset
    /// instead of an SF Symbol — preferred per design system (art > system icons).
    var assetIcon: String? = nil
    /// When `true`, the asset is drawn with its original colors (no template
    /// tint). Use for full-color HUD illustrations like `hud-daily-quests`.
    /// When `false` (default), the asset is tinted with `DarkFantasyTheme.danger`,
    /// matching the legacy monochrome error glyph behaviour (e.g. `rush-ui-combat-skull`).
    var assetUsesOriginalColor: Bool = false
    var title: String = "Something Went Wrong"
    var message: String = "We couldn't load this content. Please try again."
    var retryLabel: String = "Retry"
    var retryAction: (() -> Void)? = nil
    var retryLayout: ErrorStateRetryLayout = .compact
    /// If provided, shows a Back CTA that calls this. If nil, falls back to
    /// SwiftUI's `@Environment(\.dismiss)` so the player is never trapped.
    var onBack: (() -> Void)? = nil
    /// When true, always render a back button (even if onBack is nil — uses dismiss).
    /// Defaults to true so error states never trap the player.
    var showBackButton: Bool = true

    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            // Error icon — prefer art asset over SF Symbol
            errorIcon
                .padding(.bottom, LayoutConstants.spaceSM)

            // Title
            Text(title)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutConstants.spaceXL)

            // Retry CTA
            if let retryAction {
                retryButton(action: retryAction)
                    .padding(.top, LayoutConstants.spaceSM)
            }

            // Back CTA — guarantees player can escape error state (Bug #18a)
            if showBackButton {
                Button {
                    if let onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.ghost)
                .padding(.horizontal, LayoutConstants.space2XL)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(title). \(message)")
    }

    // MARK: - Icon

    @ViewBuilder
    private var errorIcon: some View {
        if let assetIcon, UIImage(named: assetIcon) != nil {
            if assetUsesOriginalColor {
                // Full-color HUD illustration — render as-is, larger so
                // the art reads clearly at a glance.
                Image(assetIcon)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 12, y: 6)
            } else {
                // Monochrome glyph — tinted danger red, matches SF Symbol path.
                Image(assetIcon)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                    .foregroundStyle(DarkFantasyTheme.danger)
            }
        } else {
            Image(systemName: icon)
                .font(DarkFantasyTheme.cinematicTitle.weight(.thin))
                .foregroundStyle(DarkFantasyTheme.danger)
        }
    }

    // MARK: - Retry Button

    @ViewBuilder
    private func retryButton(action: @escaping () -> Void) -> some View {
        switch retryLayout {
        case .compact:
            Button(action: action) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "arrow.clockwise")
                    Text(retryLabel)
                }
            }
            .buttonStyle(.secondary)
            .padding(.horizontal, LayoutConstants.space2XL)
        case .fullWidth:
            Button(action: action) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "arrow.clockwise")
                    Text(retryLabel)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }
}

// MARK: - Preset Factories

extension ErrorStateView {

    /// Network failure (most common)
    static func network(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Check your internet connection and try again.",
            retryAction: retryAction
        )
    }

    /// Server error (5xx)
    static func server(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "server.rack",
            title: "Server Error",
            message: "Our servers are having trouble. Please try again in a moment.",
            retryAction: retryAction
        )
    }

    /// Battle failed to initialize
    static func battleInit(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "bolt.slash",
            title: "Battle Failed",
            message: "Could not start the battle. Your stamina was not consumed.",
            retryAction: retryAction
        )
    }

    /// Purchase failed
    static func purchase(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "creditcard.trianglebadge.exclamationmark",
            title: "Purchase Failed",
            message: "The transaction could not be completed. You were not charged.",
            retryAction: retryAction
        )
    }

    /// Data load failed (generic)
    static func loadFailed(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "exclamationmark.triangle",
            title: "Failed to Load",
            message: "Something went wrong loading this content.",
            retryAction: retryAction
        )
    }

    /// Timeout
    static func timeout(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "clock.badge.exclamationmark",
            title: "Request Timed Out",
            message: "The server took too long to respond. Try again.",
            retryAction: retryAction
        )
    }
}
