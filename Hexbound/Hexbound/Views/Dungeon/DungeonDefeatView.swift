import SwiftUI

struct DungeonDefeatView: View {
    let vm: DungeonRoomViewModel

    var body: some View {
        BattleResultCardView(config: buildConfig())
    }

    private func buildConfig() -> BattleResultConfig {
        let boss = vm.dungeon?.bosses[safe: vm.selectedBossIndex] ?? vm.selectedBoss
        let subtitle = boss.map { "Defeated by \($0.name)" } ?? "You have fallen"

        // Show progress earned during the run even on defeat.
        // Bug #16: honour Training Camp label too.
        let dungeonProgress: DungeonProgressConfig? = {
            guard let total = vm.dungeon?.totalBosses, total > 0 else { return nil }
            let isTraining = vm.dungeon?.id.contains("training") ?? false
            return DungeonProgressConfig(
                defeated: vm.defeatFloorsCleared,
                total: total,
                isComplete: false,
                progressLabel: isTraining ? "Training Progress" : "Dungeon Progress",
                completeLabel: isTraining ? "TRAINING COMPLETE!" : "DUNGEON CLEARED!"
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
