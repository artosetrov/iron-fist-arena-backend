import SwiftUI

/// Bottom sheet for comparing player stats vs opponent before a fight.
/// Shows VS header, equipment comparison, full stat comparison (combat + base stats), win prediction, and fight CTA.
struct ArenaComparisonSheet: View {
    let opponent: Opponent
    let character: Character
    let isFighting: Bool
    let canFight: Bool
    let staminaCost: Int
    let onFight: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(GameDataCache.self) private var cache
    @Environment(AppState.self) private var appState
    // confirmation dialog removed — fight triggers directly

    private var winChance: Int {
        ArenaComparisonSheet.estimateWinChance(char: character, opponent: opponent)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle + Close button
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.textTertiary)
                    .frame(width: 36, height: 4)

                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.closeButton)
                    .padding(.trailing, LayoutConstants.screenPadding)
                }
            }
            .padding(.top, LayoutConstants.spaceMD)
            .padding(.bottom, LayoutConstants.spaceSM)

            ScrollView {
                VStack(spacing: LayoutConstants.spaceMD) {
                    // VS Header
                    vsHeader

                    // Combat Stats
                    combatStatsSection

                    // Base Stats
                    baseStatsSection

                    // Win Rate & Record
                    winRateSection

                    // Win chance prediction
                    winPrediction
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceSM)
            }

            // Fight button pinned to bottom
            fightButton
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.safeAreaBottom + LayoutConstants.spaceSM)
                .padding(.top, LayoutConstants.spaceXS)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(DarkFantasyTheme.bgArenaSheet)
        .presentationCornerRadius(20)
    }

    // MARK: - VS Header

    private var vsHeader: some View {
        HStack(spacing: LayoutConstants.spaceLG) {
            // My avatar
            VStack(spacing: LayoutConstants.spaceSM) {
                AvatarImageView(
                    skinKey: character.avatar,
                    characterClass: character.characterClass,
                    size: 100
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXL))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                        .stroke(DarkFantasyTheme.success, lineWidth: 2)
                )
                .shadow(color: DarkFantasyTheme.success.opacity(0.3), radius: 8)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 3, y: 2)

                Text(character.characterName)
                    .font(DarkFantasyTheme.section(size: 15))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                Text("Lv.\(character.level) \(character.characterClass.displayName)")
                    .font(DarkFantasyTheme.body(size: 12).bold())
                    .foregroundStyle(DarkFantasyTheme.gold)
            }

            // VS
            Text("VS")
                .font(DarkFantasyTheme.title(size: 32))
                .foregroundStyle(DarkFantasyTheme.gold)

            // Opponent avatar (mirrored to face player)
            VStack(spacing: LayoutConstants.spaceSM) {
                AvatarImageView(
                    skinKey: opponent.avatar,
                    characterClass: opponent.characterClass,
                    size: 100
                )
                .scaleEffect(x: -1, y: 1)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXL))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                        .stroke(DarkFantasyTheme.danger, lineWidth: 2)
                )
                .shadow(color: DarkFantasyTheme.danger.opacity(0.3), radius: 8)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 3, y: 2)

                Text(opponent.characterName)
                    .font(DarkFantasyTheme.section(size: 15))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                Text("Lv.\(opponent.level) \(opponent.characterClass.displayName)")
                    .font(DarkFantasyTheme.body(size: 12).bold())
                    .foregroundStyle(DarkFantasyTheme.gold)
            }
        }
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        let playerItems = appState.cachedInventory?.filter { $0.isEquipped == true } ?? []
        
        return VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("Equipment")

            HStack(spacing: LayoutConstants.spaceLG) {
                // Player equipment
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("YOUR GEAR")
                        .font(DarkFantasyTheme.body(size: 10))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .tracking(1)

                    equippedItemsGrid(items: playerItems)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 120)
                    .overlay(DarkFantasyTheme.borderSubtle)

                // Opponent placeholder
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("OPPONENT")
                        .font(DarkFantasyTheme.body(size: 10))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .tracking(1)

                    opponentPlaceholder
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.4), length: 12, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }

    private func equippedItemsGrid(items: [Item]) -> some View {
        VStack(spacing: LayoutConstants.equipmentGap) {
            ForEach(Array(stride(from: 0, to: max(1, items.count), by: 3)), id: \.self) { rowStart in
                HStack(spacing: LayoutConstants.equipmentGap) {
                    ForEach(0..<3, id: \.self) { colIndex in
                        let itemIndex = rowStart + colIndex
                        if itemIndex < items.count {
                            equippedItemSlot(items[itemIndex])
                        } else {
                            emptyItemSlot
                        }
                    }
                }
            }
        }
    }

    private func equippedItemSlot(_ item: Item) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Item background
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgDarkPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .stroke(DarkFantasyTheme.rarityColor(for: item.rarity), lineWidth: 1.5)
                    )
                    .frame(height: 60)

                // Item image
                ItemImageView(
                    imageKey: item.resolvedImageKey,
                    imageUrl: item.imageUrl,
                    fallbackIcon: "📦"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                // Rarity badge
                Text(item.rarity.displayName.prefix(1).uppercased())
                    .font(DarkFantasyTheme.body(size: 9).bold())
                    .foregroundStyle(.white)
                    .padding(3)
                    .background(Circle().fill(DarkFantasyTheme.rarityColor(for: item.rarity)))
                    .padding(4)
            }

            // Item name
            Text(item.displayName)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)
        }
    }

    private var emptyItemSlot: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgDarkPanel.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(DarkFantasyTheme.borderSubtle, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
                .frame(height: 60)

            Text("Empty")
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }

    private var opponentPlaceholder: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceSM) {
                // Class icon
                Text(opponent.characterClass.icon)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 2) {
                    Text(opponent.characterClass.displayName)
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)

                    Text("Lv. \(opponent.level)")
                        .font(DarkFantasyTheme.body(size: 10))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                Spacer()
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgDarkPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )

            Text("Equipment data\nunavailable")
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Combat Stats Section

    private var combatStatsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("Combat Stats")

            statRow(label: "Attack", myValue: character.attackPower, theirValue: opponent.strength ?? 0)
            statRow(label: "Defense", myValue: character.armor ?? 0, theirValue: opponent.vitality ?? 0)
            statRow(label: "HP", myValue: character.maxHp, theirValue: opponent.maxHp)
            statRow(label: "Speed", myValue: character.agility ?? 0, theirValue: opponent.agility ?? 0)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.4), length: 12, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }

    // MARK: - Base Stats Section

    private var baseStatsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("Base Stats")

            statRow(label: "Strength", myValue: character.strength ?? 0, theirValue: opponent.strength ?? 0)
            statRow(label: "Agility", myValue: character.agility ?? 0, theirValue: opponent.agility ?? 0)
            statRow(label: "Vitality", myValue: character.vitality ?? 0, theirValue: opponent.vitality ?? 0)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.4), length: 12, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DarkFantasyTheme.body(size: 12))
            .foregroundStyle(DarkFantasyTheme.textTertiary)
            .tracking(2)
    }

    @ViewBuilder
    private func statRow(label: String, myValue: Int, theirValue: Int) -> some View {
        HStack {
            Text("\(myValue)")
                .font(DarkFantasyTheme.section(size: 18))
                .foregroundStyle(statColor(my: myValue, their: theirValue))
                .frame(width: 70, alignment: .trailing)

            Spacer()

            Text(label)
                .font(DarkFantasyTheme.body(size: 13))
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Spacer()

            Text("\(theirValue)")
                .font(DarkFantasyTheme.section(size: 18))
                .foregroundStyle(statColor(my: theirValue, their: myValue))
                .frame(width: 70, alignment: .leading)
        }
    }

    private func statColor(my: Int, their: Int) -> Color {
        if my > their { return DarkFantasyTheme.success }
        if my < their { return DarkFantasyTheme.danger }
        return DarkFantasyTheme.textTertiary
    }

    // MARK: - Win Rate Section

    private var winRateSection: some View {
        let myWR = character.pvpWins + character.pvpLosses > 0
            ? Int(Double(character.pvpWins) / Double(character.pvpWins + character.pvpLosses) * 100)
            : 0

        return VStack(spacing: LayoutConstants.spaceSM) {
            statRow(label: "Win Rate", myValue: myWR, theirValue: Int(opponent.winRate))
            statRow(label: "W/L", myValue: character.pvpWins, theirValue: opponent.pvpWins)
        }
        .padding(.horizontal, LayoutConstants.cardPadding)
    }

    // MARK: - Win Prediction

    private var winPrediction: some View {
        HStack(spacing: 6) {
            Text("Estimated win chance:")
                .font(DarkFantasyTheme.body(size: 15))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Text("\(winChance)%")
                .font(DarkFantasyTheme.section(size: 20))
                .foregroundStyle(winChanceColor)
        }
    }

    private var winChanceColor: Color {
        if winChance >= 65 { return DarkFantasyTheme.success }
        if winChance >= 40 { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.danger
    }

    // MARK: - Fight Button

    private var fightButton: some View {
        Button {
            HapticManager.heavy()
            onFight()
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                if isFighting {
                    ProgressView()
                        .tint(.textPrimary)
                } else {
                    Text("FIGHT")
                    if staminaCost > 0 {
                        Text("(\(staminaCost) STA)")
                            .font(DarkFantasyTheme.body(size: 13))
                    } else {
                        Text("FREE")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .padding(.horizontal, LayoutConstants.spaceSM)
                            .padding(.vertical, LayoutConstants.space2XS)
                            .background(DarkFantasyTheme.bgDarkPanel)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .buttonStyle(.fight)
        .disabled(isFighting || !canFight)
    }

    // MARK: - Win Chance Calculation

    static func estimateWinChance(char: Character, opponent: Opponent) -> Int {
        let myAtk = Double(char.attackPower)
        let myDef = Double(char.armor ?? 0)
        let myHp = Double(char.maxHp)
        let mySpd = Double(char.agility ?? 0)

        let theirAtk = Double(opponent.strength ?? 0)
        let theirDef = Double(opponent.vitality ?? 0)
        let theirHp = Double(opponent.maxHp)
        let theirSpd = Double(opponent.agility ?? 0)

        let myPower = (myAtk + myDef) + myHp / 2.0 + mySpd * 2.0
        let theirPower = (theirAtk + theirDef) + theirHp / 2.0 + theirSpd * 2.0

        let chance = 50.0 + (myPower - theirPower) / 5.0
        return min(95, max(15, Int(chance.rounded())))
    }
}
