import SwiftUI

/// Bottom sheet for comparing player stats vs opponent before a fight.
struct ArenaComparisonSheet: View {
    let opponent: Opponent
    let character: Character
    let isFighting: Bool
    let canFight: Bool
    let staminaCost: Int
    let onFight: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(GameDataCache.self) private var cache
    @State private var showStaminaConfirm = false

    private var winChance: Int {
        ArenaComparisonSheet.estimateWinChance(char: character, opponent: opponent)
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(DarkFantasyTheme.textTertiary)
                .frame(width: 36, height: 4)
                .padding(.top, LayoutConstants.spaceMD)

            // VS Header
            vsHeader

            // Combat Stats
            combatStatsSection

            // Win Rate & Record
            winRateSection

            // Win chance prediction
            winPrediction

            // Fight button
            fightButton
                .padding(.top, LayoutConstants.spaceXS)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.safeAreaBottom + LayoutConstants.spaceSM)
        .presentationDetents([.height(560)])
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
                    size: 80
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(DarkFantasyTheme.success, lineWidth: 2)
                )
                .shadow(color: DarkFantasyTheme.success.opacity(0.3), radius: 8)

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

            // Opponent avatar
            VStack(spacing: LayoutConstants.spaceSM) {
                AvatarImageView(
                    skinKey: opponent.avatar,
                    characterClass: opponent.characterClass,
                    size: 80
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(DarkFantasyTheme.danger, lineWidth: 2)
                )
                .shadow(color: DarkFantasyTheme.danger.opacity(0.3), radius: 8)

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

    // MARK: - Combat Stats Section

    private var combatStatsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("COMBAT STATS")
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            statRow(label: "Attack", myValue: character.attackPower, theirValue: opponent.strength ?? 0)
            statRow(label: "Defense", myValue: character.armor ?? 0, theirValue: opponent.vitality ?? 0)
            statRow(label: "HP", myValue: character.maxHp, theirValue: opponent.maxHp)
            statRow(label: "Speed", myValue: character.agility ?? 0, theirValue: opponent.agility ?? 0)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
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
            if staminaCost > 0 {
                showStaminaConfirm = true
            } else {
                onFight()
            }
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                if isFighting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("FIGHT")
                    if staminaCost > 0 {
                        Text("(\(staminaCost) STA)")
                            .font(DarkFantasyTheme.body(size: 13))
                    } else {
                        Text("(FREE)")
                            .font(DarkFantasyTheme.body(size: 13))
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                }
            }
        }
        .buttonStyle(.fight)
        .disabled(isFighting || !canFight)
        .confirmationDialog(
            "SPEND STAMINA",
            isPresented: $showStaminaConfirm,
            presenting: staminaCost
        ) { cost in
            Button("Fight (\(cost) STA)") {
                onFight()
            }
            Button("Cancel", role: .cancel) { }
        } message: { cost in
            Text("Spend \(cost) stamina to fight \(opponent.characterName)?")
        }
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
