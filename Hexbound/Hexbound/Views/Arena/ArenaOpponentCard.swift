import SwiftUI

/// Opponent card — vertical layout with avatar, name, rating, stats.
struct ArenaOpponentCard: View {
    let opponent: Opponent
    let playerRating: Int
    let onTap: () -> Void

    private var ratingDiff: Int { opponent.pvpRating - playerRating }

    private var difficulty: OpponentDifficulty {
        if ratingDiff < -200 { return .easy }
        if ratingDiff < 200 { return .medium }
        return .hard
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: LayoutConstants.spaceSM) {
                // Avatar
                AvatarImageView(
                    skinKey: opponent.avatar,
                    characterClass: opponent.characterClass,
                    size: 96
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DarkFantasyTheme.borderMedium, lineWidth: 2)
                )

                // Name
                Text(opponent.characterName)
                    .font(DarkFantasyTheme.section(size: 15))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                // Class + Level
                Text("Lv.\(opponent.level) \(opponent.characterClass.displayName.uppercased())")
                    .font(DarkFantasyTheme.body(size: 12).bold())
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .lineLimit(1)

                // Rating
                Text("\(opponent.pvpRating)")
                    .font(DarkFantasyTheme.section(size: 20))
                    .foregroundStyle(DarkFantasyTheme.info)

                // Stats — label left, value right
                VStack(spacing: 5) {
                    inlineStat("Attack", value: opponent.strength ?? 0, color: DarkFantasyTheme.danger)
                    inlineStat("Defense", value: opponent.vitality ?? 0, color: DarkFantasyTheme.info)
                    inlineStat("Win Rate", value: Int(opponent.winRate), color: DarkFantasyTheme.success, suffix: "%")
                }
            }
            .padding(LayoutConstants.bannerPadding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        DarkFantasyTheme.bgArenaCard
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(difficulty.borderColor, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                difficultyBadge
            }
            .shadow(color: difficulty.borderColor.opacity(0.2), radius: 8, y: 2)
        }
        .buttonStyle(.scalePress(0.96))
    }

    // MARK: - Difficulty Badge

    private var difficultyBadge: some View {
        Text(difficulty.label)
            .font(DarkFantasyTheme.body(size: 10).bold())
            .foregroundStyle(difficulty.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(difficulty.textColor.opacity(0.15))
            )
            .padding(LayoutConstants.spaceSM)
    }

    // MARK: - Inline Stat (label left, value right)

    @ViewBuilder
    private func inlineStat(_ label: String, value: Int, color: Color, suffix: String = "") -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Spacer()
            Text("\(value)\(suffix)")
                .font(DarkFantasyTheme.section(size: 13))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Opponent Difficulty

enum OpponentDifficulty {
    case easy, medium, hard

    var label: String {
        switch self {
        case .easy: "EASY"
        case .medium: "MEDIUM"
        case .hard: "HARD"
        }
    }

    var borderColor: Color {
        switch self {
        case .easy: DarkFantasyTheme.difficultyEasy.opacity(0.4)
        case .medium: DarkFantasyTheme.difficultyMedium.opacity(0.4)
        case .hard: DarkFantasyTheme.difficultyHard.opacity(0.4)
        }
    }

    var textColor: Color {
        switch self {
        case .easy: DarkFantasyTheme.difficultyEasy
        case .medium: DarkFantasyTheme.difficultyMedium
        case .hard: DarkFantasyTheme.difficultyHard
        }
    }
}

