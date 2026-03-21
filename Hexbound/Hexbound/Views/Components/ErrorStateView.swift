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
struct ErrorStateView: View {
    var icon: String = "exclamationmark.triangle"
    var title: String = "Something Went Wrong"
    var message: String = "We couldn't load this content. Please try again."
    var retryLabel: String = "Retry"
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            // Error icon
            Image(systemName: icon)
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(DarkFantasyTheme.danger)
                .padding(.bottom, LayoutConstants.spaceSM)

            // Title
            Text(title)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutConstants.spaceXL)

            // Retry CTA
            if let retryAction {
                Button(action: retryAction) {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "arrow.clockwise")
                        Text(retryLabel)
                    }
                }
                .buttonStyle(.secondary)
                .padding(.horizontal, LayoutConstants.space2XL)
                .padding(.top, LayoutConstants.spaceSM)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(title). \(message)")
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
