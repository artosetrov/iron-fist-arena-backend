import SwiftUI

// MARK: - Treasure Reward Overlay
// Rich reward modal for dungeon rush treasure rooms.
// Features: scale bounce, count-up gold, coin particles, delayed continue button.

struct TreasureRewardOverlay: View {
    let gold: Int
    let buff: RushBuff?
    let buffAssetName: String?
    let onDismiss: () -> Void

    // MARK: - Animation State

    @State private var appeared = false
    @State private var modalScale: CGFloat = 0.7
    @State private var goldCount: Double = 0
    @State private var showBurst = false
    @State private var animationDone = false
    @State private var skipped = false

    private let animationDuration: Double = 0.8

    var body: some View {
        GameModal(
            accent: DarkFantasyTheme.gold,
            // A tap beside the chest means "skip the count-up" while the
            // animation runs, and only closes once it has finished — the
            // reward must be on screen before it can be dismissed.
            onBackdropTap: {
                if animationDone { onDismiss() } else { skipAnimation() }
            },
            // Same reason: no swiping the reward away before it has shown.
            dismissOnSwipeDown: animationDone,
            // The chest bounce is the reward beat, not a generic entrance, so
            // the frame scales with it.
            cardScale: modalScale,
            onDismiss: onDismiss
        ) {
            VStack(spacing: LayoutConstants.spaceLG) {
                // Chest image with particle burst
                ZStack {
                    Image("rush-ui-treasure-chest")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: DarkFantasyTheme.goldGlow, radius: 24)
                        .rewardBurst(isActive: $showBurst, style: .gold)
                }
                .accessibilityHidden(true)

                Text("TREASURE!")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                VStack(spacing: LayoutConstants.spaceSM) {
                    if gold > 0 {
                        // Large gold amount — matches or exceeds top gold counter size
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image("icon-gold")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                            Text("+\(Int(goldCount)) GOLD")
                                .font(DarkFantasyTheme.section)
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                                .monospacedDigit()
                                .contentTransition(.numericText(value: goldCount))
                        }
                    }

                    if let buff, let assetName = buffAssetName {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                            Text(buff.name)
                                .font(DarkFantasyTheme.body)
                                .foregroundStyle(DarkFantasyTheme.purple)
                        }
                    }
                }

                GoldDivider()

                // Continue button — appears after animation or tap-to-skip
                Button { onDismiss() } label: { Text("CONTINUE") }
                    .buttonStyle(.primary)
                    .accessibilityLabel("Continue")
                    .opacity(animationDone ? 1 : 0)
                    .animation(.easeIn(duration: 0.2), value: animationDone)
            }
        }
        .onAppear {
            guard !appeared else { return }
            appeared = true
            startEntrance()
        }
    }

    // MARK: - Animation Sequence

    private func startEntrance() {
        SFXManager.shared.play(.chestOpen)
        HapticManager.medium()

        // Phase 1: Scale bounce 0.7 → 1.2 → 1.0
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            modalScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                modalScale = 1.0
            }
        }

        // Phase 2: Coin burst particles (at 0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showBurst = true
            HapticManager.coinCascade(count: 5)
        }

        // Phase 3: Count-up gold from 0 → target (0.3s to 1.1s)
        if gold > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SFXManager.shared.play(.coinDrop)
                withAnimation(.easeOut(duration: animationDuration)) {
                    goldCount = Double(gold)
                }
            }
        }

        // Phase 4: Show continue button after animation completes
        let totalDuration = 0.3 + animationDuration + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            guard !skipped else { return }
            animationDone = true
        }
    }

    private func skipAnimation() {
        guard !animationDone else { return }
        skipped = true
        withAnimation(.easeOut(duration: 0.1)) {
            modalScale = 1.0
            goldCount = Double(gold)
        }
        animationDone = true
    }
}
