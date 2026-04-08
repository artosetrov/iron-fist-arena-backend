import SwiftUI

struct LoadingOverlay: View {
    var message: String = "LOADING"

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

                    Image("preloader-hex")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                }

                // Unified hex pulse loader with text + ornamental dots
                HexPulseLoader(.large, message: message)

                Spacer()
            }
        }
    }
}
