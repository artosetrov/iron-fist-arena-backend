import SwiftUI

struct CurrencyDisplay: View {
    let gold: Int
    var gems: Int? = nil
    var showAddButton: Bool = false
    var onAdd: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
<<<<<<< HEAD
            // Gold (animated tick-up)
=======
            // Gold
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-gold")
                    .resizable()
                    .scaledToFit()
<<<<<<< HEAD
                    .frame(width: 36, height: 36)
                NumberTickUpText(
                    value: gold,
                    color: DarkFantasyTheme.goldBright,
                    font: DarkFantasyTheme.section(size: 28)
                )
            }
            .accessibilityLabel("Gold: \(gold)")

            // Gems (animated tick-up)
=======
                    .frame(width: 18, height: 18)
                Text(formatGold(gold))
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            // Gems
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
            if let gems = gems, gems > 0 {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gems")
                        .resizable()
                        .scaledToFit()
<<<<<<< HEAD
                        .frame(width: 36, height: 36)
                    NumberTickUpText(
                        value: gems,
                        color: DarkFantasyTheme.cyan,
                        font: DarkFantasyTheme.section(size: 28)
                    )
=======
                        .frame(width: 18, height: 18)
                    Text("\(gems)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.cyan)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
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
