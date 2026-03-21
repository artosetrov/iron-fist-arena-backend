import SwiftUI

struct LevelUpModalView: View {
    @Environment(AppState.self) private var appState
    @State private var appear = false
    @State private var glowPulse = false
    @State private var showDetails = false
    @State private var showBurst = false

    var body: some View {
        ZStack {
            // Backdrop
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()

            // Glow effect behind card
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DarkFantasyTheme.goldBright.opacity(0.3),
                            DarkFantasyTheme.gold.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .opacity(appear ? 1 : 0)

            // Card content
            VStack(spacing: 0) {
                Spacer()

                // Level up icon
                Text("\u{2694}\u{FE0F}")
                    .font(.system(size: LayoutConstants.textHero))
                    .padding(.bottom, LayoutConstants.spaceSM)

                // Title with burst
                ZStack {
                    if showBurst {
                        RewardBurstView(style: .levelUp, isActive: $showBurst)
                            .allowsHitTesting(false)
                    }
                    Text("LEVEL UP!")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textCinematic))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 12)
                }

                // New level
                Text("LEVEL \(appState.levelUpNewLevel)")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textCelebration))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .padding(.top, LayoutConstants.spaceSM)

                // Divider
                Rectangle()
                    .fill(DarkFantasyTheme.gold.opacity(0.4))
                    .frame(width: 120, height: 1.5)
                    .padding(.vertical, LayoutConstants.spaceMD)

                // Rewards section
                if showDetails {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        rewardRow(
                            icon: "\u{2B50}",
                            label: "Stat Points",
                            value: "+\(appState.levelUpStatPoints)"
                        )
                        rewardRow(
                            icon: "\u{1F4A0}",
                            label: "Passive Point",
                            value: "+1"
                        )
                    }
                    .padding(.horizontal, LayoutConstants.spaceLG * 2)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Continue button
                Button("CONTINUE") {
                    HapticManager.medium()
                    appState.dismissLevelUpModal()
                }
                .buttonStyle(.primary)
                .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.4, isActive: showDetails)
                .shimmer(color: DarkFantasyTheme.gold, duration: 3)
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceLG * 2)
            }
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(MotionConstants.dramatic) {
                appear = true
            }
            withAnimation(MotionConstants.glowLoop) {
                glowPulse = true
            }
            // Burst after card appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showBurst = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                showDetails = true
            }
        }
        .onDisappear {
            glowPulse = false
            appear = false
            showDetails = false
        }
    }

    @ViewBuilder
    private func rewardRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Text(icon)
                .font(.system(size: 22))

            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Spacer()

            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .padding(.vertical, LayoutConstants.spaceXS)
        .padding(.horizontal, LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
        )
    }
}
