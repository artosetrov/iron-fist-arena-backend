import SwiftUI

struct DailyQuestsDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DailyQuestsViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    // Reset timer
                    Text(vm.resetTimeText)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .padding(.top, LayoutConstants.spaceSM)

                    if vm.isLoading && vm.quests.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SkeletonQuestCard()
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                // Bonus panel
                                bonusPanel(vm: vm)

                                // Quest cards
                                ForEach(vm.quests) { quest in
                                    questCard(quest, vm: vm)
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.cyan)
            }
        }
        .onAppear {
            if vm == nil { vm = DailyQuestsViewModel(appState: appState) }
            // Reload quests every time view appears (e.g., after PvP/dungeon)
            if let vm { Task { await vm.loadQuests() } }
        }
    }

    // MARK: - Helpers

    private func timeUntilReset() -> String {
        let now = Date()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let tomorrow = utc.date(byAdding: .day, value: 1, to: now),
              let midnight = utc.date(from: utc.dateComponents([.year, .month, .day], from: tomorrow))
        else { return "" }
        let remaining = Int(midnight.timeIntervalSince(now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        return "\(h)h \(m)m"
    }

    // MARK: - Bonus Panel

    @ViewBuilder
    private func bonusPanel(vm: DailyQuestsViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("Complete All \(vm.quests.count) Quests")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            // Progress
            HStack(spacing: LayoutConstants.spaceSM) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DarkFantasyTheme.bgTertiary)
                        let fraction = vm.quests.isEmpty ? 0.0 : Double(vm.completedCount) / Double(vm.quests.count)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DarkFantasyTheme.gold)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 8)

                Text("\(vm.completedCount)/\(vm.quests.count)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(width: 30)
            }

            Text("Bonus: +500 Gold, +10 Gems")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            if vm.bonusClaimedToday {
                VStack(spacing: 4) {
                    Text("✓ Claimed")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.success)
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text("Next bonus: \(timeUntilReset())")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightSM + 10)
                .background(DarkFantasyTheme.success.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
            } else if vm.canClaimBonus {
                Button {
                    Task { await vm.claimBonus() }
                } label: {
                    if vm.isClaimingBonus {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Text("CLAIM BONUS")
                    }
                }
                .buttonStyle(.compactPrimary)
                .disabled(vm.isClaimingBonus)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Quest Type → Destination Mapping

    private func destinationRoute(for quest: Quest) -> AppRoute? {
        switch quest.type {
        case "pvp_wins":
            return .arena
        case "dungeons_complete":
            return .dungeonSelect
        case "gold_spent":
            return .shop
        case "consumable_use", "item_upgrade":
            return .hero
        case "shell_game_play":
            return .shellGame
        case "gold_mine_collect":
            return .goldMine
        default:
            return nil
        }
    }

    // MARK: - Quest Card

    @ViewBuilder
    private func questCard(_ quest: Quest, vm: DailyQuestsViewModel) -> some View {
        let isClaiming = vm.claimingQuestId == quest.id
        let destination = destinationRoute(for: quest)

        Button {
            if let destination {
                if destination == .shop {
                    appState.shopInitialTab = 0
                }
                appState.mainPath.append(destination)
            }
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                // Icon
                Text(quest.icon)
                    .font(.system(size: 28)) // emoji text — keep as is
                    .frame(width: 44)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(quest.rewardClaimed ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.textPrimary)

                    Text(quest.description)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(2)

                    // Progress bar
                    HStack(spacing: LayoutConstants.spaceSM) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(DarkFantasyTheme.bgTertiary)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(quest.completed ? DarkFantasyTheme.success : DarkFantasyTheme.cyan)
                                    .frame(width: geo.size.width * quest.progressFraction)
                            }
                        }
                        .frame(height: 6)

                        Text("\(quest.progress)/\(quest.target)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .frame(width: 36, alignment: .trailing)
                    }

                    // Rewards
                    Text("\(quest.rewardGold) Gold  \(quest.rewardXp) XP")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }

                Spacer(minLength: 4)

                // Right side: Claim button or navigation chevron
                VStack(spacing: 6) {
                    if quest.rewardClaimed {
                        Text("Done")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.success)
                    } else if quest.canClaim {
                        Button {
                            Task { await vm.claimQuest(quest) }
                        } label: {
                            if isClaiming {
                                ProgressView().tint(DarkFantasyTheme.textOnGold).scaleEffect(0.8)
                            } else {
                                Text("Claim")
                            }
                        }
                        .frame(width: 60, height: 30)
                        .buttonStyle(.compactPrimary)
                        .disabled(isClaiming)
                    }

                    // Navigation chevron — shows destination is tappable
                    if destination != nil && !quest.rewardClaimed {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold)) // SF Symbol icon — keep as is
                            .foregroundStyle(DarkFantasyTheme.goldDim)
                    }
                }
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(quest.rewardClaimed ? DarkFantasyTheme.bgPrimary : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        quest.rewardClaimed ? DarkFantasyTheme.success.opacity(0.2)
                        : quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.4)
                        : DarkFantasyTheme.borderSubtle,
                        lineWidth: 1
                    )
            )
            .opacity(quest.rewardClaimed ? 0.7 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuestCardButtonStyle())
        .disabled(destination == nil && !quest.canClaim)
    }
}

// MARK: - Quest Card Press Style

struct QuestCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
