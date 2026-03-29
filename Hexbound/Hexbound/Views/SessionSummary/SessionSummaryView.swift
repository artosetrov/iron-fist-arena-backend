import SwiftUI

struct SessionSummaryView: View {
    let characterId: String
    let onDismiss: () -> Void

    @State private var vm: SessionSummaryViewModel?

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
                    .transaction { $0.animation = nil }
            } else {
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .task {
            let newVM = SessionSummaryViewModel(characterId: characterId)
            vm = newVM
            await newVM.load()
        }
    }

    @ViewBuilder
    private func content(vm: SessionSummaryViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            // Title
            OrnamentalTitle("Session Complete")
                .padding(.top, LayoutConstants.spaceMD)

            if vm.isLoading {
                Spacer()
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
                Spacer()
            } else if let summary = vm.summary {
                ScrollView {
                    VStack(spacing: LayoutConstants.spaceMD) {
                        // Combat Stats
                        combatCard(summary: summary)

                        // Rewards
                        rewardsCard(summary: summary)

                        // Quest Progress
                        if summary.questsTotal > 0 {
                            questCard(summary: summary)
                        }

                        // Rating
                        ratingCard(summary: summary)
                    }
                    .padding(.horizontal, LayoutConstants.spaceMD)
                }

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, LayoutConstants.spaceLG)
                .padding(.bottom, LayoutConstants.spaceLG)
            } else {
                Spacer()
                Text(vm.error ?? "No session data")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, LayoutConstants.spaceLG)
                .padding(.bottom, LayoutConstants.spaceLG)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DarkFantasyTheme.bgPrimary)
    }

    // MARK: - Cards

    private func combatCard(summary: SessionSummaryData) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("Combat")

            HStack(spacing: LayoutConstants.spaceLG) {
                statPill(label: "Matches", value: "\(summary.matchesPlayed)", color: DarkFantasyTheme.gold)
                statPill(label: "Wins", value: "\(summary.wins)", color: DarkFantasyTheme.success)
                statPill(label: "Losses", value: "\(summary.losses)", color: DarkFantasyTheme.danger)
            }

            if summary.matchesPlayed > 0 {
                // Win rate bar
                let winRate = summary.matchesPlayed > 0 ? Double(summary.wins) / Double(summary.matchesPlayed) : 0
                VStack(spacing: 4) {
                    HStack {
                        Text("Win Rate")
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                        Spacer()
                        Text("\(Int(winRate * 100))%")
                            .font(DarkFantasyTheme.caption.bold())
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(DarkFantasyTheme.bgTertiary)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(DarkFantasyTheme.gold)
                                .frame(width: geo.size.width * winRate, height: 8)
                                .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    private func rewardsCard(summary: SessionSummaryData) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("Rewards Earned")

            HStack(spacing: LayoutConstants.spaceLG) {
                rewardRow(icon: "icon-gold", label: "Gold", value: "+\(summary.goldEarned)")
                rewardRow(icon: "icon-xp", label: "XP", value: "+\(summary.xpEarned)")
            }

            if summary.itemsGained > 0 {
                HStack {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DarkFantasyTheme.gold)
                    Text("\(summary.itemsGained) items obtained")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    private func questCard(summary: SessionSummaryData) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("Daily Quests")

            HStack {
                Text("\(summary.questsCompleted)/\(summary.questsTotal) completed")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Spacer()
                if summary.questsCompleted == summary.questsTotal {
                    Text("ALL DONE")
                        .font(DarkFantasyTheme.caption.bold())
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }

            // Progress bar
            GeometryReader { geo in
                let progress = summary.questsTotal > 0 ? Double(summary.questsCompleted) / Double(summary.questsTotal) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.info)
                        .frame(width: geo.size.width * progress, height: 10)
                        .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                }
            }
            .frame(height: 10)
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    private func ratingCard(summary: SessionSummaryData) -> some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: summary.ratingChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(summary.ratingChange >= 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rating Change")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Text("\(summary.ratingChange > 0 ? "+" : "")\(summary.ratingChange)")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(summary.ratingChange >= 0 ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)
            }

            Spacer()
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(DarkFantasyTheme.caption.bold())
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(1.5)
            Spacer()
        }
    }

    private func statPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DarkFantasyTheme.title)
                .foregroundStyle(color)
            Text(label)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func rewardRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(DarkFantasyTheme.body.bold())
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text(label)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
