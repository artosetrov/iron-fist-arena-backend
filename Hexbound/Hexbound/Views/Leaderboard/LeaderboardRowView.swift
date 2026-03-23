import SwiftUI

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let isSelf: Bool
    let valueLabel: String
    let onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Rank
            Text("#\(entry.rank)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(rankColor)
                .frame(width: 40, alignment: .leading)

            // Class icon
            Text(entry.classIcon)
                .font(.system(size: 18)) // emoji text — keep as is
                .frame(width: 28)

            // Name
            Text(entry.characterName)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(isSelf ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            // Value
            Text(formattedValue)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(isSelf ? DarkFantasyTheme.gold.opacity(0.08) : DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(isSelf ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: isSelf ? 2 : 1)
        )
        .onTapGesture {
            if !isSelf { onTap?() }
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
