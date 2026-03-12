import SwiftUI

/// Compact hero summary widget for use on focused gameplay screens (dungeon, combat).
/// Shows avatar, name, class, level, HP, stamina, XP, and optionally currencies.
struct CompactHeroWidget: View {
    let character: Character
    var showCurrencies: Bool = false

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    var body: some View {
        HStack(spacing: 10) {
            // Avatar with level badge
            ZStack(alignment: .bottomTrailing) {
                AvatarImageView(
                    skinKey: character.avatar,
                    characterClass: character.characterClass,
                    size: 48
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DarkFantasyTheme.gold, lineWidth: 2)
                )
                .frame(width: 48, height: 48)

                // Level badge
                Text("\(character.level)")
                    .font(DarkFantasyTheme.section(size: 9).bold())
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(DarkFantasyTheme.gold))
                    .offset(x: 3, y: 3)
            }

            // Info column
            VStack(alignment: .leading, spacing: 3) {
                // Name + class
                HStack(spacing: 4) {
                    Text(character.characterName)
                        .font(DarkFantasyTheme.section(size: 12))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .lineLimit(1)

                    Text(character.characterClass.displayName)
                        .font(DarkFantasyTheme.body(size: 10))
                        .foregroundStyle(DarkFantasyTheme.classColor(for: character.characterClass))
                        .lineLimit(1)
                }

                // HP bar
                HubStatBar(
                    label: "HP",
                    valueText: "\(character.currentHp)/\(character.maxHp)",
                    percentage: character.hpPercentage,
                    color: DarkFantasyTheme.hpBlood
                )

                // Stamina bar
                HubStatBar(
                    label: "SP",
                    valueText: "\(character.currentStamina)/\(character.maxStamina)",
                    percentage: character.staminaPercentage,
                    color: DarkFantasyTheme.stamina
                )

                // XP bar
                HubStatBar(
                    label: "XP",
                    valueText: "\(Int(character.xpPercentage * 100))%",
                    percentage: character.xpPercentage,
                    color: DarkFantasyTheme.cyan
                )
            }

            // Optional compact currency display
            if showCurrencies {
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 3) {
                        Image("icon-gold")
                            .resizable()
                            .frame(width: 14, height: 14)
                        Text(formatGold(character.gold))
                            .font(DarkFantasyTheme.body(size: 10))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .monospacedDigit()
                    }
                    HStack(spacing: 3) {
                        Image("icon-gems")
                            .resizable()
                            .frame(width: 14, height: 14)
                        Text("\(character.gems ?? 0)")
                            .font(DarkFantasyTheme.body(size: 10))
                            .foregroundStyle(DarkFantasyTheme.cyan)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
        )
    }
}
