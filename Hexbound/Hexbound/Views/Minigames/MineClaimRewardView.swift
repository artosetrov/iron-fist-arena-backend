import SwiftUI

/// Victory-style modal shown after collecting Gold Mine rewards.
/// Animates gold + gems earned with a satisfying counter tick-up.
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
                            .frame(width: 64, height: 64)
                            .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 12, y: 4)

                        Text("MINE HAUL")
                            .font(DarkFantasyTheme.title)
                            .foregroundStyle(DarkFantasyTheme.gold)
                            .tracking(3)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Reward rows
                if showRewards {
                    VStack(spacing: LayoutConstants.spaceMD) {
                        if goldEarned > 0 {
                            rewardRow(
                                icon: "shop-gold-tier1",
                                label: "Gold",
                                value: animatedGold,
                                color: DarkFantasyTheme.gold
                            )
                        }
                        if gemsEarned > 0 {
                            rewardRow(
                                icon: "icon-gem",
                                label: "Gems",
                                value: animatedGems,
                                color: DarkFantasyTheme.cyan
                            )
                        }
                    }
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
                    .buttonStyle(ButtonStyles.primary)
                    .padding(.horizontal, LayoutConstants.spaceLG)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(LayoutConstants.spaceLG)
        }
        .onAppear { runEntryAnimation() }
    }

    private func rewardRow(icon: String, label: String, value: Int, color: Color) -> some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            Image(icon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 36, height: 36)

            Text(label)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Spacer()

            Text("+\(value)")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(color)
                .contentTransition(.numericText(value: Double(value)))
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgCard.opacity(0.8))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
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
