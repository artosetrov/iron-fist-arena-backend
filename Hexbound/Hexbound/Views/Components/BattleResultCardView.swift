import SwiftUI

/// Unified compact card overlay for victory / defeat / loot results.
///
/// Used by:  CombatResultDetailView, DungeonVictoryView, LootDetailView
/// Follows the "card on dimmed background" pattern with:
///  • Pulsing title glow (victory=gold, defeat=red)
///  • Staggered reward counters
///  • Inline loot cards (scale-in)
///  • Shake on defeat
///  • Particle overlay
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
                        .scaleEffect(showCard ? 1 : 0.9)
                        .opacity(showCard ? 1 : 0)

                    // Buttons below card
                    buttonsSection
                        .padding(.top, LayoutConstants.spaceLG)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .opacity(showButtons ? 1 : 0)
                        .offset(y: showButtons ? 0 : 15)

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

            // Subtitle
            if let subtitle = config.subtitle {
                Text(subtitle)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .opacity(showTitle ? 1 : 0)
            }

            // First Win Bonus
            if config.firstWinBonus {
                firstWinBadge
                    .opacity(showRewards ? 1 : 0)
                    .scaleEffect(showRewards ? 1 : 0.8)
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

            Spacer().frame(height: LayoutConstants.spaceMD)
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
            .scaleEffect(showTitle ? 1 : 0.5)
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
        .scaleEffect(isRevealed ? 1.0 : 0.3)
        .opacity(isRevealed ? 1.0 : 0.0)
    }

    // MARK: - Buttons

    @ViewBuilder
    private var buttonsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(config.buttons.enumerated()), id: \.offset) { _, button in
                Button {
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
                .buttonStyle(resolveButtonStyle(button.style))
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

    // MARK: - Animation Sequence

    private func runAnimationSequence() {
        // 0.0s — card scales in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showCard = true
        }

        // 0.3s — title slams in
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65).delay(0.3)) {
            showTitle = true
        }

        // 0.4s — defeat shake
        if !config.isVictory {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shakeSequence()
            }
        }

        // 0.6s — start title glow pulsing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                titleGlowPulse = true
            }
        }

        // 0.8s — rewards appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                showRewards = true
            }
            // Roll up counters
            rollUp(to: config.goldReward ?? 0, binding: $goldDisplay, duration: 0.6)
            rollUp(to: config.xpReward ?? 0, binding: $xpDisplay, duration: 0.6)
        }

        // 1.4s — loot section appears
        if !config.lootItems.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showLoot = true
                }
                // Stagger loot card reveals
                for i in config.lootItems.indices {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            _ = revealedLootIndices.insert(i)
                        }
                    }
                }
            }
        }

        // 1.8s (or 1.4s if no loot) — buttons
        let buttonDelay = config.lootItems.isEmpty ? 1.4 : 1.8 + Double(config.lootItems.count) * 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
            withAnimation(.easeOut(duration: 0.3)) {
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
