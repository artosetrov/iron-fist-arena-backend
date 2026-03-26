import SwiftUI

// MARK: - NPC Hint Overlay

/// View modifier that shows a one-time NPC hint at the bottom of a screen.
/// Usage: `.npcHint(.arena)` on any screen's root view.
struct NPCHintOverlay: ViewModifier {
    let hint: NPCHint
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
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceSM)
                }
            }
            .onAppear {
                // Small delay so the screen renders first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    hintManager.tryShow(hint, for: charId)
                }
            }
    }
}

extension View {
    /// Shows a one-time NPC guide hint when this screen first appears.
    func npcHint(_ hint: NPCHint) -> some View {
        modifier(NPCHintOverlay(hint: hint))
    }
}
