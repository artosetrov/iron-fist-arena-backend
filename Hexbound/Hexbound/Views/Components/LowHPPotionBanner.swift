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
            Image("pot_health_small")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .breathing(scale: 0.06, isActive: true)

            // Text
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("Critical HP!")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.danger)

                Text(hasHealthPotion
                     ? "Drink a potion to restore health before your next fight."
                     : "You have no potions. Visit the shop to stock up!")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Action button
            Button {
                if hasHealthPotion {
                    onDrinkPotion()
                } else {
                    onGoToShop()
                }
            } label: {
                Text(hasHealthPotion ? "HEAL" : "SHOP")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(hasHealthPotion ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.goldBright)
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.vertical, LayoutConstants.spaceSM)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(hasHealthPotion ? DarkFantasyTheme.gold : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .stroke(hasHealthPotion ? Color.clear : DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.scalePress(0.9))
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.danger.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.danger.opacity(0.35), lineWidth: 1.5)
        )
    }
}
