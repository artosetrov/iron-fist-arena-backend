import SwiftUI

struct OpponentCardView: View {
    let opponent: Opponent
    let isFighting: Bool
    let canFight: Bool
    let staminaCost: Int
    let onFight: () -> Void
    var playerRating: Int = 0
    var playerLevel: Int = 1
    var playerAttackPower: Int = 0
    var playerArmor: Int = 0

    /// Composite threat ratio: compares combined power (rating + attack + armor + level×10)
    private var threatRatio: Double {
        let myPower = Double(playerRating) + Double(playerAttackPower) + Double(playerArmor) + Double(playerLevel * 10)
        let oppPower = Double(opponent.pvpRating) + Double(opponent.attackPower) + Double(opponent.armor ?? 0) + Double(opponent.level * 10)
        return oppPower / max(myPower, 1)
    }

    private var difficultyLabel: String {
        if threatRatio < 0.85 { return "Easy" }
        if threatRatio < 0.95 { return "Fair" }
        if threatRatio > 1.15 { return "Hard" }
        if threatRatio > 1.05 { return "Tough" }
        return "Medium"
    }

    private var difficultyColor: Color {
        if threatRatio < 0.85 { return DarkFantasyTheme.success }
        if threatRatio < 0.95 { return DarkFantasyTheme.textSecondary }
        if threatRatio > 1.15 { return DarkFantasyTheme.danger }
        if threatRatio > 1.05 { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.textSecondary
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Top row: class icon + name + level
            HStack {
                // Avatar — deterministicSeed falls back to a stable class-pool portrait
                AvatarImageView(
                    skinKey: opponent.avatar,
                    characterClass: opponent.characterClass,
                    size: 44,
                    deterministicSeed: opponent.id
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
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text(opponent.characterClass.displayName)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.classColor(for: opponent.characterClass))

                        Text(difficultyLabel)
                            .font(DarkFantasyTheme.body.weight(.semibold))
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
                        .font(DarkFantasyTheme.body.weight(.semibold))
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
                        HexPulseLoader(.compact)
                            .tint(DarkFantasyTheme.textOnGold)
                    } else {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "swords")
                                .font(DarkFantasyTheme.body)
                            Text("FIGHT")
                        }
                        if staminaCost > 0 {
                            Text("(\(staminaCost) STA)")
                                .font(DarkFantasyTheme.body)
                        } else {
                            Text("FREE")
                                .font(DarkFantasyTheme.body)
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
