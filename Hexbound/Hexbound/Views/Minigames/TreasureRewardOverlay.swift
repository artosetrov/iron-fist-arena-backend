import SwiftUI

// MARK: - Treasure Reward Overlay
// Reward card for dungeon rush treasure rooms (a dungeon reward card since
// 2026-10-22, RewardCard.swift): the open chest in the treasure vault, the
// gold counting up, the buff, CONTINUE once the count has landed.
// Features: card bounce (the documented treasure-chest exception to the no-scale
// rule), coin burst, count-up gold, delayed continue button.

struct TreasureRewardOverlay: View {
    let gold: Int
    let buff: RushBuff?
    let buffAssetName: String?
    let onDismiss: () -> Void

    // MARK: - Animation State

    @State private var appeared = false
    @State private var cardScale: CGFloat = 0.85
    @State private var goldCount: Double = 0
    @State private var showBurst = false
    @State private var animationDone = false
    @State private var skipped = false
    @State private var dragOffset: CGFloat = 0

    private let animationDuration: Double = 0.8

    /// Past this many points a swipe down closes the card (as in `GameModal`).
    private static var dismissThreshold: CGFloat { 110 }

    // MARK: - Card

    /// The gold decides the metal; a buff makes it at least silver.
    private var tier: RewardCardTier {
        RewardCardTier.best([RewardCardTier(gold: gold), buff == nil ? nil : .silver])
    }

    /// The chest that fits the haul: wood for small change, iron, then gold.
    private var chestAsset: String {
        switch tier {
        case .iron, .bronze: "rush2-chest-wood-open"
        case .silver: "rush2-chest-iron-open"
        case .gold, .mythic: "rush2-chest-gold-open"
        }
    }

    private var art: RewardCardArt {
        var art = RewardCardArt.object(chestAsset, fill: 0.78)
        art.backdrop = "bg-rush-treasure"
        return art
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .contentShape(Rectangle())
                // A tap beside the card means "skip the count-up" while the
                // animation runs, and only closes once it has finished — the
                // reward must be on screen before it can be dismissed.
                .onTapGesture {
                    if animationDone { onDismiss() } else { skipAnimation() }
                }
                .accessibilityHidden(true)

            RewardCardStage { width, artRatio in
                RewardCard(
                    family: .dungeon,
                    tier: tier,
                    art: art,
                    width: width,
                    artRatio: artRatio,
                    header: {
                        // The burst rises from the foot of the chest.
                        RewardCardTitle(title: "TREASURE!")
                            .rewardBurst(isActive: $showBurst, style: .gold)
                    },
                    content: { rewards },
                    actions: { continueButton }
                )
            }
            // The chest bounce is the reward beat, not a generic entrance, so
            // the card bounces with it (the documented treasure exception).
            .scaleEffect(cardScale)
            .offset(y: dragOffset)
            // Same reason as the backdrop: no swiping the reward away before it
            // has shown.
            .gesture(dragGesture, including: animationDone ? .all : .subviews)
        }
        .transition(.opacity)
        .onAppear {
            guard !appeared else { return }
            appeared = true
            startEntrance()
        }
    }

    // MARK: - Pieces

    private var rewards: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if gold > 0 {
                RewardCardRow(icon: "icon-gold", value: "+\(Int(goldCount))", label: "Gold")
            }

            if let buff, let assetName = buffAssetName {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                        .accessibilityHidden(true)
                    Text(buff.name)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.purple)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    // Continue button — appears after animation or tap-to-skip
    private var continueButton: some View {
        Button { onDismiss() } label: {
            Text("CONTINUE")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .accessibilityLabel("Continue")
        .opacity(animationDone ? 1 : 0)
        .allowsHitTesting(animationDone)
        .animation(.easeIn(duration: 0.2), value: animationDone)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height > Self.dismissThreshold {
                    onDismiss()
                }
                withAnimation(MotionConstants.spring) { dragOffset = 0 }
            }
    }

    // MARK: - Animation Sequence

    private func startEntrance() {
        SFXManager.shared.play(.chestOpen)
        HapticManager.medium()

        // Phase 1: bounce in. Gentler than the old 0.7 → 1.2 → 1.0 of the
        // small modal: the card is three times its size.
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            cardScale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                cardScale = 1.0
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
            cardScale = 1.0
            goldCount = Double(gold)
        }
        animationDone = true
    }
}
