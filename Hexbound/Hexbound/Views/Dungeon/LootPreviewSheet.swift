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
                    // Item image — unified ItemCardView
                    ItemCardView(loot: loot, context: .preview) { }
                        .frame(width: 88, height: 88)

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
                                .padding(.horizontal, LayoutConstants.spaceXS)
                                .padding(.vertical, LayoutConstants.space2XS)
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
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.08, bottomShadow: 0.14)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: rarityColor.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(rarityColor.opacity(0.5), lineWidth: 2)
            )
            .cornerBrackets(color: rarityColor.opacity(0.5), length: 18, thickness: 2.0)
            .cornerDiamonds(color: rarityColor.opacity(0.4), size: 6)
            .shadow(color: rarityColor.opacity(0.18), radius: 10, y: 0)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            .fixedSize(horizontal: false, vertical: true)
        }
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
