import SwiftUI

/// Victory-style modal shown after Gold Mine reward payouts.
/// Used for collect-all claims and slot-bonus minigame rewards.
struct MineClaimRewardView: View {
    let goldEarned: Int
    let gemsEarned: Int
    let onDismiss: () -> Void

    @State private var animatedGold: Int = 0
    @State private var animatedGems: Int = 0
    @State private var showContent = false
    @State private var showRewards = false
    @State private var showButton = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: LayoutConstants.spaceLG) {
                // Title
                if showContent {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Image("building-gold-mine")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 128, height: 128)
                            .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 12, y: 4)

                        Text("MINE HAUL")
                            .font(DarkFantasyTheme.title)
                            .foregroundStyle(DarkFantasyTheme.gold)
                            .tracking(3)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Rewards — single centered horizontal line (matches ClaimRewardModalView)
                if showRewards {
                    HStack(spacing: LayoutConstants.spaceLG) {
                        if goldEarned > 0 {
                            rewardItem(
                                icon: "shop-gold-tier1",
                                value: animatedGold,
                                color: DarkFantasyTheme.gold
                            )
                        }
                        if gemsEarned > 0 {
                            rewardItem(
                                icon: "icon-gem",
                                value: animatedGems,
                                color: DarkFantasyTheme.cyan
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                // Continue button
                if showButton {
                    Button(action: dismiss) {
                        Text("CONTINUE")
                            .font(DarkFantasyTheme.buttonLabel)
                            .foregroundStyle(DarkFantasyTheme.textOnGold)
                            .tracking(2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LayoutConstants.spaceMS)
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, LayoutConstants.spaceLG)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(LayoutConstants.spaceLG)
        }
        .onAppear { runEntryAnimation() }
    }

    private func rewardItem(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(icon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 32, height: 32)

            Text("+\(value)")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
        }
    }

    private func dismiss() {
        withAnimation(MotionConstants.snappy) {
            showContent = false
            showRewards = false
            showButton = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }

    private func runEntryAnimation() {
        HapticManager.success()
        SFXManager.shared.play(.uiRewardClaim)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showContent = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showRewards = true
            }
        }
        // Animate counters ticking up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: MotionConstants.tickUpLong)) {
                animatedGold = goldEarned
                animatedGems = gemsEarned
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }
}
