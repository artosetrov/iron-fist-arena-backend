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

// MARK: - Card

extension PurchaseRevealContent {
    /// The card's metal: the pack's own tier (its shop art is `…-tier1` … `…-tier5`),
    /// else what is in the box. Legendary shards make it at least gold.
    var cardTier: RewardCardTier {
        if let digit = artAsset.split(separator: "-").last.flatMap({ $0.hasPrefix("tier") ? Int($0.dropFirst(4)) : nil }),
           let tier = RewardCardTier(rawValue: digit) {
            return tier
        }
        let gold = rewards.filter { $0.kind == .gold }.reduce(0) { $0 + $1.quantity }
        let gems = rewards.filter { $0.kind == .gems }.reduce(0) { $0 + $1.quantity }
        let shards = rewards.contains { $0.kind == .legendaryShard }
        return RewardCardTier.best([RewardCardTier(gold: gold, gems: gems), shards ? .gold : nil])
    }

    /// The gem packs keep their own painted tier art; everything else shows
    /// the most valuable thing in the box, painted big.
    var cardArt: RewardCardArt {
        if artAsset.hasPrefix("shop-gems-tier") {
            return .object(artAsset, fill: 0.6)
        }
        let gold = rewards.filter { $0.kind == .gold }.reduce(0) { $0 + $1.quantity }
        let gems = rewards.filter { $0.kind == .gems }.reduce(0) { $0 + $1.quantity }
        return .headline(gold: gold, gems: gems, xp: 0, items: [], hasConsumables: false)
    }
}

// MARK: - Purchase Reward Reveal

/// Full-screen "purchase complete" ceremony, on a merchant reward card since
/// 2026-10-22 (`RewardCard`; metal = the pack's tier): the card lands with a
/// burst, then each reward counts up in turn, then CONTINUE. Owns its animation state, so
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

            RewardCardStage { width, artRatio in
                let metrics = RewardCardFrameMetrics.of(.merchant, content.cardTier)
                let artHeight = width * (1 - metrics.insetL - metrics.insetR) * artRatio
                RewardCard(
                    family: .merchant,
                    tier: content.cardTier,
                    art: content.cardArt,
                    width: width,
                    artRatio: artRatio,
                    header: { header(artHeight: artHeight) },
                    content: { cardContent },
                    actions: { continueButton }
                )
            }
            .opacity(showArt ? 1 : 0)
            .offset(y: showArt ? 0 : LayoutConstants.spaceMS)
        }
        .contentShape(Rectangle())
        .onTapGesture { skipToEnd() }
        .accessibilityAddTraits(.isModal)
        .task { await runCeremony() }
    }

    // MARK: - Pieces

    private func header(artHeight: CGFloat) -> some View {
        RewardCardTitle(title: "PURCHASE COMPLETE", subtitle: "Added to your account")
            .opacity(showTitle ? 1 : 0)
            .offset(y: showTitle ? 0 : LayoutConstants.spaceSM)
            .overlay(alignment: .top) {
                // Zero-size anchor at the middle of the card's illustration:
                // particles fly out from the art.
                RewardBurstView(style: content.burst, isActive: $burst, particleCount: content.particleCount)
                    .frame(width: 0, height: 0)
                    .offset(y: -(artHeight / 2) + RewardCardLayout.titleOverlap)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }

    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
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
        }
    }

    private var continueButton: some View {
        Button("CONTINUE", action: onDismiss)
            .buttonStyle(.primary)
            .opacity(showButton ? 1 : 0)
            .allowsHitTesting(showButton)
            .accessibilityHidden(!showButton)
    }

    /// One line per reward, counting up in turn. Every line is laid out from
    /// the start (and fades in), so the card keeps its height as they land.
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceXS)
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
