import SwiftUI

struct ItemCardView: View {
    let item: Item
    var equippedItem: Item?
    let onTap: () -> Void

    private var rarityColor: Color {
        DarkFantasyTheme.rarityColor(for: item.rarity)
    }

    /// Comparison vs currently equipped item in same slot
    private var comparisonDelta: Int? {
        guard item.isEquipped != true,
              item.itemType != .consumable,
              let equipped = equippedItem else { return nil }
        let diff = item.totalPower - equipped.totalPower
        return diff != 0 ? diff : nil
    }

    private var hasDurability: Bool {
        item.maxDurability != nil && (item.maxDurability ?? 0) > 0
    }

    private var durabilityFraction: Double {
        guard let max = item.maxDurability, max > 0 else { return 1.0 }
        return Double(item.durability ?? 0) / Double(max)
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
                    systemIcon: item.consumableIcon,
                    systemIconColor: item.consumableIconColor,
                    fallbackIcon: item.itemType.icon
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            .overlay(alignment: .topLeading) {
                // Comparison indicator vs equipped item
                if let delta = comparisonDelta {
                    Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold)) // SF Symbol icon — keep as is
                        .foregroundStyle(delta > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
                        .padding(3)
                        .background(
                            Circle()
                                .fill(DarkFantasyTheme.bgSecondary.opacity(0.9))
                        )
                        .padding(3)
                }
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
            // Rarity border
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        rarityColor.opacity(item.isEquipped == true ? 1.0 : 0.4),
                        lineWidth: item.isEquipped == true ? 2 : 1
                    )
            )
            // Durability ring contour (over rarity border, only when damaged)
            .overlay {
                if hasDurability && durabilityFraction < 1.0 {
                    DurabilityRingOverlay(
                        fraction: durabilityFraction,
                        cornerRadius: LayoutConstants.cardRadius
                    )
                }
            }
            .shadow(color: DarkFantasyTheme.rarityGlow(for: item.rarity), radius: item.rarity == .legendary ? 10 : 6)
        }
        .buttonStyle(.scalePress(0.95))
    }
}

// MARK: - Durability Ring Overlay (contour around icon)

struct DurabilityRingOverlay: View {
    let fraction: Double
    var cornerRadius: CGFloat = 12
    var lineWidth: CGFloat = 2.5

    private var durabilityColor: Color {
        DarkFantasyTheme.durabilityColor(fraction: fraction)
    }

    var body: some View {
        ZStack {
            // Dimmed background track
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(durabilityColor.opacity(0.15), lineWidth: lineWidth)

            // Filled portion
            RoundedRectangle(cornerRadius: cornerRadius)
                .trim(from: 0, to: fraction)
                .stroke(
                    durabilityColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .shadow(color: durabilityColor.opacity(0.5), radius: 3)
                // Start from top-center (default is right-center)
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2) // inset so stroke doesn't clip
    }
}
