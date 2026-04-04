import SwiftUI

struct OpponentCardView: View {
    let opponent: Opponent
    let isFighting: Bool
    let canFight: Bool
    let staminaCost: Int
    let onFight: () -> Void
    var playerRating: Int = 0

    private var ratingDiff: Int { opponent.pvpRating - playerRating }

    private var difficultyLabel: String {
        let diff = ratingDiff
        if diff < -200 { return "Easy" }
        if diff < -50 { return "Fair" }
        if diff < 100 { return "Tough" }
        return "Hard"
    }

    private var difficultyColor: Color {
        let diff = ratingDiff
        if diff < -200 { return DarkFantasyTheme.success }
        if diff < -50 { return DarkFantasyTheme.textSecondary }
        if diff < 100 { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.danger
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Top row: class icon + name + level
            HStack {
                // Avatar
                AvatarImageView(
                    skinKey: opponent.avatar,
                    characterClass: opponent.characterClass,
                    size: 44
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.classColor(for: opponent.characterClass).opacity(0.4), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(opponent.characterName)
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("Lv.\(opponent.level)")
                            .font(DarkFantasyTheme.uiLabel)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text(opponent.characterClass.displayName)
                            .font(DarkFantasyTheme.uiLabel)
                            .foregroundStyle(DarkFantasyTheme.classColor(for: opponent.characterClass))

                        Text(difficultyLabel)
                            .font(DarkFantasyTheme.badge)
                            .foregroundStyle(difficultyColor)
                            .padding(.horizontal, LayoutConstants.spaceXS)
                            .padding(.vertical, LayoutConstants.space2XS)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                    .fill(difficultyColor.opacity(0.15))
                            )
                    }
                }

                Spacer()

                // Rating badge
                VStack(spacing: LayoutConstants.space2XS) {
                    Text("\(opponent.pvpRating)")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.rankColor(for: opponent.pvpRating))
                    Image(systemName: opponent.rank.icon)
                        .font(DarkFantasyTheme.caption.weight(.semibold))
                        .foregroundStyle(opponent.rank.color)
                }
            }

            // Stats row
            HStack(spacing: LayoutConstants.spaceMD) {
                GlassStatPill(value: "\(opponent.maxHp)", label: "HP", color: DarkFantasyTheme.danger, size: .compact)
                GlassStatPill(value: "\(opponent.pvpWins)/\(opponent.pvpLosses)", label: "W/L", color: DarkFantasyTheme.textSecondary, size: .compact)
                GlassStatPill(value: String(format: "%.0f%%", opponent.winRate), label: "WR", color: opponent.winRate >= 50 ? DarkFantasyTheme.success : DarkFantasyTheme.danger, size: .compact)
                Spacer()
            }

            // Fight button
            Button {
                onFight()
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    if isFighting {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                    } else {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "swords")
                                .font(DarkFantasyTheme.caption)
                            Text("FIGHT")
                        }
                        if staminaCost > 0 {
                            Text("(\(staminaCost) STA)")
                                .font(DarkFantasyTheme.caption)
                        } else {
                            Text("FREE")
                                .font(DarkFantasyTheme.caption)
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                                .padding(.horizontal, LayoutConstants.spaceSM)
                                .padding(.vertical, LayoutConstants.space2XS)
                                .background(DarkFantasyTheme.bgDarkPanel)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .buttonStyle(.primary)
            .disabled(isFighting || !canFight)
        }
        .panelCard()
    }

    // MARK: - Stat Pill (uses shared GlassStatPill component)
}
