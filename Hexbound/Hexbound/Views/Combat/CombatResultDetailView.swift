import SwiftUI

struct CombatResultDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var showRewards = false

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

                    // Trophy
                    Text(isWin ? "🏆" : "💀")
                        .font(.system(size: 56))
                        .padding(.top, LayoutConstants.spaceSM)

                    Spacer().frame(height: LayoutConstants.spaceLG)

                    // First Win Bonus Badge
                    if res.firstWinBonus == true {
                        Text("FIRST WIN BONUS x2!")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .padding(.horizontal, 16)
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

                    Spacer()

                    // Buttons
                    VStack(spacing: LayoutConstants.spaceSM) {
                        if !appState.pendingLoot.isEmpty {
                            Button("VIEW LOOT") {
                                appState.mainPath.append(AppRoute.loot)
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
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showRewards = true
            }
            // Reload character immediately to reflect new XP/level
            Task {
                let charService = CharacterService(appState: appState)
                await charService.loadCharacter()
            }
            // Show level-up modal after a short delay
            if let res = result, res.leveledUp == true,
               let newLevel = res.newLevel {
                let statPoints = res.statPointsAwarded ?? 3
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    appState.triggerLevelUpModal(newLevel: newLevel, statPoints: statPoints)
                }
            }
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
                        icon: "💰",
                        value: "+\(gold)",
                        label: "Gold",
                        color: DarkFantasyTheme.goldBright,
                        delay: 0
                    )
                }

                if let xp = res.xpReward, xp > 0 {
                    rewardItem(
                        icon: "⭐",
                        value: "+\(xp)",
                        label: "XP",
                        color: DarkFantasyTheme.goldBright,
                        delay: 0.15
                    )
                }

                if let change = res.ratingChange, change != 0 {
                    rewardItem(
                        icon: "📈",
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
    private func rewardItem(icon: String, value: String, label: String, color: Color, delay: Double) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text(icon)
                .font(.system(size: 28))

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
