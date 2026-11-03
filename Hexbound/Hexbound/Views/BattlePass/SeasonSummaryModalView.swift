import SwiftUI

// MARK: - Season Summary Data

struct SeasonSummaryData {
    let seasonName: String
    let finalLevel: Int
    let totalBattles: Int
    let wins: Int
    let peakRank: Int
    let goldEarned: Int
    let rewardsClaimed: Int
    let hadPremium: Bool
}

// MARK: - Season Summary Modal

/// Full-screen ceremony for the end of a battle-pass season.
/// Animates stats tick-up → "NEW SEASON BEGINS" slam → dismiss.
///
/// NOT WIRED (checked 2026-10-14). Nothing instantiates this view, and no
/// client code detects a season rollover — `BattlePassViewModel` reads the
/// current season but never compares it with the last one seen.
///
/// Kept deliberately rather than deleted: to wire it, persist the last seen
/// season id, compare on battle-pass load, and enqueue this through
/// `AppState.ModalType` with the summary the server already has.
///
/// Since 2026-10-22 it plays on a glory reward card (RewardCard.swift): the metal
/// of the level reached (battle-pass brackets, one step up for a premium pass)
/// and the laurel medallion as the illustration. It reads nothing from the
/// environment, so it can be presented from anywhere once it is wired.
struct SeasonSummaryModalView: View {
    let summary: SeasonSummaryData
    let onDismiss: () -> Void

    // Animation phases
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showNewSeason = false
    @State private var newSeasonScale: CGFloat = MotionConstants.vsScaleFrom
    @State private var newSeasonOpacity: Double = 0
    @State private var showContinue = false
    @State private var showBurst = false

    var body: some View {
        ZStack {
            // Background
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            // Subtle gold gradient
            LinearGradient(
                colors: [DarkFantasyTheme.gold.opacity(0.05), .clear, DarkFantasyTheme.gold.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RewardCardStage { width, artRatio in
                RewardCard(
                    family: .glory,
                    tier: cardTier,
                    art: .object("reward-art-xp", fill: 0.68),
                    width: width,
                    artRatio: artRatio,
                    header: { cardHeader },
                    content: { cardContent },
                    actions: { continueButton }
                )
            }
            .opacity(showTitle ? 1 : 0)
        }
        .onAppear {
            runCeremonySequence()
        }
    }

    // MARK: - Card

    /// A hundred battle-pass levels in five metals (1–19 iron … 80+ mythic, as the
    /// battle-pass claim cards), one step up for a season played with the premium pass.
    private var cardTier: RewardCardTier {
        let byLevel = min(5, 1 + summary.finalLevel / 20) + (summary.hadPremium ? 1 : 0)
        return RewardCardTier(rawValue: min(5, byLevel)) ?? .iron
    }

    private var cardHeader: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("SEASON COMPLETE")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(3)

            Text(summary.seasonName.uppercased())
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .accessibilityAddTraits(.isHeader)

            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceXS)
        }
        .opacity(showTitle ? 1 : 0)
    }

    /// Stats, then the NEW SEASON beat. Both are laid out from the start and
    /// revealed in turn, so the card keeps its height.
    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            statsGrid
                .opacity(showStats ? 1 : 0)

            // "NEW SEASON BEGINS" slam
            Text("NEW SEASON BEGINS")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 12)
                .shadow(color: DarkFantasyTheme.bgAbyss, radius: 4)
                .opacity(newSeasonOpacity)
                .overlay {
                    if showNewSeason {
                        RewardBurstView(style: .levelUp, isActive: $showBurst)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var continueButton: some View {
        Button {
            HapticManager.medium()
            onDismiss()
        } label: {
            Text("CONTINUE")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.4, isActive: showContinue)
        .shimmer(color: DarkFantasyTheme.goldBright, duration: 2.5)
        .opacity(showContinue ? 1 : 0)
        .offset(y: showContinue ? 0 : 15)
        .allowsHitTesting(showContinue)
    }

    // MARK: - Stats Grid

    /// Two columns, three rows (plain stacks: the card's stage measures its height).
    private var statsGrid: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceSM) {
                statCell(label: "FINAL LEVEL", value: summary.finalLevel, asset: "reward-level-up", index: 0)
                statCell(label: "TOTAL BATTLES", value: summary.totalBattles, asset: "icon-fights", index: 1)
            }
            HStack(spacing: LayoutConstants.spaceSM) {
                statCell(label: "VICTORIES", value: summary.wins, asset: "icon-wins", index: 2)
                statCell(label: "PEAK RANK", value: summary.peakRank, asset: "icon-leaderboard", prefix: "#", index: 3)
            }
            HStack(spacing: LayoutConstants.spaceSM) {
                statCell(label: "GOLD EARNED", value: summary.goldEarned, asset: "icon-gold", index: 4)
                statCell(label: "REWARDS CLAIMED", value: summary.rewardsClaimed, asset: "hud-gift", index: 5)
            }
        }
    }

    private func statCell(label: String, value: Int, asset: String, prefix: String = "", index: Int) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)

            HStack(spacing: 0) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                NumberTickUpText(
                    value: value,
                    color: DarkFantasyTheme.goldBright,
                    font: DarkFantasyTheme.cardTitle
                )
            }

            Text(label)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.15), lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.25), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.gold.opacity(0.08), radius: 6)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
        .staggeredAppear(index: index)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Ceremony Sequence

    private func runCeremonySequence() {
        // Phase 1: Title appears (0s)
        withAnimation(MotionConstants.dramatic) {
            showTitle = true
        }
        HapticManager.medium()

        // Phase 2: Stats grid (phase1 + fast = 0.55s)
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyPhase1 + MotionConstants.fast) {
            withAnimation(MotionConstants.spring) {
                showStats = true
            }
        }

        // Phase 3: "NEW SEASON BEGINS" slam (after stats have animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonySlow) {
            showNewSeason = true
            HapticManager.heavy()

            withAnimation(.easeOut(duration: MotionConstants.vsSlamDuration)) {
                newSeasonScale = MotionConstants.vsScaleTo
                newSeasonOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showBurst = true
                HapticManager.rankUp()
            }
        }

        // Phase 4: Continue button (ceremonySlow + ceremonyPhase4 = 3.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonySlow + MotionConstants.ceremonyPhase4) {
            withAnimation(MotionConstants.spring) {
                showContinue = true
            }
        }
    }
}
