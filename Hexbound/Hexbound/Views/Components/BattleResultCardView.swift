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
///  • Primary CTA: gold glowPulse + shimmer (victory) / red glowPulse (defeat)
///  • HapticManager integration throughout ceremony
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
    @State var titleScale: CGFloat = MotionConstants.vsScaleFrom // 2.5 → 1.0 slam
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

            // Main card — scrollable so buttons are always reachable
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
                .frame(maxHeight: UIScreen.main.bounds.height * 0.88)
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
        VStack(spacing: LayoutConstants.spaceSM) {

            // Title — hero element, no illustration above
            titleView
                .padding(.top, LayoutConstants.spaceLG)

            // Victory Stars — labelled slots (earned + missed conditions visible)
            if let conditions = config.starConditions, config.isVictory, !conditions.isEmpty {
                victoryStarsView(conditions: conditions)
            }

            // Subtitle (near-miss motivation or general)
            if let subtitle = config.subtitle {
                Text(subtitle)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(!config.isVictory ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                    .opacity(showTitle ? 1 : 0)
                    .transition(.opacity)
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

            // XP Bar — HERO SIZE with numbers
            if let xpBarConfig = config.xpBarConfig {
                heroXpBarView(xpBarConfig)
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

            // Combat log (optional — PvP/Arena) — collapsible round summary
            if !config.combatLog.isEmpty {
                combatLogSection
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .opacity(showButtons ? 1 : 0)
            }

            // Buttons inside card — tight to loot
            buttonsSection
                .padding(.top, LayoutConstants.spaceXS)
                .padding(.horizontal, LayoutConstants.cardPadding)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 15)

            Spacer().frame(height: LayoutConstants.spaceMD)
        }
    }

    // MARK: - Title

    @ViewBuilder
    var titleView: some View {
        Text(config.title)
            .font(DarkFantasyTheme.cinematicTitle)
            .foregroundStyle(accentColor)
            .shadow(
                color: accentColor.opacity(titleGlowPulse ? 0.6 : 0.2),
                radius: titleGlowPulse ? 20 : 8
            )
            .opacity(showTitle ? 1 : 0)
    }

    // MARK: - First Win Badge

    @ViewBuilder
    var firstWinBadge: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image("reward-first-win")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            Text("FIRST WIN BONUS x2!")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(DarkFantasyTheme.goldBright.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.goldBright.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Rewards

    var hasRewards: Bool {
        (config.goldReward ?? 0) > 0 || (config.xpReward ?? 0) > 0 || config.ratingChange != nil
    }
}
