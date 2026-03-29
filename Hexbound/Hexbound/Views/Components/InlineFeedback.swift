import SwiftUI

// MARK: - Layer 1: Inline Feedback System
// Replaces ~100 unnecessary toasts with on-element visual feedback.
// Pattern: flash border on element + floating text + haptic = user knows action succeeded.

/// Floating text that drifts upward and fades out (e.g., "+120 gold", "EQUIPPED", "+50 HP").
struct FloatingFeedbackText: View {
    let text: String
    let color: Color
    @Binding var isVisible: Bool

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.cardTitle)
            .foregroundStyle(color)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 3, y: 1)
            .offset(y: offsetY)
            .opacity(opacity)
            .onChange(of: isVisible) { _, visible in
                if visible {
                    // Reset
                    offsetY = 0
                    opacity = 1
                    // Animate float up + fade
                    withAnimation(.easeOut(duration: 1.0)) {
                        offsetY = -28
                    }
                    withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                        opacity = 0
                    }
                    // Auto-hide after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isVisible = false
                    }
                }
            }
            .allowsHitTesting(false)
    }
}

/// Flash border overlay — pulses a colored border on an element, then fades.
/// Usage: `.overlay { FlashBorder(color: .gold, isActive: $showFlash) }`
struct FlashBorder: View {
    let color: Color
    @Binding var isActive: Bool
    var cornerRadius: CGFloat = LayoutConstants.radiusLG
    var lineWidth: CGFloat = 2

    @State private var opacity: Double = 0
    @State private var glowRadius: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(color, lineWidth: lineWidth)
            .shadow(color: color.opacity(0.5), radius: glowRadius)
            .opacity(opacity)
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, active in
                if active {
                    // Flash in
                    withAnimation(.easeOut(duration: 0.15)) {
                        opacity = 1
                        glowRadius = 8
                    }
                    // Fade out
                    withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                        opacity = 0
                        glowRadius = 0
                    }
                    // Reset
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isActive = false
                    }
                }
            }
    }
}

/// Checkmark badge that pops in (for "equipped", "saved", "claimed" confirmations).
struct InlineCheckmark: View {
    @Binding var isVisible: Bool
    var color: Color = DarkFantasyTheme.success

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)

            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DarkFantasyTheme.textOnGold)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .allowsHitTesting(false)
        .onChange(of: isVisible) { _, visible in
            if visible {
                // Pop in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    scale = 1.0
                    opacity = 1.0
                }
                // Fade out after a beat
                withAnimation(.easeOut(duration: 0.3).delay(1.0)) {
                    opacity = 0
                }
                // Reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isVisible = false
                    scale = 0.3
                }
            }
        }
    }
}

// MARK: - View Modifiers for Convenience

/// Adds a floating feedback text above the view.
/// Usage: `.inlineFloat(text: "+120", color: .gold, isVisible: $showFloat)`
struct InlineFloatModifier: ViewModifier {
    let text: String
    let color: Color
    @Binding var isVisible: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                FloatingFeedbackText(text: text, color: color, isVisible: $isVisible)
                    .offset(y: -8)
            }
    }
}

/// Adds a flash border + optional checkmark overlay.
/// Usage: `.inlineFlash(color: .gold, isActive: $flash, showCheck: $check)`
struct InlineFlashModifier: ViewModifier {
    let color: Color
    @Binding var isActive: Bool
    @Binding var showCheck: Bool
    var cornerRadius: CGFloat = LayoutConstants.radiusLG

    func body(content: Content) -> some View {
        content
            .overlay {
                FlashBorder(color: color, isActive: $isActive, cornerRadius: cornerRadius)
            }
            .overlay(alignment: .topTrailing) {
                InlineCheckmark(isVisible: $showCheck, color: color)
                    .offset(x: -4, y: 4)
            }
    }
}

extension View {
    /// Floating text feedback ("+120 gold", "EQUIPPED", etc.)
    func inlineFloat(text: String, color: Color, isVisible: Binding<Bool>) -> some View {
        modifier(InlineFloatModifier(text: text, color: color, isVisible: isVisible))
    }

    /// Flash border + checkmark feedback for success confirmations
    func inlineFlash(color: Color, isActive: Binding<Bool>, showCheck: Binding<Bool>, cornerRadius: CGFloat = LayoutConstants.radiusLG) -> some View {
        modifier(InlineFlashModifier(color: color, isActive: isActive, showCheck: showCheck, cornerRadius: cornerRadius))
    }

    /// Simple flash border only (no checkmark)
    func flashBorder(color: Color, isActive: Binding<Bool>, cornerRadius: CGFloat = LayoutConstants.radiusLG) -> some View {
        overlay {
            FlashBorder(color: color, isActive: isActive, cornerRadius: cornerRadius)
        }
    }
}
