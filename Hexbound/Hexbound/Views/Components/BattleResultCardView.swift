import SwiftUI

/// Unified compact card overlay for victory / defeat / loot results.
///
/// Used by:  CombatResultDetailView, DungeonVictoryView, LootDetailView
/// Follows the "card on dimmed background" pattern with:
///  • Screen flash (gold=victory, red=defeat) (Motion Audit §2.12)
///  • Dramatic title slam (scale 2.5→1.0 with bounce)
///  • RewardBurstView particle explosion on victory
///  • Pulsing title glow (victory=gold, defeat=red)
///  • Staggered reward counters with tick-up
///  • Inline loot cards (scale-in with per-item haptics)
///  • Shake + haptic on defeat
///  • FIGHT AGAIN: gold glowPulse + shimmer (victory) / red glowPulse (defeat)
///  • HapticManager integration throughout ceremony
struct BattleResultCardView: View {

    // MARK: - Config

    let config: BattleResultConfig

    // MARK: - Animation State

    @State private var showCard = false
    @State private var showTitle = false
    @State private var showRewards = false
    @State private var showLoot = false
    @State private var showButtons = false
    @State private var titleGlowPulse = false
    @State private var shakeOffset: CGFloat = 0
    @State private var revealedLootIndices: Set<Int> = []

    // Ceremony enhancements (Motion Audit §2.12, §3.8)
    @State private var screenFlashOpacity: Double = 0
    @State private var titleScale: CGFloat = MotionConstants.vsScaleFrom // 2.5 → 1.0 slam
    @State private var showRewardBurst = false

    // Reward counter roll-ups
    @State private var goldDisplay = 0
    @State private var xpDisplay = 0

    var body: some View {
        ZStack {
            // Dimmed background
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture { } // absorb taps

            // Particles behind card
            VictoryParticlesView(
                isVictory: config.isVictory,
                particleCount: config.isVictory ? 35 : 15
            )
            .ignoresSafeArea()

            // Screen flash overlay (gold on victory, red on defeat)
            accentColor
                .ignoresSafeArea()
                .opacity(screenFlashOpacity)
                .allowsHitTesting(false)

            // Reward burst particles (victory only)
            if config.isVictory {
                GeometryReader { geo in
                    RewardBurstView(
                        style: .victory,
                        isActive: $showRewardBurst
                    )
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Color glow behind card
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

            // Spinning rays behind card
            SpinningRaysView()
                .ignoresSafeArea()
                .opacity(showCard ? 0.7 : 0)
                .animation(.easeIn(duration: 0.6), value: showCard)
                .allowsHitTesting(false)

            // Main card
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: LayoutConstants.space2XL)

                    cardContent
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                                .fill(DarkFantasyTheme.bgSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                                .stroke(accentColor.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: accentColor.opacity(0.3), radius: 20, y: 4)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .offset(x: shakeOffset)
                        .opacity(showCard ? 1 : 0)

                    Spacer(minLength: LayoutConstants.spaceLG)
                }
            }
        }
        .onAppear {
            runAnimationSequence()
        }
    }

    // MARK: - Accent Color

    private var accentColor: Color {
        config.isVictory ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceMD) {

            // Result illustration
            if let imageName = config.illustrationImage {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, LayoutConstants.spaceLG)
            } else {
                // SF Symbol fallback
                Image(systemName: config.isVictory ? "shield.checkered" : "flame.fill")
                    .font(DarkFantasyTheme.title(size: 48))
                    .foregroundStyle(accentColor)
                    .padding(.top, LayoutConstants.spaceLG)
            }

            // Title
            titleView
                .padding(.bottom, LayoutConstants.spaceXS)

            // Subtitle (near-miss motivation or general)
            if let subtitle = config.subtitle {
                Text(subtitle)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(!config.isVictory ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                    .opacity(showTitle ? 1 : 0)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // First Win Bonus
            if config.firstWinBonus {
                firstWinBadge
                    .opacity(showRewards ? 1 : 0)
            }

            // Divider
            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)
                .opacity(showRewards ? 1 : 0)

            // Rewards section
            if hasRewards {
                rewardsSection
                    .opacity(showRewards ? 1 : 0)
                    .offset(y: showRewards ? 0 : 10)
            }

            // XP Bar (optional)
            if let xpBarConfig = config.xpBarConfig {
                xpBarView(xpBarConfig)
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .opacity(showRewards ? 1 : 0)
            }

            // Dungeon Progress (optional)
            if let dungeonProgress = config.dungeonProgress {
                dungeonProgressBar(dungeonProgress)
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .opacity(showRewards ? 1 : 0)
            }

            // Loot section
            if !config.lootItems.isEmpty {
                lootSection
                    .opacity(showLoot ? 1 : 0)
            }

            // Buttons inside card
            buttonsSection
                .padding(.top, LayoutConstants.spaceMD)
                .padding(.horizontal, LayoutConstants.cardPadding)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 15)

            Spacer().frame(height: LayoutConstants.spaceLG)
        }
    }

    // MARK: - Title

    @ViewBuilder
    private var titleView: some View {
        Text(config.title)
            .font(DarkFantasyTheme.title(size: LayoutConstants.textCinematic))
            .foregroundStyle(accentColor)
            .shadow(
                color: accentColor.opacity(titleGlowPulse ? 0.6 : 0.2),
                radius: titleGlowPulse ? 20 : 8
            )
            .opacity(showTitle ? 1 : 0)
    }

    // MARK: - First Win Badge

    @ViewBuilder
    private var firstWinBadge: some View {
        HStack(spacing: 8) {
            Image("reward-first-win")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            Text("FIRST WIN BONUS x2!")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, 6)
        .background(DarkFantasyTheme.goldBright.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DarkFantasyTheme.goldBright.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Rewards

    private var hasRewards: Bool {
        (config.goldReward ?? 0) > 0 || (config.xpReward ?? 0) > 0 || config.ratingChange != nil
    }

    @ViewBuilder
    private var rewardsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("REWARDS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            HStack(spacing: 0) {
                if let gold = config.goldReward, gold > 0 {
                    rewardCounter(
                        iconImage: "reward-gold",
                        value: "+\(goldDisplay)",
                        label: "Gold",
                        color: DarkFantasyTheme.goldBright
                    )
                }

                if let xp = config.xpReward, xp > 0 {
                    rewardCounter(
                        iconImage: "reward-xp",
                        value: "+\(xpDisplay)",
                        label: "XP",
                        color: DarkFantasyTheme.purple
                    )
                }

                if let change = config.ratingChange, change != 0 {
                    rewardCounter(
                        iconImage: change > 0 ? "reward-rating-up" : "reward-rating-down",
                        value: change > 0 ? "+\(change)" : "\(change)",
                        label: "Rating",
                        color: change > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger
                    )
                }
            }
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceMD)
    }

    @ViewBuilder
    private func rewardCounter(iconImage: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(iconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - XP Bar

    @ViewBuilder
    private func xpBarView(_ xpConfig: XPBarConfig) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("Level \(xpConfig.displayLevel)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.purple)

                Spacer()

                if xpConfig.leveledUp {
                    HStack(spacing: 4) {
                        Image("reward-level-up")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("LEVEL UP!")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .shadow(color: DarkFantasyTheme.goldBright.opacity(0.6), radius: 8)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 5)
                        .fill(DarkFantasyTheme.xpGradient)
                        .frame(width: geo.size.width * min(xpConfig.progress, 1.0))
                }
            }
            .frame(height: 10)
        }
        .padding(.top, LayoutConstants.spaceSM)
    }

    // MARK: - Dungeon Progress

    @ViewBuilder
    private func dungeonProgressBar(_ progress: DungeonProgressConfig) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("Dungeon Progress")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Spacer()
                Text("\(progress.defeated) / \(progress.total)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(
                        progress.isComplete
                            ? DarkFantasyTheme.success
                            : DarkFantasyTheme.textSecondary
                    )
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            progress.isComplete
                                ? DarkFantasyTheme.canonicalHpGradient(percentage: 1.0)
                                : DarkFantasyTheme.progressGradient
                        )
                        .frame(width: geo.size.width * progress.fraction)
                        .animation(.easeOut(duration: 0.8), value: progress.defeated)
                }
            }
            .frame(height: 8)

            if progress.isComplete {
                Text("DUNGEON CLEARED!")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .padding(.top, LayoutConstants.spaceXS)
            }
        }
        .padding(.top, LayoutConstants.spaceSM)
    }

    // MARK: - Loot Section

    @ViewBuilder
    private var lootSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)

            Text("LOOT")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.spaceMD) {
                    ForEach(Array(config.lootItems.enumerated()), id: \.offset) { index, item in
                        inlineLootCard(item, index: index)
                            .onTapGesture {
                                config.onLootTap?(index)
                            }
                    }
                }
                .padding(.horizontal, LayoutConstants.cardPadding)
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func inlineLootCard(_ item: LootItemDisplay, index: Int) -> some View {
        let isRevealed = revealedLootIndices.contains(index)
        let rarityColor = item.rarityColor

        VStack(spacing: LayoutConstants.spaceXS) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgTertiary)

                if let imageKey = item.imageKey {
                    ItemImageView(
                        imageKey: imageKey,
                        imageUrl: item.imageUrl,
                        systemIcon: item.sfIcon,
                        systemIconColor: item.sfColor,
                        fallbackIcon: item.fallbackIcon
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if let sfIcon = item.sfIcon {
                    Image(systemName: sfIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(item.sfColor ?? rarityColor)
                } else {
                    Text(item.fallbackIcon)
                        .font(.system(size: 28))
                }
            }
            .frame(width: 72, height: 72)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(rarityColor, lineWidth: 2)
            )
            .shadow(color: rarityColor.opacity(0.4), radius: 8)

            Text(item.name)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .textCase(.uppercase)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .frame(width: 80)

            Text(item.rarityName)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(rarityColor)
        }
        .opacity(isRevealed ? 1.0 : 0.0)
        // Epic+ items get ambient glow pulse after reveal
        .glowPulse(color: rarityColor, intensity: item.rarityTier >= 3 ? 0.5 : 0, isActive: isRevealed && item.rarityTier >= 3)
    }

    // MARK: - Buttons

    @ViewBuilder
    private var buttonsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(config.buttons.enumerated()), id: \.offset) { index, button in
                resultButton(button, index: index)
            }
        }
    }

    @ViewBuilder
    private func resultButton(_ button: ResultButton, index: Int) -> some View {
        if button.style == .primary && config.isVictory {
            buttonLabel(button)
                .buttonStyle(resolveButtonStyle(button.style))
                .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.5, isActive: showButtons)
                .shimmer(color: DarkFantasyTheme.gold, duration: 3)
        } else if button.style == .primary && !config.isVictory {
            buttonLabel(button)
                .buttonStyle(resolveButtonStyle(button.style))
                .glowPulse(color: DarkFantasyTheme.danger, intensity: 0.4, isActive: showButtons)
        } else {
            buttonLabel(button)
                .buttonStyle(resolveButtonStyle(button.style))
        }
    }

    private func buttonLabel(_ button: ResultButton) -> some View {
        Button {
            HapticManager.medium()
            button.action()
        } label: {
            if let icon = button.icon {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                    Text(button.title)
                }
            } else {
                Text(button.title)
            }
        }
    }

    private func resolveButtonStyle(_ style: ResultButtonStyle) -> some ButtonStyle {
        switch style {
        case .primary: return AnyButtonStyle(PrimaryButtonStyle())
        case .secondary: return AnyButtonStyle(SecondaryButtonStyle())
        case .ghost: return AnyButtonStyle(GhostButtonStyle())
        }
    }

    // MARK: - Animation Sequence (Motion Audit §2.12)
    // Victory: flash gold → title slam (2.5→1.0) → particles → reward burst → counters → loot → CTAs
    // Defeat:  flash red → title fade → shake + haptic → counters → CTAs (red glow)

    private func runAnimationSequence() {
        // ── 0.0s — Screen flash + card scales in ──
        screenFlashOpacity = config.isVictory ? 0.4 : 0.25
        withAnimation(.easeOut(duration: MotionConstants.fast)) {
            screenFlashOpacity = 0
        }
        withAnimation(MotionConstants.dramatic) {
            showCard = true
        }

        // ── 0.25s — Title SLAMS in (scale 2.5→1.0 with bounce) ──
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.fast) {
            if config.isVictory {
                HapticManager.heavy()
            } else {
                HapticManager.defeat()
            }
            withAnimation(MotionConstants.springBouncy) {
                showTitle = true
            }
        }

        // ── 0.4s — Defeat shake / Victory burst ──
        if config.isVictory {
            DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.normal) {
                showRewardBurst = true
                HapticManager.victory()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.normal) {
                shakeSequence()
                HapticManager.shake()
            }
        }

        // ── 0.6s — Title glow pulsing begins ──
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.reward) {
            withAnimation(MotionConstants.pulse) {
                titleGlowPulse = true
            }
        }

        // ── 0.8s — Rewards appear + counters tick up ──
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: MotionConstants.fast)) {
                showRewards = true
            }
            rollUp(to: config.goldReward ?? 0, binding: $goldDisplay, duration: MotionConstants.tickUpDuration)
            rollUp(to: config.xpReward ?? 0, binding: $xpDisplay, duration: MotionConstants.tickUpDuration)
        }

        // ── 1.4s — Loot section with RARITY-BASED reveal (Audit §7 #11) ──
        if !config.lootItems.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeOut(duration: MotionConstants.fast)) {
                    showLoot = true
                }
                // Calculate cumulative delay based on rarity tiers
                var cumulativeDelay: Double = 0
                for i in config.lootItems.indices {
                    let tier = config.lootItems[i].rarityTier
                    let itemDelay = cumulativeDelay
                    cumulativeDelay += rarityRevealDelay(tier: tier)

                    DispatchQueue.main.asyncAfter(deadline: .now() + itemDelay) {
                        // Epic/Legendary: anticipation pause (dim + glow)
                        if tier >= 3 {
                            HapticManager.medium()
                        }
                    }

                    // Reveal the item
                    let revealTime = tier >= 3 ? itemDelay + MotionConstants.anticipationDuration : itemDelay
                    DispatchQueue.main.asyncAfter(deadline: .now() + revealTime) {
                        let animation: Animation = tier >= 3
                            ? MotionConstants.springBouncy
                            : tier >= 2 ? MotionConstants.spring : MotionConstants.snappy
                        withAnimation(animation) {
                            _ = revealedLootIndices.insert(i)
                        }
                        // Rarity-scaled haptic
                        switch tier {
                        case 4: HapticManager.legendaryReveal()
                        case 3: HapticManager.heavy()
                        case 2: HapticManager.medium()
                        default: HapticManager.light()
                        }
                    }
                }
            }
        }

        // ── Buttons appear last ──
        let lootTotalDelay = config.lootItems.reduce(0.0) { acc, item in acc + rarityRevealDelay(tier: item.rarityTier) }
        let buttonDelay = config.lootItems.isEmpty ? 1.4 : 1.4 + lootTotalDelay + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
            withAnimation(.easeOut(duration: MotionConstants.fast)) {
                showButtons = true
            }
        }
    }

    // MARK: - Shake Effect (defeat)

    private func shakeSequence() {
        let offsets: [CGFloat] = [12, -10, 8, -6, 4, -2, 0]
        for (i, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }

    // MARK: - Rarity Reveal Timing

    /// Per-item delay based on rarity tier (Audit §3.5)
    private func rarityRevealDelay(tier: Int) -> Double {
        switch tier {
        case 0: return 0.12      // common — instant pop
        case 1: return 0.18      // uncommon — quick
        case 2: return 0.28      // rare — noticeable pause
        case 3: return 0.45      // epic — anticipation + reveal
        default: return 0.65     // legendary — full ceremony
        }
    }

    // MARK: - Counter Roll-Up

    private func rollUp(to target: Int, binding: Binding<Int>, duration: Double) {
        guard target > 0 else { return }
        let steps = 20
        let interval = duration / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.none) {
                    binding.wrappedValue = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Configuration Types

struct BattleResultConfig {
    // Core
    let isVictory: Bool
    let title: String
    let subtitle: String?
    let illustrationImage: String?

    // Rewards
    let goldReward: Int?
    let xpReward: Int?
    let ratingChange: Int?
    let firstWinBonus: Bool

    // XP bar (optional — arena/pvp show this)
    let xpBarConfig: XPBarConfig?

    // Dungeon progress (optional — dungeon shows this)
    let dungeonProgress: DungeonProgressConfig?

    // Loot
    let lootItems: [LootItemDisplay]
    let onLootTap: ((Int) -> Void)?

    // Buttons
    let buttons: [ResultButton]
}

struct XPBarConfig {
    let displayLevel: Int
    let progress: CGFloat
    let leveledUp: Bool
}

struct DungeonProgressConfig {
    let defeated: Int
    let total: Int
    let isComplete: Bool

    var fraction: Double {
        Double(defeated) / Double(max(total, 1))
    }
}

struct LootItemDisplay {
    let name: String
    let rarityName: String
    let rarityColor: Color
    let imageKey: String?
    let imageUrl: String?
    let sfIcon: String?
    let sfColor: Color?
    let fallbackIcon: String
    /// 0=common, 1=uncommon, 2=rare, 3=epic, 4=legendary
    var rarityTier: Int = 0
}

struct ResultButton {
    let title: String
    let icon: String?
    let style: ResultButtonStyle
    let action: () -> Void
}

enum ResultButtonStyle {
    case primary, secondary, ghost
}

// MARK: - Type-Erased ButtonStyle

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { config in
            AnyView(style.makeBody(configuration: config))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Spinning Rays Background

/// Animated spinning rays (spokes) like a light wheel — orange radial beams rotating continuously.
struct SpinningRaysView: View {
    @State private var rotation: Double = 0
    let spokeCount: Int = 14
    let color: Color = DarkFantasyTheme.goldBright

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.4)
            let radius = max(geo.size.width, geo.size.height) * 1.2

            Canvas { context, size in
                let angleStep = .pi * 2 / Double(spokeCount)
                let halfWidth: Double = 0.06 // half-angle of each spoke in radians

                for i in 0..<spokeCount {
                    let angle = Double(i) * angleStep + rotation * .pi / 180

                    var path = Path()
                    path.move(to: center)
                    path.addLine(to: CGPoint(
                        x: center.x + radius * cos(angle - halfWidth),
                        y: center.y + radius * sin(angle - halfWidth)
                    ))
                    path.addLine(to: CGPoint(
                        x: center.x + radius * cos(angle + halfWidth),
                        y: center.y + radius * sin(angle + halfWidth)
                    ))
                    path.closeSubpath()

                    context.fill(path, with: .linearGradient(
                        Gradient(colors: [
                            color.opacity(0.35),
                            color.opacity(0.08),
                            color.opacity(0)
                        ]),
                        startPoint: center,
                        endPoint: CGPoint(
                            x: center.x + radius * cos(angle),
                            y: center.y + radius * sin(angle)
                        )
                    ))
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}
