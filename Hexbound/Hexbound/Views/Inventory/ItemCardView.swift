import SwiftUI

struct ItemCardView: View {
    let item: Item
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
                ItemImageView(
                    imageKey: item.imageKey,
                    imageUrl: item.imageUrl,
                    fallbackIcon: item.itemType.icon
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            .overlay(alignment: .topTrailing) {
                // Equipped badge
                if item.isEquipped == true {
                    Text("E")
                        .font(DarkFantasyTheme.body(size: 9).bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(DarkFantasyTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                }
            }
            .overlay(alignment: .bottomLeading) {
                // Upgrade dots
                if let upg = item.upgradeLevel, upg > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<upg, id: \.self) { _ in
                            Circle()
                                .fill(DarkFantasyTheme.gold)
                                .frame(width: 5, height: 5)
                                .shadow(color: DarkFantasyTheme.goldGlow, radius: 2)
                        }
                    }
                    .padding(4)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Quantity badge for consumables
                if let qty = item.quantity, qty > 1 {
                    Text("x\(qty)")
                        .font(DarkFantasyTheme.body(size: 10).bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(DarkFantasyTheme.bgElevated.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        rarityColor.opacity(item.isEquipped == true ? 1.0 : 0.4),
                        lineWidth: item.isEquipped == true ? 2 : 1
                    )
            )
            .shadow(color: DarkFantasyTheme.rarityGlow(for: item.rarity), radius: item.rarity == .legendary ? 10 : 6)
        }
        .buttonStyle(.plain)
    }
}
