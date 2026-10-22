import SwiftUI

/// Full-screen rank-up ceremony modal for PvP tier promotion.
/// Old rank → new rank transition, reward display, haptic + SFX.
///
/// Wired 2026-10-14. It sat unused for months because the signal was missing,
/// not the screen: `/api/pvp/resolve` returned the new rating and nothing
/// else, so crossing into Gold looked exactly like any other +24 and the
/// promotion passed without so much as a toast. Resolve now reports the
/// crossing itself (`result.tier_change`), and `CombatResultDetailView`
/// enqueues this through `AppState.ModalType.rankUp`.
///
/// Fires on a TIER change only. Divisions move three times per tier, and a
/// full-screen ceremony three times as often would stop meaning anything.
///
/// Since 2026-10-22 it plays on an arena reward card (RewardCard.swift): the
/// metal of the new tier, the player's hero as the illustration, old → new rank
/// in one line under the title.
struct RankUpCeremonyView: View {
    let oldRank: String
    let newRank: String
    let newRating: Int
    let goldReward: Int
    let gemReward: Int
    let onDismiss: () -> Void

    @Environment(AppState.self) private var appState

    @State private var showOldRank = false
    @State private var showTransition = false
    @State private var showNewRank = false
    @State private var showRewards = false
    @State private var showButton = false
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dark overlay
            DarkFantasyTheme.bgAbyss.opacity(0.92)
                .ignoresSafeArea()

            RewardCardStage { width, artRatio in
                RewardCard(
                    family: .arena,
                    tier: RewardCardTier(rankKey: PvPRank.tierKey(fromLabel: newRank)),
                    art: heroArt,
                    width: width,
                    artRatio: artRatio,
                    header: {
                        RewardCardTitle(title: "RANK UP", tracking: 4)
                            .opacity(showOldRank ? 1 : 0)
                    },
                    content: { cardContent },
                    actions: { dismissButton }
                )
            }
            .opacity(showOldRank ? 1 : 0)
        }
        .onAppear {
            startCeremony()
        }
        .onDisappear {
            glowOpacity = 0
        }
    }

    // MARK: - Card

    /// The player's hero, standing in the arena.
    private var heroArt: RewardCardArt {
        guard let hero = appState.currentCharacter else {
            return .object("icon-pvp-rating", fill: 0.5)
        }
        return .hero(skinKey: hero.avatar, characterClass: hero.characterClass)
    }

    /// Old rank → new rank, the rating, and whatever the promotion paid. Laid out
    /// from the start and revealed in beats, so the card keeps its height.
    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
                rankBadge(rank: oldRank, isOld: true)
                    .opacity(showTransition ? 0.4 : 1)

                Image("ui-arrow-right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                    .opacity(showTransition ? 1 : 0)
                    .accessibilityHidden(true)

                rankBadge(rank: newRank, isOld: false)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(glowOpacity), radius: 20)
                    .opacity(showNewRank ? 1 : 0)
            }
            .frame(maxWidth: .infinity)

            Text("Rating: \(newRating)")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .opacity(showNewRank ? 1 : 0)

            // Rewards
            // Promotion carries no reward of its own today, so this block is
            // usually absent.
            if goldReward > 0 || gemReward > 0 {
                VStack(spacing: LayoutConstants.spaceXS) {
                    if goldReward > 0 {
                        RewardCardRow(icon: "icon-gold", value: "+\(goldReward)", label: "Gold",
                                      color: DarkFantasyTheme.goldBright)
                    }
                    if gemReward > 0 {
                        RewardCardRow(icon: "icon-gems", value: "+\(gemReward)", label: "Gems",
                                      color: DarkFantasyTheme.purple)
                    }
                }
                .opacity(showRewards ? 1 : 0)
            }
        }
    }

    private var dismissButton: some View {
        Button {
            onDismiss()
        } label: {
            Text("Glory Awaits")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .opacity(showButton ? 1 : 0)
        .allowsHitTesting(showButton)
    }

    // MARK: - Components

    private func rankBadge(rank: String, isOld: Bool) -> some View {
        let color = isOld ? DarkFantasyTheme.textSecondary : rankColor(for: newRank)
        let frameColor = isOld ? DarkFantasyTheme.borderMedium : rankColor(for: newRank)
        return VStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: PvPRank.icon(forTierKey: PvPRank.tierKey(fromLabel: rank)))
                .font((isOld ? DarkFantasyTheme.section : DarkFantasyTheme.title).bold())
                .foregroundStyle(color)

            Text(rank.uppercased())
                .font(isOld ? DarkFantasyTheme.cardTitle : DarkFantasyTheme.section)
                .foregroundStyle(color)
                .tracking(1.5)
                .lineLimit(1)
                // Never below the 16 pt floor: 18 × 0.9, 22 × 0.75.
                .minimumScaleFactor(isOld ? 0.9 : 0.75)
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceMD)
        .frame(minWidth: isOld ? 88 : 112)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: isOld ? DarkFantasyTheme.bgTertiary : rankColor(for: newRank).opacity(0.15),
                glowIntensity: isOld ? 0.3 : 0.6,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: frameColor.opacity(0.2))
        .cornerBrackets(color: frameColor.opacity(0.5), length: 12, thickness: 1.5)
        .compositingGroup()
    }

    // MARK: - Animation

    private func startCeremony() {
        // Staggered reveal — evenly spaced ~0.6s apart
        withAnimation(.easeOut(duration: 0.5)) {
            showOldRank = true
        }

        // Phase 1: Transition arrow
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyPhase3) {
            withAnimation(.easeInOut(duration: MotionConstants.normal)) {
                showTransition = true
            }
        }

        // Phase 2: New rank reveal (0.8 + 0.6 = 1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyPhase3 + MotionConstants.reward) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showNewRank = true
            }
            HapticManager.rankUp()
            SFXManager.shared.play(.epicHornFanfare)
        }

        // Phase 3: Glow pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyButton) {
            withAnimation(.easeIn(duration: 0.8).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }

        // Phase 4: Rewards (ceremonyButton + 0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonyButton + MotionConstants.normal) {
            withAnimation(.easeOut(duration: 0.4)) {
                showRewards = true
            }
        }

        // Phase 5: Dismiss button (ceremonySlow + ceremonyPhase1)
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.ceremonySlow + MotionConstants.ceremonyPhase1) {
            withAnimation(.easeOut(duration: MotionConstants.ceremonyPhase1)) {
                showButton = true
            }
        }
    }

    // MARK: - Helpers

    /// The ceremony receives rendered labels ("Silver II"), not ratings, so the
    /// tier key is recovered from the label. This used to be its own color
    /// table keyed on the whole string — which meant that the moment the server
    /// started sending divisions, every rank-up ceremony fell through to the
    /// default gold.
    private func rankColor(for rank: String) -> Color {
        DarkFantasyTheme.rankColor(forTierKey: PvPRank.tierKey(fromLabel: rank))
    }
}

/// What the ceremony needs to play, lifted off a `TierChangeInfo` plus
/// whatever the fight paid out.
struct RankUpData {
    let oldRank: String
    let newRank: String
    let newRating: Int
    var goldReward: Int = 0
    var gemReward: Int = 0

    /// Returns nil unless this was a promotion across a TIER boundary.
    init?(tierChange: TierChangeInfo, newRating: Int) {
        guard tierChange.isPromotion, tierChange.isTierChange else { return nil }
        oldRank = tierChange.from.label
        newRank = tierChange.to.label
        self.newRating = newRating
    }
}
