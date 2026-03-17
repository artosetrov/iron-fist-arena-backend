import SwiftUI

// MARK: - Tutorial Tooltip View

/// A themed tooltip bubble with arrow, title, message, and dismiss/skip controls.
/// Attach via `.tutorialTooltip(step:)` view modifier.
struct TutorialTooltipView: View {
    let step: TutorialStep
    let onDismiss: () -> Void
    let onSkipAll: () -> Void

    @State private var appeared = false

    private let bubbleMaxWidth: CGFloat = 280

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Title row
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(step.title)
                    .font(DarkFantasyTheme.section(size: 15))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
            }

            // Message
            Text(step.message)
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Action row
            HStack {
                Button {
                    onSkipAll()
                } label: {
                    Text("Skip all tips")
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("Got it")
                        .font(DarkFantasyTheme.section(size: 13))
                        .foregroundStyle(DarkFantasyTheme.bgPrimary)
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.vertical, LayoutConstants.spaceXS)
                        .background(
                            Capsule().fill(DarkFantasyTheme.gold)
                        )
                }
            }
        }
        .padding(LayoutConstants.spaceMD)
        .frame(maxWidth: bubbleMaxWidth)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: DarkFantasyTheme.gold.opacity(0.15), radius: 16, y: 4)
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

// MARK: - Spotlight Overlay

/// Full-screen dimmed overlay that highlights a target rect and shows a tooltip.
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
                    .fill(Color.black.opacity(0.55))
                    .ignoresSafeArea()
                    .onTapGesture { onDismiss() }

                // Tooltip positioned relative to target
                tooltipPositioned(in: geo)
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

    @ViewBuilder
    private func tooltipPositioned(in geo: GeometryProxy) -> some View {
        let edge = step.arrowEdge
        let tooltip = TutorialTooltipView(
            step: step,
            onDismiss: onDismiss,
            onSkipAll: onSkipAll
        )

        switch edge {
        case .top:
            // Tooltip below the target
            tooltip
                .position(
                    x: clampX(targetFrame.midX, in: geo.size.width),
                    y: targetFrame.maxY + 16 + 60
                )
        case .bottom:
            // Tooltip above the target
            tooltip
                .position(
                    x: clampX(targetFrame.midX, in: geo.size.width),
                    y: targetFrame.minY - 16 - 60
                )
        case .leading:
            // Tooltip to the right
            tooltip
                .position(
                    x: min(targetFrame.maxX + 150, geo.size.width - 20),
                    y: targetFrame.midY
                )
        case .trailing:
            // Tooltip to the left
            tooltip
                .position(
                    x: max(targetFrame.minX - 150, 20),
                    y: targetFrame.midY
                )
        }
    }

    private func clampX(_ x: CGFloat, in width: CGFloat) -> CGFloat {
        let margin: CGFloat = 20
        let halfBubble: CGFloat = 140
        return min(max(x, margin + halfBubble), width - margin - halfBubble)
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
