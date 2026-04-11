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
            // NPCGuideOverlay — full-screen dim + tap-blocked presentation.
            // Switched from safeAreaInset (inline push) to overlay so the hint
            // reads as a modal coach, matching the Arena Master pattern.
            .overlay {
                if let active = hintManager.activeHint, active.id == hint.id {
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
                                hintManager.dismiss(for: charId)
                            },
                            ctaLabel: active.ctaLabel,
                            onCTA: onCTA.map { action in
                                {
                                    hintManager.dismiss(for: charId)
                                    action()
                                }
                            },
                            // Hint cards are short (~140pt). Default offset -140 leaves the NPC
                            // floating above the plate with a gap. These values guarantee a
                            // peek-from-behind look matching the minigame widgets.
                            customAvatarSize: 320,
                            customAvatarOffset: -60
                        )
                    }
                    .transition(.opacity)
                    .zIndex(100)
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
