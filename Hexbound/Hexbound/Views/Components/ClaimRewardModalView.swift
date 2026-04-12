import SwiftUI

// MARK: - Claim Reward Modal
//
// Universal reward ceremony for ALL claim actions across the game:
//   • Shop contraband, special offers
//   • Daily login, daily quests (individual + bonus)
//   • Achievements, battle pass nodes
//
// Visual language mirrors BattleResultCardView (dimmed backdrop, spinning rays,
// title slam, tick-up counters, loot cards, shimmer CTA) but is simpler —
// no victory/defeat split, no XP bar, no rating, no stars.
//
// Usage:
//   .claimRewardModal(config: $vm.claimRewardConfig)
//
// Set `claimRewardConfig` to a non-nil value to present; the modal
// auto-dismisses when the user taps CONTINUE.

struct ClaimRewardConfig: Equatable {
    let title: String            // e.g. "REWARD CLAIMED!"
    let subtitle: String?        // e.g. "Contraband Drop #3"

    // Rewards — show counters for non-zero values
    let goldReward: Int
    let gemsReward: Int
    let xpReward: Int

    // Loot items / consumables (optional)
    let lootItems: [ClaimLootItem]

    // Dismiss callback (called when CONTINUE tapped)
    // Not part of Equatable — always treated as equal
    var onDismiss: (() -> Void)?

    static func == (lhs: ClaimRewardConfig, rhs: ClaimRewardConfig) -> Bool {
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.goldReward == rhs.goldReward &&
        lhs.gemsReward == rhs.gemsReward &&
        lhs.xpReward == rhs.xpReward &&
        lhs.lootItems == rhs.lootItems
    }
}

struct ClaimLootItem: Equatable, Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let imageKey: String?
    let fallbackIcon: String
    let rarity: ItemRarity
    let rarityColor: Color

    static func == (lhs: ClaimLootItem, rhs: ClaimLootItem) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.quantity == rhs.quantity
    }
}

// MARK: - View

struct ClaimRewardModalView: View {

    let config: ClaimRewardConfig
    let onDismiss: () -> Void

    // MARK: Animation State

    @State private var showCard = false
    @State private var showTitle = false
    @State private var showRewards = false
    @State private var showLoot = false
    @State private var showButton = false
    @State private var titleGlowPulse = false
    @State private var screenFlashOpacity: Double = 0
    @State private var showRewardBurst = false

    // Tick-up counters
    @State private var goldDisplay = 0
    @State private var gemsDisplay = 0
    @State private var xpDisplay = 0

    private let accentColor = DarkFantasyTheme.goldBright

    var body: some View {
        ZStack {
            // Dimmed background
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture { } // absorb taps

            // Particles
            VictoryParticlesView(isVictory: true, particleCount: 25)
                .ignoresSafeArea()

            // Screen flash
            accentColor
                .ignoresSafeArea()
                .opacity(screenFlashOpacity)
                .allowsHitTesting(false)

            // Reward burst
            GeometryReader { geo in
                RewardBurstView(
                    style: .victory,
                    isActive: $showRewardBurst
                )
                .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Radial glow
            RadialGradient(
                colors: [
                    accentColor.opacity(0.2),
                    accentColor.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            .opacity(showCard ? 1 : 0)

            // Spinning rays
            SpinningRaysView()
                .ignoresSafeArea()
                .opacity(showCard ? 0.7 : 0)
                .animation(.easeIn(duration: 0.6), value: showCard)
                .allowsHitTesting(false)

            // Main card
            ScrollView(.vertical, showsIndicators: false) {
                cardContent
            }
            .scrollBounceBehavior(.basedOnSize)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.modalRadius))
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgPrimary,
                    glowColor: DarkFantasyTheme.bgSecondary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: accentColor.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(accentColor.opacity(0.5), lineWidth: 2)
            )
            .cornerBrackets(color: accentColor.opacity(0.4), length: 18, thickness: 2.0)
            .cornerDiamonds(color: accentColor.opacity(0.5), size: 6)
            .shadow(color: accentColor.opacity(0.3), radius: 20, y: 4)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 12, y: 6)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.78)
            .opacity(showCard ? 1 : 0)
        }
        .onAppear {
            runCeremony()
        }
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceSM) {

            // Title
            Text(config.title)
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(accentColor)
                .shadow(
                    color: accentColor.opacity(titleGlowPulse ? 0.6 : 0.2),
                    radius: titleGlowPulse ? 20 : 8
                )
                .opacity(showTitle ? 1 : 0)
                .padding(.top, LayoutConstants.spaceLG)

            // Subtitle
            if let subtitle = config.subtitle {
                Text(subtitle)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .opacity(showTitle ? 1 : 0)
            }

            // Divider
            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)
                .opacity(showRewards ? 1 : 0)

            // Rewards counters
            if hasRewards {
                rewardsSection
                    .opacity(showRewards ? 1 : 0)
                    .offset(y: showRewards ? 0 : 10)
            }

            // Loot cards
            if !config.lootItems.isEmpty {
                lootSection
                    .opacity(showLoot ? 1 : 0)
            }

            // Continue button
            Button {
                HapticManager.medium()
                SFXManager.shared.play(.uiConfirm)
                onDismiss()
            } label: {
                Text("CONTINUE")
                    .font(DarkFantasyTheme.buttonLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .frame(height: 50)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 15)
            .shimmer(color: DarkFantasyTheme.goldBright, duration: 2.5)
            .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.5, isActive: showButton)

            Spacer().frame(height: LayoutConstants.spaceMD)
        }
    }

    // MARK: - Rewards

    private var hasRewards: Bool {
        config.goldReward > 0 || config.gemsReward > 0 || config.xpReward > 0
    }

    @ViewBuilder
    private var rewardsSection: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            if config.goldReward > 0 {
                rewardRow(
                    iconImage: "icon-gold",
                    value: goldDisplay,
                    color: DarkFantasyTheme.goldBright
                )
            }

            if config.gemsReward > 0 {
                rewardRow(
                    iconImage: "icon-gems",
                    value: gemsDisplay,
                    color: DarkFantasyTheme.purple
                )
            }

            if config.xpReward > 0 {
                rewardRow(
                    iconImage: "reward-xp",
                    value: xpDisplay,
                    color: DarkFantasyTheme.xpRing
                )
            }
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceLG)
    }

    @ViewBuilder
    private func rewardRow(iconImage: String, value: Int, color: Color) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(iconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)

            Text("+\(value)")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loot

    @ViewBuilder
    private var lootSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("LOOT")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            // Grid of loot items — uses standard ItemCardView, same as shop/inventory
            let columns = Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.shopGap), count: min(config.lootItems.count, 3))
            LazyVGrid(columns: columns, spacing: LayoutConstants.shopGap) {
                ForEach(config.lootItems) { item in
                    lootItemCard(item)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.cardPadding)
    }

    @ViewBuilder
    private func lootItemCard(_ item: ClaimLootItem) -> some View {
        let label = item.quantity > 1 ? "×\(item.quantity)" : item.name
        ItemCardView(
            rarity: item.rarity,
            imageKey: item.imageKey,
            imageUrl: nil,
            fallbackIcon: item.fallbackIcon,
            context: .offerReward(label: label),
            onTap: {}
        )
        .allowsHitTesting(false)
    }

    // MARK: - Ceremony

    private func runCeremony() {
        // 0.0s — Screen flash + card appears
        screenFlashOpacity = 0.35
        withAnimation(.easeOut(duration: MotionConstants.fast)) {
            screenFlashOpacity = 0
        }
        withAnimation(MotionConstants.dramatic) {
            showCard = true
        }

        // 0.25s — Title slam
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.fast) {
            HapticManager.heavy()
            SFXManager.shared.play(.uiRewardClaim)
            withAnimation(MotionConstants.springBouncy) {
                showTitle = true
            }
        }

        // 0.4s — Reward burst
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.normal) {
            showRewardBurst = true
            HapticManager.victory()
        }

        // 0.6s — Title glow pulsing
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.reward) {
            withAnimation(MotionConstants.pulse) {
                titleGlowPulse = true
            }
        }

        // 0.8s — Rewards appear + tick-up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: MotionConstants.fast)) {
                showRewards = true
            }
            rollUp(to: config.goldReward, binding: $goldDisplay, duration: MotionConstants.tickUpDuration)
            rollUp(to: config.gemsReward, binding: $gemsDisplay, duration: MotionConstants.tickUpDuration)
            rollUp(to: config.xpReward, binding: $xpDisplay, duration: MotionConstants.tickUpDuration)
        }

        // 1.4s — Loot section
        let lootTime: Double = 1.4
        if !config.lootItems.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + lootTime) {
                withAnimation(.easeOut(duration: MotionConstants.fast)) {
                    showLoot = true
                }
                HapticManager.medium()
                SFXManager.shared.play(.itemDrop)
            }
        }

        // 1.8s (or 1.4s if no loot) — Continue button
        let buttonTime = config.lootItems.isEmpty ? 1.2 : lootTime + 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + buttonTime) {
            withAnimation(.easeOut(duration: MotionConstants.fast)) {
                showButton = true
            }
        }
    }

    // MARK: - Tick-Up Helper

    private func rollUp(to target: Int, binding: Binding<Int>, duration: Double) {
        guard target > 0 else { return }
        let steps = 12
        let stepDuration = duration / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.linear(duration: stepDuration)) {
                    binding.wrappedValue = Int(Double(target) * Double(i) / Double(steps))
                }
                if i == steps { HapticManager.light() }
            }
        }
    }
}

// MARK: - View Modifier for easy presentation

extension View {
    /// Present a claim reward modal over the current view.
    /// Set `config` to non-nil to show; set to nil to dismiss.
    func claimRewardModal(config: Binding<ClaimRewardConfig?>) -> some View {
        self.overlay {
            if let cfg = config.wrappedValue {
                ClaimRewardModalView(config: cfg) {
                    cfg.onDismiss?()
                    config.wrappedValue = nil
                }
                .transition(.opacity)
                .animation(MotionConstants.snappy, value: config.wrappedValue != nil)
                .zIndex(999)
            }
        }
    }
}

// MARK: - Convenience builders from OfferContent

extension ClaimRewardConfig {
    /// Build config from an array of OfferContent (used by shop contraband & special offers).
    static func fromOfferContents(
        title: String,
        subtitle: String? = nil,
        contents: [OfferContent],
        onDismiss: (() -> Void)? = nil
    ) -> ClaimRewardConfig {
        var gold = 0, gems = 0, xp = 0
        var loot: [ClaimLootItem] = []

        for content in contents {
            switch content.type {
            case "gold":
                gold += content.quantity
            case "gems":
                gems += content.quantity
            case "xp":
                xp += content.quantity
            case "consumable":
                loot.append(ClaimLootItem(
                    id: content.id ?? UUID().uuidString,
                    name: Self.consumableName(content.id),
                    quantity: content.quantity,
                    imageKey: content.id,
                    fallbackIcon: "cross.vial",
                    rarity: .uncommon,
                    rarityColor: DarkFantasyTheme.rarityUncommon
                ))
            case "item":
                loot.append(ClaimLootItem(
                    id: content.id ?? UUID().uuidString,
                    name: content.id ?? "Item",
                    quantity: content.quantity,
                    imageKey: content.id,
                    fallbackIcon: "shippingbox",
                    rarity: .rare,
                    rarityColor: DarkFantasyTheme.rarityRare
                ))
            default:
                break
            }
        }

        return ClaimRewardConfig(
            title: title,
            subtitle: subtitle,
            goldReward: gold,
            gemsReward: gems,
            xpReward: xp,
            lootItems: loot,
            onDismiss: onDismiss
        )
    }

    private static func consumableName(_ id: String?) -> String {
        guard let id else { return "Potion" }
        return id
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
