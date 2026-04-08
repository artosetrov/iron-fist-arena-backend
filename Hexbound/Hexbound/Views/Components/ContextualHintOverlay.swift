import SwiftUI

// MARK: - Contextual Hint Overlay

/// View modifier that shows contextual NPC hints based on player state.
/// - First visit: Full NPCGuideWidget (bottom sheet with typewriter animation)
/// - Repeat visits: Compact inline NPCCompactHintView
///
/// Usage:
/// ```swift
/// .contextualHint(hint, onCTA: { navigateToShop() })
/// ```
struct ContextualHintOverlay: ViewModifier {
    let hint: NPCHint?
    var onCTA: (() -> Void)? = nil
    @Environment(AppState.self) private var appState
    @State private var showCompact = false
    @State private var dismissed = false

    func body(content: Content) -> some View {
        let hintManager = NPCHintManager.shared
        let charId = appState.currentCharacter?.id ?? ""

        content
            .safeAreaInset(edge: .bottom) {
                if !dismissed, let hint {
                    let hasSeen = hintManager.hasSeen(hint.id, for: charId)

                    if !hasSeen {
                        // First visit: Full NPC widget
                        if let active = hintManager.activeHint, active.id == hint.id {
                            NPCGuideWidget(
                                npcTitle: active.npcName,
                                onDismiss: {
                                    hintManager.dismiss(for: charId)
                                },
                                npcImageName: active.npcImage,
                                plainMessage: active.message,
                                onSkipAll: {
                                    hintManager.skipAll(for: charId)
                                },
                                onContinue: {
                                    hintManager.dismiss(for: charId)
                                },
                                ctaLabel: active.ctaLabel,
                                onCTA: onCTA.map { action in
                                    {
                                        hintManager.dismiss(for: charId)
                                        action()
                                    }
                                },
                                typewriterEnabled: true
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.bottom, LayoutConstants.spaceSM)
                        }
                    } else if hint.compactText != nil, showCompact {
                        // Repeat visit: Compact widget
                        NPCCompactHintView(
                            hint: hint,
                            onAction: onCTA,
                            onDismiss: {
                                withAnimation(MotionConstants.smooth) {
                                    dismissed = true
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)
                    }
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
                if !hasSeen {
                    // First visit — show full widget after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        hintManager.tryShow(hint, for: charId)
                    }
                } else if hint.compactText != nil {
                    // Repeat visit — show compact after shorter delay
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
    /// First visit: full NPCGuideWidget. Repeat: compact inline widget.
    /// Pass nil hint to show nothing.
    func contextualHint(_ hint: NPCHint?, onCTA: (() -> Void)? = nil) -> some View {
        modifier(ContextualHintOverlay(hint: hint, onCTA: onCTA))
    }
}
