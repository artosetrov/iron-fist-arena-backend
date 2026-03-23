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

/// Full-screen ceremony shown when a season ends.
/// Animates stats tick-up → "NEW SEASON BEGINS" slam → dismiss.
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

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer()

                // Season name
                if showTitle {
                    VStack(spacing: LayoutConstants.spaceXS) {
                        Text("SEASON COMPLETE")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .tracking(3)

                        Text(summary.seasonName.uppercased())
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textCelebration))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .tracking(2)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Stats grid — animated tick-up
                if showStats {
                    statsGrid
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer()

                // "NEW SEASON BEGINS" slam
                if showNewSeason {
                    ZStack {
                        Text("NEW SEASON BEGINS")
                            .font(DarkFantasyTheme.title(size: 28))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .tracking(3)
                            .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 12)
                            .shadow(color: DarkFantasyTheme.bgAbyss, radius: 4)
                            .opacity(newSeasonOpacity)

                        RewardBurstView(style: .levelUp, isActive: $showBurst)
                    }
                }

                Spacer()

                // Continue button
                if showContinue {
                    Button {
                        HapticManager.medium()
                        onDismiss()
                    } label: {
                        Text("CONTINUE")
                    }
                    .buttonStyle(.primary)
                    .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.4, isActive: true)
                    .shimmer(color: DarkFantasyTheme.goldBright, duration: 2.5)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.vertical, LayoutConstants.spaceLG)
        }
        .onAppear {
            runCeremonySequence()
        }
    }

    // MARK: - Stats Grid

    @ViewBuilder
    private var statsGrid: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

        LazyVGrid(columns: columns, spacing: LayoutConstants.spaceMD) {
            statCell(label: "FINAL LEVEL", value: summary.finalLevel, icon: "star.fill", index: 0)
            statCell(label: "TOTAL BATTLES", value: summary.totalBattles, icon: "swords", index: 1)
            statCell(label: "VICTORIES", value: summary.wins, icon: "trophy.fill", index: 2)
            statCell(label: "PEAK RANK", value: summary.peakRank, icon: "crown", prefix: "#", index: 3)
            statCell(label: "GOLD EARNED", value: summary.goldEarned, icon: "dollarsign.circle", assetIcon: "icon-gold", index: 4)
            statCell(label: "REWARDS CLAIMED", value: summary.rewardsClaimed, icon: "gift", index: 5)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func statCell(label: String, value: Int, icon: String, assetIcon: String? = nil, prefix: String = "", index: Int) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            if let assetIcon {
                Image(assetIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            } else {
                Text(icon)
                    .font(.system(size: 24))
            }

            HStack(spacing: 0) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                NumberTickUpText(
                    value: value,
                    color: DarkFantasyTheme.goldBright,
                    font: DarkFantasyTheme.title(size: LayoutConstants.textCard)
                )
            }

            Text(label)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceMD)
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
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
        .staggeredAppear(index: index)
    }

    // MARK: - Ceremony Sequence

    private func runCeremonySequence() {
        // Phase 1: Title appears (0s)
        withAnimation(MotionConstants.dramatic) {
            showTitle = true
        }
        HapticManager.medium()

        // Phase 2: Stats grid (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(MotionConstants.spring) {
                showStats = true
            }
        }

        // Phase 3: "NEW SEASON BEGINS" slam (2.5s — after stats have animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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

        // Phase 4: Continue button (3.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(MotionConstants.spring) {
                showContinue = true
            }
        }
    }
}
