import SwiftUI

/// The project's modal container.
///
/// Before 2026-10-14 there was none. Thirty-four screens each built their own
/// backdrop, centred their own card and repeated the same nine ornamental
/// modifiers with slightly different numbers — `cornerBrackets(length: 16)`
/// here, `18` there, `22` in the design-system version nobody called. The
/// backdrop alone was written four ways (`bgModal`, `bgBackdrop`,
/// `bgAbyss.opacity(0.85)`, `Color.black.opacity(0.55)`), closing behaviour
/// differed per modal, and nothing could be dismissed by swiping down.
///
/// This owns the parts that should not vary — backdrop, centring, transition,
/// dismissal — and delegates the card itself to `.modalOverlay(accent:)` in
/// `Theme/CardStyles.swift`, which already described the canonical frame. The
/// accent parameter is why that modifier went unused: modals need the colour
/// of their meaning (item rarity, danger, stamina), not always gold.
///
/// Usage:
/// ```
/// if showResult {
///     GameModal(accent: DarkFantasyTheme.danger, onDismiss: { showResult = false }) {
///         VStack { ... }
///     }
///     .zIndex(ZLayer.modal)
/// }
/// ```
struct GameModal<Content: View>: View {
    var accent: Color = DarkFantasyTheme.goldBright
    /// Confirmations and anything with a consequence set this false, so a
    /// stray tap outside cannot answer the question for the player.
    var dismissOnBackdropTap: Bool = true
    var dismissOnSwipeDown: Bool = true
    var maxWidth: CGFloat = 320
    let onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var dragOffset: CGFloat = 0

    /// Past this many points the modal closes on release.
    private static var dismissThreshold: CGFloat { 110 }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    guard dismissOnBackdropTap else { return }
                    onDismiss()
                }
                // VoiceOver reaches the card directly; the backdrop is a
                // pointer affordance, not content.
                .accessibilityHidden(true)

            content()
                .modalOverlay(accent: accent)
                .frame(maxWidth: maxWidth)
                .padding(.horizontal, LayoutConstants.screenPadding)
                .offset(y: dragOffset)
                .gesture(dragGesture, including: dismissOnSwipeDown ? .all : .subviews)
        }
        // Opacity only — the project does not scale modals in (see
        // TalentsTabView's note on the no-scale rule).
        .transition(.opacity)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Downward only: an upward drag should not lift the card off
                // the backdrop.
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height > Self.dismissThreshold {
                    onDismiss()
                }
                withAnimation(MotionConstants.spring) { dragOffset = 0 }
            }
    }
}
