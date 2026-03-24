import SwiftUI

struct LeaderboardRowView: View {
    @Environment(GameDataCache.self) private var cache
    let entry: LeaderboardEntry
    let isSelf: Bool
    let valueLabel: String
    let onTap: (() -> Void)?

    private let avatarSize: CGFloat = 40

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Rank badge
            rankBadge

            // Portrait
            portraitView

            // Name + class
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.characterName)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(isSelf ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(className)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    if let lvl = entry.level {
                        Text("Lv.\(lvl)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Value
            Text(formattedValue)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .frame(minWidth: 50, alignment: .trailing)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS + 2)
        .background(
            RadialGlowBackground(
                baseColor: isSelf ? DarkFantasyTheme.gold.opacity(0.06) : DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 1, inset: 1,
                     color: isSelf ? DarkFantasyTheme.gold.opacity(0.2) : DarkFantasyTheme.borderSubtle.opacity(0.3))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.2), radius: 2, y: 1)
        .onTapGesture {
            if !isSelf { onTap?() }
        }
    }

    // MARK: - Rank Badge

    private var rankBadge: some View {
        ZStack {
            if entry.rank <= 3 {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 28, height: 28)
            }
            Text("\(entry.rank)")
                .font(DarkFantasyTheme.section(size: entry.rank <= 3 ? LayoutConstants.textLabel : LayoutConstants.textBadge))
                .foregroundStyle(rankColor)
        }
        .frame(width: 30)
    }

    // MARK: - Portrait

    private var portraitView: some View {
        let charClass = CharacterClass(rawValue: entry.characterClass) ?? .warrior
        return AvatarImageView(
            skinKey: entry.avatar,
            characterClass: charClass,
            size: avatarSize
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(isSelf ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: 1.5)
        )
    }

    // MARK: - Helpers

    private var className: String {
        switch entry.characterClass {
        case "warrior": "Warrior"
        case "rogue": "Rogue"
        case "mage": "Mage"
        case "tank": "Tank"
        default: entry.characterClass.capitalized
        }
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: DarkFantasyTheme.goldBright
        case 2: DarkFantasyTheme.rankSilver
        case 3: DarkFantasyTheme.rankBronze
        default: DarkFantasyTheme.textSecondary
        }
    }

    private var formattedValue: String {
        if entry.value >= 10000 {
            return "\(entry.value / 1000)k"
        }
        return "\(entry.value)"
    }
}
