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
                CurrencyDisplay(
                    gold: item.isGemPurchase ? 0 : item.goldPrice,
                    gems: item.isGemPurchase ? item.gemPrice : nil,
                    size: .mini,
                    currencyType: item.isGemPurchase ? .gems : .gold,
                    animated: false
                )
                .padding(.horizontal, LayoutConstants.spaceXS)
                .padding(.vertical, LayoutConstants.space2XS)
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
