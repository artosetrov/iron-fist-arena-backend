import SwiftUI

struct DailyQuestsDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: DailyQuestsViewModel?
    @State private var showQuestBurst = false
    @State private var burstQuestId: String?
    @State private var appearCount = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    // Reset timer
                    Text(vm.resetTimeText)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .padding(.top, LayoutConstants.spaceSM)
                        .accessibilityLabel("Daily quests reset: \(vm.resetTimeText)")

                    if vm.errorMessage != nil {
                        ErrorStateView.loadFailed { Task { await vm.loadQuests() } }
                    } else if vm.isLoading && vm.quests.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SkeletonQuestCard()
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                    } else if vm.quests.isEmpty {
                        EmptyStateView.questsComplete
                    } else {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                // Bonus panel
                                bonusPanel(vm: vm)

                                // Quest cards
                                ForEach(Array(vm.quests.enumerated()), id: \.element.id) { index, quest in
                                    questCard(quest, vm: vm)
                                        .staggeredAppear(index: index)
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.cyan)
            }
        }
        .onAppear {
            if vm == nil { vm = DailyQuestsViewModel(appState: appState, cache: cache) }
            appearCount += 1
        }
        .task(id: appearCount) {
            // Reload quests every time view appears (e.g., after PvP/dungeon)
            guard appearCount > 0 else { return }
            await vm?.loadQuests()
        }
    }

    // MARK: - Quest Icon Asset

    /// Returns the asset image name for a quest type.
    /// For `item_upgrade` uses the hero's avatar (dynamic).
    private func questIconAsset(for questType: String) -> String {
        switch questType {
        case "pvp_wins":          return "building-arena"
        case "dungeons_complete": return "building-dungeon"
        case "gold_spent":        return "building-shop"
        case "item_upgrade":
            return appState.currentCharacter?.avatar ?? "knight"
        case "consumable_use":    return "health-potion-medium"
        case "shell_game_play":   return "shell-cup"
        case "gold_mine_collect": return "building-gold-mine"
        default:                  return "icon-xp" // safe fallback
        }
    }

    // MARK: - Helpers

    private func timeUntilReset() -> String {
        let now = Date()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        guard let tomorrow = utc.date(byAdding: .day, value: 1, to: now),
              let midnight = utc.date(from: utc.dateComponents([.year, .month, .day], from: tomorrow))
        else { return "" }
        let remaining = Int(midnight.timeIntervalSince(now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        return "\(h)h \(m)m"
    }

    // MARK: - Reward Cells Row

    /// Builds a horizontal row of loot-style reward cells for a quest.
    @ViewBuilder
    private func rewardCellsRow(gold: Int, xp: Int, gems: Int?) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if gold > 0 {
                QuestRewardCell(type: .gold, value: gold)
            }
            if xp > 0 {
                QuestRewardCell(type: .xp, value: xp)
            }
            if let gems, gems > 0 {
                QuestRewardCell(type: .gems, value: gems)
            }
        }
    }

    // MARK: - Bonus Panel

    @ViewBuilder
    private func bonusPanel(vm: DailyQuestsViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            Text("Complete All \(vm.quests.count) Quests")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .accessibilityLabel("Daily quest completion challenge")

            // Segmented progress bar — 1 segment per quest
            SegmentedProgressBar(
                progress: vm.completedCount,
                target: vm.quests.count,
                isBonus: true
            )

            // Bonus rewards as loot cells
            rewardCellsRow(gold: 500, xp: 0, gems: 10)

            if vm.bonusClaimedToday {
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("✓ Claimed")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.success)
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text("Next bonus: \(timeUntilReset())")
                            .font(DarkFantasyTheme.body)
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
                        HexPulseLoader.onGold()
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
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .cardShadow()
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

        questCardContent(quest, vm: vm, isClaiming: isClaiming, destination: destination)
        .overlay {
            if showQuestBurst && burstQuestId == quest.id {
                GeometryReader { geo in
                    RewardBurstView(style: .claim, isActive: $showQuestBurst)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Quest Card Content

    /// Separates navigation (outer button) from claim action to avoid button-in-button tap interception.
    /// When quest.canClaim == true, the card body is NOT wrapped in a navigation button —
    /// only the Claim button is interactive. Otherwise, the whole card is a navigation button.
    @ViewBuilder
    private func questCardContent(_ quest: Quest, vm: DailyQuestsViewModel, isClaiming: Bool, destination: AppRoute?) -> some View {
        let cardBody = questCardBody(quest, vm: vm, isClaiming: isClaiming, destination: destination)

        if quest.canClaim || quest.rewardClaimed {
            // No outer navigation button — Claim button handles interaction,
            // or quest is already done (no interaction needed)
            cardBody
        } else if let destination {
            // Quest not yet complete — whole card navigates to relevant screen
            Button {
                if destination == .shop {
                    appState.shopInitialTab = 0
                }
                appState.mainPath.append(destination)
            } label: {
                cardBody
            }
            .buttonStyle(QuestCardButtonStyle())
        } else {
            // No destination, not claimable — static card
            cardBody
        }
    }

    // MARK: - Quest Card Body (v3 — loot cells + segmented bar)

    @ViewBuilder
    private func questCardBody(_ quest: Quest, vm: DailyQuestsViewModel, isClaiming: Bool, destination: AppRoute?) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // === ROW 1: Icon + Title + Chevron/Status ===
            HStack(spacing: LayoutConstants.spaceMS) {
                // Quest icon
                Image(questIconAsset(for: quest.type))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )

                // Title + description
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(quest.title)
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(quest.rewardClaimed ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    Text(quest.description)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                // Right side: status indicator
                if quest.rewardClaimed {
                    Text("✓ Done")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.success)
                } else if destination != nil && !quest.canClaim {
                    Image(systemName: "chevron.right")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                }
            }

            // === ROW 2: Loot-style reward cells ===
            rewardCellsRow(gold: quest.rewardGold, xp: quest.rewardXp, gems: quest.rewardGems)

            // === ROW 3: Segmented progress bar ===
            SegmentedProgressBar(progress: quest.progress, target: quest.target)

            // === ROW 4: Claim button (only when claimable) ===
            if quest.canClaim {
                Button {
                    HapticManager.success()
                    SFXManager.shared.play(.uiQuestComplete)
                    showQuestBurst = true
                    burstQuestId = quest.id
                    Task { await vm.claimQuest(quest) }
                } label: {
                    if isClaiming {
                        HexPulseLoader.onGold()
                    } else {
                        Text("CLAIM")
                    }
                }
                .buttonStyle(.compactPrimary)
                .disabled(isClaiming)
            }
        }
        .padding(LayoutConstants.spaceMS)
        // Ornamental card system
        .background(
            RadialGlowBackground(
                baseColor: quest.rewardClaimed ? DarkFantasyTheme.bgPrimary : DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: quest.rewardClaimed ? 0.2 : 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.12) : DarkFantasyTheme.borderMedium.opacity(0.15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    quest.rewardClaimed ? DarkFantasyTheme.success.opacity(0.2)
                    : quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.4)
                    : DarkFantasyTheme.borderSubtle,
                    lineWidth: quest.canClaim ? 1.5 : 1
                )
        )
        .cornerBrackets(
            color: quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.4)
                : quest.rewardClaimed ? DarkFantasyTheme.success.opacity(0.15)
                : DarkFantasyTheme.borderMedium.opacity(0.25),
            length: 14,
            thickness: 1.5
        )
        .compositingGroup()
        .shadow(color: quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.15) : .clear, radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
        .brightness(quest.rewardClaimed ? -0.08 : 0)
        .contentShape(Rectangle())
    }
}

// MARK: - Quest Card Press Style

struct QuestCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}
