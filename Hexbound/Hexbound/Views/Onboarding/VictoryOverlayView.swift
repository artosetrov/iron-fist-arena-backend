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

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer()

                // Title
                Text("VICTORY")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.4), radius: 12)
                    .opacity(titleOpacity)

                Text("Well fought, \(heroName).")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .opacity(titleOpacity)

                Spacer().frame(height: LayoutConstants.spaceLG)

                // Reward rows
                VStack(spacing: LayoutConstants.spaceMS) {
                    if let rewards = appState.tutorialRewards {
                        rewardRow(
                            icon: "dollarsign.circle.fill",
                            text: "+\(rewards.gold) GOLD",
                            color: DarkFantasyTheme.gold,
                        )
                        .opacity(goldRowOpacity)

                        rewardRow(
                            icon: "star.circle.fill",
                            text: "+\(rewards.xp) XP",
                            color: DarkFantasyTheme.toastLevelUp,
                        )
                        .opacity(xpRowOpacity)

                        if let itemName = rewards.itemName {
                            rewardRow(
                                icon: "shield.fill",
                                text: itemName.uppercased(),
                                color: DarkFantasyTheme.textPrimary,
                            )
                            .opacity(itemRowOpacity)
                        }

                        if rewards.leveledUp, let newLevel = rewards.newLevel {
                            rewardRow(
                                icon: "arrow.up.circle.fill",
                                text: "LEVEL \(newLevel) REACHED",
                                color: DarkFantasyTheme.toastLevelUp,
                            )
                            .opacity(levelUpRowOpacity)
                        }

                        if rewards.statPointsAwarded > 0 {
                            rewardRow(
                                icon: "sparkles",
                                text: "+\(rewards.statPointsAwarded) STAT \(rewards.statPointsAwarded == 1 ? "POINT" : "POINTS")",
                                color: DarkFantasyTheme.gold,
                            )
                            .opacity(statPointsRowOpacity)
                        }

                        if rewards.passivePointsAwarded > 0 {
                            rewardRow(
                                icon: "hexagon.fill",
                                text: "+\(rewards.passivePointsAwarded) PASSIVE \(rewards.passivePointsAwarded == 1 ? "POINT" : "POINTS")",
                                color: DarkFantasyTheme.toastLevelUp,
                            )
                            .opacity(passivePointsRowOpacity)
                        }
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)

                Spacer()

                Button {
                    advance()
                } label: {
                    Text("CONTINUE")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceLG)
                .opacity(ctaOpacity)
            }
        }
        .onAppear(perform: startRevealSequence)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Victory. Continue to see the lore intro.")
    }

    // MARK: - Subviews

    private func rewardRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(color.opacity(0.5), lineWidth: 1),
                ),
        )
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
