import SwiftUI

/// W2.D3 — Tutorial victory overlay.
///
/// Shown after the scripted first fight resolves. Reveals rewards with a
/// staggered opacity fade (no scale, per design preference) and then routes
/// the player to the cinematic lore intro — which is NOW earned, not gated.
///
/// Flow: tutorialVictory → loreIntro (OnboardingCinematicView) → game
///
/// Rewards read from `appState.tutorialRewards` which was populated by
/// `TutorialFightViewModel.resolve`. If the payload is missing (shouldn't
/// happen, but defensive), we skip straight to the lore intro.
///
/// Since 2026-10-22 the rewards sit on an arena reward card (RewardCard.swift):
/// iron — the first fight — with the new hero as the illustration.
struct VictoryOverlayView: View {
    let heroName: String

    @Environment(AppState.self) private var appState

    @State private var titleOpacity: Double = 0
    @State private var goldRowOpacity: Double = 0
    @State private var xpRowOpacity: Double = 0
    @State private var itemRowOpacity: Double = 0
    @State private var levelUpRowOpacity: Double = 0
    @State private var statPointsRowOpacity: Double = 0
    @State private var passivePointsRowOpacity: Double = 0
    @State private var ctaOpacity: Double = 0
    @State private var didAdvance = false

    var body: some View {
        ZStack {
            // Dark ceremonial backdrop
            DarkFantasyTheme.bgPrimary
                .ignoresSafeArea()

            Image("bg-arena")
                .resizable()
                .scaledToFill()
                .opacity(0.25)
                .ignoresSafeArea()

            RadialGradient(
                colors: [DarkFantasyTheme.gold.opacity(0.15), .clear],
                center: .center,
                startRadius: 40,
                endRadius: 400,
            )
            .ignoresSafeArea()

            RewardCardStage { width, artRatio in
                RewardCard(
                    family: .arena,
                    tier: .iron,
                    art: heroArt,
                    width: width,
                    artRatio: artRatio,
                    header: {
                        RewardCardTitle(
                            title: "VICTORY",
                            subtitle: "Well fought, \(heroName).",
                            color: DarkFantasyTheme.gold
                        )
                        .opacity(titleOpacity)
                    },
                    content: { rewardRows },
                    actions: { continueButton }
                )
            }
            .opacity(titleOpacity)
        }
        .onAppear(perform: startRevealSequence)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Victory. Continue to see the lore intro.")
    }

    // MARK: - Card

    /// The hero who just won; the arena's victory painting if the hero is not loaded yet.
    private var heroArt: RewardCardArt {
        guard let hero = appState.currentCharacter else {
            return RewardCardArt(subject: .none, backdrop: "onboarding-victory")
        }
        return .hero(skinKey: hero.avatar, characterClass: hero.characterClass)
    }

    /// Reward lines, revealed one after another.
    @ViewBuilder
    private var rewardRows: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            if let rewards = appState.tutorialRewards {
                RewardCardRow(icon: "icon-gold", value: "+\(rewards.gold)", label: "Gold",
                              color: DarkFantasyTheme.gold)
                    .opacity(goldRowOpacity)

                RewardCardRow(icon: "reward-xp", value: "+\(rewards.xp)", label: "XP",
                              color: DarkFantasyTheme.toastLevelUp)
                    .opacity(xpRowOpacity)

                if let itemName = rewards.itemName {
                    RewardCardRow(
                        icon: UIImage(named: rewards.itemCatalogKey) != nil ? rewards.itemCatalogKey : "reward-loot",
                        value: itemName.uppercased(),
                        label: "",
                        color: DarkFantasyTheme.textPrimary
                    )
                    .opacity(itemRowOpacity)
                }

                if rewards.leveledUp, let newLevel = rewards.newLevel {
                    RewardCardRow(icon: "reward-level-up", value: "LEVEL \(newLevel)", label: "reached",
                                  color: DarkFantasyTheme.toastLevelUp)
                        .opacity(levelUpRowOpacity)
                }

                if rewards.statPointsAwarded > 0 {
                    RewardCardRow(
                        icon: "reward-level-up",
                        value: "+\(rewards.statPointsAwarded)",
                        label: rewards.statPointsAwarded == 1 ? "Stat Point" : "Stat Points",
                        color: DarkFantasyTheme.gold
                    )
                    .opacity(statPointsRowOpacity)
                }

                if rewards.passivePointsAwarded > 0 {
                    RewardCardRow(
                        icon: "reward-first-win",
                        value: "+\(rewards.passivePointsAwarded)",
                        label: rewards.passivePointsAwarded == 1 ? "Passive Point" : "Passive Points",
                        color: DarkFantasyTheme.toastLevelUp
                    )
                    .opacity(passivePointsRowOpacity)
                }
            }
        }
    }

    private var continueButton: some View {
        Button {
            advance()
        } label: {
            Text("CONTINUE")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .opacity(ctaOpacity)
    }

    // MARK: - Reveal Sequence

    private func startRevealSequence() {
        HapticManager.rankUp()
        SFXManager.shared.play(.uiConfirm)

        // Staggered opacity reveal — no scale animations (per design preference)
        withAnimation(.easeOut(duration: 0.5)) {
            titleOpacity = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.4)) { goldRowOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeOut(duration: 0.4)) { xpRowOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeOut(duration: 0.4)) { itemRowOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeOut(duration: 0.4)) { levelUpRowOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeOut(duration: 0.4)) { statPointsRowOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeOut(duration: 0.4)) { passivePointsRowOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.4)) { ctaOpacity = 1 }
        }
    }

    // MARK: - Advance

    private func advance() {
        guard !didAdvance else { return }
        didAdvance = true
        HapticManager.heavy()
        SFXManager.shared.play(.uiConfirm)

        // Queue building unlocks so the hub can ceremonialize them
        if let unlocks = appState.tutorialRewards?.unlocks, !unlocks.isEmpty {
            appState.pendingBuildingUnlocks = unlocks
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            appState.currentScreen = .loreIntro(heroName: heroName)
        }
    }
}
