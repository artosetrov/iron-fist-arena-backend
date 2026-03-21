import SwiftUI

// MARK: - Staggered Appear Animation (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §3.5)
// Cards/items fade in with slide-up, staggered by index.
// Usage: ForEach(items.indices) { i in ItemView().staggeredAppear(index: i) }

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let slideDistance: CGFloat
    let duration: Double
    let stagger: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : slideDistance)
            .onAppear {
                let delay = Double(index) * stagger
                withAnimation(
                    .easeOut(duration: duration)
                    .delay(delay)
                ) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Staggered fade-in + slide-up for list/grid items.
    /// - Parameters:
    ///   - index: Item position in the list (0-based). Determines delay.
    ///   - slideDistance: How far the item slides up from (default 8pt).
    ///   - duration: Animation duration per item (default 0.25s).
    ///   - stagger: Delay between items (default 0.05s).
    func staggeredAppear(
        index: Int,
        slideDistance: CGFloat = MotionConstants.cardSlideDistance,
        duration: Double = MotionConstants.fast,
        stagger: Double = MotionConstants.cardStagger
    ) -> some View {
        modifier(StaggeredAppearModifier(
            index: index,
            slideDistance: slideDistance,
            duration: duration,
            stagger: stagger
        ))
    }
}

// MARK: - Screen Shake Modifier (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §4.1)
// Applies a shake effect to the entire view.
// Usage: .screenShake(trigger: $shakeTriggered)

struct ScreenShakeModifier: ViewModifier {
    @Binding var trigger: Bool
    var intensity: CGFloat = MotionConstants.shakeIntensity
    var cycles: Int = MotionConstants.shakeCycles

    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, newValue in
                guard newValue else { return }
                shakeSequence()
            }
    }

    private func shakeSequence() {
        let cycleDuration = MotionConstants.shakeDuration / Double(cycles * 2)
        for i in 0..<(cycles * 2) {
            let direction: CGFloat = i.isMultiple(of: 2) ? 1 : -1
            let decay = 1.0 - (Double(i) / Double(cycles * 2))
            DispatchQueue.main.asyncAfter(deadline: .now() + cycleDuration * Double(i)) {
                withAnimation(.easeInOut(duration: cycleDuration)) {
                    offset = direction * intensity * decay
                }
            }
        }
        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.shakeDuration) {
            withAnimation(.easeOut(duration: 0.1)) {
                offset = 0
            }
            trigger = false
        }
    }
}

extension View {
    /// Apply screen shake effect. Set trigger to true to shake.
    func screenShake(
        trigger: Binding<Bool>,
        intensity: CGFloat = MotionConstants.shakeIntensity
    ) -> some View {
        modifier(ScreenShakeModifier(trigger: trigger, intensity: intensity))
    }
}

// MARK: - Glow Pulse Modifier (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §4.1)
// Subtle pulsing glow for CTAs, claimable items, FIGHT button.

struct GlowPulseModifier: ViewModifier {
    let color: Color
    let intensity: CGFloat
    let isActive: Bool

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? color.opacity(isPulsing ? Double(intensity) : Double(intensity * 0.3)) : .clear,
                radius: isPulsing ? 16 : 8
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(MotionConstants.pulse) {
                    isPulsing = true
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(MotionConstants.pulse) {
                        isPulsing = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPulsing = false
                    }
                }
            }
    }
}

extension View {
    /// Add a pulsing glow effect. Perfect for FIGHT button, claimable badges.
    func glowPulse(
        color: Color = DarkFantasyTheme.goldGlow,
        intensity: CGFloat = 0.6,
        isActive: Bool = true
    ) -> some View {
        modifier(GlowPulseModifier(color: color, intensity: intensity, isActive: isActive))
    }
}

// MARK: - Idle Breathing Modifier
// Subtle opacity breathing for portraits, ambient elements.

struct BreathingModifier: ViewModifier {
    let scale: CGFloat  // kept for API compat, ignored
    let isActive: Bool

    @State private var isBreathing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive && isBreathing ? 0.85 : 1.0)
            .onAppear {
                guard isActive else { return }
                withAnimation(MotionConstants.breathing) {
                    isBreathing = true
                }
            }
    }
}

extension View {
    /// Subtle idle breathing scale animation. Perfect for character portraits.
    func breathing(scale: CGFloat = 1.01, isActive: Bool = true) -> some View {
        modifier(BreathingModifier(scale: scale, isActive: isActive))
    }
}
