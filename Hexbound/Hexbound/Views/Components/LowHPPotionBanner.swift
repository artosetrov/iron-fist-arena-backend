import SwiftUI

/// Banner shown on the Arena screen when the hero's HP is critically low (< 30%).
/// If the player has a health potion — offers to drink it immediately.
/// If no potions — directs to the shop (Potions tab).
struct LowHPPotionBanner: View {
    let character: Character
    let hasHealthPotion: Bool
    let onDrinkPotion: () -> Void
    let onGoToShop: () -> Void

    /// Show banner only when HP < 30%
    static func shouldShow(character: Character?) -> Bool {
        guard let char = character else { return false }
        return char.hpPercentage < 0.30 && char.currentHp > 0
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Potion icon
            Image("health_potion_small")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .breathing(scale: 0.06, isActive: true)

            // Text
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("Critical HP!")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.danger)

                Text(hasHealthPotion
                     ? "Drink a potion to restore health before your next fight."
                     : "You have no potions. Visit the shop to stock up!")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Action button — design system ButtonStyle
            Button {
                if hasHealthPotion {
                    onDrinkPotion()
                } else {
                    onGoToShop()
                }
            } label: {
                Text(hasHealthPotion ? "HEAL" : "SHOP")
            }
            .buttonStyle(.compactPrimary)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.danger.opacity(0.08),
                glowColor: DarkFantasyTheme.danger.opacity(0.04),
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.danger.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.danger.opacity(0.35), lineWidth: 1.5)
        )
        .cornerBrackets(color: DarkFantasyTheme.danger.opacity(0.4), length: 10, thickness: 1.2)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.danger.opacity(0.1), radius: 4, y: 1)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }
}
