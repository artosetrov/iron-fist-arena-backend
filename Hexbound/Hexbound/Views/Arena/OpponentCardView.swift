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

                VStack(alignment: .leading, spacing: 2) {
                    Text(opponent.characterName)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("Lv.\(opponent.level)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text(opponent.characterClass.displayName)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.classColor(for: opponent.characterClass))

                        Text(difficultyLabel)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                            .foregroundStyle(difficultyColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(difficultyColor.opacity(0.15))
                            )
                    }
                }

                Spacer()

                // Rating badge
                VStack(spacing: 2) {
                    Text("\(opponent.pvpRating)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                        .foregroundStyle(DarkFantasyTheme.rankColor(for: opponent.pvpRating))
                    Text(opponent.rank.icon)
                        .font(.system(size: 14))
                }
            }

            // Stats row
            HStack(spacing: LayoutConstants.spaceMD) {
                statPill(label: "HP", value: "\(opponent.maxHp)", color: DarkFantasyTheme.danger)
                statPill(label: "W/L", value: "\(opponent.pvpWins)/\(opponent.pvpLosses)", color: DarkFantasyTheme.textSecondary)
                statPill(label: "WR", value: String(format: "%.0f%%", opponent.winRate), color: opponent.winRate >= 50 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
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
                        Text("⚔️ FIGHT")
                        if staminaCost > 0 {
                            Text("(\(staminaCost) STA)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        } else {
                            Text("(FREE)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .foregroundStyle(DarkFantasyTheme.success)
                        }
                    }
                }
            }
            .buttonStyle(.primary)
            .disabled(isFighting || !canFight)
        }
        .panelCard()
    }

    @ViewBuilder
    private func statPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).bold())
                .foregroundStyle(color)
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }
}
