import SwiftUI

/// Blocking modal displayed when a 401 / session expired error occurs.
/// Uses the standard ornamental modal pattern — no dismiss gesture, single CTA.
struct SessionExpiredModalView: View {
    @Environment(AppState.self) private var appState

    @State private var showBackdrop = false
    @State private var showCard = false
    @State private var cardScale: CGFloat = MotionConstants.modalScaleFrom

    var body: some View {
        ZStack {
            // Backdrop — non-dismissable (no tap gesture)
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()
                .opacity(showBackdrop ? 1 : 0)

            // Modal card
            VStack(spacing: LayoutConstants.spaceLG) {
                // Lock icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DarkFantasyTheme.gold.opacity(0.15), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }

                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("Session Expired")
                        .font(DarkFantasyTheme.section(size: 20))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)

                    Text("Your session has ended.\nPlease log in again to continue.")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                // Gold CTA button
                Button {
                    HapticManager.medium()
                    appState.dismissSessionExpiredAndLogout()
                } label: {
                    Text("Log In")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody).bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(DarkFantasyTheme.goldGradient)
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                        .surfaceLighting(cornerRadius: LayoutConstants.buttonRadius)
                        .cornerBrackets(color: DarkFantasyTheme.goldBright.opacity(0.5), length: 10, thickness: 1.5)
                        .cornerDiamonds(color: DarkFantasyTheme.goldBright.opacity(0.4), size: 5)
                        .innerBorder(cornerRadius: LayoutConstants.buttonRadius - 2, inset: 2, color: DarkFantasyTheme.goldBright.opacity(0.3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log in again")
            }
            .padding(LayoutConstants.spaceLG)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .frame(width: 280)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: DarkFantasyTheme.gold.opacity(0.1))
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 18, thickness: 2.0)
            .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.4), size: 6)
            .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 10)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .scaleEffect(cardScale)
            .opacity(showCard ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: MotionConstants.overlayFade)) {
                showBackdrop = true
            }
            withAnimation(MotionConstants.dramatic.delay(0.1)) {
                showCard = true
                cardScale = 1.0
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}
