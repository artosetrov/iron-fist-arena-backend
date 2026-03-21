import SwiftUI

// MARK: - Tutorial Tooltip View (uses unified NPCGuideWidget)

/// Wrapper around `NPCGuideWidget` for tutorial steps.
/// Adds entrance animation (scale + fade) and maps `TutorialStep` to widget props.
struct TutorialTooltipView: View {
    let step: TutorialStep
    let onDismiss: () -> Void
    let onSkipAll: () -> Void

    @State private var appeared = false

    var body: some View {
        NPCGuideWidget(
            npcTitle: step.npcName,
            onDismiss: onDismiss,
            npcImageName: step.npcImageAsset,
            plainMessage: step.message,
            onSkipAll: onSkipAll,
            onContinue: {
                onDismiss()
            },
            npcFallbackIcon: step.npcFallbackIcon
        )
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Spotlight Overlay

/// Full-screen dimmed overlay that highlights a target rect and shows an NPC tooltip at the bottom.
struct TutorialSpotlightOverlay: View {
    let step: TutorialStep
    let targetFrame: CGRect
    let onDismiss: () -> Void
    let onSkipAll: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dimmed backdrop with cutout
                spotlightMask(in: geo.size)
                    .fill(DarkFantasyTheme.bgAbyss.opacity(0.55))
                    .ignoresSafeArea()
                    .onTapGesture { onDismiss() }

                // Tooltip pinned to bottom of screen (uses NPCGuideWidget)
                VStack {
                    Spacer()
                    TutorialTooltipView(
                        step: step,
                        onDismiss: onDismiss,
                        onSkipAll: onSkipAll
                    )
                    .padding(.horizontal, LayoutConstants.npcOuterPadding)
                    .padding(.bottom, LayoutConstants.npcOuterPadding)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func spotlightMask(in size: CGSize) -> Path {
        var path = Path()
        path.addRect(CGRect(origin: .zero, size: size))
        // Cutout — rounded rect around the target
        let inset = targetFrame.insetBy(dx: -6, dy: -6)
        let cutout = Path(roundedRect: inset, cornerRadius: 10)
        path = path.subtracting(cutout)
        return path
    }
}

// MARK: - Anchor Preference Key

struct TutorialAnchorKey: PreferenceKey {
    static var defaultValue: [TutorialStep: CGRect] = [:]
    static func reduce(value: inout [TutorialStep: CGRect], nextValue: () -> [TutorialStep: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - View Modifier: Tooltip Anchor

/// Mark a view as the anchor for a tutorial step.
/// Usage: `.tutorialAnchor(.hubCharacterCard)`
struct TutorialAnchorModifier: ViewModifier {
    let step: TutorialStep

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: TutorialAnchorKey.self,
                            value: [step: geo.frame(in: .global)]
                        )
                }
            )
    }
}

extension View {
    func tutorialAnchor(_ step: TutorialStep) -> some View {
        modifier(TutorialAnchorModifier(step: step))
    }
}

// MARK: - View Modifier: Tutorial Overlay Host

/// Add to a screen's root view to show tutorial tooltips.
/// Usage: `.tutorialOverlay(steps: [.hubCharacterCard, .hubCityMap])`
struct TutorialOverlayModifier: ViewModifier {
    let steps: [TutorialStep]
    let delay: TimeInterval

    @State private var anchors: [TutorialStep: CGRect] = [:]
    private let tutorial = TutorialManager.shared

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(TutorialAnchorKey.self) { value in
                anchors = value
            }
            .overlay {
                if let active = tutorial.activeStep,
                   let frame = anchors[active] {
                    TutorialSpotlightOverlay(
                        step: active,
                        targetFrame: frame,
                        onDismiss: { tutorial.dismiss() },
                        onSkipAll: { tutorial.skipAll() }
                    )
                    .transition(.opacity)
                }
            }
            .task {
                // Small delay so the screen renders and anchors are captured
                try? await Task.sleep(for: .seconds(delay))
                showNextAvailable()
            }
            .onChange(of: tutorial.activeStep) { _, newValue in
                if newValue == nil {
                    // After dismissing, show next tooltip in sequence
                    Task {
                        try? await Task.sleep(for: .seconds(0.4))
                        showNextAvailable()
                    }
                }
            }
    }

    private func showNextAvailable() {
        for step in steps {
            if tutorial.shouldShow(step) && anchors[step] != nil {
                tutorial.tryShow(step)
                return
            }
        }
    }
}

extension View {
    /// Attach tutorial overlay to a screen. Steps are shown in order.
    func tutorialOverlay(steps: [TutorialStep], delay: TimeInterval = 0.8) -> some View {
        modifier(TutorialOverlayModifier(steps: steps, delay: delay))
    }
}
