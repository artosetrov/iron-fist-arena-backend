import SwiftUI

/// The result of a fight or a find, on a painted reward card (`RewardCard`).
///
/// Used by:  CombatResultDetailView (arena, PvP, challenges, training),
/// DungeonDefeatView, LootDetailView. DungeonVictoryView draws its own card
/// (stars, the dungeon's progress, the next boss).
///
/// The card's family, tier and illustration come from `BattleResultConfig`
/// (`cardFamily`, `resolvedCardTier`, `resolvedCardArt`); a loss dims it.
/// Around it, the ceremony:
///  • Screen flash (gold=victory, red=defeat) (Motion Audit §2.12)
///  • RewardBurstView particle explosion on victory
///  • Pulsing title glow (victory=gold, defeat=red)
///  • Staggered reward counters with tick-up
///  • Loot tiles flipped one by one (per-item haptics scaled by rarity)
///  • Shake + haptic on defeat
///  • Primary CTA: gold glowPulse + shimmer (victory) / red glowPulse (defeat)
///  • HapticManager integration throughout ceremony
///
/// Everything is laid out from the first frame and revealed with opacity, so
/// the stage never jumps between its full and compact sizes mid-ceremony.
struct BattleResultCardView: View {

    // MARK: - Config

    let config: BattleResultConfig

    // MARK: - Animation State

    @State var showCard = false
    @State var showTitle = false
    @State var showRewards = false
    @State var showLoot = false
    @State var showButtons = false
    @State var titleGlowPulse = false
    @State var shakeOffset: CGFloat = 0
    @State var revealedLootIndices: Set<Int> = []

    // Ceremony enhancements (Motion Audit §2.12, §3.8)
    @State var screenFlashOpacity: Double = 0
    @State var showRewardBurst = false

    // Reward counter roll-ups
    @State var goldDisplay = 0
    @State var xpDisplay = 0
    @State var ratingDisplay = 0

    // Per-item reveal state (Gold / XP / Rating staggered fade-in)
    // NOTE: defaults to true as a safety net — staggered reveal flips them to false
    // at start of runAnimationSequence and then back to true on schedule. If reveal
    // logic fails for any reason, items remain visible rather than disappearing.
    @State var goldItemVisible = true
    @State var xpItemVisible = true
    @State var ratingItemVisible = true

    // Completion pulse opacity (1.0 → 0.7 → 1.0 when count-up finishes)
    @State var goldPulseOpacity: Double = 1.0
    @State var xpPulseOpacity: Double = 1.0
    @State var ratingPulseOpacity: Double = 1.0

    // Hero XP counter roll-up
    @State var xpHeroDisplay: Int = 0

    // Victory stars
    @State var revealedStars: Int = 0

    // Combat log section (collapsed by default)
    @State var showCombatLog: Bool = false

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

            // The card. The stage shrinks the illustration, then scrolls, when
            // the whole card does not fit — the buttons stay reachable.
            RewardCardStage { width, artRatio in
                RewardCard(
                    family: config.cardFamily,
                    tier: config.resolvedCardTier,
                    dimmed: !config.isVictory,
                    art: config.resolvedCardArt,
                    width: width,
                    artRatio: artRatio,
                    header: { titleView },
                    content: { cardContent },
                    actions: { actionsSection }
                )
            }
            .offset(x: shakeOffset)
            .opacity(showCard ? 1 : 0)
        }
        .onAppear {
            runAnimationSequence()
        }
    }

    // MARK: - Accent Color

    var accentColor: Color {
        config.isVictory ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger
    }

    // MARK: - Card Content

    @ViewBuilder
    var cardContent: some View {
        if let duel = config.duel {
            duelCardContent(duel)
        } else {
            classicCardContent
        }
    }

    /// Dungeon / training / loot layout.
    @ViewBuilder
    var classicCardContent: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Victory Stars — labelled slots (earned + missed conditions visible)
            if let conditions = config.starConditions, config.isVictory, !conditions.isEmpty {
                victoryStarsView(conditions: conditions)
            }

            // Subtitle (near-miss motivation or general)
            if let subtitle = config.subtitle {
                subtitleText(subtitle)
            }

            // First Win Bonus
            if config.firstWinBonus {
                firstWinBadge
                    .opacity(showRewards ? 1 : 0)
            }

            // Rewards — one line each; the card grows with the list
            if hasRewards {
                rewardsSection(ratingBefore: nil)
                    .opacity(showRewards ? 1 : 0)
                    .offset(y: showRewards ? 0 : 10)
            }

            // XP Bar — HERO SIZE with numbers
            if let xpBarConfig = config.xpBarConfig {
                heroXpBarView(xpBarConfig)
                    .opacity(showRewards ? 1 : 0)
            }

            // Dungeon Progress (optional)
            if let dungeonProgress = config.dungeonProgress {
                dungeonProgressBar(dungeonProgress)
                    .opacity(showRewards ? 1 : 0)
            }

            // Loot section
            if !config.lootItems.isEmpty {
                lootSection
                    .opacity(showLoot ? 1 : 0)
            }

            // Combat log (optional — PvP/Arena) — collapsible round summary
            if !config.combatLog.isEmpty {
                combatLogSection
                    .opacity(showButtons ? 1 : 0)
            }
        }
    }

    /// The buttons, in the card's action band.
    var actionsSection: some View {
        buttonsSection
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 15)
    }

    // MARK: - Title

    /// The title on the illustration's fade (with the card's gold divider).
    var titleView: some View {
        RewardCardTitle(title: config.title, color: accentColor, glow: titleGlowPulse)
            .opacity(showTitle ? 1 : 0)
    }

    /// Near-miss motivation on a loss (gold), a plain line on a win.
    func subtitleText(_ subtitle: String) -> some View {
        Text(subtitle)
            .font(DarkFantasyTheme.body)
            .foregroundStyle(!config.isVictory ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .opacity(showTitle ? 1 : 0)
    }

    // MARK: - First Win Badge

    var firstWinBadge: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image("reward-first-win")
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
            Text("FIRST WIN BONUS x2!")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityLight))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.goldBright.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Rewards

    var hasRewards: Bool {
        (config.goldReward ?? 0) > 0 || (config.xpReward ?? 0) > 0 || (config.ratingChange ?? 0) != 0
    }
}
