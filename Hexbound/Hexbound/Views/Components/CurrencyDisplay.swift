import SwiftUI

struct CurrencyDisplay: View {
    let gold: Int
    var gems: Int? = nil
    var showAddButton: Bool = false
    var onAdd: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Gold (animated tick-up)
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-gold")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                NumberTickUpText(
                    value: gold,
                    color: DarkFantasyTheme.goldBright,
                    font: DarkFantasyTheme.section(size: 28)
                )
            }
            .accessibilityLabel("Gold: \(gold)")

            // Gems (animated tick-up)
            if let gems = gems, gems > 0 {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gems")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                    NumberTickUpText(
                        value: gems,
                        color: DarkFantasyTheme.cyan,
                        font: DarkFantasyTheme.section(size: 28)
                    )
                }
                .accessibilityLabel("Gems: \(gems)")
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
                .accessibilityLabel("Buy currency")
            }
        }
    }
}
