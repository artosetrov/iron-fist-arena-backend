import SwiftUI

/// Full-screen rank-up ceremony modal shown after PvP rank promotion.
/// Features: old rank → new rank transition, reward display, haptic + SFX.
struct RankUpCeremonyView: View {
    let oldRank: String
    let newRank: String
    let newRating: Int
    let goldReward: Int
    let gemReward: Int
    let onDismiss: () -> Void

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

            VStack(spacing: LayoutConstants.spaceXL) {
                Spacer()

                // Title
                Text("RANK UP")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(4)
                    .opacity(showOldRank ? 1 : 0)

                // Old rank
                if showOldRank {
                    rankBadge(rank: oldRank, isOld: true)
                        .opacity(showTransition ? 0.4 : 1)
                }

                // Arrow transition
                if showTransition {
                    Image(systemName: "chevron.down.2")
                        .font(DarkFantasyTheme.title.bold())
                        .foregroundStyle(DarkFantasyTheme.gold)
                }

                // New rank with glow
                if showNewRank {
                    rankBadge(rank: newRank, isOld: false)
                        .shadow(color: DarkFantasyTheme.goldBright.opacity(glowOpacity), radius: 20)

                    Text("Rating: \(newRating)")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                // Rewards
                if showRewards {
                    GoldDivider()
                        .padding(.horizontal, LayoutConstants.cinematicPaddingH)

                    HStack(spacing: LayoutConstants.spaceXL) {
                        if goldReward > 0 {
                            rewardPill(icon: "icon-gold", amount: goldReward)
                        }
                        if gemReward > 0 {
                            rewardPill(icon: "icon-gems", amount: gemReward)
                        }
                    }
                }

                Spacer()

                // Dismiss button
                if showButton {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Glory Awaits")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, LayoutConstants.spaceXL)
                }

                Spacer().frame(height: LayoutConstants.spaceXL)
            }
        }
        .onAppear {
            startCeremony()
        }
        .onDisappear {
            glowOpacity = 0
        }
    }

    // MARK: - Components

    private func rankBadge(rank: String, isOld: Bool) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: isOld ? "shield" : "shield.fill")
                .font((isOld ? DarkFantasyTheme.title : DarkFantasyTheme.cinematicTitle).bold())
                .foregroundStyle(
                    isOld ? DarkFantasyTheme.textSecondary : rankColor(for: newRank)
                )

            Text(rank.uppercased())
                .font(isOld ? DarkFantasyTheme.title : DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(
                    isOld ? DarkFantasyTheme.textSecondary : rankColor(for: newRank)
                )
                .tracking(2)
        }
        .padding(LayoutConstants.spaceLG)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: isOld ? DarkFantasyTheme.bgTertiary : rankColor(for: newRank).opacity(0.15),
                glowIntensity: isOld ? 0.3 : 0.6,
                cornerRadius: LayoutConstants.modalRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.modalRadius)
        .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: (isOld ? DarkFantasyTheme.borderMedium : rankColor(for: newRank)).opacity(0.2))
        .cornerBrackets(color: (isOld ? DarkFantasyTheme.borderMedium : rankColor(for: newRank)).opacity(0.5), length: 18, thickness: 2)
        .cornerDiamonds(color: (isOld ? DarkFantasyTheme.borderMedium : rankColor(for: newRank)).opacity(0.4), size: 6)
        .compositingGroup()
    }

    private func rewardPill(icon: String, amount: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
            Text("+\(amount)")
                .font(DarkFantasyTheme.body.bold())
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1))
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
            SFXManager.shared.play(.uiLevelUp)
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

    private func rankColor(for rank: String) -> Color {
        switch rank.lowercased() {
        case "bronze": return DarkFantasyTheme.rarityUncommon
        case "silver": return DarkFantasyTheme.textSecondary
        case "gold": return DarkFantasyTheme.gold
        case "platinum": return DarkFantasyTheme.info
        case "diamond": return DarkFantasyTheme.rarityEpic
        case "grandmaster": return DarkFantasyTheme.rarityLegendary
        default: return DarkFantasyTheme.gold
        }
    }
}
