import SwiftUI

struct CombatResultDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var showRewards = false

    // XP bar animation state
    @State private var xpBarProgress: CGFloat = 0
    @State private var showXpBar = false
    @State private var showLevelUpFlash = false
    @State private var displayLevel: Int = 0
    @State private var xpSnapshotCaptured = false
    @State private var oldXpFraction: CGFloat = 0
    @State private var newXpFraction: CGFloat = 0
    @State private var didLevelUp = false

    private var combatData: CombatData? {
        appState.combatResult
    }

    private var result: CombatResultInfo? {
        combatData?.result
    }

    private var isWin: Bool {
        result?.isWin ?? false
    }

    private var source: String {
        combatData?.source ?? "training"
    }

    var body: some View {
        ZStack {
            // Background with subtle glow
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            // Victory/Defeat gradient glow
            if isWin {
                RadialGradient(
                    colors: [
                        DarkFantasyTheme.success.opacity(0.15),
                        DarkFantasyTheme.success.opacity(0.05),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
            } else {
                RadialGradient(
                    colors: [
                        DarkFantasyTheme.danger.opacity(0.12),
                        DarkFantasyTheme.danger.opacity(0.04),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
            }

            if let _ = combatData, let res = result {
                VStack(spacing: 0) {
                    Spacer()

                    // Result Title
                    resultTitle

                    // Result illustration
                    Image(isWin ? "result-victory" : "result-defeat")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)
                        .padding(.top, LayoutConstants.spaceSM)

                    Spacer().frame(height: LayoutConstants.spaceLG)

                    // First Win Bonus Badge
                    if res.firstWinBonus == true {
                        HStack(spacing: 8) {
                            Image("reward-first-win")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 128, height: 128)
                            Text("FIRST WIN BONUS x2!")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                        }
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.vertical, 6)
                        .background(DarkFantasyTheme.goldBright.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DarkFantasyTheme.goldBright.opacity(0.4), lineWidth: 1)
                        )
                        .opacity(showRewards ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.2), value: showRewards)
                        .padding(.bottom, LayoutConstants.spaceSM)
                    }

                    // Rewards Card
                    rewardsCard(res)

                    // XP Progress Bar
                    if let xp = res.xpReward, xp > 0 {
                        xpProgressBar
                    }

                    Spacer()

                    // Buttons
                    VStack(spacing: LayoutConstants.spaceSM) {
                        if !appState.pendingLoot.isEmpty {
                            Button {
                                appState.mainPath.append(AppRoute.loot)
                            } label: {
                                HStack(spacing: 8) {
                                    Image("reward-loot")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 128, height: 128)
                                    Text("VIEW LOOT")
                                }
                            }
                            .buttonStyle(.primary)

                            Button("CONTINUE") {
                                goBack()
                            }
                            .buttonStyle(.secondary)
                        } else {
                            Button("CONTINUE") {
                                goBack()
                            }
                            .buttonStyle(.primary)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceLG)
                }
            } else {
                // Fallback — combat result not available (shouldn't happen)
                VStack(spacing: LayoutConstants.spaceMD) {
                    Spacer()
                    Text("Battle Complete")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Button("RETURN") {
                        goBack()
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            captureXpSnapshot()

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showRewards = true
            }
            // Reload character immediately to reflect new XP/level
            Task {
                let charService = CharacterService(appState: appState)
                await charService.loadCharacter()
            }
            // Run XP bar animation after rewards card appears
            runXpBarAnimation()
        }
    }

    // MARK: - Result Title

    @ViewBuilder
    private var resultTitle: some View {
        Text(isWin ? "VICTORY!" : "DEFEAT")
            .font(DarkFantasyTheme.title(size: LayoutConstants.textCinematic))
            .foregroundStyle(isWin ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
            .shadow(color: (isWin ? DarkFantasyTheme.successGlow : DarkFantasyTheme.dangerGlow), radius: 16)
    }

    // MARK: - Rewards Card

    @ViewBuilder
    private func rewardsCard(_ res: CombatResultInfo) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Text("REWARDS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            HStack(spacing: 0) {
                if let gold = res.goldReward, gold > 0 {
                    rewardItem(
                        iconImage: "reward-gold",
                        value: "+\(gold)",
                        label: "Gold",
                        color: DarkFantasyTheme.goldBright,
                        delay: 0
                    )
                }

                if let xp = res.xpReward, xp > 0 {
                    rewardItem(
                        iconImage: "reward-xp",
                        value: "+\(xp)",
                        label: "XP",
                        color: DarkFantasyTheme.goldBright,
                        delay: 0.15
                    )
                }

                if let change = res.ratingChange, change != 0 {
                    rewardItem(
                        iconImage: change > 0 ? "reward-rating-up" : "reward-rating-down",
                        value: change > 0 ? "+\(change)" : "\(change)",
                        label: "Rating",
                        color: change > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger,
                        delay: 0.3
                    )
                }
            }
        }
        .padding(.vertical, LayoutConstants.spaceMD)
        .padding(.horizontal, LayoutConstants.spaceLG)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderOrnament.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding * 2)
        .opacity(showRewards ? 1 : 0)
        .offset(y: showRewards ? 0 : 20)
    }

    @ViewBuilder
    private func rewardItem(iconImage: String, value: String, label: String, color: Color, delay: Double) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(iconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)

            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(color)

            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .opacity(showRewards ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(delay + 0.3), value: showRewards)
    }

    // MARK: - XP Progress Bar

    @ViewBuilder
    private var xpProgressBar: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("Level \(displayLevel)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.purple)

                Spacer()

                if showLevelUpFlash {
                    HStack(spacing: 4) {
                        Image("reward-level-up")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 128)
                        Text("LEVEL UP!")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .shadow(color: DarkFantasyTheme.goldBright.opacity(0.6), radius: 8)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 5)
                        .fill(DarkFantasyTheme.xpGradient)
                        .frame(width: geo.size.width * min(xpBarProgress, 1.0))
                }
            }
            .frame(height: 12)

            HStack {
                let xpNeeded = xpNeededForLevel(displayLevel)
                let currentXp = Int(xpBarProgress * CGFloat(xpNeeded))
                Text("\(currentXp) / \(xpNeeded) XP")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Spacer()
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding * 2)
        .padding(.top, LayoutConstants.spaceMD)
        .opacity(showXpBar ? 1 : 0)
        .offset(y: showXpBar ? 0 : 10)
    }

    private func xpNeededForLevel(_ level: Int) -> Int {
        let next = level + 1
        return 100 * next + 20 * next * next
    }

    private func captureXpSnapshot() {
        guard !xpSnapshotCaptured, let res = result else { return }
        xpSnapshotCaptured = true

        let xpReward = res.xpReward ?? 0
        let leveledUp = res.leveledUp == true
        let newLevel = res.newLevel
        self.didLevelUp = leveledUp

        if leveledUp, let newLvl = newLevel {
            // Character level hasn't been updated by applyResolveToCharacter yet
            let previousLevel = newLvl - 1
            displayLevel = previousLevel
            let prevXpNeeded = xpNeededForLevel(previousLevel)
            // applyResolveToCharacter sets experience = oldXp + xpReward (without level reset)
            let currentExp = appState.currentCharacter?.experience ?? 0
            let oldXp = currentExp - xpReward
            oldXpFraction = CGFloat(max(0, oldXp)) / CGFloat(max(1, prevXpNeeded))
            // After level-up, the new XP is the overflow
            let overflowXp = currentExp - prevXpNeeded
            let newXpNeeded = xpNeededForLevel(newLvl)
            newXpFraction = CGFloat(max(0, overflowXp)) / CGFloat(max(1, newXpNeeded))
        } else {
            let charLevel = appState.currentCharacter?.level ?? 1
            displayLevel = charLevel
            let xpNeeded = xpNeededForLevel(charLevel)
            let currentExp = appState.currentCharacter?.experience ?? 0
            let oldXp = currentExp - xpReward
            oldXpFraction = CGFloat(max(0, oldXp)) / CGFloat(max(1, xpNeeded))
            newXpFraction = CGFloat(max(0, currentExp)) / CGFloat(max(1, xpNeeded))
        }

        xpBarProgress = oldXpFraction
    }

    private func runXpBarAnimation() {
        // Show XP bar after rewards appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showXpBar = true
            }
        }

        if didLevelUp {
            // Phase 1: fill to 100%
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    xpBarProgress = 1.0
                }
            }
            // Phase 2: show LEVEL UP flash
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showLevelUpFlash = true
                }
            }
            // Phase 3: reset bar and fill to new level progress
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                xpBarProgress = 0
                if let newLvl = result?.newLevel {
                    displayLevel = newLvl
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    xpBarProgress = newXpFraction
                }
            }
            // Show level-up modal after bar animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if let res = result, res.leveledUp == true, let newLevel = res.newLevel {
                    let statPoints = res.statPointsAwarded ?? 3
                    appState.triggerLevelUpModal(newLevel: newLevel, statPoints: statPoints)
                }
            }
        } else {
            // Simple fill animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    xpBarProgress = newXpFraction
                }
            }
        }
    }

    // MARK: - Navigation

    private func goBack() {
        // Capture source before clearing combat data
        let currentSource = source

        appState.combatData = nil
        appState.combatResult = nil
        appState.invalidateCache("quests")

        // Reset navigation in one step to avoid per-pop re-renders
        if currentSource == "arena" || currentSource == "pvp" {
            // Pop back to Arena (keep first path item)
            let keepCount = min(1, appState.mainPath.count)
            let removals = appState.mainPath.count - keepCount
            if removals > 0 {
                appState.mainPath.removeLast(removals)
            }
        } else {
            appState.mainPath = NavigationPath()
        }
    }
}
