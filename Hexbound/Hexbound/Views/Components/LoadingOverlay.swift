import SwiftUI

struct LoadingOverlay: View {
    var message: String = "LOADING"
    @State private var animatePulse = false

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer()

                // Pulsing logo with ornamental frame
                ZStack {
                    // Radial glow behind logo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DarkFantasyTheme.goldGlow,
                                    DarkFantasyTheme.goldBright.opacity(0.08),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .opacity(animatePulse ? 0.6 : 0.2)
                        .animation(
                            MotionConstants.pulse,
                            value: animatePulse
                        )

                    Image("preloader-hex")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                        .shadow(color: DarkFantasyTheme.goldBright.opacity(0.5), radius: animatePulse ? 20 : 8)
                        .animation(
                            MotionConstants.pulse,
                            value: animatePulse
                        )
                }

                Text(message)
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.3), radius: 12)

                // Ornamental loading bar
                HStack(spacing: 0) {
                    // Left line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, DarkFantasyTheme.goldDim],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40, height: 1)

                    // Animated loading dots with diamond style
                    HStack(spacing: LayoutConstants.spaceMS) {
                        ForEach(0..<3, id: \.self) { i in
                            Rectangle()
                                .fill(DarkFantasyTheme.gold)
                                .frame(width: 6, height: 6)
                                .rotationEffect(.degrees(45))
                                .shadow(color: DarkFantasyTheme.goldGlow, radius: animatePulse ? 4 : 0)
                                .opacity(animatePulse ? 1 : 0.3)
                                .animation(
                                    .easeInOut(duration: MotionConstants.tickUpDuration)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.15),
                                    value: animatePulse
                                )
                        }
                    }

                    // Right line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [DarkFantasyTheme.goldDim, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40, height: 1)
                }

                Spacer()
            }
        }
        .onAppear { animatePulse = true }
        .onDisappear { animatePulse = false }
    }
}
