import SwiftUI

// MARK: - NPC Hint Overlay

/// View modifier that shows a one-time NPC hint at the bottom of a screen.
/// Usage: `.npcHint(.arena)` on any screen's root view.
/// The hint waits for `isReady` to become true (content loaded) before showing.
struct NPCHintOverlay: ViewModifier {
    let hint: NPCHint
    var isReady: Bool
    var onCTA: (() -> Void)? = nil
    @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        let hintManager = NPCHintManager.shared
        let charId = appState.currentCharacter?.id ?? ""

        content
            .safeAreaInset(edge: .bottom) {
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
            }
            .onChange(of: isReady) { _, ready in
                if ready {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hintManager.tryShow(hint, for: charId)
                    }
                }
            }
            .onAppear {
                if isReady {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        hintManager.tryShow(hint, for: charId)
                    }
                }
            }
    }
}

extension View {
    /// Shows a one-time NPC guide hint when this screen's content is ready.
    func npcHint(_ hint: NPCHint, isReady: Bool = true, onCTA: (() -> Void)? = nil) -> some View {
        modifier(NPCHintOverlay(hint: hint, isReady: isReady, onCTA: onCTA))
    }
}
