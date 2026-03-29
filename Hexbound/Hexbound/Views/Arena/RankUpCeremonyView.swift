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

            VStack(spacing: LayoutConstants.spacingXL) {
                Spacer()

                // Title
                Text("RANK UP")
                    .font(DarkFantasyTheme.largeTitleFont)
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
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }

                // New rank with glow
                if showNewRank {
                    rankBadge(rank: newRank, isOld: false)
                        .shadow(color: DarkFantasyTheme.goldBright.opacity(glowOpacity), radius: 20)

                    Text("Rating: \(newRating)")
                        .font(DarkFantasyTheme.bodyFont)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                // Rewards
                if showRewards {
                    GoldDivider()
                        .padding(.horizontal, 40)

                    HStack(spacing: LayoutConstants.spacingXL) {
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
                    .padding(.horizontal, LayoutConstants.spacingXL)
                }

                Spacer().frame(height: LayoutConstants.spacingXL)
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
        VStack(spacing: 8) {
            Image(systemName: isOld ? "shield" : "shield.fill")
                .font(.system(size: isOld ? 48 : 64, weight: .bold))
                .foregroundStyle(
                    isOld ? DarkFantasyTheme.textSecondary : rankColor(for: newRank)
                )

            Text(rank.uppercased())
                .font(isOld ? DarkFantasyTheme.titleFont : DarkFantasyTheme.largeTitleFont)
                .foregroundStyle(
                    isOld ? DarkFantasyTheme.textSecondary : rankColor(for: newRank)
                )
                .tracking(2)
        }
        .padding(LayoutConstants.spacingLG)
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
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text("+\(amount)")
                .font(DarkFantasyTheme.bodyBoldFont)
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Animation

    private func startCeremony() {
        // Staggered reveal
        withAnimation(.easeOut(duration: 0.5)) {
            showOldRank = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showTransition = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showNewRank = true
            }
            HapticManager.rankUp()
            SFXManager.shared.play(.uiLevelUp)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.8).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showRewards = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeOut(duration: 0.3)) {
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
