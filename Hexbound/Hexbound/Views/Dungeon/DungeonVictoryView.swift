import SwiftUI

/// Boss victory overlay shown after a successful dungeon fight. Mirrors the
/// arena/pvp victory screen (`CombatResultDetailView`) by running the same
/// XP bar fill + LEVEL UP! flash animation and deferring the level-up modal
/// until the bar finishes filling. Keep these two flows in sync — if the
/// arena animation sequence is tweaked, update `runXpBarAnimation()` below
/// too.
struct DungeonVictoryView: View {
    @Environment(AppState.self) private var appState
    let vm: DungeonRoomViewModel

    // XP bar animation state — mirrors CombatResultDetailView.
    @State private var xpBarProgress: CGFloat = 0
    @State private var showLevelUpFlash = false
    @State private var displayLevel: Int = 0
    @State private var xpSnapshotCaptured = false
    @State private var oldXpFraction: CGFloat = 0
    @State private var newXpFraction: CGFloat = 0
    @State private var didLevelUp = false
    @State private var hasPlayedVictorySFX = false

    var body: some View {
        BattleResultCardView(config: buildConfig())
            .onAppear {
                captureXpSnapshot()
                if !hasPlayedVictorySFX {
                    hasPlayedVictorySFX = true
                    SFXManager.shared.play(.battleVictory)
                }
                runXpBarAnimation()
            }
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
        // Bug #16: Training Camp is not a dungeon — use "Training Progress"
        // and "TRAINING COMPLETE!" copy when the current track is training.
        let total = vm.dungeon?.totalBosses ?? 10
        let isTraining = vm.dungeon?.id.contains("training") ?? false
        let dungeonProgress = DungeonProgressConfig(
            defeated: vm.defeatedCount,
            total: total,
            isComplete: vm.isDungeonComplete,
            progressLabel: isTraining ? "Training Progress" : "Dungeon Progress",
            completeLabel: isTraining ? "TRAINING COMPLETE!" : "DUNGEON CLEARED!"
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

        // Hero XP counter: xpBefore rolls to xpBefore + xpReward. For the
        // no-level-up path this is the true pre-fight XP; for the level-up
        // path it's the new level's remaining XP minus the reward (can
        // underflow briefly — arena has the same behaviour).
        let xpReward = vm.victoryXP
        let currentExp = appState.currentCharacter?.experience ?? 0
        let xpBeforeValue = max(0, currentExp - xpReward)
        let xpNeededValue = DungeonRoomViewModel.xpNeededForLevel(displayLevel)

        return BattleResultConfig(
            isVictory: true,
            title: "VICTORY",
            subtitle: subtitle,
            illustrationImage: nil, // uses SF Symbol fallback (shield.checkered)
            starRating: stars,
            goldReward: vm.victoryGold > 0 ? vm.victoryGold : nil,
            xpReward: xpReward > 0 ? xpReward : nil,
            ratingChange: nil,
            firstWinBonus: false,
            xpBefore: xpBeforeValue,
            xpNeeded: xpNeededValue,
            xpBarConfig: XPBarConfig(
                displayLevel: displayLevel,
                progress: xpBarProgress,
                leveledUp: showLevelUpFlash
            ),
            dungeonProgress: dungeonProgress,
            lootItems: lootItems,
            onLootTap: nil,
            buttons: buttons
        )
    }

    // MARK: - XP Snapshot & Animation (mirrors CombatResultDetailView)

    private func captureXpSnapshot() {
        guard !xpSnapshotCaptured else { return }
        xpSnapshotCaptured = true

        let xpReward = vm.victoryXP
        let leveledUp = vm.victoryLeveledUp
        let newLevel = vm.victoryNewLevel
        self.didLevelUp = leveledUp

        if leveledUp, let newLvl = newLevel {
            // Start at the pre-level-up bar state so the fill animation
            // shows the overflow transition. `appState.currentCharacter`
            // has already been optimistically bumped in the VM — use its
            // post-fight values for the end fraction.
            let previousLevel = newLvl - 1
            displayLevel = previousLevel
            let prevXpNeeded = DungeonRoomViewModel.xpNeededForLevel(previousLevel)
            oldXpFraction = CGFloat(max(0, vm.preFightXP)) / CGFloat(max(1, prevXpNeeded))

            let overflowXp = appState.currentCharacter?.experience ?? 0
            let newXpNeeded = DungeonRoomViewModel.xpNeededForLevel(newLvl)
            newXpFraction = CGFloat(max(0, overflowXp)) / CGFloat(max(1, newXpNeeded))
        } else {
            let charLevel = appState.currentCharacter?.level ?? vm.preFightLevel
            displayLevel = charLevel
            let xpNeeded = DungeonRoomViewModel.xpNeededForLevel(charLevel)
            let currentExp = appState.currentCharacter?.experience ?? 0
            let oldXp = max(0, currentExp - xpReward)
            oldXpFraction = CGFloat(oldXp) / CGFloat(max(1, xpNeeded))
            newXpFraction = CGFloat(max(0, currentExp)) / CGFloat(max(1, xpNeeded))
        }

        xpBarProgress = oldXpFraction
    }

    private func runXpBarAnimation() {
        if didLevelUp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: MotionConstants.tickUpLong)) {
                    xpBarProgress = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showLevelUpFlash = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                xpBarProgress = 0
                if let newLvl = vm.victoryNewLevel {
                    displayLevel = newLvl
                }
                withAnimation(.easeOut(duration: MotionConstants.reward)) {
                    xpBarProgress = newXpFraction
                }
            }
            // Defer level-up modal until the bar finishes filling so it
            // doesn't cover the reward animation (same timing as arena).
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if let newLvl = vm.victoryNewLevel {
                    let statPoints = vm.victoryStatPointsAwarded > 0 ? vm.victoryStatPointsAwarded : 3
                    appState.triggerLevelUpModal(newLevel: newLvl, statPoints: statPoints)
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: MotionConstants.tickUpLong)) {
                    xpBarProgress = newXpFraction
                }
            }
        }
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
