import SwiftUI

/// Victory over a dungeon boss (classic or dice fight). Full-screen over the
/// dungeon: the defeated boss's portrait with a DEFEATED ribbon, stars,
/// rewards (gold, XP, loot — never PvP rating), the XP bar, the dungeon's
/// progress, and the next boss already revealed with FIGHT NEXT.
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

    private static let medallionSize: CGFloat = 132
    private static let tileHeight: CGFloat = 64

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

    // MARK: Body

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: LayoutConstants.spaceMD) {
                        medallion
                            .padding(.top, LayoutConstants.spaceLG)
                        titleBlock
                        rewardsGrid
                        xpRow
                        progressBlock
                        if let next = nextBoss {
                            nextBossCard(next)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceMD)
                }
                .scrollIndicators(.hidden)

                buttons
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceSM)
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

    // MARK: Medallion

    @ViewBuilder
    private var medallion: some View {
        if let boss = defeatedBoss {
            ZStack {
                Circle().fill(DarkFantasyTheme.bgSecondary)
                BossArtImage(boss: boss, kind: .portrait, style: .lit, contentMode: .fill)
                    .frame(width: Self.medallionSize, height: Self.medallionSize)
                    .saturation(0.45)
                    .clipShape(Circle())
            }
            .frame(width: Self.medallionSize, height: Self.medallionSize)
            .overlay(Circle().stroke(DarkFantasyTheme.goldBright, lineWidth: 4))
            .overlay(alignment: .bottom) {
                Text("DEFEATED")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .fill(DarkFantasyTheme.danger)
                    )
                    .offset(y: 12)
            }
            .dualShadow(glowColor: DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityMedium), glowRadius: 12, depth: .elevated)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(boss.name) defeated"))
        }
    }

    // MARK: Title + stars

    private var titleBlock: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text(vm.isDungeonComplete
                 ? (isTraining ? "TRAINING COMPLETE!" : "DUNGEON CLEARED!")
                 : "VICTORY!")
                .font(DarkFantasyTheme.cinematicTitle)
                .tracking(1)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, LayoutConstants.spaceSM)

            if let boss = defeatedBoss {
                Text("\(boss.name) · Stage \(boss.id)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

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
            .padding(.top, LayoutConstants.spaceXS)
        }
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

    private var rewardsGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.spaceSM), count: 3),
            spacing: LayoutConstants.spaceSM
        ) {
            if vm.victoryGold > 0 {
                rewardTile(asset: "icon-gold", value: "+\(vm.victoryGold)", color: DarkFantasyTheme.goldBright, label: "gold")
            }
            if vm.victoryXP > 0 {
                rewardTile(asset: "icon-xp", value: "+\(vm.victoryXP)", color: DarkFantasyTheme.xpRing, label: "XP")
            }
            ForEach(Array(lootDisplays.enumerated()), id: \.offset) { _, item in
                ItemCardView(
                    rarity: item.rarity,
                    imageKey: item.imageKey,
                    imageUrl: item.imageUrl,
                    fallbackIcon: item.fallbackIcon,
                    systemIcon: item.sfIcon,
                    systemIconColor: item.sfColor,
                    context: .loot
                ) {}
                .frame(width: Self.tileHeight, height: Self.tileHeight)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Text("\(item.name), \(item.rarityName)"))
            }
        }
    }

    private func rewardTile(asset: String, value: String, color: Color, label: String) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
            Text(value)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.tileHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(color.opacity(DarkFantasyTheme.opacityMedium), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(value) \(label)"))
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
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("NEXT · STAGE \(next.id)")
                    .font(DarkFantasyTheme.body)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.gold)
                Text(next.name.uppercased())
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Lv \(next.level) · \(next.hp) HP")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .padding(.leading, LayoutConstants.spaceMS)
            Spacer(minLength: LayoutConstants.spaceSM)
            BossStageArt(boss: next, mirrored: true, light: DarkFantasyTheme.purple)
                .frame(width: 140, height: 112)
        }
        .frame(height: 112)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
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
