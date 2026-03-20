import SwiftUI

struct CurrencyDisplay: View {
    let gold: Int
    var gems: Int? = nil
    var showAddButton: Bool = false
    var onAdd: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Gold
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-gold")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(formatGold(gold))
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            // Gems
            if let gems = gems, gems > 0 {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gems")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text("\(gems)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
            }

            if showAddButton {
                Button {
                    onAdd?()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            }
        }
    }

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
