import SwiftUI

struct DungeonVictoryView: View {
    let vm: DungeonRoomViewModel

    var body: some View {
        BattleResultCardView(config: buildConfig())
    }

    // MARK: - Build Config

    private func buildConfig() -> BattleResultConfig {
        let boss = vm.dungeon?.bosses[safe: vm.selectedBossIndex - 1] ?? vm.selectedBoss
        let subtitle = boss.map { "\($0.name) Defeated!" }

        // Convert dungeon loot items to LootItemDisplay
        let lootItems: [LootItemDisplay] = vm.victoryItems.map { item in
            let name = item["name"] as? String ?? "Item"
            let rawRarity = item["rarity"] as? String ?? "common"
            let rarity = ItemRarity(rawValue: rawRarity) ?? .common
            let rawType = item["type"] as? String ?? "weapon"
            let type = ItemType(rawValue: rawType)
            let upgrade = item["upgrade_level"] as? Int ?? 0
            let isGold = rawType == "gold" || rawType == "currency"
            let quantity = item["quantity"] as? Int ?? item["amount"] as? Int
            let consumableType = item["consumable_type"] as? String ?? item["consumableType"] as? String

            let displayName: String
            if isGold, let qty = quantity {
                displayName = "\(qty) Gold"
            } else {
                displayName = upgrade > 0 ? "\(name) +\(upgrade)" : name
            }

            return LootItemDisplay(
                name: displayName,
                rarityName: rarity.displayName,
                rarityColor: DarkFantasyTheme.rarityColor(for: rarity),
                imageKey: item["image_key"] as? String ?? item["imageKey"] as? String,
                imageUrl: item["image_url"] as? String,
                sfIcon: LootDetailView.consumableSFIcon(for: consumableType, type: rawType),
                sfColor: LootDetailView.consumableSFColor(for: consumableType, type: rawType),
                fallbackIcon: type?.icon ?? "shippingbox",
                rarityTier: rarity.tier
            )
        }

        // Dungeon progress
        let total = vm.dungeon?.totalBosses ?? 10
        let dungeonProgress = DungeonProgressConfig(
            defeated: vm.defeatedCount,
            total: total,
            isComplete: vm.isDungeonComplete
        )

        // Buttons
        var buttons: [ResultButton] = []
        if vm.isDungeonComplete {
            buttons.append(ResultButton(title: "CLAIM & EXIT", icon: "trophy.fill", style: .primary) {
                withAnimation { vm.dismissVictory() }
            })
        } else {
            buttons.append(ResultButton(title: "NEXT BOSS", icon: "chevron.right", style: .primary) {
                withAnimation { vm.proceedToNextBoss() }
            })
            buttons.append(ResultButton(title: "LEAVE DUNGEON", icon: nil, style: .ghost) {
                withAnimation { vm.dismissVictory() }
                vm.goBack()
            })
        }

        // Star rating based on HP remaining (server should send this in future)
        // For now: 3★ if >75% HP, 2★ if >25%, 1★ otherwise
        let hpFraction = vm.hpFractionAfterBattle ?? 1.0
        let stars: Int = hpFraction > 0.75 ? 3 : hpFraction > 0.25 ? 2 : 1

        return BattleResultConfig(
            isVictory: true,
            title: "VICTORY",
            subtitle: subtitle,
            illustrationImage: nil, // uses SF Symbol fallback (shield.checkered)
            starRating: stars,
            goldReward: vm.victoryGold > 0 ? vm.victoryGold : nil,
            xpReward: vm.victoryXP > 0 ? vm.victoryXP : nil,
            ratingChange: nil,
            firstWinBonus: false,
            xpBarConfig: nil,
            dungeonProgress: dungeonProgress,
            lootItems: lootItems,
            onLootTap: nil,
            buttons: buttons
        )
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
