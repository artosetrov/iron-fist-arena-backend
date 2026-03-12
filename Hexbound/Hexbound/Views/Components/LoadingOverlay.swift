import SwiftUI

struct LoadingOverlay: View {
    var message: String = "LOADING"
    @State private var animatePulse = false

    var body: some View {
        ZStack {
            Color(hex: 0x0A0A14).opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer()

                // Pulsing logo
                Image("hexbound-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.5), radius: animatePulse ? 20 : 8)
                    .scaleEffect(animatePulse ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: animatePulse
                    )

                Text(message)
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.3), radius: 12)

                // Animated loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(DarkFantasyTheme.gold)
                            .frame(width: 8, height: 8)
                            .opacity(animatePulse ? 1 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.15),
                                value: animatePulse
                            )
                    }
                }

                Spacer()
            }
        }
        .onAppear { animatePulse = true }
        .onDisappear { animatePulse = false }
    }
}
