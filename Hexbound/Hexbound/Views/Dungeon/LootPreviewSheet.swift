import SwiftUI

/// Modal sheet showing loot item details when tapped from boss card
struct LootPreviewSheet: View {
    let loot: LootPreview
    let onClose: () -> Void

    private var rarityColor: Color {
        DarkFantasyTheme.rarityColor(for: loot.rarity)
    }

    var body: some View {
        ZStack {
            // Backdrop
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
                    // Item image
                    ZStack {
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(rarityColor.opacity(0.15))

                        ItemImageView(
                            imageKey: loot.imageKey,
                            imageUrl: loot.imageUrl,
                            fallbackIcon: loot.icon
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius - 2))
                    }
                    .frame(width: 88, height: 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(rarityColor.opacity(0.5), lineWidth: 1)
                    )

                    // Info
                    VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                        Text(loot.name)
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                            .foregroundStyle(rarityColor)
                            .lineLimit(2)

                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text(loot.rarity.rawValue)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(rarityColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(rarityColor.opacity(0.15))
                                )
                                .overlay(
                                    Capsule().stroke(rarityColor.opacity(0.4), lineWidth: 1)
                                )
                        }

                        Text(loot.detail)
                            .font(DarkFantasyTheme.section(size: 14))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }

                    Spacer(minLength: 0)

                    // Close button
                    Button { onClose() } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.closeButton)
                }
                .padding(LayoutConstants.cardPadding)

                // Divider
                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(height: 1)

                // Drop info section
                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("ui-dice")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("DROP INFO")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .tracking(1.2)
                    }

                    HStack {
                        Text("Amount / Chance")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                        Spacer()
                        Text(loot.detail)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            .foregroundStyle(rarityColor)
                    }
                }
                .padding(LayoutConstants.cardPadding)

                // Description
                if loot.rarity != .common {
                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)

                    Text(lootFlavorText(for: loot))
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).italic())
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(LayoutConstants.cardPadding)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(rarityColor.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .fixedSize(horizontal: false, vertical: true)
        }
        .presentationBackground(.clear)
        .presentationDetents([.medium])
    }

    private func lootFlavorText(for loot: LootPreview) -> String {
        // Generic flavor text based on rarity
        switch loot.rarity {
        case .legendary:
            return "A weapon of legend. Few have seen it, fewer have wielded it."
        case .epic:
            return "Forged in battle and tempered by blood. A prize worthy of champions."
        case .rare:
            return "Not easily found. This item holds power beyond the ordinary."
        case .uncommon:
            return "A step above the mundane. Useful for those who seek an edge."
        default:
            return ""
        }
    }
}
