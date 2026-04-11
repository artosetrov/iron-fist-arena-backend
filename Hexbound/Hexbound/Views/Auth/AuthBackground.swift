import SwiftUI

/// Shared title-screen art background for auth flows (Welcome/Login/Register).
/// Use as the deepest layer inside an auth-screen ZStack, above `bgPrimary`.
struct AuthBackground: View {
    var body: some View {
        ZStack {
            // Base fill — guarantees opaque backdrop on any scale
            DarkFantasyTheme.bgPrimary
                .ignoresSafeArea()

            // Hero art — pinned to container size, never leading-anchored
            GeometryReader { geo in
                Image("bg-title")
                    .resizable()
                    .interpolation(.medium)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            // Darkening gradient — heavy top/bottom, lighter through the middle
            // so the logo/form stays legible on any hero art.
            LinearGradient(
                stops: [
                    .init(color: DarkFantasyTheme.bgPrimary.opacity(0.88), location: 0.0),
                    .init(color: DarkFantasyTheme.bgPrimary.opacity(0.70), location: 0.30),
                    .init(color: DarkFantasyTheme.bgPrimary.opacity(0.85), location: 0.55),
                    .init(color: DarkFantasyTheme.bgPrimary.opacity(1.00), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}
