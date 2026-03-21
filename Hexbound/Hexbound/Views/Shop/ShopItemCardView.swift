import SwiftUI

struct ShopItemCardView: View {
    let item: ShopItem
    let canAfford: Bool
    let meetsLevel: Bool
    let isBuying: Bool
    let onTap: () -> Void

    private var rarityColor: Color {
        DarkFantasyTheme.rarityColor(for: item.rarity)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(rarityColor.opacity(0.15))

                // Icon or image — centered
                if isBuying {
                    ProgressView()
                        .tint(DarkFantasyTheme.gold)
                } else {
                    ItemImageView(
                        imageKey: item.imageKey,
                        imageUrl: item.imageUrl,
                        systemIcon: item.consumableIcon,
                        systemIconColor: item.consumableIconColor,
                        fallbackIcon: item.typeIcon
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .overlay(alignment: .bottom) {
                // Price bar at bottom
                HStack(spacing: 2) {
<<<<<<< HEAD
                    Image(systemName: item.isGemPurchase ? "diamond" : "dollarsign.circle")
                        .font(.system(size: 14))
=======
                    Text(item.isGemPurchase ? "💎" : "💰")
                        .font(.system(size: 16))
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                    Text(item.isGemPurchase ? "\(item.gemPrice)" : "\(item.goldPrice)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(
                            item.isGemPurchase ? DarkFantasyTheme.cyan : DarkFantasyTheme.goldBright
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(.bgAbyss.opacity(0.45))
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: LayoutConstants.cardRadius,
                        bottomTrailingRadius: LayoutConstants.cardRadius,
                        topTrailingRadius: 0
                    )
                )
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        canAfford && meetsLevel ? rarityColor.opacity(0.5) : DarkFantasyTheme.borderSubtle,
                        lineWidth: 1
                    )
            )
            .opacity(canAfford && meetsLevel ? 1.0 : 0.5)
        }
        .buttonStyle(.scalePress(0.95))
    }
}
