import SwiftUI

// MARK: - Contextual Hint Overlay

/// Unified view modifier that shows contextual NPC hints based on player state.
/// - First visit: Inline NPC Speech Card (compact NPCGuideWidget without typewriter)
/// - Repeat visits: Category-based ContextualHintBar
///
/// Usage:
/// ```swift
/// .contextualHint(hint, onCTA: { navigateToShop() })
/// ```
struct ContextualHintOverlay: ViewModifier {
    let hint: NPCHint?
    var onCTA: (() -> Void)? = nil
    /// Extra bottom padding so the hint clears floating buttons (e.g. Hub map toggle)
    var bottomInset: CGFloat = 0
    @Environment(AppState.self) private var appState
    @State private var showCompact = false
    @State private var dismissed = false

    func body(content: Content) -> some View {
        let hintManager = NPCHintManager.shared
        let charId = appState.currentCharacter?.id ?? ""

        content
            // First-visit full NPC Speech Card — presented as a modal coach
            // via NPCGuideOverlay (full-screen dim + taps blocked).
            .overlay {
                if !dismissed, let hint,
                   !hintManager.hasSeen(hint.id, for: charId),
                   let active = hintManager.activeHint, active.id == hint.id {
                    NPCGuideOverlay(onBackdropTap: {
                        hintManager.dismiss(for: charId)
                    }) {
                        NPCGuideWidget(
                            npcTitle: active.npcName,
                            onDismiss: {
                                hintManager.dismiss(for: charId)
                            },
                            npcImageName: active.npcImage,
                            plainMessage: active.message,
                            onDontShowAgain: {
                                // Bug #17: dismiss() already marks both main + compact as seen
                                hintManager.dismiss(for: charId)
                            },
                            ctaLabel: active.ctaLabel,
                            onCTA: onCTA.map { action in
                                {
                                    hintManager.dismiss(for: charId)
                                    action()
                                }
                            }
                            // overlapCardPx defaults to 8 — NPC peeks from BEHIND the card
                            // with only 8pt visible overlap, regardless of card height.
                        )
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            // Repeat-visit compact bar — stays inline (safeAreaInset) because
            // it's a small non-modal reminder, not a coach.
            .safeAreaInset(edge: .bottom) {
                if !dismissed, let hint,
                   hintManager.hasSeen(hint.id, for: charId),
                   hint.compactText != nil,
                   showCompact,
                   !hintManager.hasCompactBeenDismissed(hint.id, for: charId) {
                    ContextualHintBar(
                        hint: hint,
                        onAction: onCTA,
                        onDismiss: {
                            // Bug #17: persist dismissal so the bar never
                            // reappears after navigation, not just this session.
                            hintManager.dismissCompact(hint.id, for: charId)
                            withAnimation(MotionConstants.smooth) {
                                dismissed = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceSM + bottomInset)
                }
            }
            .onChange(of: hint?.id) { _, _ in
                dismissed = false
                showCompact = false
            }
            .onAppear {
                guard let hint, let charId = appState.currentCharacter?.id else { return }
                dismissed = false

                let hasSeen = hintManager.hasSeen(hint.id, for: charId)
                let compactDismissed = hintManager.hasCompactBeenDismissed(hint.id, for: charId)

                if !hasSeen {
                    // First visit — show full widget after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        hintManager.tryShow(hint, for: charId)
                    }
                } else if hint.compactText != nil, !compactDismissed {
                    // Repeat visit — show compact only if not permanently dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(MotionConstants.smooth) {
                            showCompact = true
                        }
                    }
                }
            }
    }

    private var hintManager: NPCHintManager { .shared }
}

extension View {
    /// Shows a contextual NPC hint based on player state.
    /// First visit: NPC Speech Card. Repeat: ContextualHintBar.
    /// Pass nil hint to show nothing.
    func contextualHint(_ hint: NPCHint?, onCTA: (() -> Void)? = nil, bottomInset: CGFloat = 0) -> some View {
        modifier(ContextualHintOverlay(hint: hint, onCTA: onCTA, bottomInset: bottomInset))
    }
}
