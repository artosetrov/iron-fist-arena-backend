import SwiftUI

/// Victory over a dungeon boss (classic or dice fight), on a painted reward
/// card over the dungeon: the fallen boss standing on its lair, the stars,
/// rewards (gold, XP, loot — never PvP rating), the XP bar, the dungeon's
/// progress, and the next boss already revealed with FIGHT NEXT.
///
/// The card is the dungeon family; its tier is the boss's level, lifted by
/// the best drop (`RewardCardTier`). The stage shrinks the illustration, then
/// scrolls, when the card does not fit.
///
/// Runs the same XP bar fill + LEVEL UP! flash as the arena result screen
/// and defers the level-up modal until the bar finishes filling. Keep the
/// two in sync — if the arena animation sequence is tweaked, update
/// `runXpBarAnimation()` below too.
struct DungeonVictoryView: View {
    @Environment(AppState.self) private var appState
    let vm: DungeonRoomViewModel
    /// FIGHT NEXT — the parent closes this overlay and starts the intro for
    /// the next boss (energy check included).
    var onFightNext: () -> Void = {}

    // XP bar animation state — mirrors CombatResultDetailView.
    @State private var xpBarProgress: CGFloat = 0
    @State private var showLevelUpFlash = false
    @State private var displayLevel: Int = 0
    @State private var xpSnapshotCaptured = false
    @State private var oldXpFraction: CGFloat = 0
    @State private var newXpFraction: CGFloat = 0
    @State private var didLevelUp = false
    @State private var hasPlayedSting = false
    @State private var contentShown = false
    @State private var levelUpDelivered = false

    /// The next boss teaser: its height and the width of the boss standing in it.
    private static let nextBossHeight: CGFloat = 96
    private static let nextBossArtWidth: CGFloat = 88

    // MARK: Derived

    private var bosses: [BossInfo] { vm.dungeon?.bosses ?? [] }
    private var total: Int { vm.dungeon?.totalBosses ?? bosses.count }

    /// The boss that just fell — fights only ever go against the current
    /// boss, so it is the last one counted as defeated.
    private var defeatedBoss: BossInfo? {
        bosses[safe: vm.defeatedCount - 1] ?? vm.selectedBoss
    }

    private var nextBoss: BossInfo? {
        vm.isDungeonComplete ? nil : vm.currentBoss
    }

    private var isTraining: Bool {
        vm.dungeon?.id.contains("training") ?? false
    }

    private var stars: [StarCondition] {
        let hp = vm.hpFractionAfterBattle ?? 1.0
        return [
            StarCondition(label: "Win", earned: true),
            StarCondition(label: "50% HP", earned: hp > 0.5),
            StarCondition(label: "75% HP", earned: hp > 0.75)
        ]
    }

    // MARK: Card

    /// The frame's metal: the fallen boss's level (the gold and XP when the boss
    /// is unknown), lifted by the best drop.
    private var cardTier: RewardCardTier {
        var readings: [RewardCardTier?] = [
            defeatedBoss.map { RewardCardTier(level: $0.level) }
                ?? RewardCardTier(gold: vm.victoryGold, xp: vm.victoryXP)
        ]
        for item in lootDisplays {
            readings.append(RewardCardTier(rarity: item.rarity))
        }
        return RewardCardTier.best(readings)
    }

    /// The fallen boss on its lair; the best reward when the boss has no art.
    private var cardArt: RewardCardArt {
        RewardCardArt.dungeonBoss(defeatedBoss, dungeonId: vm.dungeon?.id)
            ?? .headline(
                gold: vm.victoryGold,
                gems: 0,
                xp: vm.victoryXP,
                items: lootDisplays.map { (imageKey: $0.imageKey, rarity: $0.rarity) },
                hasConsumables: lootDisplays.contains { $0.fallbackIcon == ItemType.consumable.icon }
            )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            RewardCardStage { width, artRatio in
                RewardCard(
                    family: .dungeon,
                    tier: cardTier,
                    art: cardArt,
                    width: width,
                    artRatio: artRatio,
                    header: { titleBlock },
                    content: { cardContent },
                    actions: { buttons }
                )
            }
            .opacity(contentShown ? 1 : 0)
        }
        .onAppear {
            captureXpSnapshot()
            if !hasPlayedSting {
                hasPlayedSting = true
                AudioManager.shared.playSting("victory-fanfare.mp3")
            }
            withAnimation(.easeOut(duration: MotionConstants.fast)) { contentShown = true }
            runXpBarAnimation()
        }
    }

    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            starsRow
            rewardsList
            if !lootDisplays.isEmpty {
                lootGrid
            }
            xpRow
            progressBlock
            if let next = nextBoss {
                nextBossCard(next)
            }
        }
    }

    // MARK: Title + stars

    private var titleBlock: some View {
        RewardCardTitle(
            title: vm.isDungeonComplete
                ? (isTraining ? "TRAINING COMPLETE!" : "DUNGEON CLEARED!")
                : "VICTORY!",
            subtitle: defeatedBoss.map { "\($0.name) · Stage \($0.id)" }
        )
    }

    private var starsRow: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                VStack(spacing: 0) {
                    Image(systemName: star.earned ? "star.fill" : "star")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(star.earned ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderMedium)
                    Text(star.label)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(star.earned ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(star.label): \(star.earned ? "earned" : "missed")"))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Rewards

    private var lootDisplays: [LootItemDisplay] {
        vm.victoryItems.map { item in
            let rarity = ItemRarity(rawValue: item.rarity ?? "common") ?? .common
            let rawType = item.itemType ?? "weapon"
            let upgrade = item.upgradeLevel ?? 0
            return LootItemDisplay(
                name: upgrade > 0 ? "\(item.displayName) +\(upgrade)" : item.displayName,
                rarityName: rarity.displayName,
                rarityColor: DarkFantasyTheme.rarityColor(for: rarity),
                imageKey: item.imageKey,
                imageUrl: item.imageUrl,
                sfIcon: LootDetailView.consumableSFIcon(for: nil, type: rawType),
                sfColor: LootDetailView.consumableSFColor(for: nil, type: rawType),
                fallbackIcon: ItemType(rawValue: rawType)?.icon ?? "shippingbox",
                rarityTier: rarity.tier
            )
        }
    }

    /// One line per currency; the card grows with the list.
    @ViewBuilder
    private var rewardsList: some View {
        if vm.victoryGold > 0 || vm.victoryXP > 0 {
            VStack(spacing: LayoutConstants.spaceXS) {
                if vm.victoryGold > 0 {
                    RewardCardRow(icon: "icon-gold", value: "+\(vm.victoryGold)", label: "Gold",
                                  color: DarkFantasyTheme.goldBright)
                }
                if vm.victoryXP > 0 {
                    RewardCardRow(icon: "icon-xp", value: "+\(vm.victoryXP)", label: "XP",
                                  color: DarkFantasyTheme.xpRing)
                }
            }
        }
    }

    /// The drops, three to a row, each named under its tile. (Plain stacks, not a
    /// lazy grid: the stage measures the card's ideal height.)
    private var lootGrid: some View {
        let items = lootDisplays
        let perRow = RewardCardLayout.lootPerRow
        let rows: [[LootItemDisplay]] = stride(from: 0, to: items.count, by: perRow).map { start in
            Array(items[start..<min(start + perRow, items.count)])
        }

        return VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, item in
                        VStack(spacing: LayoutConstants.spaceXS) {
                            ItemCardView(
                                rarity: item.rarity,
                                imageKey: item.imageKey,
                                imageUrl: item.imageUrl,
                                fallbackIcon: item.fallbackIcon,
                                systemIcon: item.sfIcon,
                                systemIconColor: item.sfColor,
                                context: .loot
                            ) {}
                            .frame(width: RewardCardLayout.lootTile, height: RewardCardLayout.lootTile)
                            RewardCardLootName(name: item.name, color: item.rarityColor)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("\(item.name), \(item.rarityName)"))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: XP

    private var xpRow: some View {
        let level = appState.currentCharacter?.level ?? displayLevel
        let xp = appState.currentCharacter?.experience ?? 0
        let needed = DungeonRoomViewModel.xpNeededForLevel(level)
        let fraction = min(max(xpBarProgress, 0), 1)

        return HStack(spacing: LayoutConstants.spaceSM) {
            Text(showLevelUpFlash ? "LEVEL UP!" : "LV \(displayLevel)")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1)
                .foregroundStyle(showLevelUpFlash ? DarkFantasyTheme.goldBright : DarkFantasyTheme.xpRing)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(showLevelUpFlash ? DarkFantasyTheme.goldBright : DarkFantasyTheme.xpRing, lineWidth: 1)
                )

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.xpRing)
                        .frame(width: geo.size.width * fraction)
                        .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                }
            }
            .frame(height: 10)

            Text("\(xp) / \(needed)")
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Level \(level), \(xp) of \(needed) XP"))
    }

    // MARK: Progress

    private var progressBlock: some View {
        let defeated = min(vm.defeatedCount, total)

        return VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                Text(vm.dungeon?.name ?? (isTraining ? "Training Camp" : "Dungeon"))
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer()
                Text("\(defeated) / \(total)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .monospacedDigit()
            }

            HStack(spacing: 0) {
                ForEach(0..<max(total, 1), id: \.self) { index in
                    progressDot(index: index, defeated: defeated)
                        .frame(maxWidth: .infinity)
                }
            }
            .background(alignment: .center) {
                GeometryReader { geo in
                    let step = geo.size.width / CGFloat(max(total, 1))
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DarkFantasyTheme.borderMedium)
                            .frame(height: 2)
                        Rectangle()
                            .fill(DarkFantasyTheme.gold)
                            .frame(width: step * CGFloat(min(defeated, max(total - 1, 0))), height: 2)
                    }
                    .padding(.horizontal, step / 2)
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(height: 24)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(defeated) of \(total) stages cleared"))
    }

    @ViewBuilder
    private func progressDot(index: Int, defeated: Int) -> some View {
        if index < defeated {
            Circle()
                .fill(DarkFantasyTheme.success)
                .frame(width: 16, height: 16)
        } else if index == defeated {
            Circle()
                .fill(DarkFantasyTheme.bgPrimary)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(DarkFantasyTheme.goldBright, lineWidth: 3))
        } else {
            Circle()
                .fill(DarkFantasyTheme.bgPrimary)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(DarkFantasyTheme.borderMedium, lineWidth: 1.5))
        }
    }

    // MARK: Next boss

    private func nextBossCard(_ next: BossInfo) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("NEXT · STAGE \(next.id)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .lineLimit(1)
                Text(next.name.uppercased())
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Lv \(next.level) · \(next.hp) HP")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.leading, LayoutConstants.spaceMS)
            .frame(maxWidth: .infinity, alignment: .leading)

            BossStageArt(boss: next, mirrored: true, light: DarkFantasyTheme.purple)
                .frame(width: Self.nextBossArtWidth, height: Self.nextBossHeight)
        }
        .frame(height: Self.nextBossHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .accessibilityElement(children: .combine)
    }

    // MARK: Buttons

    @ViewBuilder
    private var buttons: some View {
        let cost = vm.dungeon?.energyCost ?? 10
        VStack(spacing: LayoutConstants.spaceXS) {
            if vm.isDungeonComplete {
                Button {
                    deliverLevelUpIfPending()
                    vm.dismissVictory()
                } label: {
                    Text("CLAIM & EXIT")
                }
                .buttonStyle(.primary)
            } else {
                Button {
                    // A level-up earned here is shown first — otherwise its
                    // modal would land on the intro or the battle.
                    if deliverLevelUpIfPending() { return }
                    onFightNext()
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("FIGHT NEXT")
                        // Inside an open run the next fight is free.
                        if !vm.hasActiveRun {
                            HStack(spacing: LayoutConstants.space2XS) {
                                Image("icon-stamina")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                                Text("\(cost)")
                            }
                            .opacity(vm.stamina >= cost ? 1 : 0.6)
                        }
                    }
                }
                .buttonStyle(.primary)
                .accessibilityLabel(Text(vm.hasActiveRun
                                         ? "Fight next boss"
                                         : "Fight next boss, costs \(cost) energy"))

                Button {
                    deliverLevelUpIfPending()
                    vm.proceedToNextBoss()
                } label: {
                    Text(isTraining ? "Back to camp" : "Back to the dungeon")
                }
                .buttonStyle(.ghost)
            }
        }
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
            // Use pre-fight snapshot directly to avoid drift from background loadCharacter()
            let oldXp = max(0, vm.preFightXP)
            let newXp = oldXp + xpReward
            oldXpFraction = CGFloat(oldXp) / CGFloat(max(1, xpNeeded))
            newXpFraction = CGFloat(min(newXp, xpNeeded)) / CGFloat(max(1, xpNeeded))
        }

        xpBarProgress = oldXpFraction
    }

    /// Show the level-up modal once. Returns true when it was shown now.
    @discardableResult
    private func deliverLevelUpIfPending() -> Bool {
        guard didLevelUp, !levelUpDelivered, let newLvl = vm.victoryNewLevel else { return false }
        levelUpDelivered = true
        let statPoints = vm.victoryStatPointsAwarded > 0 ? vm.victoryStatPointsAwarded : 3
        appState.triggerLevelUpModal(
            newLevel: newLvl,
            statPoints: statPoints,
            passivePoints: vm.victoryPassivePointsAwarded
        )
        return true
    }

    private func runXpBarAnimation() {
        if didLevelUp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: MotionConstants.tickUpLong)) {
                    xpBarProgress = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                withAnimation(.easeOut(duration: MotionConstants.fast)) {
                    showLevelUpFlash = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                xpBarProgress = 0
                if let newLvl = vm.victoryNewLevel {
                    displayLevel = newLvl
                }
                withAnimation(.easeOut(duration: MotionConstants.reward)) {
                    xpBarProgress = newXpFraction
                    showLevelUpFlash = false
                }
            }
            // Defer level-up modal until the bar finishes filling so it
            // doesn't cover the reward animation (same timing as arena).
            // A button tap before then delivers it early (see `buttons`).
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                deliverLevelUpIfPending()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
