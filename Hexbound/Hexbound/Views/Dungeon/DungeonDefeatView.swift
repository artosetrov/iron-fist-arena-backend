import SwiftUI

struct DungeonDefeatView: View {
    let vm: DungeonRoomViewModel

    var body: some View {
        BattleResultCardView(config: buildConfig())
    }

    private func buildConfig() -> BattleResultConfig {
        let boss = vm.dungeon?.bosses[safe: vm.selectedBossIndex] ?? vm.selectedBoss
        let subtitle = boss.map { "Defeated by \($0.name)" } ?? "You have fallen"

        // Show progress earned during the run even on defeat
        let dungeonProgress: DungeonProgressConfig? = {
            guard let total = vm.dungeon?.totalBosses, total > 0 else { return nil }
            return DungeonProgressConfig(
                defeated: vm.defeatFloorsCleared,
                total: total,
                isComplete: false
            )
        }()

        let buttons: [ResultButton] = [
            ResultButton(title: "TRY AGAIN", icon: "arrow.clockwise", style: .primary) {
                withAnimation { vm.dismissDefeat() }
            }
        ]

        return BattleResultConfig(
            isVictory: false,
            title: "DEFEATED",
            subtitle: subtitle,
            illustrationImage: nil,
            goldReward: vm.defeatTotalGold > 0 ? vm.defeatTotalGold : nil,
            xpReward: vm.defeatTotalXP > 0 ? vm.defeatTotalXP : nil,
            ratingChange: nil,
            firstWinBonus: false,
            xpBarConfig: nil,
            dungeonProgress: dungeonProgress,
            lootItems: [],
            onLootTap: nil,
            buttons: buttons
        )
    }
}
