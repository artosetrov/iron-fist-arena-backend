import SwiftUI

// MARK: - NPC Guide Overlay

/// Full-screen overlay container for `NPCGuideWidget` presentations.
///
/// Responsibilities:
/// - Dims the entire screen (bgAbyss @ 50%) so the widget reads as a modal-style
///   coach hint rather than inline content.
/// - Blocks taps from reaching the UI behind — only the backdrop tap, dismiss (✕),
///   CTA, or "Don't show again" can close the widget.
/// - Pins the widget to the bottom of the screen, respecting safe area.
/// - Applies the standard entrance/exit transition (dim fade + widget slide-up).
///
/// Used by: ArenaDetailView, HubView (onboarding + merchant), ShopDetailView,
/// NPCHintOverlay, ContextualHintOverlay.
///
/// NOT used by: FortuneWheelDetailView, ShellGameDetailView (their widget IS the
/// primary interaction surface), TutorialSpotlightOverlay (has its own spotlight
/// dim), ModalsCatalogView (dev catalog preview).
///
/// Usage:
/// ```swift
/// .overlay {
///     if showGuide {
///         NPCGuideOverlay(onBackdropTap: { dismiss() }) {
///             NPCGuideWidget(
///                 npcTitle: "Arena Master",
///                 onDismiss: { dismiss() },
///                 ...
///             )
///         }
///         .transition(.opacity)
///         .zIndex(100)
///     }
/// }
/// ```
@MainActor
struct NPCGuideOverlay<Content: View>: View {
    /// Called when the user taps the dim backdrop outside the widget.
    /// Typically mirrors the widget's `onDismiss` so tap-to-close works everywhere.
    var onBackdropTap: () -> Void
    /// Widget content — typically an `NPCGuideWidget`.
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            // Layer 0: Full-screen dim backdrop.
            // - bgAbyss @ 50% matches HubView onboarding convention.
            // - .ignoresSafeArea() makes the dim cover status bar + home indicator.
            // - .contentShape(Rectangle()) ensures the whole area catches taps
            //   (otherwise a Color view with only onTapGesture may not cover
            //   the extended safe-area region reliably).
            // - Tap on backdrop → onBackdropTap (parent decides whether to dismiss).
            DarkFantasyTheme.bgAbyss
                .opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    onBackdropTap()
                }

            // Layer 1: Widget content pinned to bottom.
            // - ZStack alignment .bottom keeps content anchored to the bottom edge
            //   while respecting safe area (so the widget sits above the home
            //   indicator without extra math).
            // - Standard npcOuterPadding matches all existing call sites for
            //   horizontal + bottom spacing.
            // - allowsHitTesting stays default (true) so the widget's own buttons
            //   work; taps on the widget's internal .contentShape are consumed
            //   by the widget, not the backdrop.
            content()
                .padding(.horizontal, LayoutConstants.npcOuterPadding)
                .padding(.bottom, LayoutConstants.npcOuterPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
