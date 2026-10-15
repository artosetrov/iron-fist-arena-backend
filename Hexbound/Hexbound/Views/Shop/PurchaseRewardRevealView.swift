import SwiftUI

// MARK: - Purchase Reveal Content

/// What a completed purchase granted, as `PurchaseRewardRevealView` shows it.
struct PurchaseRevealContent {
    let artAsset: String
    let accent: Color
    let burst: BurstStyle
    var particleCount: Int? = nil
    let rewards: [PackageReward]
    /// Extra line under the rewards — e.g. the Gem Card's daily payout.
    var note: String? = nil
}

extension PurchaseRevealContent {
    /// A gem pack or bundle: its tier art and everything in the box. Bigger
    /// purchases get a bigger burst.
    init(package: CurrencyPackage) {
        let burst: BurstStyle
        let particles: Int
        switch package.currencyType {
        case .gems:
            // Violet amethyst art → the purple/cyan epic burst.
            burst = .epic
            particles = min(MotionConstants.particlesLegendary, 12 + package.totalAmount / 250)
        case .gold:
            burst = package.amount > 3000 ? .legendary : .gold
            particles = min(MotionConstants.particlesLegendary, 20 + package.amount / 1000)
        }
        self.init(
            artAsset: package.artAsset,
            accent: package.currencyType.accentColor,
            burst: burst,
            particleCount: particles,
            rewards: package.rewards
        )
    }

    /// Monthly Gem Card: the instant gems now; the rest arrives with daily
    /// logins. `terms` are the card as it stood before this purchase — an
    /// active card is extended rather than restarted.
    static func monthlyGemCard(terms: IAPOffers.GemCard) -> PurchaseRevealContent {
        PurchaseRevealContent(
            artAsset: "icon-gems",
            accent: DarkFantasyTheme.cyan,
            burst: .rare,
            rewards: [.gems(terms.instantGems)],
            note: terms.active
                ? "\(terms.days) days added to your card — \(terms.daysRemaining + terms.days) days of +\(terms.dailyGems) gems ahead."
                : "Then +\(terms.dailyGems) gems each day you log in, for the next \(terms.days) days."
        )
    }
}

// MARK: - Purchase Reward Reveal

/// Full-screen "purchase complete" ceremony: the art lands with a burst, then
/// each reward counts up in turn, then CONTINUE. Owns its animation state, so
/// it lives in its own file (Hexbound/CLAUDE.md → Animated Overlays). Tap
/// anywhere to skip to the end; Reduce Motion shows the end state at once.
struct PurchaseRewardRevealView: View {
    let content: PurchaseRevealContent
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showArt = false
    @State private var showTitle = false
    @State private var visibleRows = 0
    @State private var shownAmounts: [Int]
    @State private var showButton = false
    @State private var burst = false
    @State private var skipped = false
    @State private var playedSound = false

    private let artSize: CGFloat = 128

    init(content: PurchaseRevealContent, onDismiss: @escaping () -> Void) {
        self.content = content
        self.onDismiss = onDismiss
        // Every amount starts at 0 so NumberTickUpText counts up to it.
        _shownAmounts = State(initialValue: Array(repeating: 0, count: content.rewards.count))
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer(minLength: LayoutConstants.spaceLG)

                artwork

                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("PURCHASE COMPLETE")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Added to your account")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : LayoutConstants.spaceSM)

                rewardList

                if let note = content.note {
                    Text(note)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(showButton ? 1 : 0)
                        .accessibilityHidden(!showButton)
                }

                Spacer(minLength: LayoutConstants.spaceLG)

                Button("CONTINUE", action: onDismiss)
                    .buttonStyle(.primary)
                    .opacity(showButton ? 1 : 0)
                    .allowsHitTesting(showButton)
                    .accessibilityHidden(!showButton)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
        .contentShape(Rectangle())
        .onTapGesture { skipToEnd() }
        .accessibilityAddTraits(.isModal)
        .task { await runCeremony() }
    }

    // MARK: - Pieces

    private var artwork: some View {
        ZStack {
            // Glow is code, not paint (docs/08_prompts/ART_STYLE_GUIDE.md).
            Circle()
                .fill(
                    RadialGradient(
                        colors: [content.accent.opacity(DarkFantasyTheme.opacityMedium), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: artSize * 0.8
                    )
                )
                .frame(width: artSize * 1.6, height: artSize * 1.6)
                .opacity(showArt ? 1 : 0)

            Image(content.artAsset)
                .resizable()
                .scaledToFit()
                .frame(width: artSize, height: artSize)
                .opacity(showArt ? 1 : 0)
                .offset(y: showArt ? 0 : LayoutConstants.spaceMS)

            // Zero-size anchor: particles fly out from the art's centre.
            RewardBurstView(style: content.burst, isActive: $burst, particleCount: content.particleCount)
                .frame(width: 0, height: 0)
        }
        .frame(height: artSize * 1.3)
        .accessibilityHidden(true)
    }

    private var rewardList: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
            ForEach(Array(content.rewards.enumerated()), id: \.element.id) { index, reward in
                let visible = index < visibleRows
                HStack(spacing: LayoutConstants.spaceMS) {
                    RewardIcon(reward: reward, size: LayoutConstants.iconXL)
                    HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceXS) {
                        NumberTickUpText(
                            value: shownAmounts[index],
                            color: reward.accent,
                            font: DarkFantasyTheme.section,
                            duration: MotionConstants.tickUpLong
                        )
                        Text(reward.noun)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    .lineLimit(1)
                }
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : LayoutConstants.spaceSM)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(reward.label)
                .accessibilityHidden(!visible)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, LayoutConstants.spaceLG)
        .padding(.vertical, LayoutConstants.spaceMD)
        .frame(maxWidth: .infinity)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: content.accent,
                glowIntensity: 0.10,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: content.accent.opacity(DarkFantasyTheme.opacityMild)
        )
        .cornerBrackets(color: content.accent.opacity(0.5), length: 14, thickness: 1.5)
        .compositingGroup()
        .opacity(showTitle ? 1 : 0)
    }

    // MARK: - Ceremony

    private func runCeremony() async {
        if reduceMotion {
            finish(animated: false)
            return
        }

        await pause(MotionConstants.ceremonyPhase1)
        guard proceed else { return }
        withAnimation(.easeOut(duration: MotionConstants.revealDuration)) { showArt = true }
        burst = true // RewardBurstView plays the haptic for its style
        playSound()

        await pause(MotionConstants.ceremonyPhase2 - MotionConstants.ceremonyPhase1)
        guard proceed else { return }
        withAnimation(.easeOut(duration: MotionConstants.revealDuration)) { showTitle = true }

        await pause(MotionConstants.ceremonyPhase3 - MotionConstants.ceremonyPhase2)
        for index in content.rewards.indices {
            guard proceed else { return }
            withAnimation(.easeOut(duration: MotionConstants.rewardItemFadeIn)) { visibleRows = index + 1 }
            shownAmounts[index] = content.rewards[index].quantity
            await pause(MotionConstants.rewardStaggerInterval)
        }

        guard proceed else { return }
        withAnimation(.easeOut(duration: MotionConstants.revealDuration)) { showButton = true }
    }

    private var proceed: Bool { !skipped && !Task.isCancelled }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    private func skipToEnd() {
        guard !showButton else { return }
        skipped = true
        finish(animated: true)
    }

    /// Jump to the final state: everything shown, every amount at its total.
    private func finish(animated: Bool) {
        playSound()
        let update = {
            showArt = true
            showTitle = true
            visibleRows = content.rewards.count
            showButton = true
        }
        if animated {
            withAnimation(.easeOut(duration: MotionConstants.fast), update)
        } else {
            update()
        }
        shownAmounts = content.rewards.map(\.quantity)
    }

    private func playSound() {
        guard !playedSound else { return }
        playedSound = true
        SFXManager.shared.play(.coinsJingle)
    }
}
