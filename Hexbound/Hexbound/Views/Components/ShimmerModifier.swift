import SwiftUI

/// Subtle horizontal shimmer effect for premium/featured cards.
/// Usage: `.shimmer()` for gold, `.shimmer(color: .cyan)` for gems.
struct ShimmerModifier: ViewModifier {
    let color: Color
    let duration: Double
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, color.opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width)
                    .offset(x: phase * geo.size.width)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Add a shimmer sweep effect. Default: gold color, 4s cycle.
    func shimmer(
        color: Color = DarkFantasyTheme.gold,
        duration: Double = 4
    ) -> some View {
        modifier(ShimmerModifier(color: color, duration: duration))
    }
}
